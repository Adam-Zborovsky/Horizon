'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');
const http = require('node:http');
const crypto = require('node:crypto');
const express = require('express');

const {
  ResearchService,
  payloadDigest,
} = require('../src/features/research/research.service');
const ResearchRunModel = require('../src/features/research/research_run.model');
const ResearchAssessmentModel = require('../src/features/research/research_assessment.model');
const ResearchSnapshotModel = require('../src/features/research/research_snapshot.model');
const ThesisCheckpointModel = require('../src/features/research/thesis_state.model');
const { researchRunSchema } = require('../src/features/research/contracts');

const OWNER_A = 'owner-h08-aaaa';
const OWNER_B = 'owner-h08-bbbb';
const INSTRUMENT = 'instrument-h08-1';

// ---------------------------------------------------------------------------
// Fixtures and hermetic in-memory repositories (no live DB, no network)
// ---------------------------------------------------------------------------

function duplicate(code, message) {
  const error = new Error(message || code);
  error.code = code;
  return error;
}

function createInMemoryRunRepository(initial = []) {
  const records = [...initial];
  const clone = (value) => structuredClone(value);
  return {
    records,
    async findByIdempotency(ownerId, positionId, idempotencyKey) {
      return clone(records.find((run) => run.owner_id_internal === ownerId
        && run.position_id === positionId
        && run.idempotency_key === idempotencyKey)) || null;
    },
    async findActive({ positionId, positionRevision, runKind }) {
      return clone(records.find((run) => run.position_id === positionId
        && run.position_revision === positionRevision
        && run.run_kind === runKind
        && (run.status === 'queued' || run.status === 'running'))) || null;
    },
    async create(run) {
      if (records.some((entry) => entry.id === run.id)
        || records.some((entry) => entry.owner_id_internal === run.owner_id_internal
          && entry.position_id === run.position_id
          && entry.idempotency_key === run.idempotency_key)) {
        throw duplicate('DUPLICATE_RUN');
      }
      records.push(clone(run));
      return clone(run);
    },
    async findById(runId) {
      return clone(records.find((run) => run.id === runId)) || null;
    },
    // Atomic compare-and-set: only a queued run can be claimed. No awaits
    // between check and set, so concurrent claimers cannot both win.
    async claimQueued(runId, patch) {
      const index = records.findIndex((run) => run.id === runId);
      if (index === -1 || records[index].status !== 'queued') return null;
      records[index] = { ...records[index], ...clone(patch) };
      return clone(records[index]);
    },
    async updateIfStatus(runId, expectedStatuses, patch) {
      const index = records.findIndex((run) => run.id === runId);
      if (index === -1 || !expectedStatuses.includes(records[index].status)) return null;
      records[index] = { ...records[index], ...clone(patch) };
      return clone(records[index]);
    },
    async supersedeStale({ ownerId, positionId, beforeRevision, excludeRunId, finishedAt }) {
      let count = 0;
      for (const run of records) {
        if (run.owner_id_internal === ownerId
          && run.position_id === positionId
          && run.position_revision < beforeRevision
          && (run.status === 'queued' || run.status === 'running')
          && run.id !== excludeRunId) {
          run.status = 'superseded';
          run.finished_at = finishedAt;
          count += 1;
        }
      }
      return count;
    },
    async findExpired(nowIso) {
      return clone(records.filter((run) => (run.status === 'queued' || run.status === 'running')
        && run.deadline_at <= nowIso));
    },
    async findLatestAttempt(ownerId, positionId) {
      const candidates = records.filter((run) => run.owner_id_internal === ownerId
        && run.position_id === positionId);
      candidates.sort((a, b) => (b.created_at + b.id).localeCompare(a.created_at + a.id));
      return clone(candidates[0]) || null;
    },
    async findLatestSuccess(ownerId, positionId) {
      const candidates = records.filter((run) => run.owner_id_internal === ownerId
        && run.position_id === positionId
        && (run.status === 'succeeded' || run.status === 'limited'));
      candidates.sort((a, b) => (b.finished_at + b.id).localeCompare(a.finished_at + a.id));
      return clone(candidates[0]) || null;
    },
  };
}

function createInMemoryAssessmentRepository(initial = []) {
  const records = [...initial];
  const clone = (value) => structuredClone(value);
  return {
    records,
    async create(assessment) {
      if (records.some((entry) => entry.id === assessment.id)
        || records.some((entry) => entry.run_id === assessment.run_id)) {
        throw duplicate('DUPLICATE_ASSESSMENT');
      }
      records.push(clone(assessment));
      return clone(assessment);
    },
    async findById(assessmentId) {
      return clone(records.find((entry) => entry.id === assessmentId)) || null;
    },
    async findByRunId(runId) {
      return clone(records.find((entry) => entry.run_id === runId)) || null;
    },
    async latestForPosition(ownerId, positionId, excludeId = null) {
      const candidates = records.filter((entry) => entry.owner_id_internal === ownerId
        && entry.position_id === positionId
        && entry.id !== excludeId);
      candidates.sort((a, b) => (b.generated_at + b.id).localeCompare(a.generated_at + a.id));
      return clone(candidates[0]) || null;
    },
    async listByPosition(ownerId, positionId, { cursor = null, limit = 20 } = {}) {
      const candidates = records.filter((entry) => entry.owner_id_internal === ownerId
        && entry.position_id === positionId
        && (cursor == null || (entry.generated_at + entry.id) < cursor));
      candidates.sort((a, b) => (b.generated_at + b.id).localeCompare(a.generated_at + a.id));
      const page = candidates.slice(0, limit);
      const next = candidates.length > limit ? `${page[page.length - 1].generated_at}|${page[page.length - 1].id}` : null;
      return { assessments: clone(page), next_cursor: next };
    },
  };
}

