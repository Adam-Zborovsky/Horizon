'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');

const metrics = require('../src/features/research/metrics');
const {
  calendarTargetDate,
  evaluationSessionDate,
} = require('../src/features/research/contracts');

const fixturesDir = path.join(__dirname, 'fixtures', 'research');
const fx = JSON.parse(fs.readFileSync(path.join(fixturesDir, 'metrics-fixtures.json'), 'utf8'));

function assertClose(actual, expected, tolerance = 1e-12) {
  assert.equal(typeof actual, 'number');
  assert.ok(Number.isFinite(actual), `expected a finite number, got ${actual}`);
  const scale = Math.max(Math.abs(expected), 1);
  assert.ok(
    Math.abs(actual - expected) <= tolerance * scale,
    `expected ${actual} to be within ${tolerance * scale} of ${expected}`,
  );
}

function assertCloseArray(actual, expected, tolerance = 1e-12) {
  assert.equal(actual.length, expected.length);
  for (let i = 0; i < expected.length; i += 1) assertClose(actual[i], expected[i], tolerance);
}

/** Weekday Mon-Fri exchange-session predicate minus an explicit holiday set. */
function sessionPredicate(nonSessions) {
  const closed = new Set(nonSessions);
  return (sessionDate) => {
    const weekday = new Date(`${sessionDate}T00:00:00Z`).getUTCDay();
    return weekday >= 1 && weekday <= 5 && !closed.has(sessionDate);
  };
}

const { price_series: priceSeries, relative_returns: relativeFixture } = fx;

// ---------------------------------------------------------------------------
// Fixture sanity
// ---------------------------------------------------------------------------

test('metric fixtures are declared, versioned and non-empty', () => {
  assert.equal(fx.fixture_kind, 'deterministic_metric_reference');
  assert.equal(fx.contract_version, 1);
  assert.match(fx.fixture_purpose, /not observed market data/);
  assert.ok(priceSeries.monotonic.closes.length >= 2);
  assert.ok(priceSeries.with_drawdown.closes.length >= 2);
  assert.ok(fx.pnl_cases.length >= 4);
  assert.ok(fx.calendar_cases.length >= 8);
});

// ---------------------------------------------------------------------------
// Returns, averages, volatility, drawdown
// ---------------------------------------------------------------------------

test('simple returns match the independently checked fixture series', () => {
  assertCloseArray(metrics.simpleReturns(priceSeries.monotonic.closes), priceSeries.monotonic.expected.simple_returns);
  assertCloseArray(metrics.simpleReturns(priceSeries.with_drawdown.closes), priceSeries.with_drawdown.expected.simple_returns);
});

test('mean return matches the independently checked fixture series', () => {
  assertClose(metrics.meanOf(metrics.simpleReturns(priceSeries.monotonic.closes)), priceSeries.monotonic.expected.mean_return);
  assertClose(metrics.meanOf(metrics.simpleReturns(priceSeries.with_drawdown.closes)), priceSeries.with_drawdown.expected.mean_return);
});

test('cumulative return matches the independently checked fixture series', () => {
  assertClose(metrics.cumulativeReturn(priceSeries.monotonic.closes), priceSeries.monotonic.expected.cumulative_return);
  assertClose(metrics.cumulativeReturn(priceSeries.with_drawdown.closes), priceSeries.with_drawdown.expected.cumulative_return);
});

test('sample variance and stddev match the independently checked fixture series', () => {
  const returnsB = metrics.simpleReturns(priceSeries.with_drawdown.closes);
  assertClose(metrics.sampleVariance(returnsB), priceSeries.with_drawdown.expected.sample_variance);
  assertClose(metrics.sampleStdDev(returnsB), priceSeries.with_drawdown.expected.sample_stddev);
  assertClose(metrics.sampleStdDev(metrics.simpleReturns(priceSeries.monotonic.closes)), priceSeries.monotonic.expected.sample_stddev);
});

test('annualized volatility matches the independently checked fixture series', () => {
  const { periods_per_year: periodsPerYear } = priceSeries.monotonic;
  assertClose(
    metrics.annualizedVolatility(priceSeries.monotonic.closes, periodsPerYear),
    priceSeries.monotonic.expected.annualized_volatility,
  );
  assertClose(
    metrics.annualizedVolatility(priceSeries.with_drawdown.closes, priceSeries.with_drawdown.periods_per_year),
    priceSeries.with_drawdown.expected.annualized_volatility,
  );
});

