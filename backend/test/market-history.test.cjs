const assert = require('node:assert/strict');
const test = require('node:test');

const {
  MarketHistoryService,
  MARKET_RANGE_CONFIG,
} = require('../src/features/market/market.service');
const { YahooMarketProvider } = require('../src/features/market/providers/yahoo');
const { createMarketRouter } = require('../src/features/market/market.routes');

const instrument = Object.freeze({
  instrument_id: 'instrument-acme-1',
  symbol: 'ACME',
  exchange: 'NYSE',
  currency: 'USD',
  provider_symbol: 'ACME',
});

const validBars = Object.freeze([
  {
    time: '2026-03-06T14:30:00Z',
    session_date: '2026-03-06',
    open: 100,
    high: 103,
    low: 99,
    close: 102,
    volume: 1200,
    adjusted_close: null,
    is_final: true,
  },
  {
    time: '2026-03-09T13:30:00Z',
    session_date: '2026-03-09',
    open: 103,
    high: 104,
    low: 101,
    close: 102,
    volume: 900,
    adjusted_close: null,
    is_final: true,
  },
]);

function createRepository(initial = []) {
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

function createService({ provider, repository = createRepository(), now = () => new Date('2026-03-10T15:00:00Z') } = {}) {
  return new MarketHistoryService({
    provider,
    snapshotRepository: repository,
    now,
    snapshotIdFactory: (() => {
      let count = 0;
      return () => `snapshot-${++count}`;
    })(),
    instrumentResolver: async (instrumentId) => (instrumentId === instrument.instrument_id ? instrument : null),
  });
}

function providerResult(overrides = {}) {
  return {
    bars: validBars,
    actual_resolution: '1d',
    exchange_timezone: 'America/New_York',
    adjustment_basis: 'raw_ohlc_unadjusted',
    delay_status: 'unknown',
    as_of: '2026-03-09T20:00:00Z',
    fetched_at: '2026-03-10T15:00:00Z',
    source: { name: 'Yahoo Finance chart', provider: 'yahoo_chart' },
    warnings: [],
    ...overrides,
  };
}

function yahooChartPayload() {
  return {
    chart: {
      result: [{
        meta: {
          currency: 'USD',
          exchangeTimezoneName: 'America/New_York',
          dataGranularity: '5m',
          regularMarketTime: 1773088200,
          exchangeDataDelayedBy: 15,
        },
        timestamp: [1773088200, 1773088500],
        indicators: {
          quote: [{
            open: [100, null],
            high: [101, 102],
            low: [99, 100],
            close: [100.5, 101],
            volume: [1000, 1200],
          }],
          adjclose: [{ adjclose: [100.5, 101] }],
        },
      }],
      error: null,
    },
  };
}

test('maps every contract range to its truthful preferred resolution', () => {
  assert.deepEqual(
    Object.fromEntries(Object.entries(MARKET_RANGE_CONFIG).map(([range, config]) => [range, config.preferred_resolution])),
    { '1D': '5m', '1W': '30m', '1M': '1d', '3M': '1d', '6M': '1d', '1Y': '1d' },
  );
});

test('labels an unsupported requested resolution instead of silently relabeling it', async () => {
  const service = createService({ provider: { fetchHistory: async () => assert.fail('provider must not run') } });

  const response = await service.getHistory({
    instrumentId: instrument.instrument_id,
    range: '1W',
    resolution: '1m',
  });

  assert.equal(response.data_status, 'unavailable');
  assert.equal(response.requested_resolution, '1m');
  assert.equal(response.actual_resolution, '1m');
  assert.equal(response.unavailable_reason, 'UNSUPPORTED_RESOLUTION');
  assert.equal(response.bars.length, 0);
});

test('removes invalid and duplicate provider bars, keeps ascending observed bars, and reports partial data', async () => {
  const service = createService({
    provider: {
      fetchHistory: async () => providerResult({
        bars: [
          validBars[1],
          { ...validBars[0], high: 98 },
          validBars[0],
          validBars[0],
        ],
      }),
    },
  });

  const response = await service.getHistory({ instrumentId: instrument.instrument_id, range: '1M' });

  assert.equal(response.data_status, 'partial');
  assert.deepEqual(response.bars, validBars);
  assert.equal(response.instrument.currency, 'USD');
  assert.equal(response.adjustment_basis, 'raw_ohlc_unadjusted');
  assert.equal(response.delay_status, 'unknown');
  assert.equal(response.warnings[0].code, 'INVALID_BARS_OMITTED');
  assert.equal(response.warnings[0].count, 2);
  assert.equal(response.snapshot_id, 'snapshot-1');
});

test('uses an expired immutable snapshot after a provider timeout and marks it stale', async () => {
  const staleResponse = {
    contract_version: 1,
    instrument,
    snapshot_id: 'snapshot-cached',
    range: '1M',
    requested_resolution: '1d',
    actual_resolution: '1d',
    exchange_timezone: 'America/New_York',
    session_mode: 'regular',
    adjustment_basis: 'raw_ohlc_unadjusted',
    as_of: '2026-03-09T20:00:00Z',
    fetched_at: '2026-03-09T20:01:00Z',
    data_status: 'available',
    delay_status: 'unknown',
    is_stale: false,
    available_ranges: ['1M'],
    bars: validBars,
    warnings: [],
    next_cursor: null,
    source: { name: 'Yahoo Finance chart', provider: 'yahoo_chart' },
  };
  const repository = createRepository([{
    snapshot_id: 'snapshot-cached',
    cache_key: `market-history:v1:${instrument.instrument_id}:1M:1d`,
    expires_at: '2026-03-10T14:00:00Z',
    response: staleResponse,
  }]);
  const service = createService({
    repository,
    provider: {
      fetchHistory: async () => {
        const error = new Error('provider timed out');
        error.code = 'PROVIDER_TIMEOUT';
        throw error;
      },
    },
  });

  const response = await service.getHistory({ instrumentId: instrument.instrument_id, range: '1M' });

  assert.equal(response.snapshot_id, 'snapshot-cached');
  assert.equal(response.is_stale, true);
  assert.equal(response.data_status, 'partial');
  assert.equal(response.delay_status, 'unknown');
  assert.deepEqual(response.bars, validBars);
  assert.equal(response.warnings.at(-1).code, 'STALE_CACHE');
  assert.equal(response.warnings.at(-1).provider_error, 'PROVIDER_TIMEOUT');
});

test('returns an explicit unavailable result when the provider fails without cached observations', async () => {
  const service = createService({
    provider: {
      fetchHistory: async () => {
        const error = new Error('provider timed out');
        error.code = 'PROVIDER_TIMEOUT';
        throw error;
      },
    },
  });

  const response = await service.getHistory({ instrumentId: instrument.instrument_id, range: '1D' });

  assert.equal(response.data_status, 'unavailable');
  assert.equal(response.unavailable_reason, 'PROVIDER_TIMEOUT');
  assert.equal(response.is_stale, false);
  assert.deepEqual(response.bars, []);
});

test('treats early closes and DST-bearing UTC timestamps as observed provider timestamps', async () => {
  const earlyCloseBar = {
    ...validBars[0],
    time: '2026-11-27T18:00:00Z',
    session_date: '2026-11-27',
  };
  const afterDstBar = {
    ...validBars[1],
    time: '2026-11-30T14:30:00Z',
    session_date: '2026-11-30',
  };
  const service = createService({
    provider: { fetchHistory: async () => providerResult({ bars: [earlyCloseBar, afterDstBar], actual_resolution: '30m' }) },
  });

  const response = await service.getHistory({ instrumentId: instrument.instrument_id, range: '1W' });

  assert.deepEqual(response.bars.map((bar) => bar.time), [earlyCloseBar.time, afterDstBar.time]);
  assert.deepEqual(response.bars.map((bar) => bar.session_date), ['2026-11-27', '2026-11-30']);
  assert.equal(response.actual_resolution, '30m');
});

test('parses Yahoo chart rows without manufacturing OHLC values and exposes delayed metadata', async () => {
  const provider = new YahooMarketProvider({
    fetch: async () => ({
      ok: true,
      json: async () => yahooChartPayload(),
    }),
  });

  const response = await provider.fetchHistory(instrument, { range: '1D', resolution: '5m' });

  assert.equal(response.delay_status, 'delayed');
  assert.equal(response.bars.length, 1);
  assert.equal(response.bars[0].open, 100);
  assert.equal(response.invalid_bar_count, 1);
});

test('bounds a response body that ignores abort and classifies it as a provider timeout', async () => {
  let aborted = false;
  const provider = new YahooMarketProvider({
    timeoutMs: 25,
    fetch: async (_url, { signal }) => {
      signal.addEventListener('abort', () => { aborted = true; });
      return { ok: true, json: () => new Promise(() => {}) };
    },
  });

  const result = await Promise.race([
    provider.fetchHistory(instrument, { range: '1D', resolution: '5m' }).then(
      () => null,
      (error) => error,
    ),
    new Promise((resolve) => setTimeout(() => resolve(null), 75)),
  ]);

  assert.equal(result?.code, 'PROVIDER_TIMEOUT');
  assert.equal(aborted, true);
});

test('bounds stalled header fetch and classifies it as a provider timeout', async () => {
  let aborted = false;
  const provider = new YahooMarketProvider({
    timeoutMs: 25,
    fetch: async (_url, { signal }) => {
      signal.addEventListener('abort', () => { aborted = true; });
      return new Promise(() => {});
    },
  });

  await assert.rejects(
    provider.fetchHistory(instrument, { range: '1D', resolution: '5m' }),
    (error) => error.code === 'PROVIDER_TIMEOUT',
  );
  assert.equal(aborted, true);
});

test('keeps the timeout through delayed body parsing and clears it after success', async () => {
  let aborted = false;
  const provider = new YahooMarketProvider({
    timeoutMs: 40,
    fetch: async (_url, { signal }) => {
      signal.addEventListener('abort', () => { aborted = true; });
      return {
        ok: true,
        json: async () => {
          await new Promise((resolve) => setTimeout(resolve, 10));
          return yahooChartPayload();
        },
      };
    },
  });

  const response = await provider.fetchHistory(instrument, { range: '1D', resolution: '5m' });
  await new Promise((resolve) => setTimeout(resolve, 50));

  assert.equal(response.bars.length, 1);
  assert.equal(aborted, false);
});

test('classifies network failure as unavailable and body parse rejection as invalid response', async () => {
  let networkAborted = false;
  let bodyAborted = false;
  const networkProvider = new YahooMarketProvider({
    timeoutMs: 30,
    fetch: async (_url, { signal }) => {
      signal.addEventListener('abort', () => { networkAborted = true; });
      throw new Error('offline');
    },
  });
  const bodyProvider = new YahooMarketProvider({
    timeoutMs: 30,
    fetch: async (_url, { signal }) => {
      signal.addEventListener('abort', () => { bodyAborted = true; });
      return { ok: true, json: async () => { throw new Error('bad body'); } };
    },
  });

  await assert.rejects(
    networkProvider.fetchHistory(instrument, { range: '1D', resolution: '5m' }),
    (error) => error.code === 'PROVIDER_UNAVAILABLE',
  );
  await assert.rejects(
    bodyProvider.fetchHistory(instrument, { range: '1D', resolution: '5m' }),
    (error) => error.code === 'PROVIDER_INVALID_RESPONSE',
  );

  await new Promise((resolve) => setTimeout(resolve, 40));
  assert.equal(networkAborted, false);
  assert.equal(bodyAborted, false);
});

test('route factory applies injected authentication and only passes server-derived user context', async () => {
  const calls = [];
  const router = createMarketRouter({
    authenticate: (req, res, next) => {
      req.user = { _id: 'owner-1' };
      next();
    },
    marketService: {
      getHistory: async (input) => {
        calls.push(input);
        return { ok: true };
      },
    },
  });
  const layer = router.stack.find((entry) => entry.route?.path === '/instruments/:instrumentId/history');
  const handler = layer.route.stack.at(-1).handle;
  const response = { statusCode: null, body: null, status(code) { this.statusCode = code; return this; }, json(body) { this.body = body; return this; } };

  await handler({ params: { instrumentId: 'instrument-acme-1' }, query: { range: '1M' }, user: { _id: 'owner-1' } }, response, assert.fail);

  assert.deepEqual(calls, [{ ownerId: 'owner-1', instrumentId: 'instrument-acme-1', range: '1M', resolution: undefined, snapshotId: undefined }]);
  assert.equal(response.statusCode, 200);
  assert.deepEqual(response.body, { ok: true });
});
