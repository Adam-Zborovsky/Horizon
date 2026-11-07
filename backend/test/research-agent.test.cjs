'use strict';

// H09 — bounded grounded research pipeline tests (agent_runtime).
// All model clients are mocks; no live model calls, no credentials, no paid
// services. Fixtures are synthetic and are NOT observed market data.

const assert = require('node:assert/strict');
const test = require('node:test');

const metricsMod = require('../src/features/research/metrics');
const validator = require('../src/features/research/result_validator');
const { createResearchAgentRuntime, PIPELINE_BUDGETS, composePositionContext } = require('../src/features/research/agent_runtime');

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

const INSTRUMENT = Object.freeze({
  instrument_id: 'inst-1',
  symbol: 'TEST',
  exchange: 'XNYS',
  currency: 'USD',
  provider_symbol: 'TEST',
});

function weekdayPredicate(sessionDate) {
  const weekday = new Date(`${sessionDate}T00:00:00Z`).getUTCDay();
  return weekday >= 1 && weekday <= 5;
}

function evidenceItem(id, kind, availableAt) {
  return {
    id,
    instrument_id: 'inst-1',
    kind,
    title: `Fixture ${id}`,
    source_url: `https://fixture.example/${id}`,
    source_name: 'Fixture Source',
    published_at: availableAt,
    retrieved_at: '2026-10-30T20:00:00.000Z',
    available_at: availableAt,
    reporting_period: null,
    excerpt: `Fixture excerpt for ${id}.`,
    source_locator: null,
    facts: [],
    coverage_status: 'available',
  };
}

function baseSnapshot(overrides = {}) {
  return {
    snapshot_id: 'snap-1',
    instrument_id: 'inst-1',
    session_as_of: '2026-10-30',
    cutoff_at: '2026-10-30T20:00:00.000Z',
    coverage: { status: 'available', gaps: [] },
    items: [
      evidenceItem('ev-filing', 'filing', '2026-10-28T14:00:00.000Z'),
      evidenceItem('ev-news', 'news', '2026-10-29T16:00:00.000Z'),
    ],
    ...overrides,
  };
}

const METRICS = [
  {
    id: 'm-close', instrument_id: 'inst-1', value: 150, unit: 'USD', currency: 'USD',
    as_of: '2026-10-30', basis: 'raw_close', method: 'last_close', method_version: 'v1',
    input_evidence_ids: ['ev-market'], input_snapshot_ids: [],
  },
  {
    id: 'm-vol', instrument_id: 'inst-1', value: 0.32, unit: 'ratio', currency: null,
    as_of: '2026-10-30', basis: 'raw_close', method: 'annualized_volatility', method_version: 'v1',
    input_evidence_ids: ['ev-market'], input_snapshot_ids: [],
  },
];

function ownedPosition(overrides = {}) {
  return {
    position_id: 'pos-1',
    state: 'owned',
    revision: 7,
    average_cost: { amount: '100.00', currency: 'USD', basis: 'raw_purchase' },
    quantity: '10',
    opened_on: '2026-01-05',
    preferred_horizon_months: 3,
    ...overrides,
  };
}

const RUN = Object.freeze({
  id: 'run-1',
  position_id: 'pos-1',
  owner_id_internal: 'owner-1',
  position_revision: 7,
  instrument_id: 'inst-1',
  run_kind: 'manual_refresh',
});

const PRIOR = Object.freeze({
  assessment_id: 'assess-0',
  session_as_of: '2026-09-30',
  checkpoints: [
    { id: 'cp-1', kind: 'fixed_observed_level', condition: 'price holds above 120', status: 'active' },
  ],
});

const CURRENT_PRICE = Object.freeze({ amount: '150.00', currency: 'USD', adjustment_basis: 'raw_purchase' });

function claim(text, { evidence = ['ev-filing'], metrics = [], type = 'observed' } = {}) {
  return { text, evidence_ids: evidence, metric_ids: metrics, claim_type: type };
}

