'use strict';

/**
 * H07 — Core deterministic metrics, economics and calendar horizons.
 *
 * All functions are pure and deterministic: no clock, randomness, network or
 * database access. Calendar horizon arithmetic is delegated to the contract
 * primitives in `./contracts` (month-end clamping, supported-year overflow,
 * evaluation-session walk-back); this module only adds registry/guard logic
 * on top and never reimplements that arithmetic.
 *
 * Money/quantity inputs use bounded decimal strings (CONTRACTS §1); derived
 * analytical values are finite JSON numbers with explicit basis labels. No
 * NaN/Infinity, no zero-as-missing, no fabricated defaults, and no FX
 * conversion: cross-currency or cross-basis comparisons are reported as
 * explicitly unavailable rather than approximated.
 *
 * Volatility output is a statistical reference of past observations. It is
 * never an expected direction, probability or forecast; numeric projections
 * remain null until H07A is independently accepted (see
 * NUMERIC_PROJECTION_LIMITATION).
 */

const { DECIMAL_LIMITS, calendarTargetDate, evaluationSessionDate } = require('./contracts');

const METHOD_VERSION = '1';

const NUMERIC_PROJECTION_LIMITATION = 'Numeric projection is intentionally null: code-produced conditional scenario and volatility-reference projection output is held for H07A and has not been independently accepted, so this outlook contains no numeric price forecast. Qualitative cases remain valid without one.';

const ISO_DATE_RE = /^(\d{4})-(\d{2})-(\d{2})$/;
const ISO_CURRENCY_RE = /^[A-Z]{3}$/;
const DECIMAL_RE = /^(?:0|[1-9]\d*)(?:\.\d+)?$/;

const MAX_ID_LENGTH = 160;
const MAX_LABEL_LENGTH = 160;
const MAX_METHOD_VERSION_LENGTH = 40;
const MAX_UNIT_LENGTH = 80;
const MAX_INPUT_IDS = 50;

// ---------------------------------------------------------------------------
// Guards
// ---------------------------------------------------------------------------

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

function assertValidSessionDate(value, label) {
  if (typeof value !== 'string' || !isRealCalendarDate(value)) {
    throw new RangeError(`Expected ${label} to be a real ISO session date`);
  }
  return value;
}

function assertNonEmptyString(value, label, maxLength) {
  if (typeof value !== 'string' || value.length === 0 || value.length > maxLength) {
    throw new RangeError(`Expected ${label} to be a non-empty string of at most ${maxLength} characters`);
  }
  return value;
}

function assertFiniteNumber(value, label) {
  if (typeof value !== 'number' || !Number.isFinite(value)) {
    throw new RangeError(`Expected ${label} to be a finite JSON number`);
  }
  return value;
}

function assertFinitePositiveNumber(value, label) {
  return assertFiniteNumber(value, label) > 0
    ? value
    : (() => { throw new RangeError(`Expected ${label} to be a positive finite number`); })();
}

function assertFiniteSeries(values, label, { positive = false, minLength = 1 } = {}) {
  if (!Array.isArray(values)) {
    throw new TypeError(`Expected ${label} to be an array`);
  }
  if (values.length < minLength) {
    throw new RangeError(`Expected ${label} to be an array of at least ${minLength} values`);
  }
  for (const value of values) {
    if (positive) assertFinitePositiveNumber(value, `${label} entry`);
    else assertFiniteNumber(value, `${label} entry`);
  }
  return values;
}

function parsePositiveDecimalString(value, label) {
  if (typeof value !== 'string' || !DECIMAL_RE.test(value)) {
    throw new RangeError(`Expected ${label} to be a bounded decimal string`);
  }
  const [integer, fraction = ''] = value.split('.');
  if (value.length > DECIMAL_LIMITS.maxLength
    || integer.length > DECIMAL_LIMITS.maxIntegerDigits
    || fraction.length > DECIMAL_LIMITS.maxFractionDigits) {
    throw new RangeError(`Expected ${label} to stay within bounded decimal precision`);
  }
  const numeric = Number(value);
  if (!Number.isFinite(numeric) || numeric <= 0) {
    throw new RangeError(`Expected ${label} to be a strictly positive decimal`);
  }
  return numeric;
}

function parseMoney(value, label) {
  if (value == null || typeof value !== 'object' || Array.isArray(value)) {
    throw new RangeError(`Expected ${label} to be a money object`);
  }
  const amount = parsePositiveDecimalString(value.amount, `${label}.amount`);
  assertNonEmptyString(value.currency, `${label}.currency`, 3);
  if (!ISO_CURRENCY_RE.test(value.currency)) {
    throw new RangeError(`Expected ${label}.currency to be an ISO 4217 currency code`);
  }
  return { amount, currency: value.currency };
}