function createInMemorySnapshotRepository(initial = []) {
  const records = [...initial];
  return {
    records,
    async create(snapshot) {
      if (records.some((entry) => entry.snapshot_id === snapshot.snapshot_id)) {
        throw duplicate('DUPLICATE_SNAPSHOT');
      }
      records.push(structuredClone(snapshot));
      return structuredClone(snapshot);
    },
    async findById(snapshotId) {
      return structuredClone(records.find((entry) => entry.snapshot_id === snapshotId)) || null;
    },
  };
}

function createInMemoryCheckpointRepository(initial = []) {
  const records = [...initial];
  const clone = (value) => structuredClone(value);
  return {
    records,
    async create(checkpoint) {
      if (records.some((entry) => entry.checkpoint_id === checkpoint.checkpoint_id)) {
        throw duplicate('DUPLICATE_CHECKPOINT');
      }
      records.push(clone(checkpoint));
      return clone(checkpoint);
    },
    async findById(ownerId, checkpointId) {
      return clone(records.find((entry) => entry.owner_id_internal === ownerId
        && entry.checkpoint_id === checkpointId)) || null;
    },
    async listByInstrument(ownerId, instrumentId) {
      return clone(records.filter((entry) => entry.owner_id_internal === ownerId
        && entry.instrument_id === instrumentId));
    },
    async update(checkpointId, patch) {
      const index = records.findIndex((entry) => entry.checkpoint_id === checkpointId);
      if (index === -1) return null;
      records[index] = { ...records[index], ...clone(patch) };
      return clone(records[index]);
    },
  };
}

function createHarness({ startIso = '2030-01-01T00:00:00.000Z' } = {}) {
  let currentIso = startIso;
  const repos = {
    runRepository: createInMemoryRunRepository(),
    assessmentRepository: createInMemoryAssessmentRepository(),
    researchSnapshotRepository: createInMemorySnapshotRepository(),
    checkpointRepository: createInMemoryCheckpointRepository(),
  };
  const evidenceSnapshotLookup = async (snapshotId) => {
    if (snapshotId === 'snapshot-evidence-h08-1') {
      return { snapshot_id: snapshotId, instrument_id: INSTRUMENT };
    }
    if (snapshotId === 'snapshot-evidence-other-instrument') {
      // Exists in storage but bound to a different instrument: delivery must
      // fail the instrument-binding guard (H08 review F1), not the "not found"
      // branch.
      return { snapshot_id: snapshotId, instrument_id: 'instrument-h08-other' };
    }
    return null;
  };
  const service = new ResearchService({
    ...repos,
    evidenceSnapshotLookup,
    now: () => new Date(currentIso),
  });
  return {
    service,
    repos,
    advance(seconds) {
      const next = new Date(new Date(currentIso).getTime() + seconds * 1000);
      currentIso = next.toISOString();
    },
    currentIso: () => currentIso,
  };
}

function queueRequest(overrides = {}) {
  return {
    owner_id: OWNER_A,
    position_id: 'pos-h08-1',
    position_revision: 1,
    run_kind: 'deep_research',
    idempotency_key: 'key-h08-001',
    instrument_id: INSTRUMENT,
    request_payload: { trigger: 'manual', note: 'first queue request' },
    ...overrides,
  };
}

function runOutcome(overrides = {}) {
  return {
    status: 'succeeded',
    evidence_snapshot_id: 'snapshot-evidence-h08-1',
    assessment_id: 'assessment-h08-1',
    ...overrides,
  };
}

function deliveredResult(overrides = {}) {
  return {
    evidence_snapshot_id: 'snapshot-evidence-h08-1',
    position_revision: 1,
    session_as_of: '2030-01-01',
    status: 'complete',
    assessment: {
      market_thesis: { business: 'Structured business assessment from bounded pipeline' },
      recommendation: { action: 'wait', horizon_months: 3 },
    },
    ...overrides,
  };
}

async function queueAndClaim(harness, overrides = {}) {
  const { run } = await harness.service.queueRun(queueRequest(overrides));
  await harness.service.claimRun({ run_id: run.id });
  return run.id;
}

// ---------------------------------------------------------------------------
// Idempotency and persistence
// ---------------------------------------------------------------------------

test('identical owner+position+idempotency-key replays the persisted run across service restarts', async () => {
  const harness = createHarness();
  const first = await harness.service.queueRun(queueRequest());
  assert.equal(first.idempotent_replay, false);
  assert.equal(first.run.status, 'queued');

  // New service instance over the same repositories: process restart.
  const restarted = new ResearchService({
    ...harness.repos,
    now: () => new Date('2030-01-01T01:00:00.000Z'),
  });
  const replay = await restarted.queueRun(queueRequest());
  assert.equal(replay.idempotent_replay, true);
  assert.equal(replay.run.id, first.run.id);
  assert.equal(harness.repos.runRepository.records.length, 1);
  assert.equal(replay.run.created_at, first.run.created_at, 'replay must not mutate the persisted run');
});

test('same idempotency key with a different payload is a 409 conflict, never a silent reuse', async () => {
  const harness = createHarness();
  await harness.service.queueRun(queueRequest());
  await assert.rejects(
    () => harness.service.queueRun(queueRequest({
      request_payload: { trigger: 'manual', note: 'different payload' },
    })),
    (error) => error.code === 'IDEMPOTENCY_CONFLICT',
  );
  assert.equal(harness.repos.runRepository.records.length, 1);
});