test('max drawdown matches the independently checked fixture series', () => {
  assertClose(metrics.maxDrawdown(priceSeries.monotonic.closes).max_drawdown, priceSeries.monotonic.expected.max_drawdown);
  const drawdown = metrics.maxDrawdown(priceSeries.with_drawdown.closes);
  const expected = priceSeries.with_drawdown.expected;
  assertClose(drawdown.max_drawdown, expected.max_drawdown);
  assert.equal(drawdown.peak_index, expected.drawdown_peak_index);
  assert.equal(drawdown.trough_index, expected.drawdown_trough_index);
  assertClose(drawdown.peak_value, expected.drawdown_peak_value);
  assertClose(drawdown.trough_value, expected.drawdown_trough_value);
});

test('relative returns match the independently checked fixture', () => {
  const relative = metrics.relativeReturns(relativeFixture.base_returns, relativeFixture.benchmark_returns);
  assertCloseArray(relative.per_period_excess, relativeFixture.expected.per_period_excess);
  assertClose(relative.cumulative_relative, relativeFixture.expected.cumulative_relative);
});

test('metric computations reject invalid inputs instead of propagating NaN', () => {
  assert.throws(() => metrics.simpleReturns([100]), RangeError);
  assert.throws(() => metrics.simpleReturns([100, Number.NaN]), RangeError);
  assert.throws(() => metrics.simpleReturns([100, Number.POSITIVE_INFINITY]), RangeError);
  assert.throws(() => metrics.simpleReturns([100, 0]), RangeError);
  assert.throws(() => metrics.simpleReturns([100, -5]), RangeError);
  assert.throws(() => metrics.simpleReturns('100,105'), TypeError);
  assert.throws(() => metrics.meanOf([]), RangeError);
  assert.throws(() => metrics.meanOf([0.1, Number.NaN]), RangeError);
  assert.throws(() => metrics.sampleVariance([0.1]), RangeError);
  assert.throws(() => metrics.annualizedVolatility([100, 105], 252), RangeError);
  assert.throws(() => metrics.annualizedVolatility([100, 105, 110], 0), RangeError);
  assert.throws(() => metrics.annualizedVolatility([100, 105, 110], 252.5), RangeError);
  assert.throws(() => metrics.annualizedVolatility([100, 105, 110], Number.NaN), RangeError);
  assert.throws(() => metrics.cumulativeReturn([100]), RangeError);
  assert.throws(() => metrics.maxDrawdown([100, Number.NaN]), RangeError);
  assert.throws(() => metrics.relativeReturns([0.1], [0.2, 0.3]), RangeError);
  assert.throws(() => metrics.relativeReturns([], []), RangeError);
  assert.throws(() => metrics.relativeReturns([0.1], [-1]), RangeError);
});

// ---------------------------------------------------------------------------
// P&L economics
// ---------------------------------------------------------------------------

test('P&L matches the independently checked available fixture cases', () => {
  for (const pnlCase of fx.pnl_cases.filter((entry) => entry.expected.status === 'available')) {
    const result = metrics.profitAndLoss(pnlCase);
    assert.equal(result.status, 'available', pnlCase.name);
    assert.equal(result.currency, pnlCase.expected.currency, pnlCase.name);
    assertClose(result.absolute_pl, pnlCase.expected.absolute_pl, 1e-9, pnlCase.name);
    assertClose(result.percent_pl, pnlCase.expected.percent_pl, 1e-9, pnlCase.name);
    assert.deepEqual(result.excluded_adjustments, ['fees', 'dividends'], pnlCase.name);
  }
});

test('P&L is deterministic for repeated identical calls', () => {
  const pnlCase = fx.pnl_cases[0];
  assert.deepEqual(metrics.profitAndLoss(pnlCase), metrics.profitAndLoss(pnlCase));
});