function assertIdArray(values, label) {
  if (!Array.isArray(values) || values.length > MAX_INPUT_IDS) {
    throw new RangeError(`Expected ${label} to be an array of at most ${MAX_INPUT_IDS} IDs`);
  }
  const seen = new Set();
  for (const entry of values) {
    assertNonEmptyString(entry, `${label} entry`, MAX_ID_LENGTH);
    if (seen.has(entry)) {
      throw new RangeError(`Expected ${label} entries to be unique`);
    }
    seen.add(entry);
  }
  return values;
}

// ---------------------------------------------------------------------------
// Return, average, volatility and drawdown computations
// ---------------------------------------------------------------------------

function simpleReturns(closes) {
  assertFiniteSeries(closes, 'closes', { positive: true, minLength: 2 });
  const returns = [];
  for (let i = 1; i < closes.length; i += 1) {
    returns.push((closes[i] - closes[i - 1]) / closes[i - 1]);
  }
  return returns;
}

function meanOf(values) {
  assertFiniteSeries(values, 'values');
  let sum = 0;
  for (const value of values) sum += value;
  return sum / values.length;
}

function sampleVariance(values) {
  assertFiniteSeries(values, 'values', { minLength: 2 });
  const mean = meanOf(values);
  let sumSquaredDeviation = 0;
  for (const value of values) sumSquaredDeviation += (value - mean) ** 2;
  return sumSquaredDeviation / (values.length - 1);
}

function sampleStdDev(values) {
  return Math.sqrt(sampleVariance(values));
}

function annualizedVolatility(closes, periodsPerYear) {
  if (!Number.isInteger(periodsPerYear) || periodsPerYear < 1) {
    throw new RangeError('Expected periodsPerYear to be a positive integer');
  }
  const returns = simpleReturns(closes);
  if (returns.length < 2) {
    throw new RangeError('Annualized volatility requires at least two return observations');
  }
  return sampleStdDev(returns) * Math.sqrt(periodsPerYear);
}

function cumulativeReturn(closes) {
  assertFiniteSeries(closes, 'closes', { positive: true, minLength: 2 });
  return closes[closes.length - 1] / closes[0] - 1;
}

function maxDrawdown(closes) {
  assertFiniteSeries(closes, 'closes', { positive: true, minLength: 2 });
  let peakValue = closes[0];
  let peakIndex = 0;
  let worst = { max_drawdown: 0, peak_index: 0, trough_index: 0, peak_value: closes[0], trough_value: closes[0] };
  for (let i = 1; i < closes.length; i += 1) {
    if (closes[i] > peakValue) {
      peakValue = closes[i];
      peakIndex = i;
    }
    const drawdown = closes[i] / peakValue - 1;
    if (drawdown < worst.max_drawdown) {
      worst = {
        max_drawdown: drawdown,
        peak_index: peakIndex,
        trough_index: i,
        peak_value: peakValue,
        trough_value: closes[i],
      };
    }
  }
  return worst;
}

function relativeReturns(returns, benchmarkReturns) {
  assertFiniteSeries(returns, 'returns');
  assertFiniteSeries(benchmarkReturns, 'benchmarkReturns');
  if (returns.length !== benchmarkReturns.length) {
    throw new RangeError('Expected returns and benchmarkReturns to have equal length');
  }
  const perPeriodExcess = [];
  let baseGrowth = 1;
  let benchmarkGrowth = 1;
  for (let i = 0; i < returns.length; i += 1) {
    if (benchmarkReturns[i] <= -1) {
      throw new RangeError('Benchmark returns cannot be at or below -100%');
    }
    perPeriodExcess.push(returns[i] - benchmarkReturns[i]);
    baseGrowth *= 1 + returns[i];
    benchmarkGrowth *= 1 + benchmarkReturns[i];
  }
  return {
    per_period_excess: perPeriodExcess,
    cumulative_relative: baseGrowth / benchmarkGrowth - 1,
  };
}

// ---------------------------------------------------------------------------
// P&L economics
// ---------------------------------------------------------------------------

/**
 * Comparable P&L from bounded decimal-string economics. Currency and
 * adjustment-basis mismatches return an explicit unavailable result instead
 * of a silent approximation (CONTRACTS §2: no sourced FX policy yet; splits
 * must be reconciled across bases). Fees and dividends are excluded and the
 * result says so.
 */
function profitAndLoss(input) {
  if (input == null || typeof input !== 'object' || Array.isArray(input)) {
    throw new RangeError('Expected a P&L input object');
  }
  const averageCost = parseMoney(input.average_cost, 'average_cost');
  const currentPrice = parseMoney(input.current_price, 'current_price');
  const quantity = parsePositiveDecimalString(input.quantity, 'quantity');
  const costBasis = assertNonEmptyString(input.cost_adjustment_basis, 'cost_adjustment_basis', MAX_LABEL_LENGTH);
  const priceBasis = assertNonEmptyString(input.price_adjustment_basis, 'price_adjustment_basis', MAX_LABEL_LENGTH);

  if (averageCost.currency !== currentPrice.currency) {
    return { status: 'unavailable', reason: 'currency_mismatch' };
  }
  if (costBasis !== priceBasis) {
    return { status: 'unavailable', reason: 'adjustment_basis_mismatch' };
  }

  const difference = currentPrice.amount - averageCost.amount;
  return {
    status: 'available',
    currency: averageCost.currency,
    average_cost: averageCost.amount,
    current_price: currentPrice.amount,
    quantity,
    absolute_pl: quantity * difference,
    percent_pl: difference / averageCost.amount,
    excluded_adjustments: Object.freeze(['fees', 'dividends']),
  };
}

