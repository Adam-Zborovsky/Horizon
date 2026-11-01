const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');

const {
  CONTRACT_VERSION,
  calendarTargetDate,
  evaluationSessionDate,
  schemas,
} = require('../src/features/research/contracts');

const fixturesDir = path.join(__dirname, 'fixtures', 'research');
const observedFixture = JSON.parse(fs.readFileSync(path.join(fixturesDir, 'observed-bars.json'), 'utf8'));
const cases = JSON.parse(fs.readFileSync(path.join(fixturesDir, 'contract-cases.json'), 'utf8'));

function resultFor(schema, value) {
  return schemas[schema].safeParse(value);
}

const canonicalSchemaNames = [
  'positionWrite',
  'marketBar',
  'evidenceItem',
  'claim',
  'numericProjection',
  'researchAssessment',
  'researchRun',
  'positionContext',
  'historyResponse',
];

test('publishes one versioned, source-specific offline observed-bar recording', () => {
  assert.equal(CONTRACT_VERSION, 1);
  assert.equal(observedFixture.fixture_kind, 'observed_recording');
  assert.equal(observedFixture.contract_version, CONTRACT_VERSION);
  assert.match(observedFixture.source.capture_url, /^https:\/\//);
  assert.match(observedFixture.source.retrieved_at, /Z$/);
  assert.match(observedFixture.source.content_sha256, /^[a-f0-9]{64}$/);
  const provenancePath = path.resolve(
    __dirname,
    '../../docs/horizon/evidence/h01/observed-bars-provenance.json',
  );
  const provenanceDigest = crypto.createHash('sha256').update(fs.readFileSync(provenancePath)).digest('hex');
  assert.equal(provenanceDigest, observedFixture.source.content_sha256);
  assert.ok(observedFixture.bars.length > 0);
  for (const bar of observedFixture.bars) {
    assert.equal(resultFor('marketBar', bar).success, true);
  }
});

test('accepts a named positive sample for every canonical schema', () => {
  assert.deepEqual(Object.keys(cases.valid).sort(), [...canonicalSchemaNames].sort());
  for (const [name, value] of Object.entries(cases.valid)) {
    assert.equal(resultFor(name, value).success, true, name);
  }
});

test('rejects a named negative sample for every canonical schema', () => {
  assert.deepEqual(Object.keys(cases.invalid).sort(), [...canonicalSchemaNames].sort());
  for (const [name, invalidCases] of Object.entries(cases.invalid)) {
    for (const invalidCase of invalidCases) {
      const value = structuredClone(cases.valid[name]);
      for (const [field, fieldValue] of Object.entries(invalidCase.changes)) {
        value[field] = fieldValue;
      }
      assert.equal(
        resultFor(name, value).success,
        false,
        `${name}: ${invalidCase.name}`,
      );
    }
  }
});

test('rejects invalid calendar instants and bounded decimal overflow without number coercion', () => {
  const invalidDate = structuredClone(cases.valid.marketBar);
  invalidDate.session_date = '2024-02-30';
  assert.equal(resultFor('marketBar', invalidDate).success, false);

  const invalidTimestamp = structuredClone(cases.valid.marketBar);
  invalidTimestamp.time = '2024-02-29T24:00:00Z';
  assert.equal(resultFor('marketBar', invalidTimestamp).success, false);

  const leapDay = structuredClone(cases.valid.positionWrite);
  leapDay.opened_on = '2024-02-29';
  leapDay.average_cost.amount = '999999999999999999999999.123456789012';
  leapDay.quantity = '0.000000000001';
  assert.equal(resultFor('positionWrite', leapDay).success, true);

  const overflow = structuredClone(leapDay);
  overflow.average_cost.amount = '9'.repeat(400);
  assert.equal(resultFor('positionWrite', overflow).success, false);

  const zero = structuredClone(leapDay);
  zero.quantity = '0.000000000000';
  assert.equal(resultFor('positionWrite', zero).success, false);
});

test('enforces bounded assessment nesting, identity references, and month-clamped horizons', () => {
  assert.equal(calendarTargetDate('2024-01-31', 1), '2024-02-29');
  assert.equal(calendarTargetDate('2023-01-31', 1), '2023-02-28');
  assert.equal(calendarTargetDate('2024-11-30', 3), '2025-02-28');
  assert.equal(
    evaluationSessionDate('2024-03-31', (date) => !['2024-03-30', '2024-03-31'].includes(date)),
    '2024-03-29',
  );

  const assessment = structuredClone(cases.valid.researchAssessment);
  assessment.session_as_of = '2024-01-31';
  assessment.outlooks[0].calendar_target_date = '2024-02-29';
  assessment.outlooks[0].evaluation_session_date = '2024-02-29';
  assessment.outlooks[1].calendar_target_date = '2024-03-31';
  assessment.outlooks[1].evaluation_session_date = '2024-03-29';
  assessment.outlooks[2].calendar_target_date = '2024-04-30';
  assessment.outlooks[2].evaluation_session_date = '2024-04-30';
  assert.equal(resultFor('researchAssessment', assessment).success, true);

  const wrongTarget = structuredClone(assessment);
  wrongTarget.outlooks[0].calendar_target_date = '2024-02-28';
  assert.equal(resultFor('researchAssessment', wrongTarget).success, false);

  const lateEvaluation = structuredClone(assessment);
  lateEvaluation.outlooks[1].evaluation_session_date = '2024-04-01';
  assert.equal(resultFor('researchAssessment', lateEvaluation).success, false);

  const projectionIdentityMismatch = structuredClone(assessment);
  projectionIdentityMismatch.outlooks[0].numeric_projection = structuredClone(cases.valid.numericProjection);
  projectionIdentityMismatch.outlooks[0].numeric_projection.target_session_date = '2024-02-29';
  projectionIdentityMismatch.outlooks[0].numeric_projection.assessment_id = 'other-assessment';
  assert.equal(resultFor('researchAssessment', projectionIdentityMismatch).success, false);

  const malformedThesis = structuredClone(assessment);
  delete malformedThesis.market_thesis.counterevidence;
  assert.equal(resultFor('researchAssessment', malformedThesis).success, false);
});

test('enforces research run lifecycle states and history ordering', () => {
  const runningWithFinish = structuredClone(cases.valid.researchRun);
  runningWithFinish.status = 'running';
  runningWithFinish.finished_at = '2024-01-05T21:05:00.000Z';
  runningWithFinish.assessment_id = null;
  runningWithFinish.evidence_snapshot_id = null;
  assert.equal(resultFor('researchRun', runningWithFinish).success, false);

  const completedWithoutFinish = structuredClone(cases.valid.researchRun);
  completedWithoutFinish.finished_at = null;
  assert.equal(resultFor('researchRun', completedWithoutFinish).success, false);

  const failedWithoutError = structuredClone(cases.valid.researchRun);
  failedWithoutError.status = 'failed';
  failedWithoutError.assessment_id = null;
  failedWithoutError.error_code = null;
  assert.equal(resultFor('researchRun', failedWithoutError).success, false);

  const duplicateHistory = structuredClone(cases.valid.historyResponse);
  duplicateHistory.bars = [structuredClone(cases.valid.marketBar), structuredClone(cases.valid.marketBar)];
  assert.equal(resultFor('historyResponse', duplicateHistory).success, false);

  const outOfOrderHistory = structuredClone(cases.valid.historyResponse);
  const later = structuredClone(cases.valid.marketBar);
  later.time = '2024-01-03T14:30:00.000Z';
  later.session_date = '2024-01-03';
  outOfOrderHistory.bars = [later, structuredClone(cases.valid.marketBar)];
  assert.equal(resultFor('historyResponse', outOfOrderHistory).success, false);
});

test('accepts queued lifecycle state only without active or terminal fields', () => {
  const run = structuredClone(cases.valid.researchRun);
  run.status = 'queued';
  run.started_at = null;
  run.heartbeat_at = null;
  run.finished_at = null;
  run.evidence_snapshot_id = null;
  run.assessment_id = null;
  assert.equal(resultFor('researchRun', run).success, true);
});

test('accepts running lifecycle state with a bounded in-progress heartbeat', () => {
  const run = structuredClone(cases.valid.researchRun);
  run.status = 'running';
  run.finished_at = null;
  run.evidence_snapshot_id = null;
  run.assessment_id = null;
  assert.equal(resultFor('researchRun', run).success, true);
});

test('accepts a resumed running lifecycle state with its persisted evidence snapshot', () => {
  const run = structuredClone(cases.valid.researchRun);
  run.status = 'running';
  run.finished_at = null;
  run.assessment_id = null;
  assert.equal(resultFor('researchRun', run).success, true);
});

test('accepts successful lifecycle state with matching snapshot and result', () => {
  const run = structuredClone(cases.valid.researchRun);
  run.status = 'succeeded';
  assert.equal(resultFor('researchRun', run).success, true);
});

test('accepts failed lifecycle state with a terminal error and no assessment', () => {
  const run = structuredClone(cases.valid.researchRun);
  run.status = 'failed';
  run.assessment_id = null;
  run.error_code = 'provider_timeout';
  assert.equal(resultFor('researchRun', run).success, true);

  run.finished_at = null;
  assert.equal(resultFor('researchRun', run).success, false);
});

test('accepts stalled lifecycle state only after deadline', () => {
  const run = structuredClone(cases.valid.researchRun);
  run.status = 'stalled';
  run.assessment_id = null;
  run.error_code = 'deadline_exceeded';
  run.finished_at = '2024-01-05T21:10:00.000Z';
  assert.equal(resultFor('researchRun', run).success, true);
});

test('accepts superseded lifecycle state without a published result', () => {
  const run = structuredClone(cases.valid.researchRun);
  run.status = 'superseded';
  run.assessment_id = null;
  run.error_code = null;
  assert.equal(resultFor('researchRun', run).success, true);
});

test('enforces semantic assessment boundaries, calendar range, and additive response policy', () => {
  const candidate = structuredClone(cases.valid.researchAssessment);
  candidate.position_context.state = 'candidate';
  candidate.position_context.average_cost = null;
  candidate.position_context.quantity = null;
  candidate.position_context.opened_on = null;
  candidate.position_context.economics_status = 'unavailable';
  candidate.recommendation.action = 'buy';
  assert.equal(resultFor('researchAssessment', candidate).success, true);

  for (const [field, value] of Object.entries({
    average_cost: { amount: '150.25', currency: 'USD' },
    quantity: '2.5',
    opened_on: '2024-01-05',
  })) {
    const candidateWithExecutedFact = structuredClone(candidate);
    candidateWithExecutedFact.position_context[field] = value;
    assert.equal(resultFor('researchAssessment', candidateWithExecutedFact).success, false, field);
  }

  for (const action of ['buy', 'wait', 'avoid', 'insufficient_evidence']) {
    const candidateAction = structuredClone(candidate);
    candidateAction.recommendation.action = action;
    assert.equal(resultFor('researchAssessment', candidateAction).success, true, action);
  }

  const ownedWithUnknownEconomics = structuredClone(cases.valid.researchAssessment);
  ownedWithUnknownEconomics.position_context.average_cost = null;
  ownedWithUnknownEconomics.position_context.quantity = null;
  ownedWithUnknownEconomics.position_context.opened_on = null;
  ownedWithUnknownEconomics.position_context.economics_status = 'unavailable';
  assert.equal(resultFor('researchAssessment', ownedWithUnknownEconomics).success, true);

  const candidateWithUnknownEconomics = candidate;

  const checkpointBase = {
    id: 'checkpoint-1',
    instrument_id: candidate.instrument_id,
    condition: 'Synthetic test condition.',
    created_at: '2024-01-05T21:00:00.000Z',
    updated_at: '2024-01-05T21:00:00.000Z',
    status: 'active',
    reason: 'Synthetic test reason.',
    source_assessment_id: candidate.id,
  };
  const withCheckpoint = (checkpoint) => {
    const assessment = structuredClone(candidateWithUnknownEconomics);
    assessment.checkpoints = [checkpoint];
    return assessment;
  };
  assert.equal(resultFor('researchAssessment', withCheckpoint({
    ...checkpointBase,
    kind: 'rolling_indicator',
    metric_id: 'metric-1',
    fixed_level: 150,
  })).success, false);
  assert.equal(resultFor('researchAssessment', withCheckpoint({
    ...checkpointBase,
    kind: 'fixed_observed_level',
    metric_id: 'metric-1',
    fixed_level: 150,
  })).success, false);
  assert.equal(resultFor('researchAssessment', withCheckpoint({
    ...checkpointBase,
    kind: 'business_condition',
    metric_id: 'metric-1',
    fixed_level: null,
  })).success, false);
  assert.equal(resultFor('researchAssessment', withCheckpoint({
    ...checkpointBase,
    kind: 'rolling_indicator',
    metric_id: 'metric-1',
    fixed_level: null,
  })).success, true);
  assert.equal(resultFor('researchAssessment', withCheckpoint({
    ...checkpointBase,
    kind: 'fixed_observed_level',
    metric_id: null,
    fixed_level: 150,
  })).success, true);
  assert.equal(resultFor('researchAssessment', withCheckpoint({
    ...checkpointBase,
    kind: 'business_condition',
    metric_id: null,
    fixed_level: null,
  })).success, true);

  assert.equal(calendarTargetDate('0001-01-31', 1), '0001-02-28');
  assert.equal(calendarTargetDate('0099-11-30', 1), '0099-12-30');
  assert.equal(calendarTargetDate('9999-10-31', 2), '9999-12-31');
  assert.throws(() => calendarTargetDate('9999-12-31', 1), RangeError);

  const beforeSession = structuredClone(candidateWithUnknownEconomics);
  beforeSession.outlooks[0].evaluation_session_date = '2024-01-04';
  assert.equal(resultFor('researchAssessment', beforeSession).success, false);

  const futureResponse = structuredClone(candidateWithUnknownEconomics);
  futureResponse.future_response_extension = { revision: 2 };
  futureResponse.market_thesis.rationale.push({
    text: 'Synthetic forward-compatible response claim.',
    evidence_ids: [],
    metric_ids: [],
    claim_type: 'assumption',
    future_response_extension: { revision: 2 },
  });
  assert.equal(resultFor('researchAssessment', futureResponse).success, true);

  const malformedRequiredResponse = structuredClone(futureResponse);
  delete malformedRequiredResponse.market_thesis;
  assert.equal(resultFor('researchAssessment', malformedRequiredResponse).success, false);

  const unknownWrite = structuredClone(cases.valid.positionWrite);
  unknownWrite.future_write_extension = true;
  assert.equal(resultFor('positionWrite', unknownWrite).success, false);
});