test('queued runs validate against the canonical researchRun contract schema', async () => {
  const harness = createHarness();
  const { run } = await harness.service.queueRun(queueRequest());
  const parsed = researchRunSchema.parse(run);
  assert.equal(parsed.status, 'queued');
  assert.equal(run.lease_nonce, null, 'queued runs carry no lease until claimed');
});

// H08 review F1 (red-first note): the pre-repair service coerced an absent
// instrument_id to null and persisted it; this test previously could not have
// been written without asserting that silent-null behavior. The snapshot and
// assessment models require instrument_id (required:true), so queueRun must
// reject instead of coercing.
test('queueRun rejects a run without a non-empty instrument_id as INVALID_INPUT (review F1)', async () => {
  const harness = createHarness();
  for (const instrument_id of [undefined, null, '']) {
    await assert.rejects(
      () => harness.service.queueRun(queueRequest({ instrument_id })),
      (error) => error.code === 'INVALID_INPUT',
      `instrument_id ${JSON.stringify(instrument_id)} must be rejected as INVALID_INPUT`,
    );
  }
  assert.equal(harness.repos.runRepository.records.length, 0,
    'a rejected queue must not persist a run');
  assert.equal(harness.repos.researchSnapshotRepository.records.length, 0,
    'a rejected queue must not persist an orphan snapshot');
});

test('at most one active run per position revision and request class', async () => {
  const harness = createHarness();
  await harness.service.queueRun(queueRequest());
  await assert.rejects(
    () => harness.service.queueRun(queueRequest({ idempotency_key: 'key-h08-002' })),
    (error) => error.code === 'RUN_ALREADY_ACTIVE',
  );
  // A different position revision is a separate request class instance.
  const newer = await harness.service.queueRun(queueRequest({
    idempotency_key: 'key-h08-003',
    position_revision: 2,
  }));
  assert.equal(newer.idempotent_replay, false);
});

// ---------------------------------------------------------------------------
// Atomic claims and leases (H03 createRunCallbackAuthorizer interface)
// ---------------------------------------------------------------------------

test('claiming is atomic: exactly one worker wins and lease fields are materialized', async () => {
  const harness = createHarness();
  const runId = await queueAndClaim(harness);
  const claimed = await harness.repos.runRepository.findById(runId);
  assert.equal(claimed.status, 'running');
  assert.equal(typeof claimed.lease_nonce, 'string');
  assert.ok(claimed.lease_nonce.length >= 16, 'lease nonce must have real entropy');
  assert.equal(new Date(claimed.lease_expires_at).toISOString(), claimed.lease_expires_at);
  assert.ok(claimed.lease_expires_at > claimed.started_at);
  assert.equal(claimed.started_at, harness.currentIso());
  assert.equal(claimed.heartbeat_at, claimed.started_at);

  await assert.rejects(
    () => harness.service.claimRun({ run_id: runId }),
    (error) => error.code === 'RUN_ALREADY_CLAIMED',
  );
  await assert.rejects(
    () => harness.service.claimRun({ run_id: 'run-h08-missing' }),
    (error) => error.code === 'RUN_NOT_FOUND',
  );
});

test('heartbeat updates stage and heartbeat_at on a running run only', async () => {
  const harness = createHarness();
  const runId = await queueAndClaim(harness);
  harness.advance(60);
  const beaten = await harness.service.heartbeatRun({ run_id: runId, stage: 'evidence_gathered' });
  assert.equal(beaten.stage, 'evidence_gathered');
  assert.equal(beaten.heartbeat_at, harness.currentIso());

  await harness.service.completeRun({
    run_id: runId,
    outcome: runOutcome(),
  });
  await assert.rejects(
    () => harness.service.heartbeatRun({ run_id: runId, stage: 'too_late' }),
    (error) => error.code === 'INVALID_RUN_TRANSITION',
  );
});

test('completion enforces outcome invariants and the run deadline', async () => {
  const harness = createHarness();
  const runId = await queueAndClaim(harness);

  await assert.rejects(
    () => harness.service.completeRun({ run_id: runId, outcome: { status: 'succeeded' } }),
    (error) => error.code === 'INVALID_RUN_OUTCOME',
    'succeeded requires both snapshot and assessment references',
  );
  await assert.rejects(
    () => harness.service.completeRun({
      run_id: runId,
      outcome: { status: 'failed', evidence_snapshot_id: 'snapshot-evidence-h08-1' },
    }),
    (error) => error.code === 'INVALID_RUN_OUTCOME',
    'failed requires an error code and no result references',
  );

  // Jump past the deadline: completion is refused, recovery will stall the run.
  harness.advance(901);
  await assert.rejects(
    () => harness.service.completeRun({ run_id: runId, outcome: runOutcome() }),
    (error) => error.code === 'RUN_DEADLINE_EXCEEDED',
  );
  const expired = await harness.repos.runRepository.findById(runId);
  assert.equal(expired.status, 'running', 'expired completion attempt must not fake success');
});

test('successful completion records immutable result references and terminal state', async () => {
  const harness = createHarness();
  const runId = await queueAndClaim(harness);
  harness.advance(30);
  const finished = await harness.service.completeRun({
    run_id: runId,
    outcome: runOutcome(),
  });
  assert.equal(finished.status, 'succeeded');
  assert.equal(finished.assessment_id, 'assessment-h08-1');
  assert.equal(finished.evidence_snapshot_id, 'snapshot-evidence-h08-1');
  assert.ok(finished.finished_at <= finished.deadline_at);
  researchRunSchema.parse(finished);
});

// ---------------------------------------------------------------------------
// Callbacks: duplicate assessment protection and binding
// ---------------------------------------------------------------------------

