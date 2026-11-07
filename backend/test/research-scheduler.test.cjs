'use strict';

// H10X — advanced scheduler recovery and leadership tests.
//
// CONTRACTS §8 "advanced scheduling" + SPEC §5: one scheduler leader/lease
// prevents replica duplicates; recovery sweep is autonomous and bounded; no
// unbounded retry/delay chain. Every client and repository is injected and
// in-memory; there is no service lifecycle (no cron, no HTTP server), no
// publication, no live DB and no credentials.

const assert = require('node:assert/strict');
const test = require('node:test');

const { ResearchService } = require('../src/features/research/research.service');
const {
  createInMemoryLeaderLease,
  createResearchScheduler,
} = require('../src/features/research/run_worker');
const {
  startResearchScheduler,
  createMongooseLeaderLease,
  createMongooseScheduledPositionsProvider,
  startQueuedRunExecutions,
} = require('../src/utils/scheduler');
const {
  hasAutomationExecutionScopes,
  startProductionSchedulers,
} = require('../src/server');

// ---------------------------------------------------------------------------
// In-memory repositories (hermetic; synthetic fixtures, NOT observed data)
// ---------------------------------------------------------------------------

function makeClock(startIso = '2030-01-01T00:00:00.000Z') {
  const clock = { iso: startIso };
  return {
    clock,
    now: () => new Date(clock.iso),
    advance(seconds) {
      clock.iso = new Date(new Date(clock.iso).getTime() + seconds * 1000).toISOString();
    },
  };
}

function createInMemoryRunRepository(initial = []) {
  const records = initial.map((run) => structuredClone(run));
  const clone = (value) => structuredClone(value);
  return {
    records,
    async findByIdempotency(ownerId, positionId, idempotencyKey) {
      return clone(records.find((run) => run.owner_id_internal === ownerId
        && run.position_id === positionId && run.idempotency_key === idempotencyKey)) || null;
    },
    async findActive({ positionId, positionRevision, runKind }) {
      return clone(records.find((run) => run.position_id === positionId
        && run.position_revision === positionRevision && run.run_kind === runKind
        && (run.status === 'queued' || run.status === 'running'))) || null;
    },
    async create(run) {
      if (records.some((entry) => entry.id === run.id)
        || records.some((entry) => entry.owner_id_internal === run.owner_id_internal
          && entry.position_id === run.position_id
          && entry.idempotency_key === run.idempotency_key)) {
        const error = new Error('Duplicate run');
        error.code = 'DUPLICATE_RUN';
        throw error;
      }
      records.push(clone(run));
      return clone(run);
    },
    async findById(runId) {
      return clone(records.find((run) => run.id === runId)) || null;
    },
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
        if (run.owner_id_internal === ownerId && run.position_id === positionId
          && run.position_revision < beforeRevision && run.id !== excludeRunId
          && (run.status === 'queued' || run.status === 'running')) {
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
      return clone(records.find((run) => run.owner_id_internal === ownerId
        && run.position_id === positionId
        && (run.status === 'succeeded' || run.status === 'limited'))) || null;
    },
  };
}

function createInMemorySnapshotRepository() {
  const records = [];
  return {
    records,
    async create(snapshot) {
      records.push(structuredClone(snapshot));
      return structuredClone(snapshot);
    },
    async findById(snapshotId) {
      return structuredClone(records.find((entry) => entry.snapshot_id === snapshotId)) || null;
    },
  };
}

// ResearchService constructor requires create/update on the assessment and
// checkpoint repositories; the scheduler exercises only run queueing/claiming/
// recovery, so those two are minimal stubs.
function createStubAssessmentRepository() {
  return { async create(assessment) { return structuredClone(assessment); } };
}

function createStubCheckpointRepository() {
  return { async update(checkpointId, patch) { return patch; } };
}

function createService(clock, { initialRuns = [] } = {}) {
  const runRepository = createInMemoryRunRepository(initialRuns);
  const service = new ResearchService({
    runRepository,
    assessmentRepository: createStubAssessmentRepository(),
    researchSnapshotRepository: createInMemorySnapshotRepository(),
    checkpointRepository: createStubCheckpointRepository(),
    evidenceSnapshotLookup: null,
    now: clock.now,
  });
  return { service, runRepository };
}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

