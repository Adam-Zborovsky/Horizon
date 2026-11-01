const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const http = require('node:http');
const test = require('node:test');
const express = require('express');

const {
  createAutomationMiddleware,
  createRunCallbackAuthorizer,
} = require('../src/middleware/automation.middleware');
const { createBriefingRouter } = require('../src/features/briefing/briefing.routes');
const briefingController = require('../src/features/briefing/briefing.controller');
const briefingService = require('../src/features/briefing/briefing.service');

const TEST_OWNER_ID = 'owner-test-001';

function makeToken() {
  return crypto.randomBytes(32).toString('hex');
}

async function withServer(router, fn) {
  const app = express();
  app.use(express.json({ limit: '1mb' }));
  app.use(router);
  const server = http.createServer(app);
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));

  try {
    const { port } = server.address();
    await fn(`http://127.0.0.1:${port}`);
  } finally {
    await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
  }
}

async function request(baseUrl, path, options = {}) {
  const response = await fetch(`${baseUrl}${path}`, options);
  return {
    status: response.status,
    body: await response.json(),
  };
}

function makeRouter({ token = makeToken(), scopes = ['briefing:read', 'briefing:write'], expiresAt, maxBodyBytes = 1024 } = {}) {
  const calls = [];
  const controller = {
    async save(req, res) {
      calls.push({ type: 'save', ownerId: req.automation.ownerId, body: req.body });
      res.status(201).json({ ownerId: req.automation.ownerId });
    },
    async getConfigForSystem(req, res) {
      calls.push({ type: 'config', ownerId: req.automation.ownerId, query: req.query });
      res.status(200).json({ ownerId: req.automation.ownerId });
    },
    getLatest: (_req, res) => res.status(200).json({}),
    triggerManual: (_req, res) => res.status(202).json({}),
    getLatestTimestamp: (_req, res) => res.status(200).json({}),
    searchTickers: (_req, res) => res.status(200).json([]),
    getConfig: (_req, res) => res.status(200).json({}),
    getHistory: (_req, res) => res.status(200).json([]),
    getOpportunityStats: (_req, res) => res.status(200).json({}),
    toggleTopic: (_req, res) => res.status(200).json({}),
    removeTopic: (_req, res) => res.status(200).json({}),
    getRecommendedTopics: (_req, res) => res.status(200).json([]),
    updateConfig: (_req, res) => res.status(200).json({}),
  };

  return {
    token,
    calls,
    router: createBriefingRouter({
      controller,
      authMiddleware: (_req, _res, next) => next(),
      automationMiddleware: createAutomationMiddleware({
        token,
        scopes,
        ownerId: TEST_OWNER_ID,
        expiresAt,
        maxBodyBytes,
      }),
    }),
  };
}

test('automation middleware fails closed when release configuration is absent', () => {
  const middleware = createAutomationMiddleware({ configuration: () => ({}) });
  const response = {
    statusCode: null,
    payload: null,
    status(statusCode) {
      this.statusCode = statusCode;
      return this;
    },
    json(payload) {
      this.payload = payload;
      return this;
    },
  };

  middleware({ requiredScopes: ['briefing:read'], requireOwner: true })(
    { body: {}, get: () => null },
    response,
    assert.fail,
  );

  assert.equal(response.statusCode, 401);
  assert.equal(response.payload.code, 'automation_auth_unavailable');
});

test('legacy ingestion denies anonymous, invalid, expired, and insufficiently scoped automation requests', async () => {
  const token = makeToken();
  const expired = makeRouter({ token, expiresAt: '2000-01-01T00:00:00.000Z' });

  await withServer(expired.router, async (baseUrl) => {
    const anonymous = await request(baseUrl, '/', { method: 'POST', headers: { 'content-type': 'application/json' }, body: '{}' });
    assert.equal(anonymous.status, 401);
    assert.equal(anonymous.body.code, 'automation_auth_required');

    const anonymousConfig = await request(baseUrl, '/config/system');
    assert.equal(anonymousConfig.status, 401);
    assert.equal(anonymousConfig.body.code, 'automation_auth_required');

    const invalid = await request(baseUrl, '/', {
      method: 'POST',
      headers: { authorization: `Bearer ${makeToken()}`, 'content-type': 'application/json' },
      body: '{}',
    });
    assert.equal(invalid.status, 401);
    assert.equal(invalid.body.code, 'automation_auth_invalid');

    const expiredResponse = await request(baseUrl, '/', {
      method: 'POST',
      headers: { authorization: `Bearer ${token}`, 'content-type': 'application/json' },
      body: '{}',
    });
    assert.equal(expiredResponse.status, 401);
    assert.equal(expiredResponse.body.code, 'automation_auth_expired');
  });

  const readOnly = makeRouter({ scopes: ['briefing:read'] });
  await withServer(readOnly.router, async (baseUrl) => {
    const response = await request(baseUrl, '/', {
      method: 'POST',
      headers: { authorization: `Bearer ${readOnly.token}`, 'content-type': 'application/json' },
      body: '{}',
    });
    assert.equal(response.status, 403);
    assert.equal(response.body.code, 'automation_scope_denied');
  });
});

