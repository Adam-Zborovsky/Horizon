'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const {
  MAX_EXTERNAL_EVIDENCE_ITEMS,
  createMongooseRunInputProvider,
  priorDecisionFromDocument,
} = require('../src/features/research/run_inputs');
const {
  buildMarketSynthesisContext,
  renderSynthesisUserPrompt,
} = require('../src/features/research/prompts');

const INSTRUMENT = {
  instrument_id: 'inst-1', symbol: 'TEST', provider_symbol: 'TEST', exchange: 'XNYS', currency: 'USD', cik: '1234',
};
const NOW = '2026-10-30T20:00:00.000Z';
const CUTOFF = new Date(NOW);

function item(id, availableAt, extras = {}) {
  return {
    id,
    instrument_id: 'inst-1',
    kind: 'filing',
    title: `Fixture ${id}`,
    source_url: `https://sec.example/${id}`,
    source_name: 'SEC EDGAR',
    published_at: availableAt,
    retrieved_at: NOW,
    available_at: availableAt,
    reporting_period: null,
    excerpt: `Fixture excerpt ${id}`,
    source_locator: id,
    facts: [],
    coverage_status: 'available',
    ...extras,
  };
}

function weekday(session) {
  const day = new Date(`${session}T00:00:00Z`).getUTCDay();
  return day >= 1 && day <= 5;
}

function models(prior = null) {
  return {
    positionModel: {
      findOne: () => ({ lean: async () => ({
        _id: 'pos-1', state: 'owned', revision: 3, instrument: INSTRUMENT,
        average_cost: { amount: '10.00', currency: 'USD', basis: 'raw_purchase' }, quantity: '2',
      }) }),
    },
    assessmentModel: {
      findOne: () => ({ sort: () => ({ lean: async () => prior }) }),
    },
  };
}

function yahooFetch() {
  return async () => ({
    ok: true,
    json: async () => ({ chart: { result: [{
      timestamp: [Date.parse('2026-10-30T16:00:00Z') / 1000],
      meta: { currency: 'USD' },
      indicators: { quote: [{ open: [100], high: [101], low: [99], close: [100], volume: [5] }] },
    }] } }),
  });
}

test('run inputs inject cutoff-valid bounded evidence and surface truthful gaps', async () => {
  const calls = [];
  const sourceItems = Array.from({ length: MAX_EXTERNAL_EVIDENCE_ITEMS + 2 }, (_, index) => item(
    `sec-${index}`,
    `2026-10-${String(index + 1).padStart(2, '0')}T12:00:00.000Z`,
    index === MAX_EXTERNAL_EVIDENCE_ITEMS + 1 ? {
      facts: [{
        id: 'fact-revenue', label: 'Revenue', value: 123456, unit: 'USD', currency: 'USD', basis: 'US-GAAP',
        reporting_period: { start: '2026-07-01', end: '2026-09-30', label: 'Q3 2026' },
      }],
    } : {},
  ));
  sourceItems.push(item('post-cutoff', '2026-11-01T00:00:00.000Z'));
  sourceItems.push(item('wrong-instrument', '2026-10-30T12:00:00.000Z', { instrument_id: 'other' }));
  const evidenceService = {
    gatherEvidence: async (request) => {
      calls.push(request);
      return { snapshot: { coverage: { status: 'available', gaps: [] } }, items: sourceItems };
    },
  };
  const provider = createMongooseRunInputProvider({
    ...models(), evidenceService, fetchImpl: yahooFetch(), now: () => CUTOFF,
  });

  const inputs = await provider({
    id: 'run-1', position_id: 'pos-1', owner_id_internal: 'owner-1', position_revision: 3,
    run_input_ref: { instrument_id: INSTRUMENT.instrument_id },
  });

  assert.deepEqual(calls, [{ instrument: INSTRUMENT, sessionAsOf: '2026-10-30', cutoffAt: NOW }]);
  assert.equal(inputs.snapshot.coverage.status, 'partial');
  assert.ok(inputs.snapshot.coverage.gaps.includes('external_evidence_context_truncated'));
  assert.equal(inputs.snapshot.items.length, MAX_EXTERNAL_EVIDENCE_ITEMS + 1);
  assert.equal(inputs.snapshot.items[0].id, 'ev-market-daily-1y');
  assert.ok(!inputs.snapshot.items.some((entry) => entry.id === 'post-cutoff'));
  assert.ok(!inputs.snapshot.items.some((entry) => entry.id === 'wrong-instrument'));
  assert.ok(inputs.snapshot.items.some((entry) => entry.id === `sec-${MAX_EXTERNAL_EVIDENCE_ITEMS + 1}`));
});

test('run inputs report unconfigured primary sources instead of implying complete coverage', async () => {
  const provider = createMongooseRunInputProvider({ ...models(), fetchImpl: yahooFetch(), now: () => CUTOFF });
  const inputs = await provider({
    id: 'run-1', position_id: 'pos-1', owner_id_internal: 'owner-1', position_revision: 3,
    run_input_ref: { instrument_id: INSTRUMENT.instrument_id },
  });

  assert.equal(inputs.snapshot.coverage.status, 'partial');
  assert.deepEqual(inputs.snapshot.coverage.gaps, ['sec_filings_not_configured', 'company_news_not_configured']);
});