test('P&L returns explicit unavailability instead of guessing across currencies or bases', () => {
  for (const pnlCase of fx.pnl_cases.filter((entry) => entry.expected.status === 'unavailable')) {
    const result = metrics.profitAndLoss(pnlCase);
    assert.deepEqual(
      { status: result.status, reason: result.reason },
      { status: 'unavailable', reason: pnlCase.expected.reason },
      pnlCase.name,
    );
    assert.equal(result.absolute_pl, undefined, pnlCase.name);
    assert.equal(result.percent_pl, undefined, pnlCase.name);
  }
});

test('P&L rejects malformed economics instead of inventing values', () => {
  const base = fx.pnl_cases[0];
  const invalid = [
    { ...base, average_cost: { ...base.average_cost, amount: '-50.25' } },
    { ...base, average_cost: { ...base.average_cost, amount: 'abc' } },
    { ...base, average_cost: { ...base.average_cost, currency: 'usd' } },
    { ...base, average_cost: { ...base.average_cost, currency: 'US' } },
    { ...base, quantity: '0' },
    { ...base, quantity: '-10' },
    { ...base, quantity: '1e3' },
    { ...base, current_price: { ...base.current_price, amount: '0' } },
    { ...base, current_price: { ...base.current_price, amount: '60.25.1' } },
    { ...base, cost_adjustment_basis: '' },
    { ...base, price_adjustment_basis: null },
    { ...base, average_cost: null },
    { ...base, quantity: null },
  ];
  for (const entry of invalid) {
    assert.throws(() => metrics.profitAndLoss(entry), RangeError, JSON.stringify(entry));
  }
});

// ---------------------------------------------------------------------------
// Metric records and registry
// ---------------------------------------------------------------------------

test('createMetric produces an immutable contract-shaped record with method/input/source IDs', () => {
  const value = metrics.annualizedVolatility(priceSeries.with_drawdown.closes, 252);
  const metric = metrics.createMetric({
    id: 'metric-annualized-volatility-b',
    instrument_id: 'instrument-ibm-xnys-usd',
    value,
    unit: 'ratio_annualized',
    currency: 'USD',
    as_of: '2024-03-28',
    basis: 'close_to_close_simple_returns',
    method: 'sample_volatility_annualized',
    method_version: metrics.METHOD_VERSION,
    input_evidence_ids: ['evidence-1', 'evidence-2'],
    input_snapshot_ids: ['snapshot-1'],
  });
  assert.deepEqual(Object.keys(metric).sort(), [
    'as_of', 'basis', 'currency', 'id', 'input_evidence_ids', 'input_snapshot_ids',
    'instrument_id', 'method', 'method_version', 'unit', 'value',
  ].sort());
  assertClose(metric.value, priceSeries.with_drawdown.expected.annualized_volatility);
  assert.equal(Object.isFrozen(metric), true);
  assert.throws(() => { metric.value = 42; }, TypeError);
});

test('createMetric guards finite values, basis, method, dates and unique input IDs', () => {
  const valid = {
    id: 'metric-x',
    instrument_id: 'instrument-ibm-xnys-usd',
    value: 0.5,
    unit: 'ratio',
    currency: 'USD',
    as_of: '2024-03-28',
    basis: 'close_to_close_simple_returns',
    method: 'mean_simple_return',
    method_version: '1',
    input_evidence_ids: ['evidence-1'],
    input_snapshot_ids: ['snapshot-1'],
  };
  const invalid = [
    { ...valid, value: Number.NaN },
    { ...valid, value: Number.POSITIVE_INFINITY },
    { ...valid, value: '0.5' },
    { ...valid, id: '' },
    { ...valid, instrument_id: '' },
    { ...valid, basis: '' },
    { ...valid, method: '' },
    { ...valid, method_version: '' },
    { ...valid, as_of: '2024-02-30' },
    { ...valid, as_of: '2024-3-28' },
    { ...valid, as_of: 'not-a-date' },
    { ...valid, currency: 'usd' },
    { ...valid, input_evidence_ids: ['evidence-1', 'evidence-1'] },
    { ...valid, input_snapshot_ids: [42] },
    { ...valid, unit: 7 },
  ];
  for (const entry of invalid) {
    assert.throws(() => metrics.createMetric(entry), RangeError, JSON.stringify(entry));
  }
});