function validSynthesis() {
  return {
    market_thesis: {
      business_assessment: {
        summary: 'Fixture business summary grounded in the filing.',
        claims: [claim('Fixture filing reports a business development.')],
      },
      price_technical_assessment: {
        summary: 'Fixture price structure summary.',
        claims: [claim('Fixture closing level is consistent with the metric.', { metrics: ['m-close'] })],
      },
      valuation_assessment: {
        summary: 'Fixture valuation summary.',
        claims: [claim('Fixture valuation interpretation.', { type: 'interpretation' })],
      },
      rationale: [claim('Fixture rationale grounded in the filing.')],
      counterevidence: [claim('Fixture counterevidence from the news item.', { evidence: ['ev-news'] })],
    },
    recommendation: {
      action: 'hold',
      horizon_months: 3,
      headline: 'Fixture headline.',
      rationale: [claim('Fixture recommendation rationale.')],
      countercase: [claim('Fixture recommendation countercase.', { evidence: ['ev-news'] })],
      invalidation_conditions: [claim('Fixture invalidation condition.', { type: 'assumption' })],
      evidence_quality: 'Two fixture sources; partial coverage.',
      predictive_uncertainty: 'High; fixture evidence only.',
    },
    outlooks: [
      {
        horizon_months: 1,
        direction: 'mixed',
        base_case: [claim('One-month fixture base case.')],
        upside_case: [claim('One-month fixture upside.')],
        downside_case: [claim('One-month fixture downside.')],
        catalysts: [claim('One-month fixture catalyst.')],
        invalidators: [claim('One-month fixture invalidator.', { type: 'assumption' })],
        data_limitations: [],
      },
      {
        horizon_months: 2,
        direction: 'positive',
        base_case: [claim('Two-month fixture base case differs from one-month.')],
        upside_case: [claim('Two-month fixture upside.')],
        downside_case: [claim('Two-month fixture downside.')],
        catalysts: [claim('Two-month fixture catalyst.')],
        invalidators: [claim('Two-month fixture invalidator.', { type: 'assumption' })],
        data_limitations: [],
      },
      {
        horizon_months: 3,
        direction: 'negative',
        base_case: [claim('Three-month fixture base case differs from the others.')],
        upside_case: [claim('Three-month fixture upside.')],
        downside_case: [claim('Three-month fixture downside.')],
        catalysts: [claim('Three-month fixture catalyst.')],
        invalidators: [claim('Three-month fixture invalidator.', { type: 'assumption' })],
        data_limitations: [],
      },
    ],
    changes_since_previous: {
      previous_assessment_id: 'assess-0',
      previous_session_as_of: '2026-09-30',
      missing_report_sessions: [],
      thesis_changes: [
        { component: 'fixture component', status: 'unchanged', reason: 'No new fixture evidence.', evidence_ids: [] },
      ],
      checkpoint_change_ids: ['cp-1'],
    },
    checkpoints: [
      { kind: 'fixed_observed_level', fixed_level: 120, condition: 'price holds above 120', status: 'active', reason: 'Fixture carried checkpoint.' },
    ],
    missing_data: [],
  };
}

function scriptedModelClient(responses, log = []) {
  return {
    async complete(request) {
      log.push(request);
      if (responses.length === 0) throw new Error('unexpected additional model call');
      const next = responses.shift();
      if (next instanceof Error) throw next;
      return { output: next };
    },
  };
}

function makeRuntime({ responses, log = [], now } = {}) {
  const modelClient = scriptedModelClient(responses ?? [validSynthesis()], log);
  let counter = 0;
  const runtime = createResearchAgentRuntime({
    modelClient,
    now: now ?? (() => new Date('2026-10-30T20:00:01.000Z')),
    idFactory: () => `assess-${++counter}`,
    isExchangeSession: weekdayPredicate,
  });
  return { runtime, log, modelClient };
}

async function runMarketSynthesis(runtime, overrides = {}) {
  return runtime.runMarketSynthesis({
    run: RUN,
    snapshot: baseSnapshot(),
    metrics: METRICS,
    instrument: INSTRUMENT,
    position: ownedPosition(),
    prior: PRIOR,
    currentPrice: CURRENT_PRICE,
    deadlineAt: '2026-10-30T20:05:00.000Z',
    ...overrides,
  });
}

// ---------------------------------------------------------------------------
// Happy path
// ---------------------------------------------------------------------------