test('concurrent result callbacks cannot create duplicate assessments', async () => {
  const harness = createHarness();
  const runId = await queueAndClaim(harness);

  const [first, second] = await Promise.all([
    harness.service.recordRunResult({
      run_id: runId,
      caller_owner_id: OWNER_A,
      delivery_id: 'delivery-1',
      result: deliveredResult(),
    }),
    harness.service.recordRunResult({
      run_id: runId,
      caller_owner_id: OWNER_A,
      delivery_id: 'delivery-2',
      result: deliveredResult(),
    }),
  ]);

  assert.equal(harness.repos.assessmentRepository.records.length, 1,
    'exactly one assessment must exist for the run');
  assert.equal(first.assessment_id, second.assessment_id);
  assert.equal(second.idempotent || first.idempotent, true,
    'the losing callback must resolve idempotently, not fail the pipeline');
  const run = await harness.repos.runRepository.findById(runId);
  assert.equal(run.status, 'succeeded');
  assert.equal(run.assessment_id, first.assessment_id);
});

test('duplicate delivery of the same delivery id is idempotent and never re-executes', async () => {
  const harness = createHarness();
  const runId = await queueAndClaim(harness);
  const first = await harness.service.recordRunResult({
    run_id: runId,
    caller_owner_id: OWNER_A,
    delivery_id: 'delivery-1',
    result: deliveredResult(),
  });
  const replay = await harness.service.recordRunResult({
    run_id: runId,
    caller_owner_id: OWNER_A,
    delivery_id: 'delivery-1',
    result: deliveredResult(),
  });
  assert.equal(replay.idempotent, true);
  assert.equal(replay.assessment_id, first.assessment_id);
  assert.equal(harness.repos.assessmentRepository.records.length, 1);
  const run = await harness.repos.runRepository.findById(runId);
  assert.equal(run.assessment_id, first.assessment_id, 'no assessment churn on replay');
});

test('callback with conflicting revision or snapshot is rejected with a conflict', async () => {
  const harness = createHarness();
  const runId = await queueAndClaim(harness);

  await assert.rejects(
    () => harness.service.recordRunResult({
      run_id: runId,
      caller_owner_id: OWNER_A,
      delivery_id: 'delivery-rev',
      result: deliveredResult({ position_revision: 99 }),
    }),
    (error) => error.code === 'REVISION_CONFLICT',
  );
  await assert.rejects(
    () => harness.service.recordRunResult({
      run_id: runId,
      caller_owner_id: OWNER_A,
      delivery_id: 'delivery-snap',
      result: deliveredResult({ evidence_snapshot_id: 'snapshot-unknown-404' }),
    }),
    (error) => error.code === 'SNAPSHOT_CONFLICT',
  );
  await assert.rejects(
    () => harness.service.recordRunResult({
      run_id: runId,
      caller_owner_id: OWNER_A,
      delivery_id: 'delivery-mismatch',
      result: deliveredResult({ evidence_snapshot_id: 'snapshot-evidence-other-instrument' }),
    }),
    (error) => error.code === 'SNAPSHOT_CONFLICT',
    'snapshot must match the run instrument',
  );
});

// H08 review O2 (same silent-null class as F1, red-first note): the pre-repair
// service normalized an absent/non-string session_as_of to null on write even
// though the assessment model requires a non-null String. Deep format
// validation remains H09's boundary; the service only stops the silent null.
test('recordRunResult rejects an absent or non-string session_as_of as INVALID_INPUT (review O2)', async () => {
  const harness = createHarness();
  const cases = [undefined, null, 42];
  for (const [index, session_as_of] of cases.entries()) {
    // Distinct position revisions per case: a rejected delivery leaves the run
    // active, and only one active run per revision is permitted.
    const runId = await queueAndClaim(harness, {
      idempotency_key: `key-asof-${index}`,
      position_revision: index + 1,
    });
    await assert.rejects(
      () => harness.service.recordRunResult({
        run_id: runId,
        caller_owner_id: OWNER_A,
        delivery_id: `delivery-asof-${index}`,
        result: { ...deliveredResult(), position_revision: index + 1, session_as_of },
      }),
      (error) => error.code === 'INVALID_INPUT',
      `session_as_of ${JSON.stringify(session_as_of)} must be rejected as INVALID_INPUT`,
    );
    assert.equal(harness.repos.assessmentRepository.records.length, 0,
      'a rejected delivery must not persist an assessment');
    const run = await harness.repos.runRepository.findById(runId);
    assert.equal(run.status, 'running', 'a rejected delivery leaves the run untouched');
  }
});

test('cross-owner callbacks are denied and never write', async () => {
  const harness = createHarness();
  const runId = await queueAndClaim(harness);
  await assert.rejects(
    () => harness.service.recordRunResult({
      run_id: runId,
      caller_owner_id: OWNER_B,
      delivery_id: 'delivery-owner-b',
      result: deliveredResult(),
    }),
    (error) => error.code === 'OWNER_DENIED',
  );
  assert.equal(harness.repos.assessmentRepository.records.length, 0);
  const run = await harness.repos.runRepository.findById(runId);
  assert.equal(run.status, 'running', 'denied callbacks leave no trace on the run');
});

// ---------------------------------------------------------------------------
// Owner isolation
// ---------------------------------------------------------------------------