test('legacy ingestion cannot use a client userId to target another owner', async () => {
  const fixture = makeRouter();

  await withServer(fixture.router, async (baseUrl) => {
    const spoofedSave = await request(baseUrl, '/', {
      method: 'POST',
      headers: { authorization: `Bearer ${fixture.token}`, 'content-type': 'application/json' },
      body: JSON.stringify({ userId: 'other-owner-999', data: { status: 'safe-test' } }),
    });
    assert.equal(spoofedSave.status, 403);
    assert.equal(spoofedSave.body.code, 'automation_owner_denied');

    const spoofedConfig = await request(baseUrl, '/config/system?userId=other-owner-999', {
      headers: { authorization: `Bearer ${fixture.token}` },
    });
    assert.equal(spoofedConfig.status, 403);
    assert.equal(spoofedConfig.body.code, 'automation_owner_denied');

    const accepted = await request(baseUrl, '/', {
      method: 'POST',
      headers: { authorization: `Bearer ${fixture.token}`, 'content-type': 'application/json' },
      body: JSON.stringify({ userId: TEST_OWNER_ID, data: { status: 'safe-test' } }),
    });
    assert.equal(accepted.status, 201);
    assert.deepEqual(fixture.calls, [{
      type: 'save',
      ownerId: TEST_OWNER_ID,
      body: { userId: TEST_OWNER_ID, data: { status: 'safe-test' } },
    }]);
  });
});

test('automation route rejects bodies beyond its bounded callback payload limit', async () => {
  const fixture = makeRouter({ maxBodyBytes: 64 });
  const body = JSON.stringify({ userId: TEST_OWNER_ID, data: 'x'.repeat(128) });

  await withServer(fixture.router, async (baseUrl) => {
    const response = await request(baseUrl, '/', {
      method: 'POST',
      headers: {
        authorization: `Bearer ${fixture.token}`,
        'content-type': 'application/json',
        'content-length': String(Buffer.byteLength(body)),
      },
      body,
    });
    assert.equal(response.status, 413);
    assert.equal(response.body.code, 'automation_body_too_large');
    assert.equal(fixture.calls.length, 0);
  });
});

test('run callback authorization requires a current nonce and rejects conflicting replay deliveries', () => {
  const authorizer = createRunCallbackAuthorizer({ now: () => new Date('2030-01-01T00:00:00.000Z') });
  const run = {
    id: 'run-test-001',
    owner_id_internal: TEST_OWNER_ID,
    position_revision: 3,
    lease_nonce: makeToken(),
    lease_expires_at: '2030-01-01T00:05:00.000Z',
  };
  const requestContext = {
    automation: { scopes: ['research:callback'], ownerId: TEST_OWNER_ID },
    headers: {
      'x-horizon-run-id': run.id,
      'x-horizon-run-nonce': run.lease_nonce,
      'x-horizon-delivery-id': 'delivery-test-001',
    },
    body: { status: 'limited' },
  };

  assert.deepEqual(authorizer.authorize(requestContext, run), { idempotent: false });
  assert.deepEqual(authorizer.authorize(requestContext, run), { idempotent: true });
  assert.throws(
    () => authorizer.authorize({ ...requestContext, body: { status: 'complete' } }, run),
    { code: 'automation_replay_conflict' },
  );
  assert.throws(
    () => authorizer.authorize({
      ...requestContext,
      headers: { ...requestContext.headers, 'x-horizon-run-nonce': makeToken() },
    }, run),
    { code: 'automation_nonce_denied' },
  );
  assert.throws(
    () => authorizer.authorize({
      ...requestContext,
      automation: { scopes: ['research:callback'], ownerId: 'other-owner-999' },
      headers: { ...requestContext.headers, 'x-horizon-delivery-id': 'delivery-test-other-owner' },
    }, run),
    { code: 'automation_owner_denied' },
  );
});

test('legacy controller persists only the automation-bound owner and removes client userId', async () => {
  const originalSave = briefingService.save;
  const originalGetConfig = briefingService.getConfig;
  const saved = [];
  const response = {
    statusCode: null,
    payload: null,
    status(statusCode) {
      this.statusCode = statusCode;
      return this;
    },
    json(payload) {
      this.payload = payload;
      return this;
    },
  };

  briefingService.save = async (ownerId, data) => {
    saved.push({ ownerId, data });
    return { stored: true };
  };
  briefingService.getConfig = async (ownerId) => ({
    ownerId,
    topics: [],
    tickers: [],
  });

  try {
    await briefingController.save({
      automation: { ownerId: TEST_OWNER_ID },
      body: { userId: TEST_OWNER_ID, data: { status: 'safe-test' } },
    }, response, assert.fail);
    assert.equal(response.statusCode, 201);
    assert.deepEqual(saved, [{ ownerId: TEST_OWNER_ID, data: { data: { status: 'safe-test' } } }]);

    const configResponse = { ...response, statusCode: null, payload: null };
    await briefingController.getConfigForSystem({
      automation: { ownerId: TEST_OWNER_ID },
      query: { userId: TEST_OWNER_ID },
    }, configResponse, assert.fail);
    assert.equal(configResponse.statusCode, 200);
    assert.deepEqual(configResponse.payload, { userId: TEST_OWNER_ID, topics: [], tickers: [] });
  } finally {
    briefingService.save = originalSave;
    briefingService.getConfig = originalGetConfig;
  }
});
