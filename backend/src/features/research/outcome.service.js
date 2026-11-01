'use strict';

const crypto = require('node:crypto');

const ForecastLedgerEntryModel = require('./outcome.model');
const {
  FORECAST_DIRECTIONS,
  STRATEGY_KINDS,
  LEDGER_STATUSES,
  HORIZON_MONTHS,
} = ForecastLedgerEntryModel;
const { calendarTargetDate, evaluationSessionDate } = require('./contracts');

// ---------------------------------------------------------------------------
// Frozen evaluation protocol (docs/horizon/evidence/evaluation-protocol.md)
// ---------------------------------------------------------------------------

// The one realization rule in scope: a direction forecast is realized by the
// sign of the instrument's horizon return from issue_session_date close to
// evaluation_session_date close. `tolerance` is the flat band that counts as
// "mixed"; it is part of the frozen benchmark definition and is recorded on
// each ledger entry, never inferred later.
const BENCHMARKS = Object.freeze({
  total_return_sign: Object.freeze({
    benchmark_id: 'benchmark-total-return-sign',
    method: 'horizon_total_return_sign',
    method_version: '1',
    definition: 'Realize a direction forecast by the sign of the instrument total return from the issue session close to the evaluation session close: strictly positive -> positive, strictly negative -> negative, within the recorded tolerance band -> mixed.',
  }),
});

// The frozen quality set: six deterministic, per-assessment quality
// dimensions, each mapped to the H09 planted-defect code that governs it.
// Quality is scored from validator output and is deliberately SEPARATE from
// forecasting metrics (direction hit rate). No dimension here is a
// probability of profit.
const FROZEN_QUALITY_SET = Object.freeze([
  Object.freeze({ dimension: 'grounding', label: 'Observed claims cite supporting evidence/metrics', defect_code: 'UNSUPPORTED_CLAIM' }),
  Object.freeze({ dimension: 'countercase', label: 'Strongest countercase is present and non-trivial', defect_code: 'MISSING_COUNTERCASE' }),
  Object.freeze({ dimension: 'coverage', label: 'Missing data is explicit and limited status carries missing_data', defect_code: 'LIMITED_WITHOUT_MISSING_DATA' }),
  Object.freeze({ dimension: 'continuity', label: 'changes_since_previous references the exact prior assessment', defect_code: 'CONTINUITY_MISMATCH' }),
  Object.freeze({ dimension: 'horizon_integrity', label: 'Three distinct horizons, no identical copy', defect_code: 'IDENTICAL_HORIZON_COPY' }),
  Object.freeze({ dimension: 'numeric_integrity', label: 'No unregistered numerals or fabricated metric references', defect_code: 'UNREGISTERED_NUMBER' }),
]);

// A direction hit rate is an empirical proportion, not a calibrated predictive
// probability. It is only published once a strategy has this many scored
// observations; below that the scorecard reports insufficient_observations and
// advertises no forecasting edge.
const MIN_MATURE_OBSERVATIONS = 10;

const MAX_ID_LENGTH = 160;
const MAX_LABEL_LENGTH = 160;
const MAX_METHOD_VERSION_LENGTH = 40;
const MAX_VERSION_KEY_LENGTH = 80;
const MAX_VERSION_VALUE_LENGTH = 4000;
const MAX_VERSIONS = 20;
const MAX_SOURCE_LENGTH = 160;

const ISO_DATE_RE = /^(\d{4})-(\d{2})-(\d{2})$/;

function serviceError(code, message) {
  const error = new Error(message || code);
  error.code = code;
  return error;
}

// Recursively key-sorted serialization so that idempotency / rewrite checks
// are byte-stable regardless of input key order.
function canonicalize(value) {
  if (Array.isArray(value)) return value.map(canonicalize);
  if (value && typeof value === 'object') {
    return Object.keys(value).sort().map((key) => [key, canonicalize(value[key])]);
  }
  return value;
}

function stableSerialize(value) {
  return JSON.stringify(canonicalize(value ?? null));
}

function assertOwnerScopedId(value, field) {
  if (typeof value !== 'string' || value.length === 0 || value.length > MAX_ID_LENGTH) {
    throw serviceError('INVALID_INPUT', `${field} must be a non-empty opaque string`);
  }
  return value;
}

