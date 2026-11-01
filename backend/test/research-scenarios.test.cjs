'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');

const scenarios = require('../src/features/research/scenarios');
const { numericProjectionSchema } = require('../src/features/research/contracts');

const fixturesDir = path.join(__dirname, 'fixtures', 'research');
const fx = JSON.parse(fs.readFileSync(path.join(fixturesDir, 'scenarios-fixtures.json'), 'utf8'));

function assertClose(actual, expected, tolerance = 1e-12) {
  assert.equal(typeof actual, 'number');
  assert.ok(Number.isFinite(actual), `expected a finite number, got ${actual}`);
  const scale = Math.max(Math.abs(expected), 1);
  assert.ok(
    Math.abs(actual - expected) <= tolerance * scale,
    `expected ${actual} to be within ${tolerance * scale} of ${expected}`,
  );
}

function assertBounds(actual, expected) {
  for (const key of ['lower', 'central', 'upper']) {
    if (expected[key] == null) assert.equal(actual[key], null, `${key} should be null`);
    else assertClose(actual[key], expected[key]);
  }
}

function conditionalInput(overrides = {}) {
  return {
    id: fx.identity.id,
    assessment_id: fx.identity.assessment_id,
    instrument_id: fx.identity.instrument_id,
    evidence_snapshot_id: fx.identity.evidence_snapshot_id,
    anchor_time: fx.identity.anchor_time,
    anchor_price_metric_id: fx.identity.anchor_price_metric_id,
    target_session_date: fx.identity.target_session_date,
    method: 'explicit assumption shifts applied to anchor price',
    method_version: '1',
    input_metric_ids: ['metric-anchor-price'],
    assumption_ids: ['assumption-a'],
    lower: 90.0,
    upper: 115.0,
    currency: fx.identity.currency,
    adjustment_basis: fx.identity.adjustment_basis,
    valid_until: fx.identity.valid_until,
    ...overrides,
  };
}

function volatilityInput(overrides = {}) {
  return {
    id: 'proj-vol-1',
    assessment_id: fx.identity.assessment_id,
    instrument_id: fx.identity.instrument_id,
    evidence_snapshot_id: fx.identity.evidence_snapshot_id,
    anchor_time: fx.identity.anchor_time,
    anchor_price_metric_id: fx.identity.anchor_price_metric_id,
    target_session_date: fx.identity.target_session_date,
    method: 'annualized historical volatility scaled by sqrt(horizon_months/12)',
    method_version: '1',
    input_metric_ids: ['metric-anchor-price', 'metric-volatility'],
    assumption_ids: [],
    lower: 90.0,
    upper: 110.0,
    currency: fx.identity.currency,
    adjustment_basis: fx.identity.adjustment_basis,
    valid_until: fx.identity.valid_until,
    ...overrides,
  };
}

// ---------------------------------------------------------------------------
// Fixture sanity
// ---------------------------------------------------------------------------

test('scenario fixtures are declared, versioned, synthetic and non-empty', () => {
  assert.equal(fx.fixture_kind, 'deterministic_scenario_reference');
  assert.equal(fx.contract_version, 1);
  assert.match(fx.fixture_purpose, /not observed market data/);
  assert.match(fx.fixture_purpose, /not calibrated forecasts/);
  assert.ok(fx.conditional_bounds.length >= 3);
  assert.ok(fx.volatility_bounds.length >= 3);
});

// ---------------------------------------------------------------------------
// conditionalScenarioBounds — reproducible arithmetic
// ---------------------------------------------------------------------------

test('conditionalScenarioBounds reproduces independently computed bounds for every fixture', () => {
  for (const c of fx.conditional_bounds) {
    const bounds = scenarios.conditionalScenarioBounds(c.anchor_price, {
      lower_shift: c.lower_shift,
      central_shift: c.central_shift,
      upper_shift: c.upper_shift,
    });
    assertBounds(bounds, c.expected);
    assert.ok(Object.isFrozen(bounds), `${c.name} bounds should be frozen`);
  }
});

test('conditionalScenarioBounds rejects unordered shifts', () => {
  assert.throws(
    () => scenarios.conditionalScenarioBounds(100.0, { lower_shift: 0.10, upper_shift: -0.10 }),
    RangeError,
  );
});