test('metric registry registers, resolves, lists sorted and rejects duplicates', () => {
  const registry = metrics.createMetricRegistry();
  const base = {
    instrument_id: 'instrument-ibm-xnys-usd',
    value: 0.1,
    unit: 'ratio',
    currency: 'USD',
    as_of: '2024-03-28',
    basis: 'close_to_close_simple_returns',
    method: 'mean_simple_return',
    method_version: metrics.METHOD_VERSION,
    input_evidence_ids: ['evidence-1'],
    input_snapshot_ids: ['snapshot-1'],
  };
  const second = metrics.createMetric({ ...base, id: 'metric-b', value: 0.2 });
  const first = metrics.createMetric({ ...base, id: 'metric-a' });
  registry.register(second);
  registry.register(first);
  assert.equal(registry.size, 2);
  assert.equal(registry.has('metric-a'), true);
  assert.deepEqual(registry.get('metric-a'), first);
  assert.equal(Object.isFrozen(registry.get('metric-a')), true);
  assert.deepEqual(registry.list().map((metric) => metric.id), ['metric-a', 'metric-b']);
  assert.equal(registry.get('metric-missing'), null);
  assert.throws(() => registry.register(metrics.createMetric({ ...base, id: 'metric-a' })), RangeError);
  assert.throws(() => registry.register({ ...base, id: 'metric-c', value: Number.NaN }), RangeError);
});

test('metric registry stores and returns the frozen validated record, never the caller mutable original', () => {
  const registry = metrics.createMetricRegistry();
  const raw = {
    id: 'metric-raw',
    instrument_id: 'instrument-ibm-xnys-usd',
    value: 0.3,
    unit: 'ratio',
    currency: 'USD',
    as_of: '2024-03-28',
    basis: 'close_to_close_simple_returns',
    method: 'mean_simple_return',
    method_version: metrics.METHOD_VERSION,
    input_evidence_ids: ['evidence-1'],
    input_snapshot_ids: ['snapshot-1'],
  };
  const returned = registry.register(raw);
  // Post-registration mutation of the caller's original must not leak into the registry.
  raw.value = 999;
  raw.currency = 'EUR';
  raw.input_evidence_ids.push('evidence-2');
  assert.equal(Object.isFrozen(returned), true);
  assert.equal(Object.isFrozen(registry.get('metric-raw')), true);
  assert.equal(returned.value, 0.3);
  assert.equal(returned.currency, 'USD');
  assert.deepEqual(returned.input_evidence_ids, ['evidence-1']);
  assert.equal(returned, registry.get('metric-raw'));
  for (const metric of registry.list()) {
    assert.equal(Object.isFrozen(metric), true);
  }
});

// ---------------------------------------------------------------------------
// Calendar horizons (delegating to contract primitives)
// ---------------------------------------------------------------------------

test('outlook horizons reproduce the independently checked calendar fixture cases', () => {
  const alwaysSession = () => true;
  for (const calendarCase of fx.calendar_cases) {
    if (calendarCase.expected_error) {
      assert.throws(
        () => metrics.outlookHorizons({ sessionAsOf: calendarCase.session_as_of, isExchangeSession: alwaysSession }),
        RangeError,
        calendarCase.name,
      );
      continue;
    }
    const horizons = metrics.outlookHorizons({
      sessionAsOf: calendarCase.session_as_of,
      isExchangeSession: sessionPredicate(calendarCase.non_sessions || []),
    });
    const entry = horizons.find((item) => item.horizon_months === calendarCase.horizon_months);
    assert.ok(entry, calendarCase.name);
    assert.equal(entry.calendar_target_date, calendarCase.expected_calendar_target, calendarCase.name);
    if (calendarCase.expected_evaluation_session) {
      assert.equal(entry.evaluation_session_date, calendarCase.expected_evaluation_session, calendarCase.name);
    }
    assert.ok(entry.evaluation_session_date <= entry.calendar_target_date, calendarCase.name);
    assert.ok(entry.evaluation_session_date >= calendarCase.session_as_of, calendarCase.name);
  }
});

test('outlook horizons cover exactly horizons 1, 2 and 3 in order', () => {
  const horizons = metrics.outlookHorizons({ sessionAsOf: '2024-03-01', isExchangeSession: () => true });
  assert.deepEqual(horizons.map((entry) => entry.horizon_months), [1, 2, 3]);
  for (const entry of horizons) {
    assert.equal(entry.calendar_target_date, calendarTargetDate('2024-03-01', entry.horizon_months));
    assert.equal(entry.evaluation_session_date, evaluationSessionDate(entry.calendar_target_date, () => true));
  }
});