function isRealCalendarDate(value) {
  const match = ISO_DATE_RE.exec(value);
  if (!match) return false;
  const year = Number(match[1]);
  const month = Number(match[2]);
  const day = Number(match[3]);
  if (month < 1 || month > 12) return false;
  const daysInMonth = new Date(Date.UTC(year, month, 0)).getUTCDate();
  return day >= 1 && day <= daysInMonth;
}

function assertRealCalendarDate(value, field) {
  if (typeof value !== 'string' || !isRealCalendarDate(value)) {
    throw serviceError('INVALID_FORECAST', `${field} must be a real ISO calendar date`);
  }
  return value;
}

// Date-only string of the injected clock, used for the point-in-time
// availability gate. ISO YYYY-MM-DD compares lexicographically.
function dateOnly(now) {
  const date = now instanceof Date ? now : new Date(now);
  return date.toISOString().slice(0, 10);
}

/**
 * Benchmark-defined realization: the direction implied by an observed return,
 * using the benchmark's flat tolerance band. Deterministic, in code — the
 * ledger never accepts a caller-asserted direction that contradicts the
 * recorded benchmark return.
 */
function realizeDirection(benchmarkReturn, tolerance = 0) {
  if (typeof benchmarkReturn !== 'number' || !Number.isFinite(benchmarkReturn)) {
    throw serviceError('INVALID_OUTCOME', 'benchmark_return must be a finite number');
  }
  if (typeof tolerance !== 'number' || !Number.isFinite(tolerance) || tolerance < 0) {
    throw serviceError('INVALID_BENCHMARK', 'benchmark tolerance must be a non-negative finite number');
  }
  if (benchmarkReturn > tolerance) return 'positive';
  if (benchmarkReturn < -tolerance) return 'negative';
  return 'mixed';
}

function validateBenchmark(benchmark) {
  if (!benchmark || typeof benchmark !== 'object' || Array.isArray(benchmark)) {
    throw serviceError('INVALID_BENCHMARK', 'benchmark must be an object');
  }
  const tolerance = benchmark.tolerance == null ? 0 : benchmark.tolerance;
  if (typeof tolerance !== 'number' || !Number.isFinite(tolerance) || tolerance < 0) {
    throw serviceError('INVALID_BENCHMARK', 'benchmark tolerance must be a non-negative finite number');
  }
  return Object.freeze({
    benchmark_id: assertOwnerScopedId(benchmark.benchmark_id, 'benchmark.benchmark_id'),
    method: assertOwnerScopedId(benchmark.method, 'benchmark.method'),
    method_version: (() => {
      const value = benchmark.method_version;
      if (typeof value !== 'string' || value.length === 0 || value.length > MAX_METHOD_VERSION_LENGTH) {
        throw serviceError('INVALID_BENCHMARK', `benchmark.method_version must be a non-empty string of at most ${MAX_METHOD_VERSION_LENGTH} characters`);
      }
      return value;
    })(),
    definition: (() => {
      const value = benchmark.definition;
      if (typeof value !== 'string' || value.length === 0 || value.length > MAX_VERSION_VALUE_LENGTH) {
        throw serviceError('INVALID_BENCHMARK', `benchmark.definition must be a non-empty string of at most ${MAX_VERSION_VALUE_LENGTH} characters`);
      }
      return value;
    })(),
    tolerance,
  });
}

function validateStrategy(strategy) {
  if (!strategy || typeof strategy !== 'object' || Array.isArray(strategy)) {
    throw serviceError('INVALID_STRATEGY', 'strategy must be an object');
  }
  if (!STRATEGY_KINDS.includes(strategy.kind)) {
    throw serviceError('INVALID_STRATEGY', `strategy.kind must be one of ${STRATEGY_KINDS.join(', ')}`);
  }
  return Object.freeze({
    strategy_id: assertOwnerScopedId(strategy.strategy_id, 'strategy.strategy_id'),
    kind: strategy.kind,
  });
}

