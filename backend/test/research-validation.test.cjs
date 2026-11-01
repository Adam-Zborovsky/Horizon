'use strict';

// H09 — result_validator fail-closed validation tests.
// Frozen evaluation protocol: planted factual/temporal/unsupported-claim
// defects, evaluated deterministically against a frozen bounded context.
// No live model calls, no paid services, no credentials. Fixtures are
// synthetic and are NOT observed market data.

const assert = require('node:assert/strict');
const test = require('node:test');

const prompts = require('../src/features/research/prompts');
const validator = require('../src/features/research/result_validator');

// ---------------------------------------------------------------------------
// Shared synthetic fixture (documented as fixture data, not observed data)
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

function evidenceItem(id, kind, availableAt, extras = {}) {
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
    ...extras,
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

const METRICS = Object.freeze([
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
]);

const PRIOR = Object.freeze({
  assessment_id: 'assess-0',
  session_as_of: '2026-09-30',
  checkpoints: [
    { id: 'cp-1', kind: 'fixed_observed_level', condition: 'price holds above 120', status: 'active' },
  ],
});

function buildContext(overrides = {}) {
  return prompts.buildMarketSynthesisContext({
    instrument: INSTRUMENT,
    sessionAsOf: '2026-10-30',
    cutoffAt: '2026-10-30T20:00:00.000Z',
    snapshot: baseSnapshot(),
    metrics: METRICS,
    position: { position_id: 'pos-1', state: 'owned', preferred_horizon_months: 3 },
    prior: PRIOR,
    isExchangeSession: weekdayPredicate,
    ...overrides,
  }).context;
}

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

function codes(issues) {
  return issues.map((issue) => issue.code);
}

// ---------------------------------------------------------------------------
// Frozen evaluation protocol: planted defects must fail closed
// ---------------------------------------------------------------------------

test('frozen evaluation protocol declares its planted defect fixtures', () => {
  assert.deepEqual(
    validator.PLANTED_DEFECT_CODES,
    [
      'FABRICATED_SOURCE',
      'FABRICATED_METRIC',
      'UNSUPPORTED_CLAIM',
      'UNREGISTERED_NUMBER',
      'POST_CUTOFF_REFERENCE',
      'STATE_INCOMPATIBLE_ACTION',
      'INVENTED_HORIZON_DATE',
      'IDENTICAL_HORIZON_COPY',
      'CONTINUITY_MISMATCH',
      'FABRICATED_CHECKPOINT_REFERENCE',
      'MISSING_COUNTERCASE',
      'LIMITED_WITHOUT_MISSING_DATA',
      'NUMERIC_PROJECTION_HELD',
    ],
  );
});

test('a valid fixture synthesis passes with zero issues', () => {
  const ctx = buildContext();
  const verdict = validator.validateSynthesisOutput(validSynthesis(), ctx);
  assert.equal(verdict.ok, true, JSON.stringify(verdict.issues));
});

// --- factual: fabricated references ---

test('planted fabricated source id fails closed', () => {
  const ctx = buildContext();
  const synthesis = validSynthesis();
  synthesis.market_thesis.rationale = [claim('Uses an invented source.', { evidence: ['ev-invented'] })];
  const verdict = validator.validateSynthesisOutput(synthesis, ctx);
  assert.equal(verdict.ok, false);
  assert.ok(codes(verdict.issues).includes('FABRICATED_SOURCE'));
});

test('planted fabricated metric id fails closed', () => {
  const ctx = buildContext();
  const synthesis = validSynthesis();
  synthesis.market_thesis.price_technical_assessment.claims = [
    claim('Invented metric value.', { metrics: ['m-invented'] }),
  ];
  const verdict = validator.validateSynthesisOutput(synthesis, ctx);
  assert.equal(verdict.ok, false);
  assert.ok(codes(verdict.issues).includes('FABRICATED_METRIC'));
});

// --- unsupported claims ---

test('planted unsupported observed claim (no references) fails closed', () => {
  const ctx = buildContext();
  const synthesis = validSynthesis();
  synthesis.market_thesis.rationale = [claim('An observed claim with no grounding.', { evidence: [], metrics: [] })];
  const verdict = validator.validateSynthesisOutput(synthesis, ctx);
  assert.equal(verdict.ok, false);
  assert.ok(codes(verdict.issues).includes('UNSUPPORTED_CLAIM'));
});

// --- numbers ---

test('planted unregistered numeral in an observed claim fails closed', () => {
  const ctx = buildContext();
  const synthesis = validSynthesis();
  synthesis.market_thesis.rationale = [
    claim('Fixture margins expanded to 42.5 percent.', { evidence: ['ev-filing'] }),
  ];
  const verdict = validator.validateSynthesisOutput(synthesis, ctx);
  assert.equal(verdict.ok, false);
  assert.ok(codes(verdict.issues).includes('UNREGISTERED_NUMBER'));
});

test('registered numeral referenced to a metric id passes', () => {
  const ctx = buildContext();
  const synthesis = validSynthesis();
  synthesis.market_thesis.rationale = [
    claim('Fixture margins expanded to 42.5 percent per the metric.', { metrics: ['m-vol'] }),
  ];
  const verdict = validator.validateSynthesisOutput(synthesis, ctx);
  assert.equal(verdict.ok, true, JSON.stringify(verdict.issues));
});

test('dates, quarter labels and horizon labels are not misread as prices', () => {
  const ctx = buildContext();
  assert.equal(validator.containsUnregisteredNumericClaim('Window through 2026-11-30 before the Q4 close.'), false);
  assert.equal(validator.containsUnregisteredNumericClaim('Over the 3-month horizon the thesis may shift.'), false);
  assert.equal(validator.containsUnregisteredNumericClaim('Margins expanded to 42.5 percent.'), true);
});

// --- temporal ---

test('planted post-cutoff evidence reference fails closed (defense in depth)', () => {
  const ctx = buildContext();
  // Plant a post-cutoff item directly into the frozen context to prove the
  // validator rejects it even if a context builder failed to filter it.
  const polluted = Object.freeze({
    ...ctx,
    evidence: Object.freeze({
      ...ctx.evidence,
      'ev-late': { id: 'ev-late', available_at: '2026-10-31T09:00:00.000Z', published_at: '2026-10-31T09:00:00.000Z' },
    }),
  });
  const synthesis = validSynthesis();
  synthesis.market_thesis.rationale = [claim('Quotes post-cutoff data.', { evidence: ['ev-late'] })];
  const verdict = validator.validateSynthesisOutput(synthesis, polluted);
  assert.equal(verdict.ok, false);
  assert.ok(codes(verdict.issues).includes('POST_CUTOFF_REFERENCE'));
});

test('context builder drops post-cutoff items and records the gap', () => {
  const ctx = buildContext({
    snapshot: baseSnapshot({
      items: [
        evidenceItem('ev-late', 'news', '2026-10-31T09:00:00.000Z'),
        evidenceItem('ev-early', 'filing', '2026-10-01T09:00:00.000Z'),
      ],
    }),
  });
  assert.deepEqual(ctx.evidence_ids, ['ev-early']);
  assert.ok(ctx.coverage.gaps.includes('post_cutoff_evidence_excluded'));
});

// --- state compatibility ---

test('planted state-incompatible action fails closed for each state', () => {
  const ownedCtx = buildContext({ position: { position_id: 'pos-1', state: 'owned', preferred_horizon_months: 3 } });
  const candidateCtx = buildContext({ position: { position_id: 'pos-2', state: 'candidate', preferred_horizon_months: 3 } });
  const legacyCtx = buildContext({ position: { position_id: 'pos-3', state: 'legacy_unclassified', preferred_horizon_months: 3 } });

  const owned = validSynthesis();
  owned.recommendation.action = 'buy';
  assert.ok(codes(validator.validateSynthesisOutput(owned, ownedCtx).issues).includes('STATE_INCOMPATIBLE_ACTION'));

  const candidate = validSynthesis();
  candidate.recommendation.action = 'hold';
  assert.ok(codes(validator.validateSynthesisOutput(candidate, candidateCtx).issues).includes('STATE_INCOMPATIBLE_ACTION'));

  const legacy = validSynthesis();
  legacy.recommendation.action = 'hold';
  assert.ok(codes(validator.validateSynthesisOutput(legacy, legacyCtx).issues).includes('STATE_INCOMPATIBLE_ACTION'));

  const legacyOk = validSynthesis();
  legacyOk.recommendation.action = 'insufficient_evidence';
  assert.equal(validator.validateSynthesisOutput(legacyOk, legacyCtx).ok, true);
});

// --- horizons ---

test('outlook horizon dates must equal the server-computed contract dates', () => {
  const ctx = buildContext();
  const synthesis = validSynthesis();
  // Mutate nothing the model controls except simulating an invented date by
  // requesting validation against an outlook whose dates were tampered with.
  const tamperedOutlooks = synthesis.outlooks.map((o) => ({
    ...o,
    calendar_target_date: '2026-12-31',
    evaluation_session_date: '2026-12-31',
  }));
  const verdict = validator.validateSynthesisOutput({ ...synthesis, outlooks: tamperedOutlooks }, ctx);
  assert.equal(verdict.ok, false);
  assert.ok(codes(verdict.issues).includes('INVENTED_HORIZON_DATE'));
});

test('planted identical copy across horizons fails closed', () => {
  const ctx = buildContext();
  const synthesis = validSynthesis();
  const copy = synthesis.outlooks[0];
  synthesis.outlooks = [copy, { ...copy, horizon_months: 2 }, synthesis.outlooks[2]];
  const verdict = validator.validateSynthesisOutput(synthesis, ctx);
  assert.equal(verdict.ok, false);
  assert.ok(codes(verdict.issues).includes('IDENTICAL_HORIZON_COPY'));
});

test('exactly one 1/2/3-month outlook set is required', () => {
  const ctx = buildContext();
  const synthesis = validSynthesis();
  synthesis.outlooks = synthesis.outlooks.slice(0, 2);
  const verdict = validator.validateSynthesisOutput(synthesis, ctx);
  assert.equal(verdict.ok, false);
  assert.ok(codes(verdict.issues).includes('INCOMPLETE_HORIZONS'));
});

// --- continuity ---

test('missing changes_since_previous with a prior assessment fails closed', () => {
  const ctx = buildContext();
  const synthesis = validSynthesis();
  synthesis.changes_since_previous = null;
  const verdict = validator.validateSynthesisOutput(synthesis, ctx);
  assert.equal(verdict.ok, false);
  assert.ok(codes(verdict.issues).includes('CONTINUITY_MISMATCH'));
});

test('wrong previous assessment id fails closed', () => {
  const ctx = buildContext();
  const synthesis = validSynthesis();
  synthesis.changes_since_previous = {
    ...synthesis.changes_since_previous,
    previous_assessment_id: 'assess-other',
  };
  const verdict = validator.validateSynthesisOutput(synthesis, ctx);
  assert.equal(verdict.ok, false);
  assert.ok(codes(verdict.issues).includes('CONTINUITY_MISMATCH'));
});

test('changes_since_previous must be null when no prior exists', () => {
  const ctx = buildContext({ prior: null });
  const synthesis = validSynthesis();
  const verdict = validator.validateSynthesisOutput(synthesis, ctx);
  assert.equal(verdict.ok, false);
  assert.ok(codes(verdict.issues).includes('CONTINUITY_MISMATCH'));
  synthesis.changes_since_previous = null;
  assert.equal(validator.validateSynthesisOutput(synthesis, ctx).ok, true);
});

test('fabricated checkpoint change reference fails closed', () => {
  const ctx = buildContext();
  const synthesis = validSynthesis();
  synthesis.changes_since_previous = {
    ...synthesis.changes_since_previous,
    checkpoint_change_ids: ['cp-1', 'cp-invented'],
  };
  const verdict = validator.validateSynthesisOutput(synthesis, ctx);
  assert.equal(verdict.ok, false);
  assert.ok(codes(verdict.issues).includes('FABRICATED_CHECKPOINT_REFERENCE'));
});

// --- direct conclusion/countercase requirements ---

test('missing counterevidence fails closed', () => {
  const ctx = buildContext();
  const synthesis = validSynthesis();
  synthesis.market_thesis.counterevidence = [];
  const verdict = validator.validateSynthesisOutput(synthesis, ctx);
  assert.equal(verdict.ok, false);
  assert.ok(codes(verdict.issues).includes('MISSING_COUNTERCASE'));
});

// --- status / missing data ---

test('limited status without missing_data fails closed', () => {
  const ctx = buildContext({
    snapshot: baseSnapshot({ coverage: { status: 'partial', gaps: ['news_coverage_unavailable'] } }),
  });
  const synthesis = validSynthesis();
  synthesis.missing_data = ['fixture explicit gap'];
  assert.equal(validator.validateSynthesisOutput(synthesis, ctx).ok, true);
  synthesis.missing_data = [];
  const verdict = validator.validateSynthesisOutput(synthesis, ctx);
  assert.equal(verdict.ok, false);
  assert.ok(codes(verdict.issues).includes('LIMITED_WITHOUT_MISSING_DATA'));
});

// --- held follow-up guard ---

test('a non-null numeric projection from the model is rejected (H07A held)', () => {
  const ctx = buildContext();
  const synthesis = validSynthesis();
  synthesis.outlooks[0].numeric_projection = { lower: 100, central: 150, upper: 200 };
  const verdict = validator.validateSynthesisOutput(synthesis, ctx);
  assert.equal(verdict.ok, false);
  assert.ok(codes(verdict.issues).includes('NUMERIC_PROJECTION_HELD'));
});

// ---------------------------------------------------------------------------
// Delivery-boundary validation (H08 O2 handoff: deep 422 validation)
// ---------------------------------------------------------------------------

function assembledAssessment(overrides = {}) {
  // Shape the runtime produces; delivery validation runs the canonical schema.
  const ctx = buildContext();
  const horizons = Object.freeze(ctx.horizons);
  const synthesized = validSynthesis();
  return {
    id: 'assess-1',
    contract_version: 1,
    position_id: 'pos-1',
    position_revision: 7,
    instrument_id: 'inst-1',
    run_id: 'run-1',
    evidence_snapshot_id: 'snap-1',
    generated_at: '2026-10-30T20:00:01.000Z',
    session_as_of: '2026-10-30',
    status: 'complete',
    market_thesis: synthesized.market_thesis,
    recommendation: synthesized.recommendation,
    position_context: {
      position_id: 'pos-1',
      instrument_id: 'inst-1',
      state: 'owned',
      revision: 7,
      average_cost: { amount: '100.00', currency: 'USD' },
      quantity: '10',
      opened_on: '2026-01-05',
      economics_status: 'available',
    },
    changes_since_previous: synthesized.changes_since_previous,
    checkpoints: [],
    outlooks: synthesized.outlooks.map((o) => {
      const h = horizons.find((entry) => entry.horizon_months === o.horizon_months);
      return {
        ...o,
        calendar_target_date: h.calendar_target_date,
        evaluation_session_date: h.evaluation_session_date,
        numeric_projection: null,
      };
    }),
    missing_data: [],
    next_review: null,
    versions: { pipeline: 'h09-bounded', contract: '1' },
    ...overrides,
  };
}

const RUN = Object.freeze({ id: 'run-1', position_id: 'pos-1', position_revision: 7, instrument_id: 'inst-1' });
const SNAPSHOT = Object.freeze({ snapshot_id: 'snap-1', instrument_id: 'inst-1', session_as_of: '2026-10-30' });

test('a fully assembled assessment passes the delivery boundary', () => {
  const verdict = validator.validateAssessmentDelivery(assembledAssessment(), {
    run: RUN,
    snapshot: SNAPSHOT,
  });
  assert.equal(verdict.ok, true, JSON.stringify(verdict.issues));
});

test('delivery boundary fails closed on revision, run, instrument and snapshot mismatch', () => {
  const cases = [
    { run: { ...RUN, position_revision: 8 } },
    { run: { ...RUN, id: 'run-other' } },
    { run: { ...RUN, instrument_id: 'inst-other' } },
    { snapshot: { ...SNAPSHOT, snapshot_id: 'snap-other' } },
    { snapshot: { ...SNAPSHOT, instrument_id: 'inst-other' } },
  ];
  for (const override of cases) {
    const verdict = validator.validateAssessmentDelivery(assembledAssessment(), { run: RUN, snapshot: SNAPSHOT, ...override });
    assert.equal(verdict.ok, false, JSON.stringify(override));
  }
});

test('delivery boundary fails closed on schema-invalid sessions and candidate economics', () => {
  const badSession = assembledAssessment({ session_as_of: '2026-02-30' });
  assert.equal(validator.validateAssessmentDelivery(badSession, { run: RUN, snapshot: SNAPSHOT }).ok, false);

  const candidateEconomics = assembledAssessment({
    position_context: {
      position_id: 'pos-1',
      instrument_id: 'inst-1',
      state: 'candidate',
      revision: 7,
      average_cost: { amount: '100.00', currency: 'USD' },
      economics_status: 'available',
    },
  });
  assert.equal(validator.validateAssessmentDelivery(candidateEconomics, { run: RUN, snapshot: SNAPSHOT }).ok, false);
});
