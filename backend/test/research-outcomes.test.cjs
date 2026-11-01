'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const {
  OutcomeService,
  computeScorecard,
  createMongooseForecastRepository,
  FORECAST_DIRECTIONS,
  STRATEGY_KINDS,
  LEDGER_STATUSES,
  FROZEN_QUALITY_SET,
  MIN_MATURE_OBSERVATIONS,
  BENCHMARKS,
  realizeDirection,
} = require('../src/features/research/outcome.service');

const ForecastLedgerEntryModel = require('../src/features/research/outcome.model');
const { calendarTargetDate, evaluationSessionDate } = require('../src/features/research/contracts');

const OWNER_A = 'owner-h16-aaaa';
const OWNER_B = 'owner-h16-bbbb';
const INSTRUMENT = 'instrument-h16-1';
const ASSESSMENT = 'assessment-h16-1';

// Every calendar date is a trading session (no walk-back) so that the exact
// evaluation date equals the contract calendar target, keeping the
// point-in-time assertions deterministic.
const EVERY_DAY_SESSION = () => true;

// ---------------------------------------------------------------------------
// Fixtures and hermetic in-memory repository (no live DB, no network)
// ---------------------------------------------------------------------------

function duplicate(code, message) {
  const error = new Error(message || code);
  error.code = code;
  return error;
}

function clone(value) {
  return structuredClone(value);
}

function createInMemoryForecastRepository(initial = []) {
  const records = [...initial];
  return {
    records,
    async findById(ledgerId) {
      return clone(records.find((entry) => entry.ledger_id === ledgerId)) || null;
    },
    async findByAssessmentHorizon(assessmentId, horizonMonths) {
      return clone(records.find((entry) => entry.assessment_id === assessmentId
        && entry.horizon_months === horizonMonths)) || null;
    },
    async create(entry) {
      const collision = records.some((existing) => existing.ledger_id === entry.ledger_id)
        || records.some((existing) => existing.assessment_id === entry.assessment_id
          && existing.horizon_months === entry.horizon_months);
      if (collision) throw duplicate('DUPLICATE_FORECAST');
      records.push(clone(entry));
      return clone(entry);
    },
    async settle(ledgerId, realizedOutcome, settledAt) {
      const index = records.findIndex((entry) => entry.ledger_id === ledgerId);
      if (index === -1 || records[index].status !== 'pending') return null;
      records[index] = {
        ...records[index],
        status: 'settled',
        realized_outcome: clone(realizedOutcome),
        settled_at: settledAt,
      };
      return clone(records[index]);
    },
    async listSettled(ownerId, instrumentId) {
      return clone(records.filter((entry) => entry.owner_id_internal === ownerId
        && entry.instrument_id === instrumentId
        && entry.status === 'settled'));
    },
    async listForAssessment(ownerId, assessmentId) {
      return clone(records.filter((entry) => entry.owner_id_internal === ownerId
        && entry.assessment_id === assessmentId));
    },
  };
}

function forecastInput(overrides = {}) {
  return {
    owner_id: OWNER_A,
    assessment_id: ASSESSMENT,
    instrument_id: INSTRUMENT,
    horizon_months: 1,
    direction: 'positive',
    issue_session_date: '2026-10-30',
    evaluation_session_date: '2026-11-30',
    benchmark: {
      benchmark_id: BENCHMARKS.total_return_sign.benchmark_id,
      method: BENCHMARKS.total_return_sign.method,
      method_version: BENCHMARKS.total_return_sign.method_version,
      definition: BENCHMARKS.total_return_sign.definition,
      tolerance: 0,
    },
    strategy: { strategy_id: 'analyst-1', kind: 'strategy_appropriate' },
    versions: {
      model_version: 'mock-1',
      prompt_version: 'prompt-1',
      method_version: 'method-1',
      snapshot_version: 'snapshot-1',
    },
    ...overrides,
  };
}

