'use strict';

/**
 * H07A — Auditable numerical scenarios and projection overlays.
 *
 * Produces OPTIONAL `NumericProjection` objects (CONTRACTS §7) of two kinds:
 *
 *   - `conditional_scenario`: scenario endpoint/range bounds derived from an
 *     explicit assumption set applied to an observed anchor price. The
 *     arithmetic is reproducible (`conditionalScenarioBounds`), and the bounds
 *     are never probability intervals and never a directional forecast.
 *
 *   - `volatility_reference`: a symmetric reference band around the anchor
 *     price scaled from an observed historical-volatility metric. It is a
 *     statistical reference, never an expected path and never a probability
 *     interval.
 *
 * `calibrated_forecast` is deliberately NOT produced here: it is gated behind
 * model/version, held-out evaluation, coverage/calibration definition and
 * observed validation evidence (CONTRACTS §7) and is not a launch claim.
 *
 * Every factory output is validated against the authoritative
 * `numericProjectionSchema` from `./contracts` before it is returned, so no
 * produced object can violate the downstream optional-renderer contract.
 *
 * Pure and deterministic: no clock, randomness, network or database access.
 * Bounds are finite positive numbers; null/insufficient inputs yield an
 * explicit null projection with limitations (`nullScenarioProjection`), never a
 * fabricated number. Only endpoint/range markers are produced — no daily paths,
 * no future candles.
 */

const { numericProjectionSchema } = require('./contracts');

const PROJECTION_KINDS = Object.freeze(['conditional_scenario', 'volatility_reference']);

const CONDITIONAL_SCENARIO_LIMITATION = 'Conditional scenario: numeric values are scenario endpoints computed from an explicit assumption set applied to the anchor price. They are not calibrated probabilities, not an expected direction, and not a forecast path.';
const VOLATILITY_REFERENCE_LIMITATION = 'Volatility reference: a symmetric band around the anchor price scaled from an observed historical-volatility metric. It is a statistical reference, not a directional forecast, not a probability interval, and not the analyst expected path.';
const CALIBRATED_FORECAST_GATE = 'Calibrated forecasts are not produced: they require a model/version, held-out evaluation, a coverage/calibration definition and observed validation evidence (CONTRACTS §7), and are gated, not a launch claim.';
const INSUFFICIENT_INPUTS_LIMITATION = 'No numeric projection was produced: inputs were null or insufficient to build an auditable conditional scenario or volatility reference. Qualitative outlooks remain valid without a numeric projection.';

const ISO_DATE_RE = /^(\d{4})-(\d{2})-(\d{2})$/;
const ISO_CURRENCY_RE = /^[A-Z]{3}$/;
const UTC_TIMESTAMP_RE = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.(\d{1,3}))?Z$/;

const MAX_ID_LENGTH = 160;
const MAX_TEXT_LENGTH = 4000;
const MAX_BASIS_LENGTH = 80;
const MAX_ASSUMPTION_IDS = 50;
const MAX_INPUT_IDS = 50;
const MAX_LIMITATIONS = 50;

// ---------------------------------------------------------------------------
// Guards
// ---------------------------------------------------------------------------

function isRealCalendarDate(value) {
  const match = ISO_DATE_RE.exec(value);
  if (!match) return false;
  const year = Number(match[1]);
  const month = Number(match[2]);
  const day = Number(match[3]);
  if (year < 1 || year > 9999 || month < 1 || month > 12) return false;
  const daysInMonth = new Date(Date.UTC(year, month, 0)).getUTCDate();
  return day >= 1 && day <= daysInMonth;
}

function assertValidSessionDate(value, label) {
  if (typeof value !== 'string' || !isRealCalendarDate(value)) {
    throw new RangeError(`Expected ${label} to be a real ISO session date`);
  }
  return value;
}

function isRealUtcTimestamp(value) {
  const match = UTC_TIMESTAMP_RE.exec(value);
  if (!match) return false;
  const [, year, month, day, hour, minute, second] = match.map(Number);
  const daysInMonth = new Date(Date.UTC(year, month, 0)).getUTCDate();
  return year >= 1 && year <= 9999
    && month >= 1 && month <= 12
    && day >= 1 && day <= daysInMonth
    && hour >= 0 && hour <= 23
    && minute >= 0 && minute <= 59
    && second >= 0 && second <= 59;
}

function assertValidUtcTimestamp(value, label) {
  if (typeof value !== 'string' || !isRealUtcTimestamp(value)) {
    throw new RangeError(`Expected ${label} to be a real UTC timestamp`);
  }
  return value;
}

function assertOpaqueId(value, label) {
  if (typeof value !== 'string' || value.length === 0 || value.length > MAX_ID_LENGTH) {
    throw new RangeError(`Expected ${label} to be a non-empty string of at most ${MAX_ID_LENGTH} characters`);
  }
  return value;
}