// ---------------------------------------------------------------------------
// Calendar horizons (delegating to contract primitives)
// ---------------------------------------------------------------------------

function outlookHorizons({ sessionAsOf, isExchangeSession }) {
  assertValidSessionDate(sessionAsOf, 'sessionAsOf');
  if (typeof isExchangeSession !== 'function') {
    throw new TypeError('Expected isExchangeSession to be a function');
  }
  return [1, 2, 3].map((horizonMonths) => {
    const calendarTarget = calendarTargetDate(sessionAsOf, horizonMonths);
    const evaluationSession = evaluationSessionDate(calendarTarget, isExchangeSession);
    if (evaluationSession < sessionAsOf) {
      throw new RangeError('Evaluation session cannot predate the assessment session');
    }
    return {
      horizon_months: horizonMonths,
      calendar_target_date: calendarTarget,
      evaluation_session_date: evaluationSession,
    };
  });
}

// ---------------------------------------------------------------------------
// Null numeric projection with explicit limitation
// ---------------------------------------------------------------------------

function nullNumericProjection(extraLimitations = []) {
  if (!Array.isArray(extraLimitations)) {
    throw new TypeError('Expected extraLimitations to be an array');
  }
  const dataLimitations = [NUMERIC_PROJECTION_LIMITATION];
  for (const entry of extraLimitations) {
    assertNonEmptyString(entry, 'limitation entry', 4000);
    dataLimitations.push(entry);
  }
  return Object.freeze({
    numeric_projection: null,
    data_limitations: Object.freeze(dataLimitations),
  });
}

// ---------------------------------------------------------------------------
// Metric records and registry
// ---------------------------------------------------------------------------

function createMetric(input) {
  if (input == null || typeof input !== 'object' || Array.isArray(input)) {
    throw new RangeError('Expected a metric input object');
  }
  return Object.freeze({
    id: assertNonEmptyString(input.id, 'metric id', MAX_ID_LENGTH),
    instrument_id: assertNonEmptyString(input.instrument_id, 'instrument_id', MAX_ID_LENGTH),
    value: assertFiniteNumber(input.value, 'metric value'),
    unit: input.unit == null
      ? null
      : assertNonEmptyString(input.unit, 'unit', MAX_UNIT_LENGTH),
    currency: input.currency == null
      ? null
      : (assertNonEmptyString(input.currency, 'currency', 3), ISO_CURRENCY_RE.test(input.currency)
        ? input.currency
        : (() => { throw new RangeError('Expected currency to be an ISO 4217 currency code'); })()),
    as_of: assertValidSessionDate(input.as_of, 'as_of'),
    basis: assertNonEmptyString(input.basis, 'basis', MAX_LABEL_LENGTH),
    method: assertNonEmptyString(input.method, 'method', MAX_LABEL_LENGTH),
    method_version: assertNonEmptyString(input.method_version, 'method_version', MAX_METHOD_VERSION_LENGTH),
    input_evidence_ids: Object.freeze([...assertIdArray(input.input_evidence_ids, 'input_evidence_ids')]),
    input_snapshot_ids: Object.freeze([...assertIdArray(input.input_snapshot_ids, 'input_snapshot_ids')]),
  });
}

function createMetricRegistry() {
  const metricsById = new Map();
  return Object.freeze({
    register(metric) {
      const validated = createMetric(metric);
      if (metricsById.has(validated.id)) {
        throw new RangeError(`Metric id '${validated.id}' is already registered`);
      }
      metricsById.set(validated.id, validated);
      return validated;
    },
    has(id) {
      return metricsById.has(id);
    },
    get(id) {
      return metricsById.get(id) ?? null;
    },
    list() {
      return [...metricsById.keys()].sort().map((id) => metricsById.get(id));
    },
    get size() {
      return metricsById.size;
    },
  });
}

module.exports = {
  METHOD_VERSION,
  NUMERIC_PROJECTION_LIMITATION,
  annualizedVolatility,
  cumulativeReturn,
  createMetric,
  createMetricRegistry,
  maxDrawdown,
  meanOf,
  nullNumericProjection,
  outlookHorizons,
  profitAndLoss,
  relativeReturns,
  sampleStdDev,
  sampleVariance,
  simpleReturns,
};