function makeService({ clock, repository, isExchangeSession = EVERY_DAY_SESSION } = {}) {
  const repo = repository || createInMemoryForecastRepository();
  let current = clock || new Date('2026-12-01T00:00:00Z');
  let ledgerSeq = 0;
  return {
    service: new OutcomeService({
      forecastRepository: repo,
      now: () => (typeof current === 'function' ? current() : current),
      idFactory: () => `ledger-h16-${String(++ledgerSeq).padStart(3, '0')}`,
      isExchangeSession,
    }),
    repo,
    setClock(value) { current = value; },
  };
}

// ---------------------------------------------------------------------------
// 1. Frozen benchmark realization
// ---------------------------------------------------------------------------

test('realizeDirection maps a positive/negative/flat return to direction', () => {
  assert.equal(realizeDirection(0.05), 'positive');
  assert.equal(realizeDirection(-0.03), 'negative');
  assert.equal(realizeDirection(0), 'mixed');
  assert.equal(realizeDirection(0.004, 0.005), 'mixed');
  assert.equal(realizeDirection(0.004, 0.001), 'positive');
  assert.equal(realizeDirection(-0.004, 0.005), 'mixed');
  assert.throws(() => realizeDirection(Number.NaN), /finite/);
  assert.throws(() => realizeDirection(Infinity), /finite/);
});

test('frozen protocol constants are present and frozen', () => {
  assert.deepEqual(FORECAST_DIRECTIONS, ['positive', 'negative', 'mixed', 'insufficient_evidence']);
  assert.deepEqual(STRATEGY_KINDS, ['strategy_appropriate', 'no_change', 'no_llm']);
  assert.deepEqual(LEDGER_STATUSES, ['pending', 'settled']);
  assert.ok(Number.isInteger(MIN_MATURE_OBSERVATIONS) && MIN_MATURE_OBSERVATIONS > 0);
  assert.ok(Array.isArray(FROZEN_QUALITY_SET) && FROZEN_QUALITY_SET.length > 0);
  assert.ok(Object.isFrozen(FROZEN_QUALITY_SET));
  assert.ok(BENCHMARKS.total_return_sign.method_version);
  assert.ok(Object.isFrozen(BENCHMARKS));
});

// ---------------------------------------------------------------------------
// 2. Model invariants (Mongoose validateSync + index introspection; no live DB)
// ---------------------------------------------------------------------------

test('ledger model requires immutable forecast fields and enforces enums', () => {
  const doc = new ForecastLedgerEntryModel({});
  const error = doc.validateSync();
  assert.ok(error, 'empty document must fail validation');
  for (const field of ['ledger_id', 'owner_id_internal', 'assessment_id', 'instrument_id', 'horizon_months', 'direction', 'issue_session_date', 'evaluation_session_date', 'benchmark', 'strategy', 'versions', 'status']) {
    assert.ok(error.errors[field], `expected required error for ${field}`);
  }
});

test('ledger model rejects an out-of-enum direction', () => {
  const input = forecastInput({ direction: 'sideways' });
  const doc = new ForecastLedgerEntryModel({
    _id: 'ledger-1',
    ledger_id: 'ledger-1',
    owner_id_internal: input.owner_id,
    assessment_id: input.assessment_id,
    instrument_id: input.instrument_id,
    horizon_months: 1,
    direction: 'sideways',
    issue_session_date: input.issue_session_date,
    evaluation_session_date: input.evaluation_session_date,
    benchmark: input.benchmark,
    strategy: input.strategy,
    versions: input.versions,
    status: 'pending',
    realized_outcome: null,
    settled_at: null,
    created_at: new Date(),
  });
  const error = doc.validateSync();
  assert.ok(error && error.errors.direction, 'sideways direction must fail enum validation');
});

test('ledger model enforces one forecast per assessment+horizon (unique index)', () => {
  const indexes = ForecastLedgerEntryModel.schema.indexes();
  const unique = indexes.filter(([, opts]) => opts && opts.unique);
  assert.ok(unique.length >= 1, 'expect at least one unique index');
  const assessmentHorizon = unique.find(([def]) => def.assessment_id && def.horizon_months);
  assert.ok(assessmentHorizon, 'expect a unique index on (assessment_id, horizon_months)');
});

// ---------------------------------------------------------------------------
// 3. registerForecast — freeze, exact calendar dates, rewrite prevention
// ---------------------------------------------------------------------------

