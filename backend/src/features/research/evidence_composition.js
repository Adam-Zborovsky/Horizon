'use strict';

// Production composition for the existing SEC and company-news adapters.
// This module owns dependency construction only: it performs no I/O until an
// explicit EvidenceService.gatherEvidence() call and accepts no credentials.

const { EvidenceService, createMongooseEvidenceRepository } = require('./evidence.service');
const { SecEvidenceAdapter, SecTickerCikResolver } = require('./providers/sec');
const { CompanyNewsProvider } = require('./providers/company_news');

const DEFAULT_PROVIDER_TIMEOUT_MS = 8_000;
const MAX_PROVIDER_TIMEOUT_MS = 8_000;
const MAX_UPSTREAM_REQUESTS_PER_GATHER = 4; // SEC mapping + submissions + facts, then one news feed.
const SEC_DISABLED_GAP = 'sec_filings_not_configured';
const NEWS_DISABLED_GAP = 'company_news_not_configured';

function compositionError(code, message) {
  const error = new Error(message);
  error.code = code;
  return error;
}

function requireBoundedTimeout(timeoutMs) {
  if (!Number.isInteger(timeoutMs) || timeoutMs <= 0 || timeoutMs > MAX_PROVIDER_TIMEOUT_MS) {
    throw new RangeError(`timeoutMs must be an integer between 1 and ${MAX_PROVIDER_TIMEOUT_MS}`);
  }
  return timeoutMs;
}

function assertInstrumentIdentity(instrument) {
  if (!instrument || typeof instrument !== 'object') {
    throw compositionError('INSTRUMENT_CONTEXT_REQUIRED', 'A server-bound instrument context is required');
  }
  if (typeof instrument.instrument_id !== 'string' || instrument.instrument_id.length === 0) {
    throw compositionError('INSTRUMENT_IDENTITY_MISSING', 'Server-bound instrument has no instrument_id');
  }
  if (typeof instrument.symbol !== 'string' || instrument.symbol.trim().length === 0) {
    throw compositionError('INSTRUMENT_SYMBOL_MISSING', 'Resolved instrument has no symbol for the company-news adapter');
  }

  // Preserve the canonical ID exactly; only pass adapter-recognized identity
  // fields. A missing CIK is deliberate: SecEvidenceAdapter surfaces explicit
  // SEC unavailability instead of issuing a fabricated CIK request.
  return Object.freeze({
    instrument_id: instrument.instrument_id,
    symbol: instrument.symbol.trim(),
    provider_symbol: typeof instrument.provider_symbol === 'string' && instrument.provider_symbol.trim()
      ? instrument.provider_symbol.trim()
      : null,
    exchange: typeof instrument.exchange === 'string' && instrument.exchange.trim()
      ? instrument.exchange.trim()
      : null,
    currency: typeof instrument.currency === 'string' && instrument.currency.trim()
      ? instrument.currency.trim()
      : null,
    cik: instrument.cik == null || instrument.cik === '' ? null : String(instrument.cik),
    news_feed_url: typeof instrument.news_feed_url === 'string' ? instrument.news_feed_url : null,
    ir_feed_url: typeof instrument.ir_feed_url === 'string' ? instrument.ir_feed_url : null,
  });
}


function isConfiguredContactUserAgent(userAgent) {
  // SEC asks automated clients to identify a contact. Reject the old placeholder
  // and require an email address or URL supplied by the operator.
  if (typeof userAgent !== 'string' || userAgent.trim().length === 0) return false;
  const value = userAgent.trim();
  if (/contact@horizon\.local/i.test(value)) return false;
  return /[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/i.test(value) || /https:\/\//i.test(value);
}

function disabledProvider(method, gap) {
  return { availabilityGap: gap, async [method]() { return []; } };
}

function createProductionEvidenceService({
  evidenceModel,
  fetchImpl = globalThis.fetch,
  timeoutMs = DEFAULT_PROVIDER_TIMEOUT_MS,
  userAgent = null,
  now = () => new Date(),
  snapshotIdFactory,
  mappingCacheTtlMs,
} = {}) {
  if (typeof fetchImpl !== 'function') throw new TypeError('createProductionEvidenceService requires fetchImpl');
  const boundedTimeoutMs = requireBoundedTimeout(timeoutMs);
  const evidenceRepository = createMongooseEvidenceRepository(evidenceModel);
  const enabled = isConfiguredContactUserAgent(userAgent);
  const secProvider = enabled
    ? new SecEvidenceAdapter({
      fetch: fetchImpl,
      userAgent: userAgent.trim(),
      timeoutMs: boundedTimeoutMs,
      now,
      cikResolver: new SecTickerCikResolver({
        fetch: fetchImpl,
        userAgent: userAgent.trim(),
        timeoutMs: boundedTimeoutMs,
        now,
        ...(mappingCacheTtlMs === undefined ? {} : { cacheTtlMs: mappingCacheTtlMs }),
      }),
    })
    : disabledProvider('fetchEvidence', SEC_DISABLED_GAP);
  const newsProvider = enabled
    ? new CompanyNewsProvider({ fetch: fetchImpl, userAgent: userAgent.trim(), timeoutMs: boundedTimeoutMs, now })
    : disabledProvider('fetchNews', NEWS_DISABLED_GAP);

  return new EvidenceService({
    secProvider,
    newsProvider,
    evidenceRepository,
    instrumentNormalizer: assertInstrumentIdentity,
    now,
    ...(snapshotIdFactory ? { snapshotIdFactory } : {}),
  });
}
module.exports = {
  DEFAULT_PROVIDER_TIMEOUT_MS,
  MAX_PROVIDER_TIMEOUT_MS,
  MAX_UPSTREAM_REQUESTS_PER_GATHER,
  SEC_DISABLED_GAP,
  NEWS_DISABLED_GAP,
  isConfiguredContactUserAgent,
  assertInstrumentIdentity,
  createProductionEvidenceService,

  requireBoundedTimeout,
};
