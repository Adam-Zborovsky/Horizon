'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const {
  MAX_PROVIDER_TIMEOUT_MS,
  MAX_UPSTREAM_REQUESTS_PER_GATHER,
  assertInstrumentIdentity,
  createProductionEvidenceService,
  requireBoundedTimeout,
} = require('../src/features/research/evidence_composition');

const NOW = '2026-10-30T20:00:00.000Z';
const CUTOFF = '2026-10-30T20:00:00.000Z';
const INSTRUMENT = Object.freeze({
  instrument_id: 'inst-aapl',
  symbol: 'AAPL',
  provider_symbol: 'AAPL',
  exchange: 'XNAS',
  currency: 'USD',
  cik: '320193',
});

function memoryEvidenceModel() {
  const records = [];
  return {
    records,
    async create(record) {
      records.push(structuredClone(record));
    },
  };
}

function productionFetch(calls) {
  return async (url, options) => {
    calls.push({ url: String(url), options });
    if (String(url) === 'https://www.sec.gov/files/company_tickers.json') {
      return { ok: true, status: 200, json: async () => ({ 0: { ticker: 'AAPL', cik_str: 320193, title: 'Apple Inc.' } }) };
    }
    if (String(url).includes('/submissions/')) {
      return {
        ok: true,
        status: 200,
        json: async () => ({ cik: '0000320193', filings: { recent: {
          accessionNumber: ['0000320193-26-000001'],
          filingDate: ['2026-10-29'],
          reportDate: ['2026-09-30'],
          acceptanceDateTime: ['2026-10-29T20:00:00.000Z'],
          form: ['10-Q'],
          primaryDocument: ['aapl-20260930.htm'],
        } } }),
      };
    }
    if (String(url).includes('/companyfacts/')) {
      return { ok: true, status: 200, json: async () => ({ facts: {} }) };
    }
    if (String(url).startsWith('https://feeds.finance.yahoo.com/')) {
      return {
        ok: true,
        status: 200,
        headers: { get: () => 'application/rss+xml' },
        text: async () => '<rss><channel><item><title>Apple update</title><link>https://finance.yahoo.com/news/apple-update.html</link><pubDate>Thu, 30 Oct 2026 12:00:00 GMT</pubDate><description>Company update.</description></item></channel></rss>',
      };
    }
    throw new Error(`Unexpected URL: ${url}`);
  };
}

test('production evidence composition maps server-bound identity to bounded SEC/news adapters without credentials', async () => {
  const calls = [];
  const model = memoryEvidenceModel();
  const service = createProductionEvidenceService({
    evidenceModel: model,
    fetchImpl: productionFetch(calls),
    userAgent: 'HorizonResearch ops@example.com',
    now: () => new Date(NOW),
    snapshotIdFactory: () => 'snapshot-composed-1',
  });

  const { snapshot } = await service.gatherEvidence({
    instrument: INSTRUMENT,
    sessionAsOf: '2026-10-30',
    cutoffAt: CUTOFF,
  });

  assert.equal(snapshot.instrument_id, INSTRUMENT.instrument_id);
  assert.equal(snapshot.cutoff_at, CUTOFF);
  assert.equal(snapshot.coverage.status, 'available');
  assert.equal(snapshot.coverage.sec_filings, 'available');
  assert.equal(snapshot.coverage.company_news, 'available');
  assert.equal(model.records.length, 1);
  assert.equal(calls.length, MAX_UPSTREAM_REQUESTS_PER_GATHER);
  assert.deepEqual(calls.map((call) => call.url), [
    'https://www.sec.gov/files/company_tickers.json',
    'https://data.sec.gov/submissions/CIK0000320193.json',
    'https://data.sec.gov/api/xbrl/companyfacts/CIK0000320193.json',
    'https://feeds.finance.yahoo.com/rss/2.0/headline?s=AAPL&region=US&lang=en-US',
  ]);
  assert.ok(calls.every((call) => call.options.headers['User-Agent'] === 'HorizonResearch ops@example.com'));
  assert.ok(calls.every((call) => call.options.signal instanceof AbortSignal));
});