test('registerForecast freezes a pending forecast', async () => {
  const { service, repo } = makeService();
  const entry = await service.registerForecast(forecastInput());
  assert.equal(entry.status, 'pending');
  assert.equal(entry.realized_outcome, null);
  assert.equal(entry.settled_at, null);
  assert.ok(entry.ledger_id.startsWith('ledger-h16-'));
  assert.equal(repo.records.length, 1);
});

test('registerForecast rejects an invalid direction', async () => {
  const { service } = makeService();
  await assert.rejects(
    service.registerForecast(forecastInput({ direction: 'sideways' })),
    (error) => error.code === 'INVALID_FORECAST',
  );
});

test('registerForecast rejects evaluation date predating issue date', async () => {
  const { service } = makeService();
  await assert.rejects(
    service.registerForecast(forecastInput({ evaluation_session_date: '2026-10-29' })),
    (error) => error.code === 'INVALID_FORECAST',
  );
});

test('registerForecast enforces the exact contract evaluation date', async () => {
  const { service } = makeService({ isExchangeSession: EVERY_DAY_SESSION });
  await assert.rejects(
    service.registerForecast(forecastInput({ evaluation_session_date: '2026-12-15' })),
    (error) => error.code === 'INVALID_FORECAST'
      && /exact contract evaluation date/.test(error.message),
  );
});

test('registerForecast accepts the walk-back evaluation date when sessions skip weekends', async () => {
  // Friday 2026-11-27 -> 1 month -> target 2026-12-27 (Sunday). A weekday-only
  // predicate walks back to Friday 2026-12-25, which must be accepted as exact.
  const weekdayOnly = (date) => {
    const day = new Date(`${date}T00:00:00Z`).getUTCDay();
    return day !== 0 && day !== 6;
  };
  const { service } = makeService({ isExchangeSession: weekdayOnly });
  const issue = '2026-11-27';
  const expected = evaluationSessionDate(calendarTargetDate(issue, 1), weekdayOnly);
  assert.ok(expected < calendarTargetDate(issue, 1), 'sanity: walk-back occurred');
  const entry = await service.registerForecast(forecastInput({
    issue_session_date: issue,
    evaluation_session_date: expected,
  }));
  assert.equal(entry.evaluation_session_date, expected);
});

test('registerForecast is idempotent for an identical duplicate', async () => {
  const { service, repo } = makeService();
  const first = await service.registerForecast(forecastInput());
  const second = await service.registerForecast(forecastInput());
  assert.equal(second.ledger_id, first.ledger_id);
  assert.equal(repo.records.length, 1, 'no second write for an identical forecast');
});

test('registerForecast prevents original forecast rewrites (conflict on differing duplicate)', async () => {
  const { service, repo } = makeService();
  const first = await service.registerForecast(forecastInput());
  await assert.rejects(
    service.registerForecast(forecastInput({ direction: 'negative' })),
    (error) => error.code === 'FORECAST_CONFLICT',
  );
  const stored = await repo.findById(first.ledger_id);
  assert.equal(stored.direction, 'positive', 'original forecast is immutable');
  assert.equal(repo.records.length, 1);
});

// ---------------------------------------------------------------------------
// 4. settleForecast — point-in-time validity, idempotency, append-only
// ---------------------------------------------------------------------------

test('settleForecast appends a realized outcome', async () => {
  const { service, repo } = makeService();
  const entry = await service.registerForecast(forecastInput());
  const settled = await service.settleForecast({
    owner_id: OWNER_A,
    ledger_id: entry.ledger_id,
    realized_direction: 'positive',
    benchmark_return: 0.04,
    observed_session_date: '2026-11-30',
    source: 'benchmark-source-1',
  });
  assert.equal(settled.status, 'settled');
  assert.equal(settled.realized_outcome.realized_direction, 'positive');
  assert.equal(settled.realized_outcome.benchmark_return, 0.04);
  assert.ok(settled.settled_at);
  const stored = await repo.findById(entry.ledger_id);
  assert.equal(stored.status, 'settled');
});

