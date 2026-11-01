const assert = require('node:assert/strict');
const http = require('node:http');
const test = require('node:test');

const { createApp } = require('../src/app');
const {
  MarketHistoryService,
  MARKET_RANGE_CONFIG,
} = require('../src/features/market/market.service');
const { historyResponseSchema } = require('../src/features/research/contracts');

const testInstrument = Object.freeze({
  instrument_id: 'instrument-acme-1',
  symbol: 'ACME',
  exchange: 'NYSE',
  currency: 'USD',
  provider_symbol: 'ACME',
});

const sampleBars = Object.freeze([
  {
    time: '2026-03-06T14:30:00Z',
    session_date: '2026-03-06',
    open: 100.5,
    high: 103.0,
    low: 99.0,
    close: 102.5,
    volume: 12000,
    adjusted_close: null,
    is_final: true,
  },
  {
    time: '2026-03-06T14:35:00Z',
    session_date: '2026-03-06',
    open: 102.5,
    high: 104.0,
    low: 101.5,
    close: 103.5,
    volume: 8500,
    adjusted_close: null,
    is_final: true,
  },
]);

function createInMemoryRepository(initial = []) {
  const rows = [...initial];
  return {
    rows,
    async latestForCacheKey(cacheKey) {
      return rows.filter((entry) => entry.cache_key === cacheKey).at(-1) || null;
    },
    async findById(id) {
      return rows.find((entry) => entry.snapshot_id === id) || null;
    },
    async create(snapshot) {
      rows.push(structuredClone(snapshot));
      return structuredClone(snapshot);
    },
  };
}

function createMockProvider({ bars = sampleBars, shouldFail = false, failureCode = 'PROVIDER_UNAVAILABLE' } = {}) {
  return {
    async fetchHistory(instrument, { range, resolution }) {
      if (shouldFail) {
        const error = new Error(failureCode);
        error.code = failureCode;
        throw error;
      }
      return {
        bars,
        actual_resolution: resolution || '5m',
        exchange_timezone: 'America/New_York',
        adjustment_basis: 'raw_ohlc_unadjusted',
        delay_status: 'delayed',
        as_of: '2026-03-06T14:35:00Z',
        fetched_at: '2026-03-06T15:00:00Z',
        source: { name: 'Yahoo Finance chart', provider: 'yahoo_chart' },
        warnings: [],
      };
    },
  };
}

function createTestMarketService({
  provider = createMockProvider(),
  repository = createInMemoryRepository(),
  now = () => new Date('2026-03-06T15:00:00Z'),
  resolver = async (id) => (id === testInstrument.instrument_id ? testInstrument : null),
} = {}) {
  let count = 0;
  return new MarketHistoryService({
    provider,
    snapshotRepository: repository,
    now,
    snapshotIdFactory: () => `test-snapshot-${++count}`,
    instrumentResolver: resolver,
  });
}

function dummyAuth(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'Not authorized, no token provided' });
  }
  const token = authHeader.slice(7).trim();
  if (token !== 'valid-test-token') {
    return res.status(401).json({ message: 'Not authorized, token failed' });
  }
  req.user = { _id: 'owner-test-user-1' };
  next();
}

async function withTestServer(app, fn) {
  const server = http.createServer(app);
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  try {
    const { port } = server.address();
    await fn(`http://127.0.0.1:${port}`);
  } finally {
    await new Promise((resolve, reject) => server.close((err) => (err ? reject(err) : resolve())));
  }
}

async function fetchJson(baseUrl, path, options = {}) {
  const res = await fetch(`${baseUrl}${path}`, options);
  let body = null;
  const contentType = res.headers.get('content-type') || '';
  if (contentType.includes('application/json')) {
    body = await res.json();
  } else {
    body = await res.text();
  }
  return { status: res.status, headers: res.headers, body };
}

test('H15A integration: protected history route is reachable through actual application routing', async () => {
  const marketService = createTestMarketService();
  const app = createApp({ marketService, authenticate: dummyAuth, logging: false });

  await withTestServer(app, async (baseUrl) => {
    const res = await fetchJson(
      baseUrl,
      `/api/v1/market/instruments/${testInstrument.instrument_id}/history?range=1D`,
      {
        headers: { authorization: 'Bearer valid-test-token' },
      },
    );

    assert.equal(res.status, 200);
    assert.equal(res.body.contract_version, 1);
    assert.equal(res.body.data_status, 'available');
    assert.equal(res.body.is_stale, false);
    assert.equal(res.body.range, '1D');
    assert.equal(res.body.requested_resolution, '5m');
    assert.equal(res.body.actual_resolution, '5m');
    assert.equal(res.body.bars.length, 2);
    assert.deepEqual(res.body.instrument, testInstrument);

    // Verify canonical contract validation passes
    assert.doesNotThrow(() => historyResponseSchema.parse(res.body));
  });
});

