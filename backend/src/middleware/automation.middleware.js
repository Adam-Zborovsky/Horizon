const crypto = require('crypto');

const DEFAULT_MAX_BODY_BYTES = 64 * 1024;
const DEFAULT_REPLAY_CACHE_SIZE = 1_000;
const DEFAULT_REPLAY_TTL_MS = 15 * 60 * 1000;

class AutomationAuthorizationError extends Error {
  constructor(code, status) {
    super(code);
    this.code = code;
    this.status = status;
  }
}

function constantTimeEquals(left, right) {
  if (typeof left !== 'string' || typeof right !== 'string') return false;
  const leftBuffer = Buffer.from(left);
  const rightBuffer = Buffer.from(right);
  return leftBuffer.length === rightBuffer.length && crypto.timingSafeEqual(leftBuffer, rightBuffer);
}

function normalizeScopes(scopes) {
  if (Array.isArray(scopes)) return new Set(scopes.filter((scope) => typeof scope === 'string' && scope.length > 0));
  if (typeof scopes === 'string') return new Set(scopes.split(/[\s,]+/).filter(Boolean));
  return new Set();
}

function parseExpiration(value) {
  if (!value) return null;
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

function safeJsonSize(value) {
  if (value === undefined) return 0;
  try {
    return Buffer.byteLength(JSON.stringify(value));
  } catch {
    return Number.POSITIVE_INFINITY;
  }
}

function sendAutomationError(res, status, code) {
  return res.status(status).json({ code, message: 'Automation request denied.' });
}

function readBearerToken(req) {
  const authorization = req.get('authorization');
  if (!authorization || !authorization.startsWith('Bearer ')) return null;
  const token = authorization.slice('Bearer '.length).trim();
  return token || null;
}

function createAutomationMiddleware({
  token,
  scopes,
  ownerId,
  expiresAt,
  maxBodyBytes = DEFAULT_MAX_BODY_BYTES,
  now = () => new Date(),
  configuration,
} = {}) {
  return function requireAutomation({ requiredScopes = [], requireOwner = false } = {}) {
    return function automationMiddleware(req, res, next) {
      const configured = configuration ? configuration() : { token, scopes, ownerId, expiresAt, maxBodyBytes };
      const configuredToken = configured && configured.token;
      const configuredScopes = normalizeScopes(configured && configured.scopes);
      const configuredOwnerId = configured && configured.ownerId;
      const configuredExpiry = parseExpiration(configured && configured.expiresAt);
      const effectiveMaxBodyBytes = configured && Number.isSafeInteger(configured.maxBodyBytes)
        ? configured.maxBodyBytes
        : maxBodyBytes;

      if (!configuredToken || configuredScopes.size === 0 || !Number.isSafeInteger(effectiveMaxBodyBytes) || effectiveMaxBodyBytes < 1) {
        return sendAutomationError(res, 401, 'automation_auth_unavailable');
      }

      const presentedToken = readBearerToken(req);
      if (!presentedToken) return sendAutomationError(res, 401, 'automation_auth_required');
      if (!constantTimeEquals(presentedToken, configuredToken)) return sendAutomationError(res, 401, 'automation_auth_invalid');
      if (configured && configured.expiresAt && !configuredExpiry) return sendAutomationError(res, 401, 'automation_auth_unavailable');
      if (configuredExpiry && configuredExpiry.getTime() <= now().getTime()) {
        return sendAutomationError(res, 401, 'automation_auth_expired');
      }
      if (!requiredScopes.every((scope) => configuredScopes.has(scope))) {
        return sendAutomationError(res, 403, 'automation_scope_denied');
      }
      if (requireOwner && (!configuredOwnerId || typeof configuredOwnerId !== 'string')) {
        return sendAutomationError(res, 401, 'automation_owner_unavailable');
      }

      const contentLength = req.get('content-length');
      if (contentLength && (!/^\d+$/.test(contentLength) || Number(contentLength) > effectiveMaxBodyBytes)) {
        return sendAutomationError(res, 413, 'automation_body_too_large');
      }
      if (safeJsonSize(req.body) > effectiveMaxBodyBytes) {
        return sendAutomationError(res, 413, 'automation_body_too_large');
      }

      req.automation = Object.freeze({
        scopes: [...configuredScopes],
        ownerId: configuredOwnerId || null,
      });
      return next();
    };
  };
}

function createRunCallbackAuthorizer({
  now = () => new Date(),
  maxEntries = DEFAULT_REPLAY_CACHE_SIZE,
  replayTtlMs = DEFAULT_REPLAY_TTL_MS,
} = {}) {
  const deliveries = new Map();

  function reject(code, status) {
    throw new AutomationAuthorizationError(code, status);
  }

  function prune(timestamp) {
    for (const [key, value] of deliveries) {
      if (value.expiresAt <= timestamp || deliveries.size > maxEntries) deliveries.delete(key);
    }
  }

  return {
    authorize(requestContext, run) {
      const timestamp = now().getTime();
      prune(timestamp);

      if (!requestContext || !requestContext.automation || !Array.isArray(requestContext.automation.scopes)
        || !requestContext.automation.scopes.includes('research:callback')) {
        reject('automation_scope_denied', 403);
      }
      if (!run || typeof run.id !== 'string' || typeof run.owner_id_internal !== 'string'
        || !Number.isSafeInteger(run.position_revision) || run.position_revision < 1) {
        reject('automation_run_invalid', 409);
      }
      if (typeof requestContext.automation.ownerId !== 'string'
        || requestContext.automation.ownerId !== run.owner_id_internal) {
        reject('automation_owner_denied', 403);
      }
      const leaseExpiresAt = parseExpiration(run.lease_expires_at);
      if (!leaseExpiresAt || leaseExpiresAt.getTime() <= timestamp) reject('automation_lease_expired', 409);

      const headers = requestContext.headers || {};
      const runId = headers['x-horizon-run-id'];
      const nonce = headers['x-horizon-run-nonce'];
      const deliveryId = headers['x-horizon-delivery-id'];
      if (runId !== run.id || typeof deliveryId !== 'string' || deliveryId.length === 0 || deliveryId.length > 128) {
        reject('automation_callback_denied', 403);
      }
      if (!constantTimeEquals(nonce, run.lease_nonce)) reject('automation_nonce_denied', 403);

      const deliveryKey = `${run.id}:${deliveryId}`;
      const digest = crypto.createHash('sha256').update(JSON.stringify(requestContext.body || null)).digest('hex');
      const existing = deliveries.get(deliveryKey);
      if (existing) {
        if (!constantTimeEquals(existing.digest, digest)) reject('automation_replay_conflict', 409);
        return { idempotent: true };
      }

      deliveries.set(deliveryKey, { digest, expiresAt: Math.min(leaseExpiresAt.getTime(), timestamp + replayTtlMs) });
      prune(timestamp);
      return { idempotent: false };
    },
  };
}

module.exports = {
  AutomationAuthorizationError,
  DEFAULT_MAX_BODY_BYTES,
  createAutomationMiddleware,
  createRunCallbackAuthorizer,
};