test('runs, assessments and thesis checkpoints are scoped to the owner', async () => {
  const harness = createHarness();
  const runId = await queueAndClaim(harness);
  await harness.service.completeRun({ run_id: runId, outcome: runOutcome() });
  await harness.service.createCheckpoint({
    owner_id: OWNER_A,
    instrument_id: INSTRUMENT,
    kind: 'fixed_observed_level',
    fixed_level: 150.25,
    condition: 'Close below the 150 support level',
  });

  const stateB = await harness.service.getPositionResearchState({
    owner_id: OWNER_B,
    position_id: 'pos-h08-1',
  });
  assert.equal(stateB.latest_assessment, null);
  assert.equal(stateB.last_success, null);
  assert.equal(stateB.latest_attempt, null);

  const assessmentsB = await harness.service.listAssessments({
    owner_id: OWNER_B,
    position_id: 'pos-h08-1',
  });
  assert.deepEqual(assessmentsB.assessments, []);
  const checkpointsB = await harness.service.listCheckpoints({
    owner_id: OWNER_B,
    instrument_id: INSTRUMENT,
  });
  assert.deepEqual(checkpointsB, []);
});

// ---------------------------------------------------------------------------
// Revision superseding
// ---------------------------------------------------------------------------

test('queueing a newer revision explicitly supersedes the older incomplete run', async () => {
  const harness = createHarness();
  const oldRun = await harness.service.queueRun(queueRequest({ position_revision: 1 }));
  const newRun = await harness.service.queueRun(queueRequest({
    position_revision: 2,
    idempotency_key: 'key-h08-rev2',
  }));
  assert.equal(newRun.idempotent_replay, false);

  const superseded = await harness.repos.runRepository.findById(oldRun.run.id);
  assert.equal(superseded.status, 'superseded');
  assert.ok(superseded.finished_at, 'superseding is explicit, not a silent abandonment');

  await assert.rejects(
    () => harness.service.completeRun({
      run_id: oldRun.run.id,
      outcome: runOutcome(),
    }),
    (error) => error.code === 'REVISION_CONFLICT',
    'a superseded run can never publish against old economics',
  );
  assert.equal(harness.repos.assessmentRepository.records.length, 0,
    'no assessment attached to stale economics');
});

// ---------------------------------------------------------------------------
// Deadline expiry, stalls and restart recovery
// ---------------------------------------------------------------------------

test('expired runs become stalled or superseded — never forever running', async () => {
  const harness = createHarness();
  // Different request classes (run kinds) do not collide on the active-run
  // rule, so three runs coexist at revision 1.
  const queuedBeforeExpiry = await harness.service.queueRun(queueRequest({
    idempotency_key: 'key-queued-1',
    run_kind: 'manual_refresh',
    deadlineSeconds: 10,
  }));
  const runningRunId = await queueAndClaim(harness, {
    idempotency_key: 'key-running-1',
    run_kind: 'deep_research',
  });
  // Queued after the clock advance, so its deadline is still in the future.
  harness.advance(1800);
  const healthyQueued = await harness.service.queueRun(queueRequest({
    idempotency_key: 'key-healthy-1',
    run_kind: 'daily_update',
  }));

  const recovered = await harness.service.recoverAbandonedRuns();
  assert.equal(recovered.stalled, 1);
  assert.equal(recovered.superseded, 1);

  const stalled = await harness.repos.runRepository.findById(runningRunId);
  assert.equal(stalled.status, 'stalled');
  assert.equal(stalled.error_code, 'RUN_STALLED');
  assert.ok(stalled.finished_at, 'stall is explicit terminal state with a timestamp');
  assert.equal(stalled.assessment_id, null, 'stalled runs never claim an assessment');

  const expiredQueued = await harness.repos.runRepository.findById(queuedBeforeExpiry.run.id);
  assert.equal(expiredQueued.status, 'superseded');

  const healthy = await harness.repos.runRepository.findById(healthyQueued.run.id);
  assert.equal(healthy.status, 'queued', 'runs inside their deadline are untouched');

  const again = await harness.service.recoverAbandonedRuns();
  assert.equal(again.stalled, 0, 'recovery is idempotent');
  assert.equal(again.superseded, 0);
});

test('restart recovery on a fresh service instance supersedes incomplete runs explicitly', async () => {
  const harness = createHarness();
  const runId = await queueAndClaim(harness);
  harness.advance(3600);

  const restarted = new ResearchService({
    ...harness.repos,
    now: () => new Date(harness.currentIso()),
  });
  const recovered = await restarted.recoverAbandonedRuns();
  assert.equal(recovered.stalled, 1);
  const run = await harness.repos.runRepository.findById(runId);
  assert.equal(run.status, 'stalled');
  const parsed = researchRunSchema.parse(run);
  assert.equal(parsed.status, 'stalled');
});

// ---------------------------------------------------------------------------
// Separate last-success and latest-attempt state
// ---------------------------------------------------------------------------

test('last successful report and latest attempt are tracked separately', async () => {
  const harness = createHarness();
  const successRunId = await queueAndClaim(harness, { idempotency_key: 'key-success' });
  const delivered = await harness.service.recordRunResult({
    run_id: successRunId,
    caller_owner_id: OWNER_A,
    delivery_id: 'delivery-success',
    result: deliveredResult(),
  });

  harness.advance(120);
  const failedRunId = await queueAndClaim(harness, {
    idempotency_key: 'key-failed',
    run_kind: 'daily_update',
  });
  await harness.service.completeRun({
    run_id: failedRunId,
    outcome: { status: 'failed', error_code: 'PIPELINE_VALIDATION_FAILED' },
  });

  const state = await harness.service.getPositionResearchState({
    owner_id: OWNER_A,
    position_id: 'pos-h08-1',
  });
  assert.equal(state.last_success.assessment_id, delivered.assessment_id,
    'existing success timestamps are never updated to disguise failure');
  assert.equal(state.last_success.run_id, successRunId);
  assert.equal(state.latest_attempt.run_id, failedRunId);
  assert.equal(state.latest_attempt.status, 'failed');
  assert.equal(state.latest_attempt.error_code, 'PIPELINE_VALIDATION_FAILED');
  assert.equal(state.latest_attempt.assessment_id, undefined,
    'failed attempts expose no assessment reference');
  assert.ok(state.latest_assessment);
  assert.equal(state.latest_assessment.artifact_kind, 'judgment');
  // Success must survive the later failure intact.
  assert.notEqual(state.last_success.finished_at, state.latest_attempt.finished_at);
});