function validateVersions(versions) {
  if (!versions || typeof versions !== 'object' || Array.isArray(versions)) {
    throw serviceError('INVALID_VERSIONS', 'versions must be a record of version identifiers');
  }
  const keys = Object.keys(versions);
  if (keys.length === 0 || keys.length > MAX_VERSIONS) {
    throw serviceError('INVALID_VERSIONS', `versions must hold between 1 and ${MAX_VERSIONS} entries`);
  }
  const record = {};
  for (const key of keys) {
    if (typeof key !== 'string' || key.length === 0 || key.length > MAX_VERSION_KEY_LENGTH) {
      throw serviceError('INVALID_VERSIONS', `version key must be a non-empty string of at most ${MAX_VERSION_KEY_LENGTH} characters`);
    }
    const value = versions[key];
    if (typeof value !== 'string' || value.length === 0 || value.length > MAX_VERSION_VALUE_LENGTH) {
      throw serviceError('INVALID_VERSIONS', `version value for '${key}' must be a non-empty string of at most ${MAX_VERSION_VALUE_LENGTH} characters`);
    }
    record[key] = value;
  }
  return record;
}

// ---------------------------------------------------------------------------
// Mongoose repository factory (ISO-string core, plain-object adapter). The
// service core operates on plain objects; this adapter owns the Date
// conversion and the atomic pending->settled compare-and-set.
// ---------------------------------------------------------------------------

function createMongooseForecastRepository(model = ForecastLedgerEntryModel) {
  const fromDoc = (record) => {
    if (!record) return null;
    const plain = record.toObject ? record.toObject() : record;
    return {
      ledger_id: plain.ledger_id,
      owner_id_internal: plain.owner_id_internal,
      assessment_id: plain.assessment_id,
      instrument_id: plain.instrument_id,
      horizon_months: plain.horizon_months,
      direction: plain.direction,
      issue_session_date: plain.issue_session_date,
      evaluation_session_date: plain.evaluation_session_date,
      benchmark: plain.benchmark,
      strategy: plain.strategy,
      versions: plain.versions,
      status: plain.status,
      realized_outcome: plain.realized_outcome ?? null,
      settled_at: plain.settled_at ? plain.settled_at.toISOString() : null,
      created_at: plain.created_at ? plain.created_at.toISOString() : null,
    };
  };
  const toDoc = (entry) => ({
    ...entry,
    _id: entry.ledger_id,
    settled_at: entry.settled_at ? new Date(entry.settled_at) : null,
    created_at: new Date(entry.created_at),
  });
  return {
    async findById(ledgerId) {
      return fromDoc(await model.findOne({ ledger_id: ledgerId }).lean());
    },
    async findByAssessmentHorizon(assessmentId, horizonMonths) {
      return fromDoc(await model.findOne({ assessment_id: assessmentId, horizon_months: horizonMonths }).lean());
    },
    async create(entry) {
      try {
        return fromDoc(await model.create(toDoc(entry)));
      } catch (error) {
        if (error && (error.code === 11000 || error.name === 'MongoServerError')) {
          throw serviceError('DUPLICATE_FORECAST', 'A forecast already exists for this assessment horizon');
        }
        throw error;
      }
    },
    async settle(ledgerId, realizedOutcome, settledAt) {
      const updated = await model.findOneAndUpdate(
        { ledger_id: ledgerId, status: 'pending' },
        { $set: { status: 'settled', realized_outcome: realizedOutcome, settled_at: new Date(settledAt) } },
        { new: true },
      ).lean();
      return fromDoc(updated);
    },
    async listSettled(ownerId, instrumentId) {
      const docs = await model.find({
        owner_id_internal: ownerId,
        instrument_id: instrumentId,
        status: 'settled',
      }).lean();
      return docs.map(fromDoc);
    },
    async listForAssessment(ownerId, assessmentId) {
      const docs = await model.find({
        owner_id_internal: ownerId,
        assessment_id: assessmentId,
      }).lean();
      return docs.map(fromDoc);
    },
  };
}

// ---------------------------------------------------------------------------
// Scorecard — pure computation over settled entries + quality observations
// ---------------------------------------------------------------------------

/**
 * Frozen scorecard. Separates forecasting metrics (direction hit rate) from
 * the frozen quality set, gates the hit rate on mature observations, and never
 * fabricates a calibrated probability or advertises a forecasting edge.
 *
 * @param {object} input
 * @param {Array}  input.entries             settled ledger entries
 * @param {Array}  input.quality_observations per-assessment quality results
 * @param {object|null} input.calibration_evidence held calibration (never upgraded into a probability here)
 */
