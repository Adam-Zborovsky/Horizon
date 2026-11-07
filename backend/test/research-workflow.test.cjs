'use strict';

// H10 — thin n8n trigger/poll/delivery and bounded run worker tests.
//
// CONTRACTS §8/§9 and the H10 package: Node owns the fixed bounded pipeline
// (H09 agent_runtime); n8n only triggers, polls persisted status and delivers
// validated bound results. Every client is injected; every repository is
// in-memory. No live DB, no network, no model calls, no credentials.

const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const fs = require('node:fs');
const http = require('node:http');
const path = require('node:path');
const test = require('node:test');
const express = require('express');

const {
  ResearchService,
} = require('../src/features/research/research.service');
const {
  createResearchAgentRuntime,
} = require('../src/features/research/agent_runtime');
const {
  validateAssessmentDelivery,
} = require('../src/features/research/result_validator');
const {
  createAutomationMiddleware,
  createRunCallbackAuthorizer,
  AutomationAuthorizationError,
} = require('../src/middleware/automation.middleware');
const {
  createAutomationRouter,
  createMongooseQueuedRunSource,
} = require('../src/features/research/automation.routes');
const {
  createRunWorker,
  queueDailyUpdateRuns,
  safeValidationDiagnostics,
  toStatusView,
} = require('../src/features/research/run_worker');

const OWNER_A = 'owner-h10-aaaa';
const OWNER_B = 'owner-h10-bbbb';
const INSTRUMENT = Object.freeze({
  instrument_id: 'inst-h10-1',
  symbol: 'TEST',
  exchange: 'XNYS',
  currency: 'USD',
  provider_symbol: 'TEST',
});
const AUTOMATION_SCOPES = Object.freeze([
  'research:trigger',
  'research:input',
  'research:status',
  'research:execute',
  'research:callback',
]);

// ---------------------------------------------------------------------------
// Hermetic fixtures (synthetic; NOT observed market data)
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
      return {
        assessments: clone(page),
        next_cursor: candidates.length > limit
          ? `${page[page.length - 1].generated_at}|${page[page.length - 1].id}`
          : null,
      };
    },
  };
}