function assertNonEmptyText(value, label, maxLength = MAX_TEXT_LENGTH) {
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

function assertIdArray(values, label, { minLength = 0, maxLength = MAX_INPUT_IDS } = {}) {
  if (!Array.isArray(values) || values.length < minLength || values.length > maxLength) {
    throw new RangeError(`Expected ${label} to be an array of at least ${minLength} and at most ${maxLength} IDs`);
  }
  const seen = new Set();
  for (const entry of values) {
    assertOpaqueId(entry, `${label} entry`);
    if (seen.has(entry)) {
      throw new RangeError(`Expected ${label} entries to be unique`);
    }
    seen.add(entry);
  }
  return values;
}

function assertOptionalBound(value, label) {
  return value == null ? null : assertFinitePositiveNumber(value, label);
}

function assertLimitations(values) {
  if (!Array.isArray(values) || values.length > MAX_LIMITATIONS) {
    throw new RangeError(`Expected limitations to be an array of at most ${MAX_LIMITATIONS} entries`);
  }
  for (const entry of values) assertNonEmptyText(entry, 'limitation entry');
  return values;
}

function assertOrderedBounds(lower, central, upper) {
  const present = [lower, central, upper].filter((value) => value != null);
  if (present.length === 0) {
    throw new RangeError('At least one projection bound is required');
  }
  if (lower != null && central != null && lower > central) {
    throw new RangeError('lower cannot exceed central');
  }
  if (central != null && upper != null && central > upper) {
    throw new RangeError('central cannot exceed upper');
  }
  if (lower != null && upper != null && lower > upper) {
    throw new RangeError('lower cannot exceed upper');
  }
}

// ---------------------------------------------------------------------------
// Reproducible bound arithmetic (the "calculation", kept separate from the
// "object production" so both are independently auditable)
// ---------------------------------------------------------------------------

/**
 * Conditional-scenario bounds from an anchor price and explicit relative
 * shifts. Each present shift `s` yields a bound `anchor * (1 + s)`; a null
 * shift yields a null bound. Shifts must be finite and strictly above -100%
 * so every present bound stays positive. Returns frozen `{lower, central,
 * upper}`. This is reproducible arithmetic, not a probability interval.
 */
function conditionalScenarioBounds(anchorPrice, shifts) {
  assertFinitePositiveNumber(anchorPrice, 'anchorPrice');
  if (shifts == null || typeof shifts !== 'object' || Array.isArray(shifts)) {
    throw new RangeError('Expected shifts to be an object with lower_shift/central_shift/upper_shift');
  }
  const bounds = { lower: null, central: null, upper: null };
  let anyShift = false;
  for (const [shiftKey, boundKey] of [['lower_shift', 'lower'], ['central_shift', 'central'], ['upper_shift', 'upper']]) {
    const shift = shifts[shiftKey];
    if (shift == null) continue;
    if (typeof shift !== 'number' || !Number.isFinite(shift) || shift <= -1) {
      throw new RangeError(`Expected ${shiftKey} to be a finite number strictly above -100%`);
    }
    anyShift = true;
    bounds[boundKey] = anchorPrice * (1 + shift);
  }
  if (!anyShift) {
    throw new RangeError('At least one of lower_shift, central_shift or upper_shift is required');
  }
  assertOrderedBounds(bounds.lower, bounds.central, bounds.upper);
  return Object.freeze(bounds);
}

/**
 * Volatility-reference band: a symmetric range around the anchor price scaled
 * from an observed annualized volatility over a one-to-three month horizon.
 * lower = anchor * (1 - z * sigma), upper = anchor * (1 + z * sigma), where
 * sigma = annualizedVolatility * sqrt(horizon_months / 12). central is always
 * null (a reference band has no expected path). If the band would reach or
 * cross zero, no range is produced — the inputs are insufficient, never
 * clamped.
 */
function volatilityReferenceBounds(anchorPrice, annualizedVolatility, { horizon_months, z_multiple = 1 } = {}) {
  assertFinitePositiveNumber(anchorPrice, 'anchorPrice');
  assertFinitePositiveNumber(annualizedVolatility, 'annualizedVolatility');
  if (horizon_months !== 1 && horizon_months !== 2 && horizon_months !== 3) {
    throw new RangeError('Expected horizon_months to be 1, 2 or 3');
  }
  if (typeof z_multiple !== 'number' || !Number.isFinite(z_multiple) || z_multiple <= 0) {
    throw new RangeError('Expected z_multiple to be a positive finite number');
  }
  const scaledVolatility = annualizedVolatility * Math.sqrt(horizon_months / 12);
  const lower = anchorPrice * (1 - z_multiple * scaledVolatility);
  const upper = anchorPrice * (1 + z_multiple * scaledVolatility);
  if (lower <= 0) {
    throw new RangeError('Volatility reference band would extend to or below zero for these inputs; no reference range is produced');
  }
  return Object.freeze({ lower, central: null, upper });
}

// ---------------------------------------------------------------------------
// Projection object production (validated against the contract schema)
// ---------------------------------------------------------------------------

function buildProjection(kind, input) {
  const projection = Object.freeze({
    id: assertOpaqueId(input.id, 'projection id'),
    assessment_id: assertOpaqueId(input.assessment_id, 'assessment_id'),
    instrument_id: assertOpaqueId(input.instrument_id, 'instrument_id'),
    evidence_snapshot_id: assertOpaqueId(input.evidence_snapshot_id, 'evidence_snapshot_id'),
    anchor_time: assertValidUtcTimestamp(input.anchor_time, 'anchor_time'),
    anchor_price_metric_id: assertOpaqueId(input.anchor_price_metric_id, 'anchor_price_metric_id'),
    target_session_date: assertValidSessionDate(input.target_session_date, 'target_session_date'),
    kind,
    method: assertNonEmptyText(input.method, 'method'),
    method_version: assertNonEmptyText(input.method_version, 'method_version'),
    input_metric_ids: Object.freeze([...assertIdArray(input.input_metric_ids, 'input_metric_ids', { minLength: 1 })]),
    assumption_ids: Object.freeze([...assertIdArray(input.assumption_ids, 'assumption_ids', { minLength: 0, maxLength: MAX_ASSUMPTION_IDS })]),
    lower: assertOptionalBound(input.lower, 'lower'),
    central: assertOptionalBound(input.central, 'central'),
    upper: assertOptionalBound(input.upper, 'upper'),
    currency: assertNonEmptyText(input.currency, 'currency', 3),
    adjustment_basis: assertNonEmptyText(input.adjustment_basis, 'adjustment_basis', MAX_BASIS_LENGTH),
    calibration: null,
    valid_until: input.valid_until == null ? null : assertValidUtcTimestamp(input.valid_until, 'valid_until'),
    limitations: Object.freeze([...assertLimitations(input.limitations)]),
  });

  if (!ISO_CURRENCY_RE.test(projection.currency)) {
    throw new RangeError('Expected currency to be an ISO 4217 currency code');
  }
  assertOrderedBounds(projection.lower, projection.central, projection.upper);
  if (projection.valid_until != null && projection.valid_until < projection.anchor_time) {
    throw new RangeError('Projection validity cannot end before its anchor');
  }
  if (projection.target_session_date < projection.anchor_time.slice(0, 10)) {
    throw new RangeError('Target session date cannot predate the anchor');
  }

  // Guarantee the downstream optional-renderer contract is preserved.
  const parsed = numericProjectionSchema.safeParse(projection);
  if (!parsed.success) {
    throw new RangeError(`Projection violates the NumericProjection contract: ${parsed.error.issues.map((issue) => issue.message).join('; ')}`);
  }
  return projection;
}

function createConditionalScenario(input) {
  if (input == null || typeof input !== 'object' || Array.isArray(input)) {
    throw new RangeError('Expected a conditional scenario input object');
  }
  const assumptions = assertIdArray(input.assumption_ids, 'assumption_ids', { minLength: 1, maxLength: MAX_ASSUMPTION_IDS });
  const limitations = [CONDITIONAL_SCENARIO_LIMITATION, ...(input.limitations ?? [])];
  return buildProjection('conditional_scenario', { ...input, assumption_ids: assumptions, limitations });
}

function createVolatilityReference(input) {
  if (input == null || typeof input !== 'object' || Array.isArray(input)) {
    throw new RangeError('Expected a volatility reference input object');
  }
  if (input.central != null) {
    throw new RangeError('A volatility reference cannot carry a central path');
  }
  const limitations = [VOLATILITY_REFERENCE_LIMITATION, ...(input.limitations ?? [])];
  return buildProjection('volatility_reference', { ...input, central: null, limitations });
}

function createProjection(input) {
  if (input == null || typeof input !== 'object' || Array.isArray(input)) {
    throw new RangeError('Expected a projection input object');
  }
  switch (input.kind) {
    case 'conditional_scenario':
      return createConditionalScenario(input);
    case 'volatility_reference':
      return createVolatilityReference(input);
    case 'calibrated_forecast':
      throw new RangeError(CALIBRATED_FORECAST_GATE);
    default:
      throw new RangeError(`Unsupported projection kind '${String(input.kind)}'`);
  }
}

// ---------------------------------------------------------------------------
// Explicit null for null/insufficient inputs
// ---------------------------------------------------------------------------

function nullScenarioProjection(extraLimitations = []) {
  if (!Array.isArray(extraLimitations)) {
    throw new TypeError('Expected extraLimitations to be an array');
  }
  const dataLimitations = [INSUFFICIENT_INPUTS_LIMITATION];
  for (const entry of extraLimitations) {
    assertNonEmptyText(entry, 'limitation entry');
    dataLimitations.push(entry);
  }
  return Object.freeze({
    numeric_projection: null,
    data_limitations: Object.freeze(dataLimitations),
  });
}

module.exports = {
  PROJECTION_KINDS,
  CONDITIONAL_SCENARIO_LIMITATION,
  VOLATILITY_REFERENCE_LIMITATION,
  CALIBRATED_FORECAST_GATE,
  INSUFFICIENT_INPUTS_LIMITATION,
  conditionalScenarioBounds,
  volatilityReferenceBounds,
  createConditionalScenario,
  createVolatilityReference,
  createProjection,
  nullScenarioProjection,
};