function computeScorecard({ entries = [], quality_observations = [], calibration_evidence = null } = {}) {
  if (!Array.isArray(entries)) throw serviceError('INVALID_INPUT', 'entries must be an array');
  if (!Array.isArray(quality_observations)) throw serviceError('INVALID_INPUT', 'quality_observations must be an array');

  const settled = entries.filter((entry) => entry
    && entry.status === 'settled'
    && entry.realized_outcome
    && entry.strategy
    && entry.strategy.strategy_id);

  const byStrategy = new Map();
  for (const entry of settled) {
    const strategyId = entry.strategy.strategy_id;
    if (!byStrategy.has(strategyId)) {
      byStrategy.set(strategyId, {
        strategy_id: strategyId,
        kind: entry.strategy.kind,
        scored: 0,
        hits: 0,
        unscored_insufficient_evidence: 0,
      });
    }
    const bucket = byStrategy.get(strategyId);
    if (entry.direction === 'insufficient_evidence') {
      bucket.unscored_insufficient_evidence += 1;
      continue;
    }
    bucket.scored += 1;
    if (entry.direction === entry.realized_outcome.realized_direction) {
      bucket.hits += 1;
    }
  }

  const directionHitRateByStrategy = {};
  let primaryScored = 0;
  for (const [strategyId, bucket] of byStrategy) {
    const mature = bucket.scored >= MIN_MATURE_OBSERVATIONS;
    if (bucket.kind === 'strategy_appropriate') primaryScored = bucket.scored;
    directionHitRateByStrategy[strategyId] = {
      kind: bucket.kind,
      scored: bucket.scored,
      unscored_insufficient_evidence: bucket.unscored_insufficient_evidence,
      hits: bucket.hits,
      hit_rate: mature ? bucket.hits / bucket.scored : null,
      mature,
      // A raw hit rate is an empirical proportion, never a calibrated
      // predictive probability (CONTRACTS §7 / SPEC §6).
      is_calibrated_probability: false,
    };
  }

  const status = primaryScored >= MIN_MATURE_OBSERVATIONS
    ? 'available'
    : 'insufficient_observations';

  // Descriptive baseline comparison: only when the primary strategy and at
  // least one baseline both have mature data. Explicitly not a superiority
  // claim — the ledger never advertises a forecasting edge at release.
  let baselineComparison = null;
  if (status === 'available') {
    const primary = [...byStrategy.values()].find((bucket) => bucket.kind === 'strategy_appropriate');
    const baselines = [...byStrategy.values()].filter((bucket) => bucket.kind !== 'strategy_appropriate'
      && bucket.scored >= MIN_MATURE_OBSERVATIONS);
    if (primary && baselines.length > 0) {
      baselineComparison = {
        descriptive_only: true,
        primary: {
          strategy_id: primary.strategy_id,
          hit_rate: primary.hits / primary.scored,
          scored: primary.scored,
        },
        baselines: baselines.map((bucket) => ({
          strategy_id: bucket.strategy_id,
          kind: bucket.kind,
          hit_rate: bucket.hits / bucket.scored,
          scored: bucket.scored,
        })),
      };
    }
  }

  // Quality: the frozen quality set, aggregated from supplied observations,
  // fully separate from the forecasting metrics above.
  const dimensions = FROZEN_QUALITY_SET.map((dimension) => dimension.dimension);
  const aggregate = {};
  for (const dimension of dimensions) {
    aggregate[dimension] = { passed: 0, total: 0 };
  }
  const perAssessment = [];
  for (const observation of quality_observations) {
    const results = observation && observation.results ? observation.results : {};
    const row = { assessment_id: observation && observation.assessment_id, results: {} };
    for (const dimension of dimensions) {
      const value = results[dimension];
      row.results[dimension] = value === 'pass' || value === 'fail' ? value : 'unknown';
      if (value === 'pass') aggregate[dimension].passed += 1;
      if (value === 'pass' || value === 'fail') aggregate[dimension].total += 1;
    }
    perAssessment.push(row);
  }

  return {
    protocol_version: '1',
    generated_at: new Date().toISOString(),
    scope: {
      settled_count: settled.length,
      scored_count: [...byStrategy.values()].reduce((sum, bucket) => sum + bucket.scored, 0),
      min_mature_observations: MIN_MATURE_OBSERVATIONS,
      strategies_present: [...byStrategy.keys()],
    },
    forecasting: {
      status,
      direction_hit_rate_by_strategy: directionHitRateByStrategy,
      baseline_comparison: baselineComparison,
      calibrated_probability_metrics: null,
      calibration_evidence_provided: calibration_evidence != null,
      edge_claim: null,
    },
    quality: {
      dimensions: FROZEN_QUALITY_SET.map((dimension) => ({
        dimension: dimension.dimension,
        label: dimension.label,
        defect_code: dimension.defect_code,
      })),
      aggregate,
      per_assessment: perAssessment,
    },
  };
}