function position(overrides = {}) {
  return {
    position_id: 'pos-h10x-1',
    owner_id: 'owner-h10x-aaaa',
    revision: 3,
    instrument_id: 'inst-h10x-1',
    ...overrides,
  };
}

function queueRequest(overrides = {}) {
  return {
    owner_id: 'owner-h10x-aaaa',
    position_id: 'pos-h10x-1',
    position_revision: 3,
    run_kind: 'daily_update',
    idempotency_key: `daily_update:2030-01-01:${overrides.position_id ?? 'pos-h10x-1'}`,
    instrument_id: 'inst-h10x-1',
    request_payload: { trigger: 'scheduled_daily', session_date: '2030-01-01' },
    ...overrides,
  };
}

// A fake service with observable call counts and an optional gated recovery, so
// leadership tests can hold a tick open while a peer attempts the lease.
function createControllableService() {
  const calls = { recover: 0, queue: 0 };
  let recoverGate = null;
  return {
    calls,
    holdRecovery() {
      let release;
      recoverGate = new Promise((resolve) => { release = resolve; });
      return release;
    },
    async recoverAbandonedRuns() {
      calls.recover += 1;
      if (recoverGate) {
        const gate = recoverGate;
        recoverGate = null;
        await gate;
      }
      return { stalled: 0, superseded: 0 };
    },
    async queueRun(args) {
      calls.queue += 1;
      return { run: { id: `run-${calls.queue}`, ...args }, idempotent_replay: false };
    },
  };
}

// ---------------------------------------------------------------------------
// 1. Leadership / lease ownership
// ---------------------------------------------------------------------------

test('createResearchScheduler requires a service with recovery and queue support', () => {
  assert.throws(
    () => createResearchScheduler({ researchService: {}, positions: () => [], leadership: createInMemoryLeaderLease() }),
    TypeError,
  );
  assert.throws(
    () => createResearchScheduler({ researchService: { recoverAbandonedRuns: async () => ({}), queueRun: async () => ({}) } }),
    TypeError,
  );
});

test('leader lease: exactly one replica runs the tick while the other backs off', async () => {
  const clock = makeClock();
  const leadership = createInMemoryLeaderLease({ now: clock.now });
  const service = createControllableService();
  const positions = () => [position()];
  const makeScheduler = (ownerId) => createResearchScheduler({
    researchService: service,
    positions,
    leadership,
    now: clock.now,
    ownerId,
  });

  const leader = makeScheduler('replica-a');
  const follower = makeScheduler('replica-b');

  // Leader acquires the lease and enters a gated recovery; the follower
  // attempts while the lease is still held.
  const release = service.holdRecovery();
  const leaderTick = leader.runTick();
  const followerTick = await follower.runTick();

  assert.equal(followerTick.leader, false, 'follower must back off while the leader holds the lease');

  release();
  const leaderResult = await leaderTick;
  assert.equal(leaderResult.leader, true);
  assert.equal(service.calls.recover, 1, 'recovery ran exactly once across both replicas');
  assert.equal(service.calls.queue, 1, 'daily queueing ran exactly once across both replicas');
});

test('non-leader tick performs zero recovery or queue side effects', async () => {
  const clock = makeClock();
  const leadership = createInMemoryLeaderLease({ now: clock.now });
  const service = createControllableService();
  const positions = () => [position()];

  // Pre-acquire the lease as a live peer.
  const held = await leadership.tryAcquire('research-scheduler', 'replica-a', 60000);
  assert.notEqual(held, null);

  const follower = createResearchScheduler({
    researchService: service,
    positions,
    leadership,
    now: clock.now,
    ownerId: 'replica-b',
  });
  const result = await follower.runTick();
  assert.equal(result.leader, false);
  assert.equal(service.calls.recover, 0, 'no recovery side effect from a non-leader');
  assert.equal(service.calls.queue, 0, 'no queue side effect from a non-leader');
});

// ---------------------------------------------------------------------------
// 2. Process restart / recovery takeover
// ---------------------------------------------------------------------------