test('settleForecast refuses settlement before the evaluation session has passed', async () => {
  const { service } = makeService({ clock: new Date('2026-11-30T23:59:00Z') });
  const entry = await service.registerForecast(forecastInput());
  await assert.rejects(
    service.settleForecast({
      owner_id: OWNER_A,
      ledger_id: entry.ledger_id,
      realized_direction: 'positive',
      benchmark_return: 0.04,
      observed_session_date: '2026-11-30',
      source: 'benchmark-source-1',
    }),
    (error) => error.code === 'OUTCOME_NOT_AVAILABLE',
  );
});

test('settleForecast is allowed once the day after the evaluation session', async () => {
  const { service, setClock } = makeService({ clock: new Date('2026-11-30T23:59:00Z') });
  const entry = await service.registerForecast(forecastInput());
  setClock(new Date('2026-12-01T00:00:00Z'));
  const settled = await service.settleForecast({
    owner_id: OWNER_A,
    ledger_id: entry.ledger_id,
    realized_direction: 'positive',
    benchmark_return: 0.04,
    observed_session_date: '2026-11-30',
    source: 'benchmark-source-1',
  });
  assert.equal(settled.status, 'settled');
});

test('settleForecast rejects an outcome observed off the exact evaluation date', async () => {
  const { service } = makeService();
  const entry = await service.registerForecast(forecastInput());
  await assert.rejects(
    service.settleForecast({
      owner_id: OWNER_A,
      ledger_id: entry.ledger_id,
      realized_direction: 'positive',
      benchmark_return: 0.04,
      observed_session_date: '2026-12-01',
      source: 'benchmark-source-1',
    }),
    (error) => error.code === 'INVALID_OUTCOME_DATE',
  );
});

test('settleForecast rejects a realization that contradicts the benchmark return', async () => {
  const { service } = makeService();
  const entry = await service.registerForecast(forecastInput());
  await assert.rejects(
    service.settleForecast({
      owner_id: OWNER_A,
      ledger_id: entry.ledger_id,
      realized_direction: 'negative',
      benchmark_return: 0.04,
      observed_session_date: '2026-11-30',
      source: 'benchmark-source-1',
    }),
    (error) => error.code === 'INVALID_REALIZED_DIRECTION',
  );
});

test('settleForecast is idempotent for an identical duplicate settlement', async () => {
  const { service, repo } = makeService();
  const entry = await service.registerForecast(forecastInput());
  const first = await service.settleForecast({
    owner_id: OWNER_A,
    ledger_id: entry.ledger_id,
    realized_direction: 'positive',
    benchmark_return: 0.04,
    observed_session_date: '2026-11-30',
    source: 'benchmark-source-1',
  });
  const second = await service.settleForecast({
    owner_id: OWNER_A,
    ledger_id: entry.ledger_id,
    realized_direction: 'positive',
    benchmark_return: 0.04,
    observed_session_date: '2026-11-30',
    source: 'benchmark-source-1',
  });
  assert.equal(second.settled_at, first.settled_at, 'settled_at unchanged on replay');
  assert.equal(repo.records.length, 1);
});

test('settleForecast rejects a conflicting second settlement (append-only)', async () => {
  const { service } = makeService();
  const entry = await service.registerForecast(forecastInput());
  await service.settleForecast({
    owner_id: OWNER_A,
    ledger_id: entry.ledger_id,
    realized_direction: 'positive',
    benchmark_return: 0.04,
    observed_session_date: '2026-11-30',
    source: 'benchmark-source-1',
  });
  await assert.rejects(
    service.settleForecast({
      owner_id: OWNER_A,
      ledger_id: entry.ledger_id,
      realized_direction: 'negative',
      benchmark_return: -0.04,
      observed_session_date: '2026-11-30',
      source: 'benchmark-source-2',
    }),
    (error) => error.code === 'OUTCOME_CONFLICT',
  );
});