test('outlook horizons reject invalid horizons, dates and predicates', () => {
  assert.throws(() => metrics.outlookHorizons({ sessionAsOf: '2024-02-30', isExchangeSession: () => true }), RangeError);
  assert.throws(() => metrics.outlookHorizons({ sessionAsOf: '2024-03-01', isExchangeSession: 'nope' }), TypeError);
  assert.throws(
    () => metrics.outlookHorizons({ sessionAsOf: '2024-03-01', isExchangeSession: () => false }),
    RangeError,
  );
});

// ---------------------------------------------------------------------------
// Null numeric projection with explicit limitation
// ---------------------------------------------------------------------------

test('numeric projection stays null with the explicit H07A limitation', () => {
  assert.equal(typeof metrics.NUMERIC_PROJECTION_LIMITATION, 'string');
  assert.ok(metrics.NUMERIC_PROJECTION_LIMITATION.length > 40);
  assert.equal(
    metrics.NUMERIC_PROJECTION_LIMITATION,
    fx.numeric_projection_limitation,
    'fixture limitation text must match the module constant',
  );
  const projection = metrics.nullNumericProjection();
  assert.equal(projection.numeric_projection, null);
  assert.deepEqual(projection.data_limitations, [fx.numeric_projection_limitation]);
  const extended = metrics.nullNumericProjection(['Average cost is unknown for this candidate position']);
  assert.equal(extended.numeric_projection, null);
  assert.deepEqual(extended.data_limitations, [
    fx.numeric_projection_limitation,
    'Average cost is unknown for this candidate position',
  ]);
  assert.throws(() => metrics.nullNumericProjection(['']), RangeError);
  assert.throws(() => metrics.nullNumericProjection([42]), RangeError);
  assert.throws(() => metrics.nullNumericProjection('not-an-array'), TypeError);
});

// ---------------------------------------------------------------------------
// Determinism and labeling guards
// ---------------------------------------------------------------------------

test('metric computations are deterministic across repeated calls', () => {
  const closes = priceSeries.with_drawdown.closes;
  assert.deepEqual(metrics.simpleReturns(closes), metrics.simpleReturns(closes));
  assert.deepEqual(metrics.maxDrawdown(closes), metrics.maxDrawdown(closes));
  assert.deepEqual(
    metrics.annualizedVolatility(closes, 252),
    metrics.annualizedVolatility(closes, 252),
  );
  assert.deepEqual(
    metrics.outlookHorizons({ sessionAsOf: '2024-03-01', isExchangeSession: sessionPredicate([]) }),
    metrics.outlookHorizons({ sessionAsOf: '2024-03-01', isExchangeSession: sessionPredicate([]) }),
  );
});

test('metric module contains no nondeterministic clock or randomness sources', () => {
  const source = fs.readFileSync(require.resolve('../src/features/research/metrics'), 'utf8');
  assert.doesNotMatch(source, /Math\.random/);
  assert.doesNotMatch(source, /Date\.now/);
  assert.doesNotMatch(source, /new Date\(\)/);
});

test('volatility output is labeled as a statistical reference, never an expected direction', () => {
  const banned = /expected|probability|direction|forecast|target price/i;
  const metric = metrics.createMetric({
    id: 'metric-volatility-reference',
    instrument_id: 'instrument-ibm-xnys-usd',
    value: metrics.annualizedVolatility(priceSeries.with_drawdown.closes, 252),
    unit: 'ratio_annualized',
    currency: 'USD',
    as_of: '2024-03-28',
    basis: 'close_to_close_sample_stddev_of_simple_returns',
    method: 'sample_volatility_annualized',
    method_version: metrics.METHOD_VERSION,
    input_evidence_ids: ['evidence-1'],
    input_snapshot_ids: ['snapshot-1'],
  });
  assert.doesNotMatch(metric.method, banned);
  assert.doesNotMatch(metric.basis, banned);
  assert.doesNotMatch(metric.unit, banned);
  assert.match(metrics.NUMERIC_PROJECTION_LIMITATION, /no numeric price forecast/);
});