test('H15A integration: anonymous denial rejects requests missing authorization header with 401', async () => {
  const marketService = createTestMarketService();
  const app = createApp({ marketService, authenticate: dummyAuth, logging: false });

  await withTestServer(app, async (baseUrl) => {
    const res = await fetchJson(
      baseUrl,
      `/api/v1/market/instruments/${testInstrument.instrument_id}/history?range=1D`,
    );

    assert.equal(res.status, 401);
    assert.equal(res.body.message, 'Not authorized, no token provided');
  });
});

test('H15A integration: invalid token denial rejects invalid bearer token with 401', async () => {
  const marketService = createTestMarketService();
  const app = createApp({ marketService, authenticate: dummyAuth, logging: false });

  await withTestServer(app, async (baseUrl) => {
    const res = await fetchJson(
      baseUrl,
      `/api/v1/market/instruments/${testInstrument.instrument_id}/history?range=1D`,
      {
        headers: { authorization: 'Bearer bad-or-forged-token' },
      },
    );

    assert.equal(res.status, 401);
    assert.equal(res.body.message, 'Not authorized, token failed');
  });
});

test('H15A integration: truthful unavailable response on provider failure without cache', async () => {
  const failingProvider = createMockProvider({ shouldFail: true, failureCode: 'PROVIDER_UNAVAILABLE' });
  const marketService = createTestMarketService({ provider: failingProvider });
  const app = createApp({ marketService, authenticate: dummyAuth, logging: false });

  await withTestServer(app, async (baseUrl) => {
    const res = await fetchJson(
      baseUrl,
      `/api/v1/market/instruments/${testInstrument.instrument_id}/history?range=1D`,
      {
        headers: { authorization: 'Bearer valid-test-token' },
      },
    );

    assert.equal(res.status, 200);
    assert.equal(res.body.contract_version, 1);
    assert.equal(res.body.data_status, 'unavailable');
    assert.equal(res.body.is_stale, false);
    assert.deepEqual(res.body.bars, []);
    assert.equal(res.body.unavailable_reason, 'PROVIDER_UNAVAILABLE');
    assert.doesNotThrow(() => historyResponseSchema.parse(res.body));
  });
});

test('H15A integration: truthful stale-cache response on provider failure with expired cache', async () => {
  const repository = createInMemoryRepository();
  const fixedNow = new Date('2026-03-06T15:00:00Z');
  const pastFetched = new Date('2026-03-06T14:00:00Z').toISOString();
  const pastExpires = new Date('2026-03-06T14:01:00Z').toISOString();

  const cachedPayload = historyResponseSchema.parse({
    contract_version: 1,
    instrument: testInstrument,
    snapshot_id: 'test-cached-snapshot-1',
    range: '1D',
    requested_resolution: '5m',
    actual_resolution: '5m',
    exchange_timezone: 'America/New_York',
    session_mode: 'regular',
    adjustment_basis: 'raw_ohlc_unadjusted',
    as_of: '2026-03-06T14:00:00Z',
    fetched_at: pastFetched,
    data_status: 'available',
    delay_status: 'delayed',
    is_stale: false,
    available_ranges: ['1D'],
    bars: sampleBars,
    warnings: [],
    next_cursor: null,
  });

  await repository.create({
    snapshot_id: 'test-cached-snapshot-1',
    cache_key: 'market-history:v1:instrument-acme-1:1D:5m',
    instrument_id: testInstrument.instrument_id,
    range: '1D',
    requested_resolution: '5m',
    fetched_at: pastFetched,
    expires_at: pastExpires,
    response: cachedPayload,
  });

  const failingProvider = createMockProvider({ shouldFail: true, failureCode: 'PROVIDER_TIMEOUT' });
  const marketService = createTestMarketService({
    provider: failingProvider,
    repository,
    now: () => fixedNow,
  });
  const app = createApp({ marketService, authenticate: dummyAuth, logging: false });

  await withTestServer(app, async (baseUrl) => {
    const res = await fetchJson(
      baseUrl,
      `/api/v1/market/instruments/${testInstrument.instrument_id}/history?range=1D`,
      {
        headers: { authorization: 'Bearer valid-test-token' },
      },
    );

    assert.equal(res.status, 200);
    assert.equal(res.body.contract_version, 1);
    assert.equal(res.body.data_status, 'partial');
    assert.equal(res.body.is_stale, true);
    assert.equal(res.body.bars.length, 2);
    assert.ok(res.body.warnings.some((w) => w.code === 'STALE_CACHE'));
    assert.doesNotThrow(() => historyResponseSchema.parse(res.body));
  });
});