test('settleForecast is owner-scoped (cross-owner and unknown ledger are indistinguishable 404)', async () => {
  const { service } = makeService();
  const entry = await service.registerForecast(forecastInput());
  await assert.rejects(
    service.settleForecast({
      owner_id: OWNER_B,
      ledger_id: entry.ledger_id,
      realized_direction: 'positive',
      benchmark_return: 0.04,
      observed_session_date: '2026-11-30',
      source: 'benchmark-source-1',
    }),
    (error) => error.code === 'NOT_FOUND',
  );
  await assert.rejects(
    service.settleForecast({
      owner_id: OWNER_A,
      ledger_id: 'ledger-does-not-exist',
      realized_direction: 'positive',
      benchmark_return: 0.04,
      observed_session_date: '2026-11-30',
      source: 'benchmark-source-1',
    }),
    (error) => error.code === 'NOT_FOUND',
  );
});

// ---------------------------------------------------------------------------
// 5. computeScorecard — frozen quality set separate from forecasting metrics
// ---------------------------------------------------------------------------

function settledEntry(strategyId, kind, direction, realizedDirection) {
  return {
    ledger_id: `ledger-${strategyId}-${direction}`,
    owner_id_internal: OWNER_A,
    instrument_id: INSTRUMENT,
    assessment_id: `assessment-${strategyId}-${direction}`,
    horizon_months: 1,
    direction,
    strategy: { strategy_id: strategyId, kind },
    status: 'settled',
    realized_outcome: { realized_direction: realizedDirection },
  };
}

test('scorecard reports insufficient observations without a hit rate or edge claim', () => {
  const entries = [
    settledEntry('analyst-1', 'strategy_appropriate', 'positive', 'positive'),
    settledEntry('analyst-1', 'strategy_appropriate', 'negative', 'positive'),
  ];
  const scorecard = computeScorecard({ entries, quality_observations: [] });
  assert.equal(scorecard.forecasting.status, 'insufficient_observations');
  assert.equal(scorecard.forecasting.edge_claim, null);
  const analyst = scorecard.forecasting.direction_hit_rate_by_strategy['analyst-1'];
  assert.equal(analyst.scored, 2);
  assert.equal(analyst.hit_rate, null, 'no hit rate below maturity threshold');
  assert.equal(analyst.is_calibrated_probability, false);
});

test('scorecard publishes hit rates only above the maturity threshold and never claims an edge', () => {
  const entries = [];
  // 10 mature analyst observations: 8 hits, 2 misses.
  for (let i = 0; i < 10; i += 1) {
    entries.push(settledEntry('analyst-1', 'strategy_appropriate', 'positive', i < 8 ? 'positive' : 'negative'));
  }
  // 10 mature no-change baseline observations: always predicts mixed, 2 flats.
  for (let i = 0; i < 10; i += 1) {
    entries.push(settledEntry('baseline-no-change', 'no_change', 'mixed', i < 2 ? 'mixed' : 'positive'));
  }
  const scorecard = computeScorecard({ entries, quality_observations: [] });
  assert.equal(scorecard.forecasting.status, 'available');
  const analyst = scorecard.forecasting.direction_hit_rate_by_strategy['analyst-1'];
  assert.equal(analyst.hits, 8);
  assert.equal(analyst.scored, 10);
  assert.equal(analyst.hit_rate, 0.8);
  assert.equal(analyst.is_calibrated_probability, false, 'a raw hit rate is not a calibrated probability');
  assert.equal(scorecard.forecasting.edge_claim, null, 'never advertises a forecasting edge');
});

test('scorecard excludes insufficient_evidence forecasts from direction scoring', () => {
  const entries = [];
  for (let i = 0; i < 10; i += 1) {
    entries.push(settledEntry('analyst-1', 'strategy_appropriate', 'positive', 'positive'));
  }
  entries.push(settledEntry('analyst-1', 'strategy_appropriate', 'insufficient_evidence', 'positive'));
  const scorecard = computeScorecard({ entries, quality_observations: [] });
  const analyst = scorecard.forecasting.direction_hit_rate_by_strategy['analyst-1'];
  assert.equal(analyst.scored, 10, 'insufficient_evidence is not scored');
  assert.equal(analyst.unscored_insufficient_evidence, 1);
  assert.equal(analyst.hit_rate, 1);
});