test('process restart: an expired leader lease is taken over and abandoned runs are recovered', async () => {
  const clock = makeClock();
  const leadership = createInMemoryLeaderLease({ now: clock.now });
  const { service, runRepository } = createService(clock);

  // One running run and one queued run, both past their deadline after a crash.
  const runningRun = await service.queueRun(queueRequest({
    position_id: 'pos-h10x-1',
    idempotency_key: 'daily_update:2030-01-01:pos-h10x-1',
  }));
  await service.claimRun({ run_id: runningRun.run.id });

  const queuedRun = await service.queueRun(queueRequest({
    position_id: 'pos-h10x-2',
    idempotency_key: 'daily_update:2030-01-01:pos-h10x-2',
  }));

  // A leader holds the lease, then dies without releasing it.
  const held = await leadership.tryAcquire('research-scheduler', 'replica-a', 60000);
  assert.notEqual(held, null);

  // 20 minutes later: both the run deadlines (15 min) and the lease TTL (1 min)
  // have lapsed.
  clock.advance(20 * 60);

  const replica = createResearchScheduler({
    researchService: service,
    positions: () => [],
    leadership,
    now: clock.now,
    ownerId: 'replica-b',
  });
  const result = await replica.runTick();
  assert.equal(result.leader, true, 'a lapsed lease must be taken over, not wedged');
  assert.equal(result.recovery.stalled, 1, 'the crashed running run is stalled');
  assert.equal(result.recovery.superseded, 1, 'the expired queued run is superseded');

  const stalled = await runRepository.findById(runningRun.run.id);
  assert.equal(stalled.status, 'stalled');
  assert.equal(stalled.error_code, 'RUN_STALLED');
  const superseded = await runRepository.findById(queuedRun.run.id);
  assert.equal(superseded.status, 'superseded');
});

test('in-memory leader lease is re-acquirable only after TTL expiry', async () => {
  const clock = makeClock();
  const leadership = createInMemoryLeaderLease({ now: clock.now });

  const first = await leadership.tryAcquire('research-scheduler', 'replica-a', 60000);
  assert.notEqual(first, null);
  assert.equal(await leadership.tryAcquire('research-scheduler', 'replica-b', 60000), null,
    'a live peer cannot steal the lease');

  clock.advance(61);
  const takeover = await leadership.tryAcquire('research-scheduler', 'replica-b', 60000);
  assert.notEqual(takeover, null, 'an expired lease must be re-acquirable');
  assert.equal(takeover.owner, 'replica-b');
});

// ---------------------------------------------------------------------------
// 3. Daily queueing is wired and idempotent
// ---------------------------------------------------------------------------

test('scheduler queues one daily run per position and replays idempotently across ticks', async () => {
  const clock = makeClock();
  const leadership = createInMemoryLeaderLease({ now: clock.now });
  const { service, runRepository } = createService(clock);
  const positions = () => [
    position({ position_id: 'pos-h10x-1' }),
    position({ position_id: 'pos-h10x-2' }),
  ];
  const scheduler = createResearchScheduler({
    researchService: service,
    positions,
    leadership,
    now: clock.now,
    recoverExpired: false,
  });

  const first = await scheduler.runTick();
  assert.equal(first.leader, true);
  assert.equal(first.queued.length, 2, 'one run per due position');
  assert.equal(first.queued.every((entry) => entry.idempotent_replay === false), true);

  const second = await scheduler.runTick();
  assert.equal(second.queued.length, 2);
  assert.equal(second.queued.every((entry) => entry.idempotent_replay === true), true,
    'a re-tick on the same day replays, never duplicates');

  assert.equal(runRepository.records.length, 2, 'exactly two persisted runs after two ticks');
});

// ---------------------------------------------------------------------------
// 4. Bounded retry (no unbounded delay chain)
// ---------------------------------------------------------------------------