test('PIPELINE_BUDGETS are named frozen code constants', async () => {
  assert.equal(PIPELINE_BUDGETS.MAX_SYNTHESIS_ATTEMPTS, 2);
  assert.ok(Object.isFrozen(PIPELINE_BUDGETS));
});

test('valid mock synthesis composes a schema-valid assessment in one model call', async () => {
  const { runtime, log } = makeRuntime();
  const outcome = await runMarketSynthesis(runtime);
  assert.equal(outcome.status, 'complete');
  assert.equal(outcome.model_calls, 1);
  assert.equal(log.length, 1);
  assert.match(outcome.result.assessment.id, /^assess-\d$/);
  assert.equal(outcome.result.position_revision, 7);
  assert.equal(outcome.result.evidence_snapshot_id, 'snap-1');
  assert.equal(outcome.result.session_as_of, '2026-10-30');

  // Canonical contract schema gate.
  const parsed = validator.parseAssessment(outcome.result.assessment);
  assert.equal(parsed.id, outcome.result.assessment.id);

  // Server-computed horizon dates, exactly one per month.
  const expected = metricsMod.outlookHorizons({ sessionAsOf: '2026-10-30', isExchangeSession: weekdayPredicate });
  assert.deepEqual(
    parsed.outlooks.map((o) => [o.horizon_months, o.calendar_target_date, o.evaluation_session_date]),
    expected.map((h) => [h.horizon_months, h.calendar_target_date, h.evaluation_session_date]),
  );
});

test('assessment binds the exact run identity and revision', async () => {
  const { runtime } = makeRuntime();
  const outcome = await runMarketSynthesis(runtime);
  const a = outcome.result.assessment;
  assert.equal(a.run_id, 'run-1');
  assert.equal(a.position_id, 'pos-1');
  assert.equal(a.position_revision, 7);
  assert.equal(a.instrument_id, 'inst-1');
  assert.equal(a.evidence_snapshot_id, 'snap-1');
  assert.equal(a.position_context.revision, 7);
  assert.equal(a.position_context.position_id, 'pos-1');
});

test('deterministic server composition attaches exact owner-bound P/L', async () => {
  const { runtime } = makeRuntime();
  const outcome = await runMarketSynthesis(runtime);
  const economics = outcome.result.assessment.economics;
  assert.ok(economics, 'economics must be composed server-side');
  assert.equal(economics.status, 'available');
  assert.equal(economics.currency, 'USD');
  assert.equal(economics.average_cost, 100);
  assert.equal(economics.current_price, 150);
  assert.equal(economics.quantity, 10);
  assert.equal(economics.absolute_pl, 500);
  assert.equal(economics.percent_pl, 0.5);
  assert.deepEqual([...economics.excluded_adjustments], ['fees', 'dividends']);
  assert.equal(outcome.result.assessment.position_context.average_cost.amount, '100.00');
});

// --- H09-N1: economics_status / economics.status naming collision (scoped repair) ---

test('position_context.economics_status keeps H01 inputs-present semantics with no dead economics parameter', async () => {
  // H09 review N1 divergence pair, reproduced end to end: the composed
  // economics.status reports 'unavailable' (currency_mismatch) while
  // position_context.economics_status reads 'available'. Under the H01
  // contract semantics (contract-cases.json / research-contracts.test.cjs)
  // economics_status means "economics inputs present on the position", not
  // "comparable P/L available" — economics.status stays the authoritative
  // P/L availability signal. The repair removes the dead `economics`
  // parameter from composePositionContext so the two fields cannot be wired
  // together; a downstream renderer (H14/H15B) must never present
  // economics_status 'available' as P/L availability when economics.status
  // is 'unavailable'.
  const { runtime } = makeRuntime();
  const outcome = await runMarketSynthesis(runtime, {
    currentPrice: { amount: '150.00', currency: 'EUR', adjustment_basis: 'raw_purchase' },
  });
  assert.equal(outcome.status, 'complete');
  const assessment = outcome.result.assessment;
  assert.equal(assessment.economics.status, 'unavailable');
  assert.equal(assessment.economics.reason, 'currency_mismatch');
  assert.equal(assessment.position_context.economics_status, 'available');
  assert.equal(assessment.position_context.average_cost.currency, 'USD');

  // The repaired composer takes only the position: the economics parameter
  // is gone (H09-N1), so economics_status is derived purely from the
  // position's own economics inputs and can never be coupled to the
  // composed economics object again.
  assert.equal(
    composePositionContext?.length,
    1,
    'H09-N1: composePositionContext must not accept an economics parameter',
  );
  assert.deepEqual(composePositionContext({ ...ownedPosition(), instrument_id: 'inst-1' }), {
    position_id: 'pos-1',
    instrument_id: 'inst-1',
    state: 'owned',
    revision: 7,
    average_cost: { amount: '100.00', currency: 'USD' },
    quantity: '10',
    opened_on: '2026-01-05',
    economics_status: 'available',
  });
});