test('run inputs re-read only the exact owner, revision, and instrument bound to the claimed run', async () => {
  const queries = [];
  const position = {
    _id: 'pos-1', owner_id: 'owner-1', state: 'owned', revision: 3, instrument: INSTRUMENT,
    average_cost: { amount: '10.00', currency: 'USD', basis: 'raw_purchase' }, quantity: '2',
  };
  const positionModel = {
    findOne(query) {
      queries.push(query);
      const matches = query._id === position._id
        && query.owner_id === position.owner_id
        && query.revision === position.revision
        && query['instrument.instrument_id'] === position.instrument.instrument_id;
      return { lean: async () => (matches ? position : null) };
    },
  };
  const assessmentModel = { findOne: () => ({ sort: () => ({ lean: async () => null }) }) };
  const provider = createMongooseRunInputProvider({
    positionModel, assessmentModel, fetchImpl: yahooFetch(), now: () => CUTOFF,
  });
  const boundRun = {
    id: 'run-1', position_id: 'pos-1', owner_id_internal: 'owner-1', position_revision: 3,
    run_input_ref: { instrument_id: INSTRUMENT.instrument_id },
  };

  await provider(boundRun);
  assert.deepEqual(queries, [{
    _id: 'pos-1', owner_id: 'owner-1', revision: 3, 'instrument.instrument_id': 'inst-1',
  }]);

  for (const mutation of [
    { owner_id_internal: 'owner-2' },
    { position_revision: 4 },
    { run_input_ref: { instrument_id: 'inst-other' } },
  ]) {
    await assert.rejects(
      () => provider({ ...boundRun, ...mutation }),
      (error) => error.code === 'INPUT_UNAVAILABLE',
    );
  }
});

test('run inputs pass the owner-bound position instrument to evidence when owners share an instrument ID', async () => {
  const ownerInstrument = { ...INSTRUMENT, instrument_id: 'shared-instrument', symbol: 'OWNER_A' };
  const otherOwnerInstrument = { ...INSTRUMENT, instrument_id: 'shared-instrument', symbol: 'OWNER_B' };
  const positions = [
    { _id: 'position-a', owner_id: 'owner-a', revision: 3, state: 'owned', instrument: ownerInstrument, average_cost: { amount: '10.00', currency: 'USD', basis: 'raw_purchase' }, quantity: '2' },
    { _id: 'position-b', owner_id: 'owner-b', revision: 3, state: 'owned', instrument: otherOwnerInstrument, average_cost: { amount: '20.00', currency: 'USD', basis: 'raw_purchase' }, quantity: '1' },
  ];
  const received = [];
  const provider = createMongooseRunInputProvider({
    positionModel: { findOne: (query) => ({ lean: async () => positions.find((position) => position._id === query._id
      && position.owner_id === query.owner_id && position.revision === query.revision
      && position.instrument.instrument_id === query['instrument.instrument_id']) || null }) },
    assessmentModel: { findOne: () => ({ sort: () => ({ lean: async () => null }) }) },
    evidenceService: { gatherEvidence: async (request) => { received.push(request); return { snapshot: { coverage: { status: 'available', gaps: [] } }, items: [] }; } },
    fetchImpl: yahooFetch(), now: () => CUTOFF,
  });

  await provider({ id: 'run-owner-a', position_id: 'position-a', owner_id_internal: 'owner-a', position_revision: 3, run_input_ref: { instrument_id: 'shared-instrument' } });
  assert.equal(received.length, 1);
  assert.deepEqual(received[0].instrument, ownerInstrument);
  assert.notDeepEqual(received[0].instrument, otherOwnerInstrument);
});

test('prior assessment extraction and prompt preserve bounded prior decisions and SEC facts', () => {
  const prior = priorDecisionFromDocument({
    _id: 'assessment-1', session_as_of: '2026-09-30',
    assessment: {
      market_thesis: {
        business_assessment: { summary: 'Prior business decision.' },
        price_technical_assessment: { summary: 'Prior technical decision.' },
        valuation_assessment: { summary: 'Prior valuation decision.' },
      },
      recommendation: { action: 'hold', headline: 'Prior decision headline.', evidence_quality: 'Limited.' },
      outlooks: [{ horizon_months: 1, direction: 'mixed', data_limitations: ['Prior source gap.'] }],
      missing_data: ['Prior filing gap.'],
      checkpoints: [{ id: 'cp-1', kind: 'business_condition', condition: 'Watch revenue.', status: 'active' }],
    },
  });
  const snapshot = {
    snapshot_id: 'snap-1', instrument_id: 'inst-1', session_as_of: '2026-10-30', cutoff_at: NOW,
    coverage: { status: 'available', gaps: [] },
    items: [item('sec-fact', '2026-10-29T12:00:00.000Z', {
      facts: [{ id: 'fact-revenue', label: 'Revenue', value: 123456, unit: 'USD', currency: 'USD', basis: 'US-GAAP', reporting_period: null }],
    })],
  };
  const context = buildMarketSynthesisContext({
    instrument: INSTRUMENT, sessionAsOf: '2026-10-30', cutoffAt: NOW, snapshot, metrics: [],
    position: { position_id: 'pos-1', state: 'owned', preferred_horizon_months: 3 }, prior,
    isExchangeSession: weekday,
  }).context;
  const prompt = renderSynthesisUserPrompt(context);

  assert.match(prompt, /fact fact-revenue: Revenue=123456 USD USD basis=US-GAAP/);
  assert.match(prompt, /PRIOR REPORT \(a prior decision, NOT evidence\)/);
  assert.match(prompt, /prior business_assessment: Prior business decision/);
  assert.match(prompt, /prior recommendation: hold — Prior decision headline/);
  assert.match(prompt, /prior outlook 1m: mixed/);
  assert.match(prompt, /prior missing data: Prior filing gap/);
  assert.equal(context.prior.checkpoints[0].is_prior_decision, true);
});