test('bounded retry: a transient tick failure is retried up to maxTickRetries then succeeds', async () => {
  const clock = makeClock();
  const leadership = createInMemoryLeaderLease({ now: clock.now });
  let recoverCalls = 0;
  const service = {
    async recoverAbandonedRuns() {
      recoverCalls += 1;
      if (recoverCalls <= 2) {
        const error = new Error('transient');
        error.code = 'TRANSIENT_DB_ERROR';
        throw error;
      }
      return { stalled: 0, superseded: 0 };
    },
    async queueRun() { return { run: { id: 'run-x' }, idempotent_replay: false }; },
  };
  const scheduler = createResearchScheduler({
    researchService: service,
    positions: () => [],
    leadership,
    now: clock.now,
    maxTickRetries: 2,
  });

  const result = await scheduler.runScheduledTick();
  assert.equal(result.leader, true);
  assert.equal(recoverCalls, 3, 'first attempt + two retries, then success (bounded)');
});

test('bounded retry: gives up after maxTickRetries and surfaces the last error', async () => {
  const clock = makeClock();
  const leadership = createInMemoryLeaderLease({ now: clock.now });
  let recoverCalls = 0;
  const service = {
    async recoverAbandonedRuns() {
      recoverCalls += 1;
      const error = new Error('down');
      error.code = 'TRANSIENT_DB_ERROR';
      throw error;
    },
    async queueRun() { return { run: { id: 'run-x' }, idempotent_replay: false }; },
  };
  const scheduler = createResearchScheduler({
    researchService: service,
    positions: () => [],
    leadership,
    now: clock.now,
    maxTickRetries: 2,
  });

  await assert.rejects(
    () => scheduler.runScheduledTick(),
    (error) => error.code === 'TRANSIENT_DB_ERROR',
  );
  assert.equal(recoverCalls, 3, 'exactly maxTickRetries + 1 attempts, no unbounded loop');
});

// ---------------------------------------------------------------------------
// 5. Source-only production integration seams
// ---------------------------------------------------------------------------

test('source scheduler uses the post-close New York cron and queues through the shared service', async () => {
  const scheduled = [];
  const cron = {
    schedule(expression, callback, options) {
      scheduled.push({ expression, callback, options });
      return { stop() {} };
    },
  };
  const service = createControllableService();
  const executionCalls = [];
  const logs = [];
  const started = startResearchScheduler({
    researchService: service,
    runWorker: { async startRun({ run_id }) { executionCalls.push(run_id); return { replayed: false }; } },
    positions: () => [position()],
    leadership: createInMemoryLeaderLease(),
    cron,
    ownerId: 'source-test-replica',
    logger: { info(message) { logs.push(message); }, warn() {} },
  });

  assert.equal(scheduled.length, 1);
  assert.equal(scheduled[0].expression, '20 16 * * 1-5');
  assert.deepEqual(scheduled[0].options, { timezone: 'America/New_York' });

  await scheduled[0].callback();
  assert.equal(service.calls.recover, 1);
  assert.equal(service.calls.queue, 1);
  assert.deepEqual(executionCalls, ['run-1']);
  assert.equal(started.scheduler instanceof Object, true);
  assert.match(logs.at(-1), /queued=1 replayed=0 queue_errors=0 execution_started=1 execution_replayed=0 execution_errors=0 recovered=0/);
});

test('source scheduler retries idempotent queued runs after restart and reports safe execution errors', async () => {
  const calls = [];
  let pipelineStarts = 0;
  const result = await startQueuedRunExecutions({
    queued: [
      { run_id: 'run-fresh', idempotent_replay: false },
      // The queue replay means a prior tick persisted this run. It does not
      // prove a worker claimed it before a process crash, so it must be tried.
      { run_id: 'run-replay', idempotent_replay: true },
      { run_id: 'run-failing', idempotent_replay: false },
    ],
    runWorker: {
      async startRun({ run_id }) {
        calls.push(run_id);
        if (run_id === 'run-failing') {
          const error = new Error('upstream credential detail must not be logged');
          error.code = 'INPUT_UNAVAILABLE';
          throw error;
        }
        // This mirrors the atomic persisted claim contract: an already-claimed
        // run returns a replay receipt and never starts another pipeline.
        if (run_id === 'run-replay') return { replayed: true };
        pipelineStarts += 1;
        return { replayed: false };
      },
    },
  });
  assert.deepEqual(calls, ['run-fresh', 'run-replay', 'run-failing']);
  assert.equal(pipelineStarts, 1, 'a claimed run is observed but never executed twice');
  assert.deepEqual(result, {
    started: 1,
    replayed: 1,
    errors: [{ run_id: 'run-failing', error_code: 'INPUT_UNAVAILABLE' }],
  });
});