// ---------------------------------------------------------------------------
// OutcomeService
// ---------------------------------------------------------------------------

class OutcomeService {
  constructor({
    forecastRepository,
    now = () => new Date(),
    idFactory = () => `ledger-${crypto.randomUUID()}`,
    isExchangeSession = null,
  } = {}) {
    if (!forecastRepository || typeof forecastRepository.create !== 'function'
      || typeof forecastRepository.settle !== 'function') {
      throw new TypeError('OutcomeService requires a forecast repository with create and settle support');
    }
    this.forecastRepository = forecastRepository;
    this.now = now;
    this.idFactory = idFactory;
    this.isExchangeSession = isExchangeSession;
  }

  // Freeze a forecast BEFORE its outcome is known (CONTRACTS §10: "forward
  // ledger records predictions before outcomes"). Immutable forecast half;
  // identical re-registration is idempotent, a differing re-registration is a
  // rewrite and is rejected.
  async registerForecast({
    owner_id,
    assessment_id,
    instrument_id,
    horizon_months,
    direction,
    issue_session_date,
    evaluation_session_date,
    benchmark,
    strategy,
    versions,
  } = {}) {
    const ownerId = assertOwnerScopedId(owner_id, 'owner_id');
    const assessmentId = assertOwnerScopedId(assessment_id, 'assessment_id');
    const instrumentId = assertOwnerScopedId(instrument_id, 'instrument_id');
    if (!HORIZON_MONTHS.includes(horizon_months)) {
      throw serviceError('INVALID_FORECAST', 'horizon_months must be 1, 2, or 3');
    }
    if (!FORECAST_DIRECTIONS.includes(direction)) {
      throw serviceError('INVALID_FORECAST', `direction must be one of ${FORECAST_DIRECTIONS.join(', ')}`);
    }
    assertRealCalendarDate(issue_session_date, 'issue_session_date');
    assertRealCalendarDate(evaluation_session_date, 'evaluation_session_date');
    if (evaluation_session_date < issue_session_date) {
      throw serviceError('INVALID_FORECAST', 'evaluation_session_date cannot predate issue_session_date');
    }
    if (this.isExchangeSession) {
      const expected = evaluationSessionDate(
        calendarTargetDate(issue_session_date, horizon_months),
        this.isExchangeSession,
      );
      if (evaluation_session_date !== expected) {
        throw serviceError('INVALID_FORECAST', `evaluation_session_date must be the exact contract evaluation date (expected ${expected})`);
      }
    }
    const frozenBenchmark = validateBenchmark(benchmark);
    const frozenStrategy = validateStrategy(strategy);
    const frozenVersions = validateVersions(versions);

    const existing = await this.forecastRepository.findByAssessmentHorizon(assessmentId, horizon_months);
    if (existing) {
      const identical = existing.direction === direction
        && existing.issue_session_date === issue_session_date
        && existing.evaluation_session_date === evaluation_session_date
        && stableSerialize(existing.benchmark) === stableSerialize(frozenBenchmark)
        && stableSerialize(existing.strategy) === stableSerialize(frozenStrategy)
        && stableSerialize(existing.versions) === stableSerialize(frozenVersions);
      if (identical) return structuredClone(existing);
      throw serviceError('FORECAST_CONFLICT', 'A forecast for this assessment horizon already exists and cannot be rewritten');
    }

    const entry = {
      ledger_id: this.idFactory(),
      owner_id_internal: ownerId,
      assessment_id: assessmentId,
      instrument_id: instrumentId,
      horizon_months,
      direction,
      issue_session_date,
      evaluation_session_date,
      benchmark: frozenBenchmark,
      strategy: frozenStrategy,
      versions: frozenVersions,
      status: 'pending',
      realized_outcome: null,
      settled_at: null,
      created_at: this.now().toISOString(),
    };
    const created = await this.forecastRepository.create(entry);
    return structuredClone(created);
  }