test('H15A integration: labels unsupported requested resolution as unavailable', async () => {
  const marketService = createTestMarketService();
  const app = createApp({ marketService, authenticate: dummyAuth, logging: false });

  await withTestServer(app, async (baseUrl) => {
    const res = await fetchJson(
      baseUrl,
      `/api/v1/market/instruments/${testInstrument.instrument_id}/history?range=1D&resolution=1d`,
      {
        headers: { authorization: 'Bearer valid-test-token' },
      },
    );

    assert.equal(res.status, 200);
    assert.equal(res.body.data_status, 'unavailable');
    assert.equal(res.body.unavailable_reason, 'UNSUPPORTED_RESOLUTION');
    assert.deepEqual(res.body.bars, []);
    assert.doesNotThrow(() => historyResponseSchema.parse(res.body));
  });
});

test('H15A integration: error shape returns 400 INVALID_RANGE for unknown range', async () => {
  const marketService = createTestMarketService();
  const app = createApp({ marketService, authenticate: dummyAuth, logging: false });

  await withTestServer(app, async (baseUrl) => {
    const res = await fetchJson(
      baseUrl,
      `/api/v1/market/instruments/${testInstrument.instrument_id}/history?range=10Y`,
      {
        headers: { authorization: 'Bearer valid-test-token' },
      },
    );

    assert.equal(res.status, 400);
    assert.equal(res.body.success, false);
    assert.equal(res.body.error.code, 'INVALID_RANGE');
  });
});

test('H15A integration: error shape returns 404 INSTRUMENT_NOT_FOUND for unknown instrument', async () => {
  const marketService = createTestMarketService();
  const app = createApp({ marketService, authenticate: dummyAuth, logging: false });

  await withTestServer(app, async (baseUrl) => {
    const res = await fetchJson(
      baseUrl,
      '/api/v1/market/instruments/unknown-instrument-999/history?range=1D',
      {
        headers: { authorization: 'Bearer valid-test-token' },
      },
    );

    assert.equal(res.status, 404);
    assert.equal(res.body.success, false);
    assert.equal(res.body.error.code, 'INSTRUMENT_NOT_FOUND');
  });
});

test('H15A integration: error shape returns 404 SNAPSHOT_NOT_FOUND for nonexistent snapshot', async () => {
  const marketService = createTestMarketService();
  const app = createApp({ marketService, authenticate: dummyAuth, logging: false });

  await withTestServer(app, async (baseUrl) => {
    const res = await fetchJson(
      baseUrl,
      `/api/v1/market/instruments/${testInstrument.instrument_id}/history?range=1D&snapshot_id=snapshot-missing-404`,
      {
        headers: { authorization: 'Bearer valid-test-token' },
      },
    );

    assert.equal(res.status, 404);
    assert.equal(res.body.success, false);
    assert.equal(res.body.error.code, 'SNAPSHOT_NOT_FOUND');
  });
});

test('H15A integration: transport-level parser DoS protection rejects oversized payload with 413', async () => {
  const marketService = createTestMarketService();
  const app = createApp({ marketService, authenticate: dummyAuth, logging: false, jsonLimit: '64kb' });

  await withTestServer(app, async (baseUrl) => {
    // Generate a payload exceeding 64kb
    const oversized = JSON.stringify({ padding: 'X'.repeat(70 * 1024) });
    const res = await fetchJson(baseUrl, '/api/v1/auth/login', {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
      },
      body: oversized,
    });

    assert.equal(res.status, 413);
  });
});

test('H15A integration: isolated app import and no premature position/research/automation mounts', async () => {
  const marketService = createTestMarketService();
  const app = createApp({ marketService, authenticate: dummyAuth, logging: false });

  await withTestServer(app, async (baseUrl) => {
    // Health check retained
    const health = await fetchJson(baseUrl, '/health');
    assert.equal(health.status, 200);
    assert.equal(health.body.status, 'healthy');

    // Webhook route is route-free (returns 404)
    const webhook = await fetchJson(baseUrl, '/webhook');
    assert.equal(webhook.status, 404);

    // Positions not mounted yet (returns 404)
    const positions = await fetchJson(baseUrl, '/api/v1/positions', {
      headers: { authorization: 'Bearer valid-test-token' },
    });
    assert.equal(positions.status, 404);

    // Research not mounted yet (returns 404)
    const research = await fetchJson(baseUrl, '/api/v1/research/positions/p1/latest', {
      headers: { authorization: 'Bearer valid-test-token' },
    });
    assert.equal(research.status, 404);
  });
});