test('changing cost alone cannot change the market thesis', async () => {
  const synthesisA = validSynthesis();
  const synthesisB = validSynthesis();
  const { runtime } = makeRuntime({ responses: [synthesisA, synthesisB] });

  const outcomeA = await runMarketSynthesis(runtime, {
    position: ownedPosition({ average_cost: { amount: '100.00', currency: 'USD', basis: 'raw_purchase' } }),
  });
  const outcomeB = await runMarketSynthesis(runtime, {
    position: ownedPosition({ average_cost: { amount: '123.45', currency: 'USD', basis: 'raw_purchase' } }),
  });

  assert.deepEqual(outcomeA.result.assessment.market_thesis, outcomeB.result.assessment.market_thesis);
  assert.deepEqual(outcomeA.result.assessment.recommendation, outcomeB.result.assessment.recommendation);
  assert.notEqual(
    outcomeA.result.assessment.economics.absolute_pl,
    outcomeB.result.assessment.economics.absolute_pl,
  );
});

// --- personal economics exclusion ---

test('market synthesis context contains no purchase cost or quantity', async () => {
  const { runtime, log } = makeRuntime();
  await runMarketSynthesis(runtime);
  const serialized = JSON.stringify(log[0]);
  assert.ok(!serialized.includes('100.00'), 'cost amount leaked into model context');
  assert.ok(!serialized.includes('average_cost'), 'average_cost leaked into model context');
  assert.ok(!serialized.includes('quantity'), 'quantity leaked into model context');
  assert.ok(!serialized.includes('"10"'), 'quantity value leaked into model context');
});

// --- frozen bounded context ---

test('source context is frozen before model invocation and digest-stamped', async () => {
  const { runtime, log } = makeRuntime();
  const outcome = await runMarketSynthesis(runtime);
  assert.ok(outcome.context_digest, 'digest must be recorded');
  assert.match(outcome.context_digest, /^[0-9a-f]{64}$/);
  assert.ok(log[0].context_digest === outcome.context_digest, 'model request must carry the frozen digest');
  assert.ok(Object.isFrozen(log[0].context), 'context must be frozen before invocation');
});

test('bounded context truncates evidence to the named budget with a gap note', async () => {
  const items = [
    evidenceItem('ev-filing', 'filing', '2026-10-28T14:00:00.000Z'),
    evidenceItem('ev-news', 'news', '2026-10-29T16:00:00.000Z'),
  ];
  for (let i = 0; i < PIPELINE_BUDGETS.MAX_CONTEXT_EVIDENCE_ITEMS + 3; i += 1) {
    items.push(evidenceItem(`ev-bulk-${i}`, 'news', `2026-10-0${(i % 9) + 1}T12:00:00.000Z`));
  }
  const { runtime, log } = makeRuntime();
  const outcome = await runMarketSynthesis(runtime, {
    snapshot: baseSnapshot({ items }),
  });
  assert.equal(outcome.status, 'complete');
  const contextText = JSON.stringify(log[0].context);
  assert.ok(!contextText.includes('ev-bulk-24'), 'context must respect the evidence budget');
  const rendered = log[0].user;
  assert.match(rendered, /evidence_context_truncated/);
});

// --- bounded attempts / repair ---