test('scorecard aggregates the frozen quality set separately from forecasting metrics', () => {
  const observations = [
    { assessment_id: 'a1', results: { grounding: 'pass', countercase: 'pass', coverage: 'pass', continuity: 'fail', horizon_integrity: 'pass', numeric_integrity: 'pass' } },
    { assessment_id: 'a2', results: { grounding: 'pass', countercase: 'fail', coverage: 'unknown', continuity: 'pass', horizon_integrity: 'pass', numeric_integrity: 'fail' } },
  ];
  const scorecard = computeScorecard({ entries: [], quality_observations: observations });
  assert.equal(scorecard.quality.aggregate.grounding.passed, 2);
  assert.equal(scorecard.quality.aggregate.grounding.total, 2);
  assert.equal(scorecard.quality.aggregate.coverage.total, 1, 'unknown is not counted in the total');
  assert.equal(scorecard.quality.aggregate.coverage.passed, 1);
  assert.equal(scorecard.quality.per_assessment.length, 2);
  // Forecasting is independent of quality: no entries -> insufficient observations.
  assert.equal(scorecard.forecasting.status, 'insufficient_observations');
});

test('scorecard never fabricates a calibrated probability metric', () => {
  const entries = [];
  for (let i = 0; i < 10; i += 1) {
    entries.push(settledEntry('analyst-1', 'strategy_appropriate', 'positive', 'positive'));
  }
  const withoutCalibration = computeScorecard({ entries, quality_observations: [] });
  assert.equal(withoutCalibration.forecasting.calibrated_probability_metrics, null);

  const withCalibration = computeScorecard({
    entries,
    quality_observations: [],
    calibration_evidence: { model_version: 'm-1', held_out_evaluation: 'none', coverage_definition: 'none', validation_evidence_ids: ['e-1'] },
  });
  assert.equal(withCalibration.forecasting.calibrated_probability_metrics, null,
    'direction hit rates cannot be upgraded to calibrated probabilities without per-forecast probabilities');
  assert.equal(withCalibration.forecasting.calibration_evidence_provided, true);
});

test('scorecard reports a descriptive baseline comparison only when both sides are mature', () => {
  const entries = [];
  for (let i = 0; i < 10; i += 1) {
    entries.push(settledEntry('analyst-1', 'strategy_appropriate', 'positive', 'positive'));
  }
  for (let i = 0; i < 10; i += 1) {
    entries.push(settledEntry('baseline-no-change', 'no_change', 'mixed', i < 1 ? 'mixed' : 'positive'));
  }
  const scorecard = computeScorecard({ entries, quality_observations: [] });
  assert.equal(scorecard.forecasting.status, 'available');
  const comparison = scorecard.forecasting.baseline_comparison;
  assert.ok(comparison, 'comparison present when primary and baselines are mature');
  assert.equal(comparison.descriptive_only, true);
  assert.ok(comparison.primary.strategy_id === 'analyst-1');
  assert.ok(Array.isArray(comparison.baselines) && comparison.baselines.length === 1);
});

test('service.buildScorecard reads settled entries from the repository', async () => {
  const { service, repo } = makeService();
  const entry = await service.registerForecast(forecastInput());
  await service.settleForecast({
    owner_id: OWNER_A,
    ledger_id: entry.ledger_id,
    realized_direction: 'positive',
    benchmark_return: 0.04,
    observed_session_date: '2026-11-30',
    source: 'benchmark-source-1',
  });
  const scorecard = await service.buildScorecard({ owner_id: OWNER_A, instrument_id: INSTRUMENT, quality_observations: [] });
  assert.equal(scorecard.forecasting.status, 'insufficient_observations');
  assert.equal(scorecard.forecasting.direction_hit_rate_by_strategy['analyst-1'].scored, 1);
  assert.equal(repo.records.length, 1);
});

// ---------------------------------------------------------------------------
// 6. Repository factory shape (storage adapter present; live-Mongo behavior deferred)
// ---------------------------------------------------------------------------

test('createMongooseForecastRepository exposes the storage adapter surface', () => {
  const repo = createMongooseForecastRepository();
  for (const method of ['findById', 'findByAssessmentHorizon', 'create', 'settle', 'listSettled', 'listForAssessment']) {
    assert.equal(typeof repo[method], 'function', `expected repository method ${method}`);
  }
});