  // Append the realized outcome exactly once. Point-in-time valid (cannot run
  // before the evaluation session has passed), idempotent (an identical
  // settlement replays the existing record), and append-only (a conflicting
  // settlement is rejected, never a rewrite).
  async settleForecast({
    owner_id,
    ledger_id,
    realized_direction,
    benchmark_return,
    observed_session_date,
    source,
  } = {}) {
    const ownerId = assertOwnerScopedId(owner_id, 'owner_id');
    assertOwnerScopedId(ledger_id, 'ledger_id');

    const entry = await this.forecastRepository.findById(ledger_id);
    if (!entry || entry.owner_id_internal !== ownerId) {
      throw serviceError('NOT_FOUND', `Forecast not found: ${ledger_id}`);
    }

    assertRealCalendarDate(observed_session_date, 'observed_session_date');
    if (observed_session_date !== entry.evaluation_session_date) {
      throw serviceError('INVALID_OUTCOME_DATE', 'The realized outcome must be observed exactly at the evaluation session date');
    }

    // Point-in-time availability: the outcome is knowable only after the
    // evaluation session has passed (CONTRACTS §10 "cannot run before
    // evaluation availability").
    if (!(dateOnly(this.now()) > entry.evaluation_session_date)) {
      throw serviceError('OUTCOME_NOT_AVAILABLE', 'Outcome cannot be settled before the evaluation session has passed');
    }

    if (typeof benchmark_return !== 'number' || !Number.isFinite(benchmark_return)) {
      throw serviceError('INVALID_OUTCOME', 'benchmark_return must be a finite number');
    }
    const expectedDirection = realizeDirection(benchmark_return, entry.benchmark.tolerance);
    if (!FORECAST_DIRECTIONS.includes(realized_direction) || realized_direction !== expectedDirection) {
      throw serviceError('INVALID_REALIZED_DIRECTION', `realized_direction must match the benchmark realization (${expectedDirection})`);
    }
    if (typeof source !== 'string' || source.length === 0 || source.length > MAX_SOURCE_LENGTH) {
      throw serviceError('INVALID_OUTCOME', `source must be a non-empty string of at most ${MAX_SOURCE_LENGTH} characters`);
    }

    const realizedOutcome = {
      realized_direction,
      benchmark_return,
      observed_session_date,
      source,
    };

    if (entry.status === 'settled') {
      if (stableSerialize(entry.realized_outcome) === stableSerialize(realizedOutcome)) {
        return structuredClone(entry);
      }
      throw serviceError('OUTCOME_CONFLICT', 'Forecast already settled with a different realized outcome');
    }

    const settledAt = this.now().toISOString();
    const settled = await this.forecastRepository.settle(ledger_id, realizedOutcome, settledAt);
    if (!settled) {
      throw serviceError('OUTCOME_CONFLICT', 'Forecast could not be settled (concurrent settlement)');
    }
    return structuredClone(settled);
  }

  async listForecasts({ owner_id, assessment_id } = {}) {
    const ownerId = assertOwnerScopedId(owner_id, 'owner_id');
    const assessmentId = assertOwnerScopedId(assessment_id, 'assessment_id');
    return this.forecastRepository.listForAssessment(ownerId, assessmentId);
  }

  async buildScorecard({ owner_id, instrument_id, quality_observations = [], calibration_evidence = null } = {}) {
    const ownerId = assertOwnerScopedId(owner_id, 'owner_id');
    const instrumentId = assertOwnerScopedId(instrument_id, 'instrument_id');
    const entries = await this.forecastRepository.listSettled(ownerId, instrumentId);
    return computeScorecard({ entries, quality_observations, calibration_evidence });
  }
}

module.exports = {
  OutcomeService,
  computeScorecard,
  createMongooseForecastRepository,
  realizeDirection,
  BENCHMARKS,
  FROZEN_QUALITY_SET,
  MIN_MATURE_OBSERVATIONS,
  FORECAST_DIRECTIONS,
  STRATEGY_KINDS,
  LEDGER_STATUSES,
};