test('invalid first attempt gets exactly one bounded repair attempt', async () => {
  const bad = validSynthesis();
  bad.market_thesis.rationale = [claim('Uses an invented source.', { evidence: ['ev-invented'] })];
  const { runtime, log } = makeRuntime({ responses: [bad, validSynthesis()] });
  const outcome = await runMarketSynthesis(runtime);
  assert.equal(outcome.status, 'complete');
  assert.equal(outcome.model_calls, 2);
  assert.equal(PIPELINE_BUDGETS.MAX_SYNTHESIS_ATTEMPTS, 2);
  assert.match(log[1].user, /repair/i);
  assert.ok(log[1].issues.length > 0, 'repair prompt must carry concrete issues');
});

test('canonical-schema-only synthesis defect gets the bounded repair attempt', async () => {
  const bad = validSynthesis();
  bad.recommendation.headline = 'x'.repeat(4001);
  const { runtime, log } = makeRuntime({ responses: [bad, validSynthesis()] });
  const outcome = await runMarketSynthesis(runtime);
  assert.equal(outcome.status, 'complete');
  assert.equal(outcome.model_calls, 2);
  assert.equal(log.length, 2);
  assert.ok(log[1].issues.some((entry) => entry.code === 'SCHEMA_INVALID'
    && entry.path === 'recommendation.headline'));
});

test('unrepairable canonical-schema-only synthesis defect reports field diagnostics', async () => {
  const bad = validSynthesis();
  bad.recommendation.headline = 'x'.repeat(4001);
  const { runtime, log } = makeRuntime({ responses: [bad, bad] });
  const outcome = await runMarketSynthesis(runtime);
  assert.equal(outcome.status, 'failed');
  assert.equal(outcome.error_code, 'SYNTHESIS_VALIDATION_FAILED');
  assert.equal(outcome.model_calls, 2);
  assert.equal(log.length, 2);
  assert.deepEqual(outcome.validation_issues.map((entry) => entry.code), ['SCHEMA_INVALID']);
  assert.equal(outcome.validation_issues[0].path, 'recommendation.headline');
});

test('two failed attempts produce a real failed status with the validation issues', async () => {
  const bad = validSynthesis();
  bad.market_thesis.rationale = [claim('Uses an invented source.', { evidence: ['ev-invented'] })];
  const worse = validSynthesis();
  worse.market_thesis.rationale = [claim('Still invented.', { evidence: ['ev-invented-2'] })];
  const { runtime, log } = makeRuntime({ responses: [bad, worse] });
  const outcome = await runMarketSynthesis(runtime);
  assert.equal(outcome.status, 'failed');
  assert.equal(outcome.error_code, 'SYNTHESIS_VALIDATION_FAILED');
  assert.equal(outcome.model_calls, 2);
  assert.equal(log.length, 2, 'no third attempt');
  assert.ok(outcome.validation_issues.length > 0);
  assert.equal(outcome.result, undefined);
});

// --- deadlines ---

test('an expired deadline fails closed before any model call', async () => {
  const { runtime, log } = makeRuntime();
  const outcome = await runMarketSynthesis(runtime, { deadlineAt: '2026-10-30T19:00:00.000Z' });
  assert.equal(outcome.status, 'failed');
  assert.equal(outcome.error_code, 'DEADLINE_EXCEEDED');
  assert.equal(log.length, 0);
});

test('a deadline crossed mid-pipeline stops the run with a real failure status', async () => {
  let tick = 0;
  const clock = [
    new Date('2026-10-30T20:00:01.000Z'), // pipeline start check
    new Date('2026-10-30T20:09:00.000Z'), // post-first-attempt check -> past deadline
  ];
  const bad = validSynthesis();
  bad.market_thesis.rationale = [claim('Uses an invented source.', { evidence: ['ev-invented'] })];
  const { runtime, log } = makeRuntime({
    responses: [bad, validSynthesis()],
    now: () => clock[Math.min(tick++, clock.length - 1)],
  });
  const outcome = await runMarketSynthesis(runtime);
  assert.equal(outcome.status, 'failed');
  assert.equal(outcome.error_code, 'DEADLINE_EXCEEDED');
  assert.ok(log.length < 2, 'no repair call after the deadline passed');
});

// --- exact revision binding ---