test('mongoose leader lease uses atomic ownership filters and refuses a duplicate-key race', async () => {
  const calls = [];
  const model = {
    findOneAndUpdate(filter, update, options) {
      calls.push({ filter, update, options });
      return { lean: async () => ({ _id: 'research-scheduler', owner: 'replica-a', expires_at: new Date('2030-01-01T00:01:00.000Z') }) };
    },
    async deleteOne(filter) {
      calls.push({ delete: filter });
      return { deletedCount: 1 };
    },
  };
  const leadership = createMongooseLeaderLease({
    model,
    now: () => new Date('2030-01-01T00:00:00.000Z'),
  });

  const lease = await leadership.tryAcquire('research-scheduler', 'replica-a', 60000);
  assert.deepEqual(lease, {
    key: 'research-scheduler', owner: 'replica-a', expires_at: '2030-01-01T00:01:00.000Z',
  });
  assert.deepEqual(calls[0].filter, {
    _id: 'research-scheduler',
    $or: [
      { expires_at: { $lte: new Date('2030-01-01T00:00:00.000Z') } },
      { owner: 'replica-a' },
    ],
  });
  assert.equal(calls[0].options.upsert, true);
  assert.equal(await leadership.release(lease), true);

  const collision = createMongooseLeaderLease({
    model: {
      findOneAndUpdate() { return { lean: async () => { const error = new Error('duplicate'); error.code = 11000; throw error; } }; },
      async deleteOne() { return { deletedCount: 0 }; },
    },
  });
  assert.equal(await collision.tryAcquire('research-scheduler', 'replica-b', 60000), null);
});

test('scheduled positions provider selects only active queueing fields', async () => {
  let filter;
  let projection;
  const provider = createMongooseScheduledPositionsProvider({
    model: {
      find(query) {
        filter = query;
        return {
          select(value) {
            projection = value;
            return this;
          },
          lean: async () => [{
            _id: 'pos-provider-1',
            owner_id: 'owner-provider-1',
            revision: 4,
            instrument: { instrument_id: 'inst-provider-1' },
          }],
        };
      },
    },
  });

  assert.deepEqual(await provider(), [{
    position_id: 'pos-provider-1',
    owner_id: 'owner-provider-1',
    revision: 4,
    instrument_id: 'inst-provider-1',
  }]);
  assert.deepEqual(filter, { archived: false });
  assert.equal(projection, '_id owner_id instrument revision');
});

test('server wires the source scheduler only with its bounded local worker', () => {
  let legacyStarts = 0;
  let researchStarts = 0;
  const warnings = [];
  const common = {
    researchService: { marker: 'shared-service' },
    legacySchedulerStarter() { legacyStarts += 1; },
    runWorker: { startRun() {} },
    researchSchedulerStarter(options) {
      researchStarts += 1;
      assert.equal(options.researchService.marker, 'shared-service');
      return { task: 'research-task' };
    },
    logger: { warn(message) { warnings.push(message); } },
  };

  assert.equal(startProductionSchedulers({ ...common, runWorker: null }), null);
  assert.equal(legacyStarts, 1);
  assert.equal(researchStarts, 0);
  assert.match(warnings[0], /bounded research worker is unavailable/);

  assert.deepEqual(startProductionSchedulers(common), { task: 'research-task' });
  assert.equal(legacyStarts, 2);
  assert.equal(researchStarts, 1);

  assert.equal(startProductionSchedulers({ ...common, automationReady: false }), null);
  assert.equal(legacyStarts, 3);
  assert.equal(researchStarts, 1);
  assert.match(warnings.at(-1), /bounded research worker is unavailable/);
});

test('automation execution readiness requires the n8n trigger, execute, and status scopes', () => {
  assert.equal(hasAutomationExecutionScopes(['research:trigger', 'research:execute', 'research:status']), true);
  assert.equal(hasAutomationExecutionScopes(['research:trigger', 'research:execute']), false);
  assert.equal(hasAutomationExecutionScopes(null), false);
});