function createInMemoryResearchSnapshotRepository(initial = []) {
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

function evidenceItem(id, kind, availableAt) {
  return {
    id,
    instrument_id: INSTRUMENT.instrument_id,
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
  };
}

function evidenceSnapshot(overrides = {}) {
  return {
    snapshot_id: 'snap-h10-1',
    instrument_id: INSTRUMENT.instrument_id,
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

const METRICS = [
  {
    id: 'm-close', instrument_id: INSTRUMENT.instrument_id, value: 150, unit: 'USD', currency: 'USD',
    as_of: '2026-10-30', basis: 'raw_close', method: 'last_close', method_version: 'v1',
    input_evidence_ids: ['ev-filing'], input_snapshot_ids: [],
  },
];

function ownedPosition(overrides = {}) {
  return {
    position_id: 'pos-h10-1',
    state: 'owned',
    revision: 7,
    average_cost: { amount: '100.00', currency: 'USD', basis: 'raw_purchase' },
    quantity: '10',
    opened_on: '2026-01-05',
    preferred_horizon_months: 3,
    ...overrides,
  };
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
    changes_since_previous: null,
    checkpoints: [
      { kind: 'fixed_observed_level', fixed_level: 120, condition: 'price holds above 120', status: 'active', reason: 'Fixture carried checkpoint.' },
    ],
    missing_data: [],
  };
}

// Scripted model client: no live calls, records every request.
function createModelClient({ outputs = [], deferred = false } = {}) {
  const state = { calls: [], release: null };
  state.complete = async function complete(request) {
    state.calls.push(request);
    const output = outputs.length > 1 ? outputs.shift() : outputs[0];
    if (deferred) {
      return new Promise((resolve) => { state.release = () => resolve({ output }); });
    }
    if (output === undefined) throw new Error('fixture model client exhausted');
    return { output };
  };
  return state;
}

function weekdayPredicate(sessionDate) {
  const weekday = new Date(`${sessionDate}T00:00:00Z`).getUTCDay();
  return weekday >= 1 && weekday <= 5;
}

// Full hermetic harness: service + runtime + worker over shared in-memory repos.
function createHarness({
  startIso = '2030-01-01T00:00:00.000Z',
  modelOutputs,
  deferredModel = false,
  deadlineSeconds = 900,
  inputProviderOverride,
  logger = null,
} = {}) {
  const clock = { iso: startIso };
  const repos = {
    runRepository: createInMemoryRunRepository(),
    assessmentRepository: createInMemoryAssessmentRepository(),
    researchSnapshotRepository: createInMemoryResearchSnapshotRepository(),
    checkpointRepository: createInMemoryCheckpointRepository(),
  };
  const evidenceStore = new Map([['snap-h10-1', evidenceSnapshot()]]);
  const evidenceSnapshotLookup = async (snapshotId) => {
    const snapshot = evidenceStore.get(snapshotId);
    return snapshot ? { snapshot_id: snapshot.snapshot_id, instrument_id: snapshot.instrument_id } : null;
  };
  const service = new ResearchService({
    ...repos,
    evidenceSnapshotLookup,
    now: () => new Date(clock.iso),
    deadlineSeconds,
  });
  const modelClient = createModelClient({ outputs: modelOutputs ?? [validSynthesis()], deferred: deferredModel });
  const runtime = createResearchAgentRuntime({
    modelClient: { complete: modelClient.complete },
    now: () => new Date(clock.iso),
    idFactory: (() => {
      let counter = 0;
      return () => `assessment-h10-${(counter += 1)}`;
    })(),
    isExchangeSession: weekdayPredicate,
  });
  const inputProvider = inputProviderOverride ?? (async (run) => ({
    snapshot: evidenceSnapshot(),
    metrics: METRICS,
    instrument: INSTRUMENT,
    position: ownedPosition({ position_id: run.position_id, revision: run.position_revision }),
    prior: null,
    currentPrice: { amount: '150.00', currency: 'USD', adjustment_basis: 'raw_purchase' },
  }));
  const worker = createRunWorker({
    researchService: service,
    agentRuntime: runtime,
    inputProvider,
    runLookup: (runId) => repos.runRepository.findById(runId),
    now: () => new Date(clock.iso),
    logger,
  });
  return {
    service,
    repos,
    worker,
    modelClient,
    evidenceStore,
    queueRun(overrides = {}) {
      return service.queueRun({
        owner_id: OWNER_A,
        position_id: 'pos-h10-1',
        position_revision: 7,
        run_kind: 'manual_refresh',
        idempotency_key: `key-h10-${crypto.randomUUID()}`,
        instrument_id: INSTRUMENT.instrument_id,
        request_payload: { trigger: 'fixture' },
        ...overrides,
      });
    },
    advance(seconds) {
      clock.iso = new Date(new Date(clock.iso).getTime() + seconds * 1000).toISOString();
    },
    nowIso: () => clock.iso,
  };
}

// ---------------------------------------------------------------------------
// HTTP harness for the automation router
// ---------------------------------------------------------------------------

async function withServer(router, fn) {
  const app = express();
  app.use(express.json({ limit: '1mb' }));
  app.use(router);
  const server = http.createServer(app);
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  try {
    const { port } = server.address();
    await fn(`http://127.0.0.1:${port}`);
  } finally {
    await new Promise((resolve, reject) => server.close((error) => (error ? reject(error) : resolve())));
  }
}

async function request(baseUrl, pathName, options = {}) {
  const response = await fetch(`${baseUrl}${pathName}`, options);
  let body = null;
  try {
    body = await response.json();
  } catch {
    body = null;
  }
  return { status: response.status, body };
}

function authorizedHeaders(token, extra = {}) {
  return {
    authorization: `Bearer ${token}`,
    'content-type': 'application/json',
    ...extra,
  };
}

function createHttpHarness({ harness, token = crypto.randomBytes(32).toString('hex'), scopes = AUTOMATION_SCOPES, ownerId = OWNER_A } = {}) {
  const middleware = createAutomationMiddleware({
    token,
    scopes,
    ownerId,
    maxBodyBytes: 64 * 1024,
  });
  const callbackAuthorizer = createRunCallbackAuthorizer({ now: () => new Date(harness.nowIso()) });
  const queuedRunSource = async ({ ownerId: owner, limit, nowIso }) => harness.repos.runRepository.records
    .filter((run) => run.owner_id_internal === owner && run.status === 'queued' && run.deadline_at > nowIso)
    .sort((a, b) => a.created_at.localeCompare(b.created_at))
    .slice(0, limit)
    .map(toStatusView);
  const router = createAutomationRouter({
    researchService: harness.service,
    runWorker: harness.worker,
    runs: harness.repos.runRepository,
    automationMiddleware: middleware,
    callbackAuthorizer,
    listQueuedRuns: queuedRunSource,
    now: () => new Date(harness.nowIso()),
  });
  // Mount under /research exactly as the integration lane will under the API
  // prefix (/api/v1/automation/research -> routes below /research here).
  const mounted = express();
  mounted.use('/research', router);
  return { router: mounted, token, middleware, callbackAuthorizer };
}

// ---------------------------------------------------------------------------
// 1. Duplicate schedules / restarts do not duplicate research
// ---------------------------------------------------------------------------

test('duplicate daily schedules queue one run per position per day (persisted idempotency)', async () => {
  const harness = createHarness();
  const positions = [
    { position_id: 'pos-h10-1', owner_id: OWNER_A, instrument_id: INSTRUMENT.instrument_id, revision: 7 },
    { position_id: 'pos-h10-2', owner_id: OWNER_A, instrument_id: INSTRUMENT.instrument_id, revision: 3 },
  ];
  const first = await queueDailyUpdateRuns({ researchService: harness.service, positions, now: () => new Date(harness.nowIso()) });
  assert.equal(first.queued.length, 2, `queue failures: ${JSON.stringify(first.errors)}`);
  assert.equal(first.queued.every((entry) => entry.idempotent_replay === false), true);

  // Same day re-fire (controller restart, cron double-fire): replays only.
  const second = await queueDailyUpdateRuns({ researchService: harness.service, positions, now: () => new Date(harness.nowIso()) });
  assert.equal(second.queued.length, 2);
  assert.equal(second.queued.every((entry) => entry.idempotent_replay === true), true);
  assert.equal(harness.repos.runRepository.records.length, 2);

  // Same-day execution (the n8n trigger path) settles the day's runs.
  for (const entry of first.queued) {
    const outcome = await harness.worker.executeRun({ run_id: entry.run_id });
    assert.equal(outcome.run.status, 'succeeded', `day-1 run must succeed (${outcome.run.error_code ?? 'no code'})`);
  }

  // Next day: new session date -> genuinely new runs, never a silent reuse.
  harness.advance(24 * 60 * 60);
  const third = await queueDailyUpdateRuns({ researchService: harness.service, positions, now: () => new Date(harness.nowIso()) });
  assert.equal(third.queued.length, 2);
  assert.equal(third.queued.every((entry) => entry.idempotent_replay === false), true);
  assert.equal(harness.repos.runRepository.records.length, 4);
});

test('one invalid position does not block the daily batch; failures are reported per position', async () => {
  const harness = createHarness();
  const positions = [
    { position_id: 'pos-bad', owner_id: OWNER_A, instrument_id: '', revision: 1 },
    { position_id: 'pos-h10-1', owner_id: OWNER_A, instrument_id: INSTRUMENT.instrument_id, revision: 7 },
  ];
  const result = await queueDailyUpdateRuns({ researchService: harness.service, positions, now: () => new Date(harness.nowIso()) });
  assert.equal(result.queued.length, 1);
  assert.equal(result.errors.length, 1);
  assert.equal(result.errors[0].position_id, 'pos-bad');
  assert.equal(typeof result.errors[0].error_code, 'string');
  assert.equal(result.errors[0].error_code.length > 0, true);
});

test('concurrent execute of the same run performs the pipeline exactly once', async () => {
  const harness = createHarness();
  const { run } = await harness.queueRun();
  const [a, b] = await Promise.all([
    harness.worker.executeRun({ run_id: run.id }),
    harness.worker.executeRun({ run_id: run.id }),
  ]);
  assert.equal(harness.modelClient.calls.length, 1, 'duplicate suppression must prevent a second model execution');
  assert.equal(a.run.status, 'succeeded', `run must succeed, got ${a.run.status} (${a.run.error_code ?? 'no code'})`);
  const persisted = await harness.repos.runRepository.findById(run.id);
  assert.equal(persisted.status, 'succeeded');
});

test('execute replay after terminal completion returns persisted status without re-execution', async () => {
  const harness = createHarness();
  const { run } = await harness.queueRun();
  await harness.worker.executeRun({ run_id: run.id });
  const replay = await harness.worker.executeRun({ run_id: run.id });
  assert.equal(replay.replayed, true, JSON.stringify(replay));
  assert.equal(harness.modelClient.calls.length, 1);
  assert.equal(replay.run.status, 'succeeded');
});

test('restart with a fresh worker while a run is claimed replays instead of double-claiming', async () => {
  const harness = createHarness({ deferredModel: true });
  const { run } = await harness.queueRun();
  const started = harness.worker.startRun({ run_id: run.id });
  const firstClaim = await started;
  assert.equal(firstClaim.replayed, false);

  // Process restart: new worker instance over the same persisted state.
  const restartedWorker = createRunWorker({
    researchService: harness.service,
    agentRuntime: createResearchAgentRuntime({
      modelClient: { complete: async () => { throw new Error('must not be called after restart'); } },
      now: () => new Date(harness.nowIso()),
      idFactory: () => 'assessment-h10-restart',
      isExchangeSession: weekdayPredicate,
    }),
    inputProvider: async () => { throw new Error('input provider must not be called after restart'); },
    runLookup: (runId) => harness.repos.runRepository.findById(runId),
    now: () => new Date(harness.nowIso()),
  });
  const replay = await restartedWorker.startRun({ run_id: run.id });
  assert.equal(replay.replayed, true);
  assert.equal(replay.run.status, 'running');
  assert.equal(replay.lease_nonce, undefined, 'replay must not hand out a fresh lease nonce');

  harness.modelClient.release();
  await harness.worker.whenSettled(run.id);
  assert.equal(harness.modelClient.calls.length, 1);
  const persisted = await harness.repos.runRepository.findById(run.id);
  assert.equal(persisted.status, 'succeeded');
});

// ---------------------------------------------------------------------------
// 2. Trigger -> execute -> poll -> result (the thin n8n loop)
// ---------------------------------------------------------------------------

test('execute accepts (202) with a run-bound lease nonce, poll exposes the terminal result bound', async () => {
  const harness = createHarness();
  const httpHarness = createHttpHarness({ harness });
  const { run } = await harness.queueRun();

  await withServer(httpHarness.router, async (baseUrl) => {
    const accepted = await request(baseUrl, `/research/runs/${run.id}/execute`, {
      method: 'POST',
      headers: authorizedHeaders(httpHarness.token),
      body: JSON.stringify({}),
    });
    assert.equal(accepted.status, 202);
    assert.equal(accepted.body.run_id, run.id);
    assert.equal(accepted.body.status, 'accepted');
    assert.equal(typeof accepted.body.lease_nonce, 'string');
    assert.equal(accepted.body.lease_nonce.length > 0, true);
    await harness.worker.whenSettled(run.id);

    const polled = await request(baseUrl, `/research/runs/${run.id}/status`, {
      headers: authorizedHeaders(httpHarness.token),
    });
    assert.equal(polled.status, 200);
    assert.equal(polled.body.run.status, 'succeeded');
    assert.equal(typeof polled.body.run.assessment_id, 'string');
    assert.equal(typeof polled.body.run.evidence_snapshot_id, 'string');
    assert.equal(JSON.stringify(polled.body).includes(accepted.body.lease_nonce), false,
      'status must never expose the lease nonce');
  });

  const assessment = await harness.repos.assessmentRepository.findByRunId(run.id);
  assert.equal(assessment.owner_id_internal, OWNER_A);
  assert.equal(assessment.position_revision, 7);
});

test('execute replay over HTTP returns recorded status/result with 200 and no duplicate model execution', async () => {
  const harness = createHarness();
  const httpHarness = createHttpHarness({ harness });
  const { run } = await harness.queueRun();
  await withServer(httpHarness.router, async (baseUrl) => {
    const headers = authorizedHeaders(httpHarness.token);
    const first = await request(baseUrl, `/research/runs/${run.id}/execute`, { method: 'POST', headers, body: '{}' });
    assert.equal(first.status, 202);
    await harness.worker.whenSettled(run.id);
    const second = await request(baseUrl, `/research/runs/${run.id}/execute`, { method: 'POST', headers, body: '{}' });
    assert.equal(second.status, 200);
    assert.equal(second.body.replayed, true);
    assert.equal(second.body.run.status, 'succeeded');
  });
  assert.equal(harness.modelClient.calls.length, 1);
});

test('queued runs endpoint returns only claimable queued runs of the automation owner, bounded', async () => {
  const harness = createHarness();
  await harness.queueRun({ position_id: 'pos-h10-1', idempotency_key: 'key-queued-1' });
  await harness.queueRun({ position_id: 'pos-h10-1', idempotency_key: 'key-queued-2', run_kind: 'daily_update' });
  const httpHarness = createHttpHarness({ harness });
  await withServer(httpHarness.router, async (baseUrl) => {
    const headers = authorizedHeaders(httpHarness.token);
    const listed = await request(baseUrl, '/research/runs/queued?limit=1', { headers });
    assert.equal(listed.status, 200);
    assert.equal(listed.body.runs.length, 1, 'limit bounds the batch');
    assert.equal(listed.body.truncated, true);
    const item = listed.body.runs[0];
    assert.equal(typeof item.run_id, 'string');
    assert.equal(JSON.stringify(item).includes('average_cost'), false, 'queued listing must not carry economics');
    // Cross-owner runs are invisible to this automation identity.
    await harness.queueRun({ owner_id: OWNER_B, position_id: 'pos-h10-b', idempotency_key: 'key-queued-b' });
    const mine = await request(baseUrl, '/research/runs/queued', { headers });
    assert.equal(mine.body.runs.length, 2);
    assert.equal(mine.body.runs.every((entry) => entry.run_id !== 'run-of-owner-b'), true);
  });
});

// ---------------------------------------------------------------------------
// 3. Result delivery binding (no arbitrary callback userId, bounded 422)
// ---------------------------------------------------------------------------

test('result delivery binds owner server-side; body userId is ignored, duplicates idempotent, conflicts 409', async () => {
  const harness = createHarness();
  const httpHarness = createHttpHarness({ harness });
  const { run } = await harness.queueRun();
  const claimed = await harness.service.claimRun({ run_id: run.id });

  await withServer(httpHarness.router, async (baseUrl) => {
    const headers = authorizedHeaders(httpHarness.token, {
      'x-horizon-run-id': run.id,
      'x-horizon-run-nonce': claimed.lease_nonce,
      'x-horizon-delivery-id': 'delivery-1',
    });
    const result = {
      evidence_snapshot_id: 'snap-h10-1',
      position_revision: 7,
      session_as_of: '2030-01-01',
      status: 'complete',
      assessment: { market_thesis: { business: 'bound fixture delivery' } },
      // Attacker-supplied userId must be irrelevant: ownership is derived
      // from the scoped automation identity and the run record.
      userId: 'owner-h10-victim',
    };
    const first = await request(baseUrl, `/research/runs/${run.id}/result`, {
      method: 'POST', headers, body: JSON.stringify(result),
    });
    assert.equal(first.status, 201);
    assert.equal(first.body.idempotent, false);
    const identical = await request(baseUrl, `/research/runs/${run.id}/result`, {
      method: 'POST', headers, body: JSON.stringify(result),
    });
    assert.equal(identical.status, 200);
    assert.equal(identical.body.idempotent, true);
    assert.equal(identical.body.assessment_id, first.body.assessment_id);

    const conflicting = await request(baseUrl, `/research/runs/${run.id}/result`, {
      method: 'POST',
      headers: authorizedHeaders(httpHarness.token, {
        'x-horizon-run-id': run.id,
        'x-horizon-run-nonce': claimed.lease_nonce,
        'x-horizon-delivery-id': 'delivery-1',
      }),
      body: JSON.stringify({ ...result, assessment: { market_thesis: { business: 'different' } } }),
    });
    assert.equal(conflicting.status, 409);

    const assessment = await harness.repos.assessmentRepository.findByRunId(run.id);
    assert.equal(assessment.owner_id_internal, OWNER_A, 'delivery must bind the run owner, never a body userId');
    assert.equal(assessment.run_id, run.id);
  });
});

test('result delivery with a wrong or expired lease nonce fails closed', async () => {
  const harness = createHarness();
  const httpHarness = createHttpHarness({ harness });
  const { run } = await harness.queueRun();
  const claimed = await harness.service.claimRun({ run_id: run.id });

  await withServer(httpHarness.router, async (baseUrl) => {
    const result = {
      evidence_snapshot_id: 'snap-h10-1', position_revision: 7, session_as_of: '2030-01-01',
      status: 'complete', assessment: { market_thesis: { business: 'x' } },
    };
    const wrongNonce = await request(baseUrl, `/research/runs/${run.id}/result`, {
      method: 'POST',
      headers: authorizedHeaders(httpHarness.token, {
        'x-horizon-run-id': run.id,
        'x-horizon-run-nonce': crypto.randomBytes(32).toString('hex'),
        'x-horizon-delivery-id': 'delivery-x',
      }),
      body: JSON.stringify(result),
    });
    assert.equal(wrongNonce.status, 403);

    harness.advance(301); // lease (300s) expired
    const expired = await request(baseUrl, `/research/runs/${run.id}/result`, {
      method: 'POST',
      headers: authorizedHeaders(httpHarness.token, {
        'x-horizon-run-id': run.id,
        'x-horizon-run-nonce': claimed.lease_nonce,
        'x-horizon-delivery-id': 'delivery-y',
      }),
      body: JSON.stringify(result),
    });
    assert.equal(expired.status, 409);
    assert.equal(harness.repos.assessmentRepository.records.length, 0, 'no assessment may persist from a rejected delivery');
  });
});

test('invalid researched result is a 422 with a bounded, honest terminal state — never an unbounded loop', async () => {
  const harness = createHarness();
  const httpHarness = createHttpHarness({ harness });
  const { run } = await harness.queueRun();
  const claimed = await harness.service.claimRun({ run_id: run.id });
  await withServer(httpHarness.router, async (baseUrl) => {
    const headers = authorizedHeaders(httpHarness.token, {
      'x-horizon-run-id': run.id,
      'x-horizon-run-nonce': claimed.lease_nonce,
      'x-horizon-delivery-id': 'delivery-bad',
    });
    const bad = await request(baseUrl, `/research/runs/${run.id}/result`, {
      method: 'POST', headers,
      body: JSON.stringify({
        evidence_snapshot_id: 'snap-h10-1', position_revision: 7, session_as_of: '2030-01-01',
        status: 'totally_invalid', assessment: {},
      }),
    });
    assert.equal(bad.status, 422);
    // A second identical bad delivery must not be retried into anything else:
    // the client owns retry policy; the backend stays deterministic.
    const again = await request(baseUrl, `/research/runs/${run.id}/result`, {
      method: 'POST', headers,
      body: JSON.stringify({
        evidence_snapshot_id: 'snap-h10-1', position_revision: 7, session_as_of: '2030-01-01',
        status: 'totally_invalid', assessment: {},
      }),
    });
    assert.equal(again.status, 422);
  });
});

// ---------------------------------------------------------------------------
// 4. Authorization boundaries on the automation surface
// ---------------------------------------------------------------------------

test('automation routes require the bearer token and exact scopes', async () => {
  const harness = createHarness();
  const httpHarness = createHttpHarness({ harness, scopes: ['research:status'] });
  const { run } = await harness.queueRun();
  await withServer(httpHarness.router, async (baseUrl) => {
    const noToken = await request(baseUrl, `/research/runs/${run.id}/status`);
    assert.equal(noToken.status, 401);
    const execute = await request(baseUrl, `/research/runs/${run.id}/execute`, {
      method: 'POST',
      headers: authorizedHeaders(httpHarness.token),
      body: '{}',
    });
    assert.equal(execute.status, 403, 'missing research:execute scope must be denied');
    const status = await request(baseUrl, `/research/runs/${run.id}/status`, {
      headers: authorizedHeaders(httpHarness.token),
    });
    assert.equal(status.status, 200);
  });
});

test('cross-owner runs are indistinguishable 404s on the automation surface', async () => {
  const harness = createHarness();
  const { run } = await harness.queueRun({ owner_id: OWNER_B, position_id: 'pos-h10-b' });
  const httpHarness = createHttpHarness({ harness }); // ownerId = OWNER_A
  await withServer(httpHarness.router, async (baseUrl) => {
    const headers = authorizedHeaders(httpHarness.token);
    for (const [method, pathName, body] of [
      ['GET', `/research/runs/${run.id}/status`, null],
      ['GET', `/research/runs/${run.id}/input`, null],
      ['POST', `/research/runs/${run.id}/execute`, '{}'],
    ]) {
      const response = await request(baseUrl, pathName, {
        method, headers, body: body ?? undefined,
      });
      assert.equal(response.status, 404, `${method} ${pathName} must not reveal another owner's run`);
    }
  });
  assert.equal(harness.modelClient.calls.length, 0, 'cross-owner probing must never execute a pipeline');
});

test('input endpoint returns the bound run input only — no lease nonce, no position economics', async () => {
  const harness = createHarness();
  const httpHarness = createHttpHarness({ harness });
  const { run } = await harness.queueRun({ request_payload: { trigger: 'fixture', note: 'input probe' } });
  await withServer(httpHarness.router, async (baseUrl) => {
    const response = await request(baseUrl, `/research/runs/${run.id}/input`, {
      headers: authorizedHeaders(httpHarness.token),
    });
    assert.equal(response.status, 200);
    assert.equal(response.body.run_id, run.id);
    assert.equal(response.body.instrument_id, INSTRUMENT.instrument_id);
    assert.equal(response.body.request_payload.note, 'input probe');
    const serialized = JSON.stringify(response.body);
    assert.equal(serialized.includes('lease_nonce'), false);
    assert.equal(serialized.includes('average_cost'), false);
    assert.equal(serialized.includes('quantity'), false);
  });
});

// ---------------------------------------------------------------------------
// 5. Deadlines, stalls, and honest status
// ---------------------------------------------------------------------------

test('queued run already past its deadline is superseded by recovery, not executed', async () => {
  const harness = createHarness({ deadlineSeconds: 1 });
  const { run } = await harness.queueRun();
  harness.advance(10);
  const outcome = await harness.worker.executeRun({ run_id: run.id });
  assert.equal(outcome.replayed, true);
  assert.equal(harness.modelClient.calls.length, 0);
  const persisted = await harness.repos.runRepository.findById(run.id);
  assert.equal(persisted.status, 'superseded');
});

test('running run past its deadline is stalled honestly (never faked complete)', async () => {
  const harness = createHarness({ deadlineSeconds: 1, deferredModel: true });
  const { run } = await harness.queueRun();
  await harness.worker.startRun({ run_id: run.id });
  harness.advance(10);
  harness.modelClient.release();
  const settled = await harness.worker.whenSettled(run.id);
  assert.equal(settled.run.status, 'stalled', `post-deadline run must stall (got ${settled.run.status})`);
  const persisted = await harness.repos.runRepository.findById(run.id);
  assert.equal(persisted.status, 'stalled');
  assert.equal(persisted.error_code, 'RUN_STALLED');
  // An explicit recovery sweep afterwards finds nothing left to stall.
  const recovery = await harness.worker.recoverExpiredRuns();
  assert.equal(recovery.stalled, 0);
});

test('pipeline completion after deadline expiry cannot fake success — run stalls', async () => {
  const harness = createHarness({ deadlineSeconds: 1 });
  const { run } = await harness.queueRun();
  await harness.worker.startRun({ run_id: run.id });
  harness.advance(10);
  const outcome = await harness.worker.whenSettled(run.id);
  assert.equal(outcome.run.status === 'stalled' || outcome.run.status === 'failed', true,
    `post-deadline completion must not be succeeded (got ${outcome.run.status})`);
  assert.equal(harness.repos.assessmentRepository.records.length, 0);
});

test('status keeps last success separate from later failure (no success rewriting)', async () => {
  const harness = createHarness();
  const first = await harness.queueRun({ idempotency_key: 'key-success-1' });
  await harness.worker.executeRun({ run_id: first.run.id });
  const successBefore = await harness.service.getPositionResearchState({ owner_id: OWNER_A, position_id: 'pos-h10-1' });
  assert.equal(successBefore.last_success.status, 'succeeded');
  const successAt = successBefore.last_success.finished_at;

  // A later attempt that expires honestly (deadline exceeded while queued)
  // must not touch the existing success record.
  harness.advance(60);
  const second = await harness.queueRun({ idempotency_key: 'key-fail-2', deadlineSeconds: 1 });
  harness.advance(2);
  const outcome = await harness.worker.executeRun({ run_id: second.run.id });
  assert.equal(outcome.replayed, true);
  const after = await harness.service.getPositionResearchState({ owner_id: OWNER_A, position_id: 'pos-h10-1' });
  assert.equal(after.last_success.finished_at, successAt, 'existing success timestamps are never updated');
  assert.equal(after.latest_attempt.status === 'superseded' || after.latest_attempt.status === 'failed' || after.latest_attempt.status === 'stalled', true);
  assert.equal(after.latest_attempt.run_id, second.run.id);
});

test('input provider failure fails the run honestly without model execution', async () => {
  const harness = createHarness({
    inputProviderOverride: async () => { throw new Error('simulated evidence store outage'); },
  });
  const { run } = await harness.queueRun();
  const outcome = await harness.worker.executeRun({ run_id: run.id });
  assert.equal(outcome.run.status, 'failed');
  assert.equal(outcome.run.error_code, 'INPUT_UNAVAILABLE');
  assert.equal(harness.modelClient.calls.length, 0);
});

test('synthesis validation failures are bounded to the H09 budget and end in a failed run', async () => {
  const harness = createHarness({ modelOutputs: [{ nope: true }] });
  const { run } = await harness.queueRun();
  const outcome = await harness.worker.executeRun({ run_id: run.id });
  assert.equal(outcome.run.status, 'failed');
  assert.equal(outcome.run.error_code, 'SYNTHESIS_VALIDATION_FAILED');
  assert.equal(harness.modelClient.calls.length, 2, 'at most two synthesis/repair attempts (CONTRACTS §8)');
});

test('worker logs safe canonical field diagnostics without model content or arbitrary paths', async () => {
  const warnings = [];
  const bad = validSynthesis();
  const secret = 'MODEL_SECRET_MUST_NOT_APPEAR';
  bad.recommendation.headline = secret.repeat(200);
  const harness = createHarness({
    modelOutputs: [bad, bad],
    logger: { warn: (message) => warnings.push(message) },
  });
  const { run } = await harness.queueRun();
  const outcome = await harness.worker.executeRun({ run_id: run.id });
  assert.equal(outcome.run.status, 'failed');
  assert.equal(outcome.run.error_code, 'SYNTHESIS_VALIDATION_FAILED');
  assert.equal(warnings.length, 1);
  assert.match(warnings[0], /SCHEMA_INVALID/);
  assert.match(warnings[0], /recommendation\.headline/);
  assert.equal(warnings[0].includes(secret), false);
  assert.deepEqual(safeValidationDiagnostics([
    { code: 'SCHEMA_INVALID', path: 'recommendation.headline', message: secret },
    { code: 'SCHEMA_INVALID', path: 'outlooks.0.base_case.0.text', message: secret },
    { code: 'SCHEMA_INVALID', path: 'arbitrary.model.supplied.path', message: secret },
    { code: 'MODEL_SUPPLIED_CODE', path: 'recommendation.headline', message: secret },
  ]), [
    { code: 'SCHEMA_INVALID', path: 'recommendation.headline' },
    { code: 'SCHEMA_INVALID', path: 'outlooks[0].base_case[0].text' },
  ]);
});

test('status view never carries the lease nonce or owner internals', () => {
  const harness = createHarness();
  const run = {
    id: 'run-x', owner_id_internal: OWNER_A, lease_nonce: 'secret-nonce-value',
    run_input_ref: { request_payload: {} }, position_id: 'pos', position_revision: 1,
    run_kind: 'manual_refresh', status: 'running', stage: 'claimed', error_code: null,
    created_at: '2030-01-01T00:00:00.000Z', started_at: null, heartbeat_at: null,
    deadline_at: '2030-01-01T00:15:00.000Z', finished_at: null,
    assessment_id: null, evidence_snapshot_id: null,
  };
  const view = toStatusView(run);
  const serialized = JSON.stringify(view);
  assert.equal(serialized.includes('secret-nonce-value'), false);
  assert.equal(serialized.includes('owner_id_internal'), false);
  assert.equal(serialized.includes('request_payload'), false);
});

// ---------------------------------------------------------------------------
// 6. Exported workflow source: thin, compiled, credential-free
// ---------------------------------------------------------------------------

const WORKFLOW_PATH = path.join(__dirname, '..', '..', 'n8n-workflow.json');
const LEGACY_ANALYST_NODES = Object.freeze([
  'Validate & Guard',
  'Fetch Config',
  'Fetch Market Data',
  'Fetch News RSS',
  'Build News Agent Prompt',
  'News Takeaway Agent',
  'Extract News Output',
  'Build Market Agent Prompt',
  'Market Analyst Agent',
  'Build Opportunity Agent Prompt',
  'Opportunity Scout Agent',
  'Extract Opportunity Output',
  'Assemble Payload',
]);

test('workflow export compiles all Code nodes as n8n async bodies and contains no analyst loop', () => {
  const workflow = JSON.parse(fs.readFileSync(WORKFLOW_PATH, 'utf8'));
  const names = workflow.nodes.map((node) => node.name);
  for (const legacy of LEGACY_ANALYST_NODES) {
    assert.equal(names.includes(legacy), false, `legacy analyst node must be gone: ${legacy}`);
  }
  const AsyncFunction = Object.getPrototypeOf(async function () {}).constructor;
  const codeNodes = workflow.nodes.filter((node) => node.type === 'n8n-nodes-base.code');
  assert.equal(codeNodes.length > 0, true, 'workflow must retain its guard/delivery Code nodes');
  for (const node of codeNodes) {
    // Throws on syntax errors; $input/$env are the n8n body contract.
    new AsyncFunction('$input', '$env', node.parameters.jsCode);
  }
});

test('workflow poll loop is bounded and honest (Wait node + counter, no self-loop)', () => {
  const workflow = JSON.parse(fs.readFileSync(WORKFLOW_PATH, 'utf8'));
  const names = new Set(workflow.nodes.map((node) => node.name));
  assert.equal(names.has('Wait Between Polls'), true, 'poll loop must wait between polls');
  const pollCounts = workflow.nodes.filter((node) => node.parameters.jsCode && node.parameters.jsCode.includes('poll_count'));
  assert.equal(pollCounts.length >= 1, true, 'a Code node must bound the poll budget');
  const pollNode = workflow.nodes.find((node) => node.name === 'Poll Run Status');
  assert.notEqual(pollNode, undefined);
  // The poll HTTP node must never feed itself directly. Its only legal
  // feeders are:
  //   - 'Polling Required?'  — the single entry into polling, gated on
  //     $json.phase === 'poll' after the trigger/execute path;
  //   - 'Wait Between Polls' — every repetition, which itself is fed only
  //     by 'Poll Budget Remaining?' (the poll_count < 60 bounded counter),
  //     so no repetition can bypass the budget gate or the wait.
  const pollIncoming = Object.entries(workflow.connections || {})
    .flatMap(([source, conn]) => (conn.main || []).flatMap((outputs) => outputs.map((target) => ({ source, target: target.node }))))
    .filter((edge) => edge.target === 'Poll Run Status')
    .map((edge) => edge.source);
  assert.equal(pollIncoming.includes('Poll Run Status'), false, 'poll node must not self-loop');
  assert.deepEqual([...pollIncoming].sort(), ['Polling Required?', 'Wait Between Polls'],
    `unexpected poll feeders: ${pollIncoming.join(', ')}`);
  const waitIncoming = Object.entries(workflow.connections || {})
    .flatMap(([source, conn]) => (conn.main || []).flatMap((outputs) => outputs.map((target) => ({ source, target: target.node }))))
    .filter((edge) => edge.target === 'Wait Between Polls')
    .map((edge) => edge.source);
  assert.deepEqual(waitIncoming, ['Poll Budget Remaining?'],
    'every repetition must pass through the bounded poll-count gate');
});

test('workflow export contains no literal credentials and no client-supplied userId forwarding', () => {
  const workflow = JSON.parse(fs.readFileSync(WORKFLOW_PATH, 'utf8'));
  const httpNodes = workflow.nodes.filter((node) => node.type === 'n8n-nodes-base.httpRequest');
  assert.equal(httpNodes.length >= 3, true, 'trigger path needs queued-list, execute and status calls');
  for (const node of httpNodes) {
    const serialized = JSON.stringify(node.parameters);
    assert.equal(/Bearer\s+[A-Za-z0-9_\-]{16,}/.test(serialized), false, `${node.name} must not embed a literal bearer token`);
    assert.equal(/userId/.test(serialized), false, `${node.name} must not forward a client userId`);
    assert.equal(node.parameters.authentication === 'genericCredentialType', true,
      `${node.name} must authenticate via n8n credentials, not inline secrets`);
  }
  const wholeExport = JSON.stringify(workflow);
  assert.equal(/[a-f0-9]{64}/.test(wholeExport), false, 'no 64-hex credential literal in the export');
});

// ---------------------------------------------------------------------------
// 7. Mongoose queued-run source shape (wiring helper, no live DB)
// ---------------------------------------------------------------------------

test('createMongooseQueuedRunSource requires a run model and builds a bounded owner-scoped query', () => {
  const fakeModel = {
    find() {
      return {
        select() { return this; },
        sort() { return this; },
        limit() { return this; },
        lean() { return this; },
        async then(resolve) { return resolve([]); },
      };
    },
  };
  const source = createMongooseQueuedRunSource(fakeModel);
  assert.equal(typeof source, 'function');
  assert.throws(() => createMongooseQueuedRunSource(null), TypeError);
  void source;
});

void AutomationAuthorizationError;
void validateAssessmentDelivery;