test('conditionalScenarioBounds rejects a shift at or below -100%', () => {
  assert.throws(() => scenarios.conditionalScenarioBounds(100.0, { lower_shift: -1.0 }), RangeError);
  assert.throws(() => scenarios.conditionalScenarioBounds(100.0, { upper_shift: -1.05 }), RangeError);
});

test('conditionalScenarioBounds requires at least one shift', () => {
  assert.throws(() => scenarios.conditionalScenarioBounds(100.0, {}), RangeError);
});

test('conditionalScenarioBounds requires a finite positive anchor price', () => {
  assert.throws(() => scenarios.conditionalScenarioBounds(0, { lower_shift: -0.1 }), RangeError);
  assert.throws(() => scenarios.conditionalScenarioBounds(NaN, { lower_shift: -0.1 }), RangeError);
  assert.throws(() => scenarios.conditionalScenarioBounds(-5, { lower_shift: -0.1 }), RangeError);
});

// ---------------------------------------------------------------------------
// volatilityReferenceBounds — reproducible arithmetic
// ---------------------------------------------------------------------------

test('volatilityReferenceBounds reproduces independently computed bands for every fixture', () => {
  for (const v of fx.volatility_bounds) {
    const bounds = scenarios.volatilityReferenceBounds(v.anchor_price, v.annualized_volatility, {
      horizon_months: v.horizon_months,
      z_multiple: v.z_multiple,
    });
    assertBounds(bounds, v.expected);
    assert.ok(Object.isFrozen(bounds), `${v.name} bounds should be frozen`);
  }
});

test('volatilityReferenceBounds never clamps a band to or below zero', () => {
  assert.throws(
    () => scenarios.volatilityReferenceBounds(100.0, 3.0, { horizon_months: 3, z_multiple: 1.0 }),
    RangeError,
  );
});

test('volatilityReferenceBounds rejects a non-positive volatility metric', () => {
  assert.throws(() => scenarios.volatilityReferenceBounds(100.0, 0, { horizon_months: 3 }), RangeError);
  assert.throws(() => scenarios.volatilityReferenceBounds(100.0, -0.2, { horizon_months: 3 }), RangeError);
});

test('volatilityReferenceBounds requires a 1-to-3 month horizon', () => {
  assert.throws(() => scenarios.volatilityReferenceBounds(100.0, 0.2, { horizon_months: 0 }), RangeError);
  assert.throws(() => scenarios.volatilityReferenceBounds(100.0, 0.2, { horizon_months: 4 }), RangeError);
});

// ---------------------------------------------------------------------------
// createConditionalScenario — auditable projection object
// ---------------------------------------------------------------------------

test('createConditionalScenario builds a frozen contract-shaped projection', () => {
  const projection = scenarios.createConditionalScenario(conditionalInput());
  assert.equal(projection.kind, 'conditional_scenario');
  assert.equal(projection.calibration, null);
  assert.ok(Object.isFrozen(projection));
  const parsed = numericProjectionSchema.safeParse(projection);
  assert.equal(parsed.success, true, JSON.stringify(parsed.error?.issues ?? null));
});

test('createConditionalScenario requires at least one explicit assumption', () => {
  assert.throws(
    () => scenarios.createConditionalScenario(conditionalInput({ assumption_ids: [] })),
    RangeError,
  );
});

test('createConditionalScenario requires at least one bound and ordered bounds', () => {
  assert.throws(
    () => scenarios.createConditionalScenario(conditionalInput({ lower: null, central: null, upper: null })),
    RangeError,
  );
  assert.throws(
    () => scenarios.createConditionalScenario(conditionalInput({ lower: 120.0, upper: 100.0 })),
    RangeError,
  );
});

test('createConditionalScenario labels itself a non-probability scenario', () => {
  const projection = scenarios.createConditionalScenario(conditionalInput());
  const text = projection.limitations.join(' ');
  assert.match(text, /not calibrated probabilities/i);
  assert.match(text, /not.*expected direction/i);
  assert.ok(!/^expected/i.test(projection.method));
});

// ---------------------------------------------------------------------------
// createVolatilityReference — reference band, not a forecast
// ---------------------------------------------------------------------------

test('createVolatilityReference builds a frozen reference band with no central path', () => {
  const projection = scenarios.createVolatilityReference(volatilityInput());
  assert.equal(projection.kind, 'volatility_reference');
  assert.equal(projection.central, null);
  assert.equal(projection.calibration, null);
  assert.ok(Object.isFrozen(projection));
  const parsed = numericProjectionSchema.safeParse(projection);
  assert.equal(parsed.success, true, JSON.stringify(parsed.error?.issues ?? null));
});