test('a position revision mismatch fails closed as REVISION_CONFLICT with no model call', async () => {
  const { runtime, log } = makeRuntime();
  await assert.rejects(
    () => runMarketSynthesis(runtime, {
      run: { ...RUN, position_revision: 8 },
    }),
    (error) => error.code === 'REVISION_CONFLICT',
  );
  assert.equal(log.length, 0);
});

// --- coverage / status ---

test('unavailable coverage fails closed without a model call', async () => {
  const { runtime, log } = makeRuntime();
  const outcome = await runMarketSynthesis(runtime, {
    snapshot: baseSnapshot({ items: [], coverage: { status: 'unavailable', gaps: ['sec_filings_unavailable', 'news_coverage_unavailable'] } }),
  });
  assert.equal(outcome.status, 'failed');
  assert.equal(outcome.error_code, 'INSUFFICIENT_EVIDENCE');
  assert.equal(log.length, 0);
});

test('partial coverage produces an honest limited status with explicit missing data', async () => {
  const { runtime } = makeRuntime();
  const outcome = await runMarketSynthesis(runtime, {
    snapshot: baseSnapshot({
      coverage: { status: 'partial', gaps: ['news_coverage_unavailable', 'consensus_estimates_unavailable'] },
    }),
  });
  assert.equal(outcome.status, 'limited');
  assert.equal(outcome.result.status, 'limited');
  const a = outcome.result.assessment;
  assert.ok(a.missing_data.includes('news_coverage_unavailable'));
  assert.ok(a.missing_data.includes('consensus_estimates_unavailable'));
  const parsed = validator.parseAssessment(a);
  assert.equal(parsed.status, 'limited');
});

// --- continuity ---

test('prior-report and checkpoint continuity is carried into the assessment', async () => {
  const { runtime } = makeRuntime();
  const outcome = await runMarketSynthesis(runtime);
  const changes = outcome.result.assessment.changes_since_previous;
  assert.equal(changes.previous_assessment_id, 'assess-0');
  assert.equal(changes.previous_session_as_of, '2026-09-30');
  assert.deepEqual(changes.checkpoint_change_ids, ['cp-1']);
});

test('without a prior assessment changes_since_previous is null', async () => {
  const { runtime } = makeRuntime();
  const outcome = await runMarketSynthesis(runtime, { prior: null });
  assert.equal(outcome.status, 'complete');
  assert.equal(outcome.result.assessment.changes_since_previous, null);
});

// --- checkpoints ---

test('synthesized checkpoints are stamped server-side and schema-validated', async () => {
  const { runtime } = makeRuntime();
  const outcome = await runMarketSynthesis(runtime);
  const checkpoints = outcome.result.assessment.checkpoints;
  assert.equal(checkpoints.length, 1);
  const cp = checkpoints[0];
  assert.equal(cp.instrument_id, 'inst-1');
  assert.equal(cp.source_assessment_id, outcome.result.assessment.id);
  assert.equal(cp.created_at, outcome.result.assessment.generated_at);
  assert.equal(cp.fixed_level, 120);
  assert.ok(!('metric_id' in cp) || cp.metric_id == null);
});

test('a synthesized rolling checkpoint referencing a fabricated metric fails closed', async () => {
  const bad = validSynthesis();
  bad.checkpoints = [
    { kind: 'rolling_indicator', metric_id: 'm-invented', condition: 'RSI condition', status: 'active', reason: 'Fixture.' },
  ];
  const { runtime } = makeRuntime({ responses: [bad, bad] });
  const outcome = await runMarketSynthesis(runtime);
  assert.equal(outcome.status, 'failed');
  assert.ok(outcome.validation_issues.some((issue) => issue.code === 'FABRICATED_METRIC'));
});

// --- injected-client contract ---

test('model client receives bounded deadline and frozen context, never credentials surface', async () => {
  const { runtime, log } = makeRuntime();
  await runMarketSynthesis(runtime);
  const request = log[0];
  assert.equal(request.deadline_at, '2026-10-30T20:05:00.000Z');
  assert.equal(typeof request.system, 'string');
  assert.equal(typeof request.user, 'string');
  assert.match(request.system, /never invent/i);
});