test('server-bound instrument validation preserves missing-identity truthfulness', async () => {
  const calls = [];
  assert.throws(() => assertInstrumentIdentity({ instrument_id: 'inst-aapl' }), (error) => error.code === 'INSTRUMENT_SYMBOL_MISSING');

  const service = createProductionEvidenceService({
    evidenceModel: memoryEvidenceModel(),
    fetchImpl: productionFetch(calls),
    userAgent: 'HorizonResearch ops@example.com',
    now: () => new Date(NOW),
    snapshotIdFactory: () => 'snapshot-no-cik',
  });
  const { snapshot } = await service.gatherEvidence({
    instrument: { ...INSTRUMENT, symbol: 'MISSING', cik: null },
    sessionAsOf: '2026-10-30',
    cutoffAt: CUTOFF,
  });
  assert.equal(snapshot.coverage.status, 'partial');
  assert.equal(snapshot.coverage.sec_filings, 'unavailable');
  assert.equal(snapshot.coverage.company_news, 'available');
  assert.ok(snapshot.coverage.gaps.includes('sec_filings_unavailable'));
  assert.equal(calls.length, 2, 'unmapped ticker fetches only the authoritative map and news feed');
  assert.ok(calls.some((call) => call.url === 'https://www.sec.gov/files/company_tickers.json'));
  assert.ok(calls.some((call) => /^https:\/\/feeds\.finance\.yahoo\.com\//.test(call.url)));
  assert.ok(!calls.some((call) => call.url.includes('/submissions/') || call.url.includes('/companyfacts/')));
  assert.ok(snapshot.coverage.gaps.includes('sec_cik_mapping_unavailable'));
});

test('composition enforces the provider timeout ceiling', () => {
  assert.equal(requireBoundedTimeout(MAX_PROVIDER_TIMEOUT_MS), MAX_PROVIDER_TIMEOUT_MS);
  assert.throws(() => requireBoundedTimeout(MAX_PROVIDER_TIMEOUT_MS + 1), RangeError);
  assert.throws(() => createProductionEvidenceService({
    evidenceModel: memoryEvidenceModel(),
    fetchImpl: async () => { throw new Error('must not call'); },
    timeoutMs: MAX_PROVIDER_TIMEOUT_MS + 1,
  }), RangeError);
});


test('absent or placeholder contact disables external evidence without any request', async () => {
  const calls = [];
  const service = createProductionEvidenceService({
    evidenceModel: memoryEvidenceModel(),
    fetchImpl: productionFetch(calls),
    userAgent: 'HorizonResearch contact@horizon.local',
    now: () => new Date(NOW),
  });
  const { snapshot } = await service.gatherEvidence({ instrument: INSTRUMENT, sessionAsOf: '2026-10-30', cutoffAt: CUTOFF });
  assert.equal(calls.length, 0);
  assert.equal(snapshot.coverage.status, 'unavailable');
  assert.ok(snapshot.coverage.gaps.includes('sec_filings_not_configured'));
  assert.ok(snapshot.coverage.gaps.includes('company_news_not_configured'));
});

test('SEC ticker mapping is cached and unknown tickers produce no submissions request', async () => {
  const calls = [];
  const service = createProductionEvidenceService({
    evidenceModel: memoryEvidenceModel(),
    fetchImpl: productionFetch(calls),
    userAgent: 'HorizonResearch ops@example.com',
    now: () => new Date(NOW),
  });
  await service.gatherEvidence({ instrument: INSTRUMENT, sessionAsOf: '2026-10-30', cutoffAt: CUTOFF });
  await service.gatherEvidence({ instrument: INSTRUMENT, sessionAsOf: '2026-10-30', cutoffAt: CUTOFF });
  assert.equal(calls.filter((call) => call.url === 'https://www.sec.gov/files/company_tickers.json').length, 1);
});

test('SEC mapping timeout is bounded even when a fetch implementation ignores abort', async () => {
  const service = createProductionEvidenceService({
    evidenceModel: memoryEvidenceModel(),
    fetchImpl: async () => new Promise(() => {}),
    userAgent: 'HorizonResearch ops@example.com',
    timeoutMs: 1,
    now: () => new Date(NOW),
  });
  const { snapshot } = await service.gatherEvidence({ instrument: INSTRUMENT, sessionAsOf: '2026-10-30', cutoffAt: CUTOFF });
  assert.ok(snapshot.coverage.gaps.includes('sec_provider_timeout'));
  assert.ok(snapshot.coverage.gaps.includes('news_coverage_unavailable'));
});