test('createVolatilityReference rejects a central path (never an expected level)', () => {
  assert.throws(
    () => scenarios.createVolatilityReference(volatilityInput({ central: 100.0 })),
    RangeError,
  );
});

test('createVolatilityReference labels itself a non-directional reference', () => {
  const projection = scenarios.createVolatilityReference(volatilityInput());
  const text = projection.limitations.join(' ');
  assert.match(text, /not a directional forecast/i);
  assert.match(text, /not.*probability interval/i);
});

// ---------------------------------------------------------------------------
// createProjection — kind dispatcher and calibrated_forecast gate
// ---------------------------------------------------------------------------

test('createProjection dispatches conditional_scenario and volatility_reference', () => {
  const cond = scenarios.createProjection({ ...conditionalInput(), kind: 'conditional_scenario' });
  const vol = scenarios.createProjection({ ...volatilityInput(), kind: 'volatility_reference' });
  assert.equal(cond.kind, 'conditional_scenario');
  assert.equal(vol.kind, 'volatility_reference');
});

test('createProjection rejects calibrated_forecast as gated, not fabricated', () => {
  assert.throws(
    () => scenarios.createProjection({ ...conditionalInput(), kind: 'calibrated_forecast' }),
    /calibrated/i,
  );
});

test('createProjection rejects an unknown kind', () => {
  assert.throws(() => scenarios.createProjection({ ...conditionalInput(), kind: 'bogus' }), RangeError);
});

// ---------------------------------------------------------------------------
// Null / insufficient inputs remain explicit
// ---------------------------------------------------------------------------

test('nullScenarioProjection returns an explicit null with limitations', () => {
  const result = scenarios.nullScenarioProjection(['anchor price metric missing']);
  assert.equal(result.numeric_projection, null);
  assert.ok(Array.isArray(result.data_limitations));
  assert.ok(result.data_limitations.length >= 1);
  assert.ok(Object.isFrozen(result));
  assert.ok(Object.isFrozen(result.data_limitations));
});

test('nullScenarioProjection rejects non-array extra limitations', () => {
  assert.throws(() => scenarios.nullScenarioProjection('not-an-array'), TypeError);
});

// ---------------------------------------------------------------------------
// Guards — malformed identity/timestamp/currency inputs fail closed
// ---------------------------------------------------------------------------

test('createProjection rejects malformed anchor timestamps and target dates', () => {
  assert.throws(() => scenarios.createConditionalScenario(conditionalInput({ anchor_time: '2024-13-40T99:00:00Z' })), RangeError);
  assert.throws(() => scenarios.createConditionalScenario(conditionalInput({ anchor_time: 'not-a-timestamp' })), RangeError);
  assert.throws(() => scenarios.createConditionalScenario(conditionalInput({ target_session_date: '2024-02-30' })), RangeError);
});

test('createProjection rejects a target date before the anchor', () => {
  assert.throws(
    () => scenarios.createConditionalScenario(conditionalInput({ target_session_date: '2024-03-14' })),
    RangeError,
  );
});

test('createProjection rejects a validity window that ends before the anchor', () => {
  assert.throws(
    () => scenarios.createConditionalScenario(conditionalInput({ valid_until: '2024-03-15T15:59:59.000Z' })),
    RangeError,
  );
});

test('createProjection rejects non-ISO currency codes', () => {
  assert.throws(() => scenarios.createConditionalScenario(conditionalInput({ currency: 'usd' })), RangeError);
  assert.throws(() => scenarios.createConditionalScenario(conditionalInput({ currency: 'US' })), RangeError);
});

test('createProjection rejects non-positive bounds', () => {
  assert.throws(() => scenarios.createConditionalScenario(conditionalInput({ lower: 0 })), RangeError);
  assert.throws(() => scenarios.createConditionalScenario(conditionalInput({ upper: -1 })), RangeError);
});

// ---------------------------------------------------------------------------
// Determinism — no clock/random in the projection path
// ---------------------------------------------------------------------------

test('projection production is deterministic (repeated calls deepEqual)', () => {
  const a = scenarios.createConditionalScenario(conditionalInput());
  const b = scenarios.createConditionalScenario(conditionalInput());
  assert.deepEqual(a, b);
});