// ---------------------------------------------------------------------------
// Thesis memory: checkpoints retain history; judgments are judgments
// ---------------------------------------------------------------------------

test('checkpoint kinds reject masquerading representations', async () => {
  const harness = createHarness();
  await assert.rejects(
    () => harness.service.createCheckpoint({
      owner_id: OWNER_A,
      instrument_id: INSTRUMENT,
      kind: 'rolling_indicator',
      metric_id: 'metric-1',
      fixed_level: 150,
      condition: 'illegal fixed level on a rolling indicator',
    }),
    (error) => error.code === 'INVALID_CHECKPOINT',
  );
  await assert.rejects(
    () => harness.service.createCheckpoint({
      owner_id: OWNER_A,
      instrument_id: INSTRUMENT,
      kind: 'fixed_observed_level',
      metric_id: 'metric-1',
      fixed_level: 150,
    }),
    (error) => error.code === 'INVALID_CHECKPOINT',
  );
  await assert.rejects(
    () => harness.service.createCheckpoint({
      owner_id: OWNER_A,
      instrument_id: INSTRUMENT,
      kind: 'business_condition',
    }),
    (error) => error.code === 'INVALID_CHECKPOINT',
  );
});

test('triggered, retired and replaced checkpoints retain full change history', async () => {
  const harness = createHarness();
  const cp1 = await harness.service.createCheckpoint({
    owner_id: OWNER_A,
    instrument_id: INSTRUMENT,
    kind: 'fixed_observed_level',
    fixed_level: 150.25,
    condition: 'Close below 150 support',
    source_assessment_id: 'assessment-source-1',
  });
  assert.equal(cp1.status, 'active');
  assert.deepEqual(cp1.history, []);

  harness.advance(60);
  const triggered = await harness.service.recordCheckpointChange({
    owner_id: OWNER_A,
    checkpoint_id: cp1.checkpoint_id,
    event: {
      event_kind: 'triggered',
      reason: 'Daily close 149.80 below fixed level 150.25',
      evidence_ids: ['evidence-bar-1'],
      source_assessment_id: 'assessment-judge-1',
      observed_value: 149.8,
    },
  });
  assert.equal(triggered.status, 'triggered');
  assert.equal(triggered.history.length, 1);
  assert.equal(triggered.history[0].event_kind, 'triggered');
  assert.equal(triggered.history[0].previous_status, 'active');
  assert.equal(triggered.history[0].new_status, 'triggered');
  assert.equal(triggered.history[0].source_assessment_id, 'assessment-judge-1');

  // A triggered checkpoint can still be explicitly replaced.
  harness.advance(60);
  const cp2 = await harness.service.createCheckpoint({
    owner_id: OWNER_A,
    instrument_id: INSTRUMENT,
    kind: 'fixed_observed_level',
    fixed_level: 148.0,
    condition: 'Close below the revised 148 level',
    predecessor_checkpoint_id: cp1.checkpoint_id,
  });
  assert.equal(cp2.predecessor_checkpoint_id, cp1.checkpoint_id);

  const replaced = await harness.service.recordCheckpointChange({
    owner_id: OWNER_A,
    checkpoint_id: cp1.checkpoint_id,
    event: {
      event_kind: 'replaced',
      reason: 'Level replaced by revised support after split',
      replacement_checkpoint_id: cp2.checkpoint_id,
      source_assessment_id: 'assessment-judge-2',
    },
  });
  assert.equal(replaced.status, 'retired');
  assert.equal(replaced.history.length, 2);
  assert.equal(replaced.history[1].event_kind, 'replaced');
  assert.equal(replaced.history[1].replacement_checkpoint_id, cp2.checkpoint_id);

  const retired = await harness.service.createCheckpoint({
    owner_id: OWNER_A,
    instrument_id: INSTRUMENT,
    kind: 'business_condition',
    condition: 'Guidance withdrawn by management',
  });
  const retiredNow = await harness.service.recordCheckpointChange({
    owner_id: OWNER_A,
    checkpoint_id: retired.checkpoint_id,
    event: { event_kind: 'retired', reason: 'Condition no longer relevant' },
  });
  assert.equal(retiredNow.status, 'retired');

  // History is retained and terminal: no further transitions from retired.
  await assert.rejects(
    () => harness.service.recordCheckpointChange({
      owner_id: OWNER_A,
      checkpoint_id: retired.checkpoint_id,
      event: { event_kind: 'triggered', reason: 'cannot trigger a retired checkpoint' },
    }),
    (error) => error.code === 'INVALID_CHECKPOINT_TRANSITION',
  );

  const all = await harness.service.listCheckpoints({
    owner_id: OWNER_A,
    instrument_id: INSTRUMENT,
  });
  assert.equal(all.length, 3);
  const cp1Stored = all.find((entry) => entry.checkpoint_id === cp1.checkpoint_id);
  assert.equal(cp1Stored.history.length, 2, 'history survives across reads');
});

test('prior assessments are identified as judgments, never as source evidence', async () => {
  const harness = createHarness();
  const firstRunId = await queueAndClaim(harness, { idempotency_key: 'key-first' });
  await harness.service.recordRunResult({
    run_id: firstRunId,
    caller_owner_id: OWNER_A,
    delivery_id: 'delivery-first',
    result: deliveredResult(),
  });

  harness.advance(3600);
  const secondRunId = await queueAndClaim(harness, { idempotency_key: 'key-second' });
  const second = await harness.service.recordRunResult({
    run_id: secondRunId,
    caller_owner_id: OWNER_A,
    delivery_id: 'delivery-second',
    result: deliveredResult(),
  });

  const changes = await harness.service.buildChangesSincePrevious({
    owner_id: OWNER_A,
    position_id: 'pos-h08-1',
    current_assessment_id: second.assessment_id,
  });
  assert.ok(changes.previous);
  assert.notEqual(changes.previous.id, second.assessment_id);
  assert.equal(changes.previous.artifact_kind, 'judgment');
  assert.equal(changes.previous.is_evidence, false,
    'prior generated judgments are not source evidence');
});

// ---------------------------------------------------------------------------
// Immutable run input snapshot references
// ---------------------------------------------------------------------------

test('queueing persists an immutable research snapshot bound to the run input', async () => {
  const harness = createHarness();
  const { run } = await harness.service.queueRun(queueRequest());
  assert.ok(run.input_snapshot_id);

  const snapshot = await harness.repos.researchSnapshotRepository.findById(run.input_snapshot_id);
  assert.equal(snapshot.position_id, 'pos-h08-1');
  assert.equal(snapshot.position_revision, 1);
  assert.equal(snapshot.instrument_id, INSTRUMENT);
  assert.equal(snapshot.payload_digest, run.payload_digest);
  assert.deepEqual(snapshot.request_payload, { trigger: 'manual', note: 'first queue request' });
  const digest = payloadDigest({ trigger: 'manual', note: 'first queue request' });
  assert.equal(snapshot.payload_digest, digest);
});

// ---------------------------------------------------------------------------
// Mongoose schema layer (validateSync probes; never connected)
// ---------------------------------------------------------------------------

test('mongoose run schema enforces the canonical shape and string opaque ids', () => {
  const doc = new ResearchRunModel({
    _id: 'run-h08-schema-1',
    position_id: 'pos-1',
    owner_id_internal: OWNER_A,
    position_revision: 1,
    run_kind: 'deep_research',
    request_class: 'deep_research',
    idempotency_key: 'key-schema-1',
    payload_digest: 'a'.repeat(64),
    status: 'queued',
    stage: 'queued',
    created_at: new Date('2030-01-01T00:00:00.000Z'),
    deadline_at: new Date('2030-01-01T00:15:00.000Z'),
    lease_nonce: null,
    lease_expires_at: null,
    input_snapshot_id: 'snapshot-run-1',
    run_input_ref: {
      payload_digest: 'a'.repeat(64),
      instrument_id: INSTRUMENT,
      position_revision: 1,
      run_kind: 'deep_research',
      request_payload: { trigger: 'manual' },
      snapshot_id: 'snapshot-run-1',
    },
    versions: { contract_version: '1' },
  });
  const error = doc.validateSync();
  assert.equal(error, undefined);
  assert.equal(typeof doc._id, 'string');

  const bad = new ResearchRunModel({
    _id: 'run-h08-schema-2',
    position_id: 'pos-1',
    owner_id_internal: OWNER_A,
    position_revision: 1,
    run_kind: 'not_a_kind',
    request_class: 'not_a_kind',
    idempotency_key: 'key-schema-2',
    payload_digest: 'b'.repeat(64),
    status: 'queued',
    stage: 'queued',
    created_at: new Date('2030-01-01T00:00:00.000Z'),
    deadline_at: new Date('2030-01-01T00:15:00.000Z'),
  });
  const badError = bad.validateSync();
  assert.ok(badError, 'invalid run_kind must fail schema validation');
});

test('mongoose assessment, snapshot and checkpoint schemas are immutable by construction', () => {
  const assessment = new ResearchAssessmentModel({
    _id: 'assessment-h08-schema-1',
    run_id: 'run-1',
    position_id: 'pos-1',
    owner_id_internal: OWNER_A,
    position_revision: 1,
    instrument_id: INSTRUMENT,
    evidence_snapshot_id: 'snapshot-1',
    generated_at: new Date('2030-01-01T00:00:00.000Z'),
    session_as_of: '2030-01-01',
    status: 'complete',
    artifact_kind: 'judgment',
    assessment: { recommendation: { action: 'wait' } },
  });
  assert.equal(assessment.validateSync(), undefined);
  assert.equal(assessment.schema.path('run_id').options.immutable, true);
  assert.equal(assessment.schema.path('position_revision').options.immutable, true);
  assert.equal(assessment.schema.path('evidence_snapshot_id').options.immutable, true);

  const snapshot = new ResearchSnapshotModel({
    snapshot_id: 'snapshot-run-schema-1',
    run_id: 'run-schema-1',
    owner_id_internal: OWNER_A,
    position_id: 'pos-1',
    position_revision: 1,
    instrument_id: INSTRUMENT,
    payload_digest: 'c'.repeat(64),
    request_payload: { trigger: 'manual' },
    created_at: new Date('2030-01-01T00:00:00.000Z'),
  });
  assert.equal(snapshot.validateSync(), undefined);
  assert.equal(snapshot.schema.path('payload_digest').options.immutable, true);

  const checkpoint = new ThesisCheckpointModel({
    _id: 'checkpoint-h08-1',
    checkpoint_id: 'checkpoint-h08-1',
    owner_id_internal: OWNER_A,
    instrument_id: INSTRUMENT,
    kind: 'fixed_observed_level',
    fixed_level: 150.25,
    condition: 'Close below 150',
    status: 'active',
    history: [],
  });
  assert.equal(checkpoint.validateSync(), undefined);
  const badCheckpoint = new ThesisCheckpointModel({
    _id: 'checkpoint-h08-2',
    checkpoint_id: 'checkpoint-h08-2',
    owner_id_internal: OWNER_A,
    instrument_id: INSTRUMENT,
    kind: 'fixed_observed_level',
    metric_id: 'metric-should-not-be-here',
    fixed_level: 150.25,
    status: 'active',
  });
  assert.ok(badCheckpoint.validateSync(), 'fixed_observed_level must reject metric references');
});

// ---------------------------------------------------------------------------
// Isolated router
// ---------------------------------------------------------------------------

test('research router exposes owner-scoped read/run endpoints as an isolated router', async () => {
  const harness = createHarness();
  const { createResearchRouter } = require('../src/features/research/research.routes');

  const authenticate = (req, res, next) => {
    const owner = req.get('x-test-owner');
    if (!owner) return res.status(401).json({ code: 'unauthenticated' });
    req.user = { _id: owner };
    return next();
  };
  const app = express();
  app.use(express.json());
  app.use('/api/v1/research', createResearchRouter({
    researchService: harness.service,
    authenticate,
  }));
  const server = http.createServer(app);
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  const base = `http://127.0.0.1:${server.address().port}/api/v1/research`;
  try {
    // Missing Idempotency-Key header -> 400.
    const missing = await fetch(`${base}/positions/pos-h08-1/runs`, {
      method: 'POST',
      headers: { 'x-test-owner': OWNER_A, 'content-type': 'application/json' },
      body: JSON.stringify({ position_revision: 1, run_kind: 'deep_research' }),
    });
    assert.equal(missing.status, 400);
    assert.equal((await missing.json()).code, 'MISSING_IDEMPOTENCY_KEY');

    // H08 review F1 (red-first note): this POST previously carried NO
    // instrument_id and asserted 202 — encoding a null instrument that the
    // snapshot/assessment models (required: true) reject. Post-repair the
    // instrument-less queue must be rejected as INVALID_INPUT (400 per the
    // router's INVALID_INPUT mapping), and the happy path must send an
    // instrument.
    const instrumentless = await fetch(`${base}/positions/pos-h08-1/runs`, {
      method: 'POST',
      headers: {
        'x-test-owner': OWNER_A,
        'content-type': 'application/json',
        'idempotency-key': 'key-route-no-instrument',
      },
      body: JSON.stringify({
        position_revision: 1,
        run_kind: 'deep_research',
        request_payload: { trigger: 'manual' },
      }),
    });
    assert.equal(instrumentless.status, 400,
      'a queue without a non-empty instrument_id must be rejected (review F1)');
    assert.equal((await instrumentless.json()).code, 'INVALID_INPUT');

    const queued = await fetch(`${base}/positions/pos-h08-1/runs`, {
      method: 'POST',
      headers: {
        'x-test-owner': OWNER_A,
        'content-type': 'application/json',
        'idempotency-key': 'key-route-1',
      },
      body: JSON.stringify({
        position_revision: 1,
        run_kind: 'deep_research',
        instrument_id: INSTRUMENT,
        request_payload: { trigger: 'manual' },
      }),
    });
    assert.equal(queued.status, 202);
    const queuedBody = await queued.json();
    assert.equal(queuedBody.run.status, 'queued');
    assert.equal(queuedBody.run.lease_nonce, undefined,
      'user-facing run views never expose the automation lease nonce');

    // Idempotent replay through the route.
    const replay = await fetch(`${base}/positions/pos-h08-1/runs`, {
      method: 'POST',
      headers: {
        'x-test-owner': OWNER_A,
        'content-type': 'application/json',
        'idempotency-key': 'key-route-1',
      },
      body: JSON.stringify({
        position_revision: 1,
        run_kind: 'deep_research',
        instrument_id: INSTRUMENT,
        request_payload: { trigger: 'manual' },
      }),
    });
    assert.equal(replay.status, 202);
    assert.equal((await replay.json()).run.id, queuedBody.run.id);

    // Owner-scoped run read; a foreign owner gets an indistinguishable 404.
    const own = await fetch(`${base}/runs/${queuedBody.run.id}`, {
      headers: { 'x-test-owner': OWNER_A },
    });
    assert.equal(own.status, 200);
    const foreign = await fetch(`${base}/runs/${queuedBody.run.id}`, {
      headers: { 'x-test-owner': OWNER_B },
    });
    assert.equal(foreign.status, 404);
    const missingRun = await fetch(`${base}/runs/run-h08-nope`, {
      headers: { 'x-test-owner': OWNER_A },
    });
    assert.equal(missingRun.status, 404);

    // Latest endpoint with no assessment yet returns nulls, not errors.
    const latest = await fetch(`${base}/positions/pos-h08-1/latest`, {
      headers: { 'x-test-owner': OWNER_A },
    });
    assert.equal(latest.status, 200);
    const latestBody = await latest.json();
    assert.equal(latestBody.latest_assessment, null);
    assert.ok(latestBody.run_state);

    // Assessment history endpoint.
    const history = await fetch(`${base}/positions/pos-h08-1/assessments`, {
      headers: { 'x-test-owner': OWNER_A },
    });
    assert.equal(history.status, 200);
    assert.deepEqual((await history.json()).assessments, []);

    // Malformed run_kind -> 400.
    const badKind = await fetch(`${base}/positions/pos-h08-1/runs`, {
      method: 'POST',
      headers: {
        'x-test-owner': OWNER_A,
        'content-type': 'application/json',
        'idempotency-key': 'key-route-bad',
      },
      body: JSON.stringify({ position_revision: 1, run_kind: 'nonsense' }),
    });
    assert.equal(badKind.status, 400);
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
});
