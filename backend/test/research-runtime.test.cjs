'use strict';

// H09X — generalized tools, stage replay and recovery tests.
//
// CONTRACTS §8/§9 (held follow-up now released): a server-owned typed tool
// registry (no arbitrary URLs/commands/owner IDs), per-run/stage call and
// response-size budgets enforced in code, scoped stage/tools automation
// endpoints, persisted stage replay that never re-charges a completed call,
// and generalized resumable recovery that preserves immutable references and
// deadlines. Every client is injected; every repository is in-memory. No live
// DB, no network, no model calls, no credentials.

const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const http = require('node:http');
const test = require('node:test');
const express = require('express');

const {
  STAGES,
  STAGE_ORDER,
  TOOLS,
  TOOL_BUDGETS,
  STAGE_CALL_BUDGETS,
  SYNTHESIS_ONLY_TOOLS,
  validateStage,
  validateToolRequest,
  createToolExecutor,
} = require('../src/features/research/tool_registry');
const {
  ResearchService,
} = require('../src/features/research/research.service');
const {
  createAutomationRouter,
} = require('../src/features/research/automation.routes');
const {
  createAutomationMiddleware,
  createRunCallbackAuthorizer,
} = require('../src/middleware/automation.middleware');

const OWNER_A = 'owner-h09x-aaaa';
const OWNER_B = 'owner-h09x-bbbb';
const INSTRUMENT_ID = 'inst-h09x-1';
const SNAPSHOT_ID = 'snapshot-run-h09x-1';

const TOOL_NAMES = Object.freeze([
  'get_market_history',
  'get_market_metrics',
  'get_financial_facts',
  'get_filing_excerpt',
  'get_earnings_context',
  'get_material_news',
  'get_confirmed_events',
  'get_prior_thesis',
  'get_position_context',
  'validate_research_result',
]);

const AUTOMATION_SCOPES = Object.freeze([
  'research:trigger',
  'research:input',
  'research:status',
  'research:execute',
  'research:callback',
  'research:stages',
  'research:tools',
]);

// ---------------------------------------------------------------------------
// Fixtures (synthetic; NOT observed market data)
// ---------------------------------------------------------------------------

function duplicate(code, message) {
  const error = new Error(message || code);
  error.code = code;
  return error;
}

function makeRun(overrides = {}) {
  const now = '2026-10-30T12:00:00.000Z';
  return {
    id: 'run-h09x-1',
    position_id: 'pos-h09x-1',
    owner_id_internal: OWNER_A,
    position_revision: 7,
    run_kind: 'deep_research',
    request_class: 'deep_research',
    idempotency_key: 'key-h09x-1',
    payload_digest: 'a'.repeat(64),
    status: 'running',
    stage: 'claimed',
    created_at: now,
    started_at: now,
    heartbeat_at: now,
    deadline_at: '2026-10-30T12:30:00.000Z',
    finished_at: null,
    evidence_snapshot_id: null,
    assessment_id: null,
    error_code: null,
    retry_count: 0,
    lease_nonce: 'deadbeef'.repeat(8),
    lease_expires_at: '2026-10-30T12:05:00.000Z',
    input_snapshot_id: SNAPSHOT_ID,
    run_input_ref: {
      payload_digest: 'a'.repeat(64),
      instrument_id: INSTRUMENT_ID,
      position_revision: 7,
      run_kind: 'deep_research',
      request_payload: { trigger: 'fixture' },
      snapshot_id: SNAPSHOT_ID,
    },
    run_result_ref: null,
    versions: { contract_version: '1', service: 'h08-research-state' },
    ...overrides,
  };
}

function createInMemoryRunRepository(initial = []) {
  const records = initial.map((run) => structuredClone(run));
  return {
    records,
    async findById(runId) {
      return structuredClone(records.find((run) => run.id === runId)) || null;
    },
    async updateIfStatus(runId, expectedStatuses, patch) {
      const index = records.findIndex((run) => run.id === runId);
      if (index === -1 || !expectedStatuses.includes(records[index].status)) return null;
      records[index] = { ...records[index], ...structuredClone(patch) };
      return structuredClone(records[index]);
    },
    async claimQueued(runId, patch) {
      const index = records.findIndex((run) => run.id === runId);
      if (index === -1 || records[index].status !== 'queued') return null;
      records[index] = { ...records[index], ...structuredClone(patch) };
      return structuredClone(records[index]);
    },
    async create(run) {
      if (records.some((entry) => entry.id === run.id)) throw duplicate('DUPLICATE_RUN');
      records.push(structuredClone(run));
      return structuredClone(run);
    },
    async findByIdempotency(ownerId, positionId, idempotencyKey) {
      return structuredClone(records.find((run) => run.owner_id_internal === ownerId
        && run.position_id === positionId
        && run.idempotency_key === idempotencyKey)) || null;
    },
    async findActive() { return null; },
    async supersedeStale() { return 0; },
    async findExpired(nowIso) {
      return structuredClone(records.filter((run) => (run.status === 'queued' || run.status === 'running')
        && run.deadline_at <= nowIso));
    },
    async findLatestAttempt() { return null; },
    async findLatestSuccess() { return null; },
  };
}

function stubAssessmentRepo() {
  return { async create() {}, async findById() { return null; }, async findByRunId() { return null; }, async latestForPosition() { return null; }, async listByPosition() { return { assessments: [], next_cursor: null }; } };
}
function stubSnapshotRepo() {
  return { async create() {}, async findById() { return null; } };
}
function stubCheckpointRepo() {
  return { async update() {}, async create() {}, async findById() { return null; }, async listByInstrument() { return []; } };
}

function createService(runRepository, overrides = {}) {
  return new ResearchService({
    runRepository,
    assessmentRepository: stubAssessmentRepo(),
    researchSnapshotRepository: stubSnapshotRepo(),
    checkpointRepository: stubCheckpointRepo(),
    evidenceSnapshotLookup: async () => ({
      snapshot_id: SNAPSHOT_ID,
      instrument_id: INSTRUMENT_ID,
    }),
    now: () => new Date('2026-10-30T12:00:00.000Z'),
    ...overrides,
  });
}

// ---------------------------------------------------------------------------
// HTTP harness
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
  try { body = await response.json(); } catch { body = null; }
  return { status: response.status, body };
}

function createHarness({ runRepo = createInMemoryRunRepository([makeRun()]), toolExecutor = null, resolveToolContext = null, token = crypto.randomBytes(32).toString('hex'), scopes = AUTOMATION_SCOPES, ownerId = OWNER_A } = {}) {
  const service = createService(runRepo);
  const middleware = createAutomationMiddleware({ token, scopes, ownerId, maxBodyBytes: 64 * 1024 });
  const callbackAuthorizer = createRunCallbackAuthorizer({ now: () => new Date('2026-10-30T12:00:00.000Z') });
  const queuedRunSource = async () => [];
  const router = createAutomationRouter({
    researchService: service,
    runWorker: { startRun: async () => { throw duplicate('UNUSED'); }, whenSettled: async () => { throw duplicate('UNUSED'); } },
    runs: runRepo,
    automationMiddleware: middleware,
    callbackAuthorizer,
    listQueuedRuns: queuedRunSource,
    now: () => new Date('2026-10-30T12:00:00.000Z'),
    toolExecutor,
    resolveToolContext,
  });
  const mounted = express();
  mounted.use('/research', router);
  return { service, runRepo, token, router: mounted };
}

function authorizedHeaders(token, extra = {}) {
  return {
    authorization: `Bearer ${token}`,
    'content-type': 'application/json',
    ...extra,
  };
}

// ---------------------------------------------------------------------------
// 1. Typed tool registry
// ---------------------------------------------------------------------------

test('registry exposes exactly the ten typed tool names from SPEC §4', () => {
  const names = Object.keys(TOOLS).sort();
  assert.deepEqual(names, [...TOOL_NAMES].sort());
});

test('stage enum is frozen and matches the contract stage vocabulary', () => {
  assert.deepEqual(STAGES, ['evidence', 'analyst', 'synthesis', 'reviewer', 'delivery']);
  assert.equal(Object.isFrozen(STAGES), true);
  assert.deepEqual(Object.keys(STAGE_ORDER).sort(), [...STAGES].sort());
});

test('per-stage tool allowlists match the SPEC §4 table', () => {
  assert.deepEqual([...TOOLS.get_market_history.allowed_stages].sort(), ['analyst', 'evidence']);
  assert.deepEqual(TOOLS.get_market_metrics.allowed_stages, ['analyst']);
  assert.deepEqual([...TOOLS.get_financial_facts.allowed_stages].sort(), ['analyst', 'evidence']);
  assert.deepEqual(TOOLS.get_filing_excerpt.allowed_stages, ['analyst']);
  assert.deepEqual(TOOLS.get_earnings_context.allowed_stages, ['analyst']);
  assert.deepEqual([...TOOLS.get_material_news.allowed_stages].sort(), ['analyst', 'evidence']);
  assert.deepEqual(TOOLS.get_confirmed_events.allowed_stages, ['analyst']);
  assert.deepEqual([...TOOLS.get_prior_thesis.allowed_stages].sort(), ['analyst', 'synthesis']);
  assert.deepEqual(TOOLS.get_position_context.allowed_stages, ['synthesis']);
  assert.deepEqual([...TOOLS.validate_research_result.allowed_stages].sort(), ['delivery', 'reviewer']);
});

test('get_position_context is synthesis-only; validate_research_result is reviewer/delivery-only', () => {
  assert.deepEqual(SYNTHESIS_ONLY_TOOLS, ['get_position_context']);
  assert.equal(TOOLS.get_position_context.synthesis_only, true);
  assert.equal(TOOLS.validate_research_result.synthesis_only, false);
  assert.equal(TOOLS.get_market_history.synthesis_only, false);
});

test('budgets are named frozen constants with the contract defaults', () => {
  assert.equal(Object.isFrozen(TOOL_BUDGETS), true);
  assert.equal(TOOL_BUDGETS.ANALYST_MAX_READ_CALLS, 8);
  assert.equal(TOOL_BUDGETS.ANALYST_MAX_RETRIEVAL_PASSES, 1);
  assert.equal(TOOL_BUDGETS.SYNTHESIS_MAX_POSITION_READS, 1);
  assert.equal(TOOL_BUDGETS.REVIEWER_MAX_WEB_TOOLS, 0);
  assert.ok(TOOL_BUDGETS.MAX_TOOL_RESULT_BYTES > 0);
  assert.equal(Object.isFrozen(STAGE_CALL_BUDGETS), true);
  assert.equal(STAGE_CALL_BUDGETS.analyst, 8);
  assert.equal(STAGE_CALL_BUDGETS.synthesis, 1);
});

test('validateToolRequest accepts a well-formed analyst read', () => {
  const verdict = validateToolRequest({
    tool_name: 'get_market_metrics',
    arguments: { metric_ids: ['metric-1', 'metric-2'] },
    stage: 'analyst',
    request_id: 'req-1',
  });
  assert.equal(verdict.ok, true);
  assert.equal(verdict.tool.name, 'get_market_metrics');
  assert.equal(verdict.stage, 'analyst');
});

test('validateToolRequest rejects an unknown tool name', () => {
  const verdict = validateToolRequest({
    tool_name: 'run_shell_command',
    arguments: {},
    stage: 'analyst',
    request_id: 'req-1',
  });
  assert.equal(verdict.ok, false);
  assert.equal(verdict.issue_code, 'UNKNOWN_TOOL');
});

test('validateToolRequest rejects a non-enum stage', () => {
  const verdict = validateToolRequest({
    tool_name: 'get_market_history',
    arguments: {},
    stage: 'arbitrary_code',
    request_id: 'req-1',
  });
  assert.equal(verdict.ok, false);
  assert.equal(verdict.issue_code, 'INVALID_STAGE');
});

test('validateToolRequest rejects a tool invoked outside its allowed stage', () => {
  const verdict = validateToolRequest({
    tool_name: 'get_market_metrics',
    arguments: {},
    stage: 'synthesis',
    request_id: 'req-1',
  });
  assert.equal(verdict.ok, false);
  assert.equal(verdict.issue_code, 'TOOL_NOT_ALLOWED_IN_STAGE');
});

test('validateToolRequest rejects a synthesis-only tool from the analyst stage', () => {
  const verdict = validateToolRequest({
    tool_name: 'get_position_context',
    arguments: {},
    stage: 'analyst',
    request_id: 'req-1',
  });
  assert.equal(verdict.ok, false);
  assert.equal(verdict.issue_code, 'SYNTHESIS_ONLY_STAGE');
});

test('validateToolRequest rejects owner/url/command keys at the request top level', () => {
  for (const key of ['owner_id', 'url', 'command', 'code', 'sql']) {
    const verdict = validateToolRequest({
      tool_name: 'get_market_history',
      arguments: {},
      stage: 'evidence',
      request_id: 'req-1',
      [key]: 'attacker-controlled',
    });
    assert.equal(verdict.ok, false, `expected ${key} to be rejected`);
    assert.equal(verdict.issue_code, 'UNEXPECTED_FIELD');
  }
});

test('validateToolRequest rejects forbidden argument keys (owner_id/url/command/code/sql)', () => {
  for (const key of ['owner_id', 'user_id', 'url', 'command', 'code', 'sql', 'path', 'token']) {
    const verdict = validateToolRequest({
      tool_name: 'get_market_history',
      arguments: { [key]: 'attacker-controlled' },
      stage: 'evidence',
      request_id: 'req-1',
    });
    assert.equal(verdict.ok, false, `expected argument key ${key} to be rejected`);
    assert.equal(verdict.issue_code, 'FORBIDDEN_ARGUMENT');
  }
});

test('validateToolRequest rejects non-object arguments and a missing request_id', () => {
  assert.equal(validateToolRequest({ tool_name: 'get_market_history', arguments: 'nope', stage: 'evidence', request_id: 'r' }).ok, false);
  assert.equal(validateToolRequest({ tool_name: 'get_market_history', arguments: {}, stage: 'evidence' }).ok, false);
  const oversized = validateToolRequest({ tool_name: 'get_market_history', arguments: {}, stage: 'evidence', request_id: 'x'.repeat(200) });
  assert.equal(oversized.ok, false);
  assert.equal(oversized.issue_code, 'INVALID_REQUEST_ID');
});

test('validateStage is strict about the enum', () => {
  assert.equal(validateStage('analyst'), true);
  assert.equal(validateStage('evidence'), true);
  assert.equal(validateStage('claimed'), false);
  assert.equal(validateStage(''), false);
  assert.equal(validateStage(null), false);
});

// ---------------------------------------------------------------------------
// 2. Tool executor budgets (response size, call budget, idempotent retry)
// ---------------------------------------------------------------------------

function makeExecutor(overrides = {}) {
  const resolvers = {
    get_market_history: async () => ({ bars: [{ close: 100 }] }),
    get_market_metrics: async () => ({ metrics: [{ metric_id: 'metric-1', value: 3 }] }),
    get_position_context: async () => ({ position_id: 'pos-h09x-1', state: 'owned' }),
    ...overrides.resolvers,
  };
  return createToolExecutor({ resolvers, ...overrides.executor });
}

test('executor resolves a tool and reports response bytes and call count', async () => {
  const executor = makeExecutor();
  const outcome = await executor.execute({
    run_id: 'run-h09x-1',
    stage: 'evidence',
    tool: TOOLS.get_market_history,
    arguments: {},
    request_id: 'req-1',
    boundContext: { instrument_id: INSTRUMENT_ID, snapshot_id: SNAPSHOT_ID, cutoff_at: '2026-10-30T00:00:00.000Z' },
  });
  assert.equal(outcome.ok, true);
  assert.equal(outcome.tool_name, 'get_market_history');
  assert.equal(outcome.call_count, 1);
  assert.ok(outcome.response_bytes > 0);
  assert.equal(typeof outcome.result, 'object');
});

test('executor enforces the per-stage call budget and records exhaustion', async () => {
  const executor = makeExecutor({ executor: { callBudgets: { evidence: 1 } } });
  const base = { run_id: 'run-h09x-1', stage: 'evidence', tool: TOOLS.get_market_history, arguments: {}, boundContext: {} };
  const first = await executor.execute({ ...base, request_id: 'req-a' });
  assert.equal(first.ok, true);
  const second = await executor.execute({ ...base, request_id: 'req-b' });
  assert.equal(second.ok, false);
  assert.equal(second.code, 'CALL_BUDGET_EXHAUSTED');
  assert.equal(second.status, 429);
});

test('executor enforces the response-size budget', async () => {
  const executor = makeExecutor({
    executor: { responseSizeLimit: 16 },
    resolvers: { get_market_history: async () => ({ huge: 'x'.repeat(512) }) },
  });
  const outcome = await executor.execute({
    run_id: 'run-h09x-1', stage: 'evidence', tool: TOOLS.get_market_history, arguments: {}, request_id: 'req-1', boundContext: {},
  });
  assert.equal(outcome.ok, false);
  assert.equal(outcome.code, 'RESPONSE_TOO_LARGE');
});

test('executor replays an identical request_id without re-charging the call budget', async () => {
  const executor = makeExecutor({ executor: { callBudgets: { evidence: 1 } } });
  const base = { run_id: 'run-h09x-1', stage: 'evidence', tool: TOOLS.get_market_history, arguments: {}, boundContext: {} };
  const first = await executor.execute({ ...base, request_id: 'req-same' });
  assert.equal(first.ok, true);
  const replay = await executor.execute({ ...base, request_id: 'req-same' });
  assert.equal(replay.ok, true);
  assert.equal(replay.call_count, 1, 'idempotent retry must not count as a new call');
});

test('executor fails closed on an unregistered tool resolver', async () => {
  const executor = makeExecutor();
  const outcome = await executor.execute({
    run_id: 'run-h09x-1', stage: 'reviewer', tool: TOOLS.validate_research_result, arguments: { result: {} }, request_id: 'req-1', boundContext: {},
  });
  assert.equal(outcome.ok, false);
  assert.equal(outcome.code, 'TOOL_NOT_REGISTERED');
});

// ---------------------------------------------------------------------------
// 3. Persisted stage replay and generalized recovery (service)
// ---------------------------------------------------------------------------

test('advanceStage persists the artifact; replayStage returns it idempotently', async () => {
  const repo = createInMemoryRunRepository([makeRun()]);
  const service = createService(repo);
  const artifact = { metric_ids: ['metric-1'], cutoff: '2026-10-30T00:00:00.000Z' };
  const advanced = await service.advanceStage({ run_id: 'run-h09x-1', stage: 'analyst', artifact });
  assert.equal(advanced.replayed, false);
  assert.equal(advanced.stage, 'analyst');
  assert.deepEqual(advanced.artifact, artifact);

  const replay = await service.replayStage({ run_id: 'run-h09x-1', stage: 'analyst' });
  assert.equal(replay.replayed, true);
  assert.deepEqual(replay.artifact, artifact);
  assert.equal(typeof replay.recorded_at, 'string');
});

test('advanceStage is idempotent for an identical artifact and conflicts for a different one', async () => {
  const repo = createInMemoryRunRepository([makeRun()]);
  const service = createService(repo);
  const artifact = { metric_ids: ['metric-1'] };
  await service.advanceStage({ run_id: 'run-h09x-1', stage: 'analyst', artifact });
  const again = await service.advanceStage({ run_id: 'run-h09x-1', stage: 'analyst', artifact });
  assert.equal(again.replayed, true);

  await assert.rejects(
    service.advanceStage({ run_id: 'run-h09x-1', stage: 'analyst', artifact: { metric_ids: ['different'] } }),
    (error) => error.code === 'STAGE_REPLAY_CONFLICT',
  );
});

test('advanceStage rejects a backward stage transition', async () => {
  const repo = createInMemoryRunRepository([makeRun()]);
  const service = createService(repo);
  await service.advanceStage({ run_id: 'run-h09x-1', stage: 'synthesis', artifact: { a: 1 } });
  await assert.rejects(
    service.advanceStage({ run_id: 'run-h09x-1', stage: 'analyst', artifact: { a: 2 } }),
    (error) => error.code === 'STAGE_OUT_OF_ORDER',
  );
});

test('advanceStage rejects a non-running run, an invalid stage, and a bad artifact', async () => {
  const repo = createInMemoryRunRepository([makeRun({ status: 'queued' })]);
  const service = createService(repo);
  await assert.rejects(
    service.advanceStage({ run_id: 'run-h09x-1', stage: 'analyst', artifact: {} }),
    (error) => error.code === 'INVALID_RUN_TRANSITION',
  );

  const running = createService(createInMemoryRunRepository([makeRun()]));
  await assert.rejects(
    running.advanceStage({ run_id: 'run-h09x-1', stage: 'claimed', artifact: {} }),
    (error) => error.code === 'INVALID_STAGE',
  );
  await assert.rejects(
    running.advanceStage({ run_id: 'run-h09x-1', stage: 'analyst', artifact: 'not-an-object' }),
    (error) => error.code === 'INVALID_STAGE_ARTIFACT',
  );
});

test('advanceStage fails closed past the run deadline', async () => {
  const repo = createInMemoryRunRepository([makeRun({ deadline_at: '2026-10-30T11:00:00.000Z' })]);
  const service = createService(repo);
  await assert.rejects(
    service.advanceStage({ run_id: 'run-h09x-1', stage: 'analyst', artifact: {} }),
    (error) => error.code === 'RUN_DEADLINE_EXCEEDED',
  );
});

test('recoverIncompleteRun preserves immutable references and deadlines without re-execution', async () => {
  const repo = createInMemoryRunRepository([makeRun()]);
  const service = createService(repo);
  await service.advanceStage({ run_id: 'run-h09x-1', stage: 'evidence', artifact: { evidence_ids: ['ev-1'] } });

  const before = await repo.findById('run-h09x-1');
  const recovered = await service.recoverIncompleteRun({ run_id: 'run-h09x-1' });
  assert.equal(recovered.resumable, true);
  assert.equal(recovered.last_stage, 'evidence');
  assert.deepEqual(recovered.stage_artifacts.evidence.artifact, { evidence_ids: ['ev-1'] });

  // Immutable references and deadlines are byte-identical after recovery.
  assert.equal(recovered.immutable.input_snapshot_id, before.input_snapshot_id);
  assert.equal(recovered.immutable.deadline_at, before.deadline_at);
  assert.equal(recovered.immutable.position_revision, before.position_revision);
  assert.deepEqual(recovered.immutable.run_input_ref, before.run_input_ref);

  const after = await repo.findById('run-h09x-1');
  assert.equal(after.input_snapshot_id, before.input_snapshot_id, 'recovery must not mutate immutable references');
  assert.equal(after.deadline_at, before.deadline_at);
});

test('recoverIncompleteRun marks an expired running run as stalled (not resumable)', async () => {
  const repo = createInMemoryRunRepository([makeRun({ deadline_at: '2026-10-30T11:00:00.000Z' })]);
  const service = createService(repo);
  const recovered = await service.recoverIncompleteRun({ run_id: 'run-h09x-1' });
  assert.equal(recovered.resumable, false);
  const refreshed = await repo.findById('run-h09x-1');
  assert.equal(refreshed.status, 'stalled');
});

// ---------------------------------------------------------------------------
// 4. Scoped stage endpoint (router)
// ---------------------------------------------------------------------------

test('POST /runs/:runId/stages/:stage records a validated artifact and replays it', async () => {
  const runRepo = createInMemoryRunRepository([makeRun()]);
  const harness = createHarness({ runRepo });
  const headers = authorizedHeaders(harness.token, {
    'x-horizon-run-id': 'run-h09x-1',
    'x-horizon-run-nonce': 'deadbeef'.repeat(8),
  });
  await withServer(harness.router, async (baseUrl) => {
    const first = await request(baseUrl, '/research/runs/run-h09x-1/stages/analyst', {
      method: 'POST', headers, body: JSON.stringify({ artifact: { metric_ids: ['metric-1'] } }),
    });
    assert.equal(first.status, 200);
    assert.equal(first.body.replayed, false);
    assert.equal(first.body.stage, 'analyst');

    const replay = await request(baseUrl, '/research/runs/run-h09x-1/stages/analyst', {
      method: 'POST', headers, body: JSON.stringify({ artifact: { metric_ids: ['metric-1'] } }),
    });
    assert.equal(replay.status, 200);
    assert.equal(replay.body.replayed, true);
    assert.deepEqual(replay.body.artifact, { metric_ids: ['metric-1'] });
  });
});

test('stage endpoint returns 404 for a cross-owner run', async () => {
  const harness = createHarness({ ownerId: OWNER_B });
  const headers = authorizedHeaders(harness.token, {
    'x-horizon-run-id': 'run-h09x-1',
    'x-horizon-run-nonce': 'deadbeef'.repeat(8),
  });
  await withServer(harness.router, async (baseUrl) => {
    const response = await request(baseUrl, '/research/runs/run-h09x-1/stages/analyst', {
      method: 'POST', headers, body: JSON.stringify({ artifact: {} }),
    });
    assert.equal(response.status, 404);
  });
});

test('stage endpoint rejects a wrong lease nonce', async () => {
  const harness = createHarness();
  const headers = authorizedHeaders(harness.token, {
    'x-horizon-run-id': 'run-h09x-1',
    'x-horizon-run-nonce': '0'.repeat(64),
  });
  await withServer(harness.router, async (baseUrl) => {
    const response = await request(baseUrl, '/research/runs/run-h09x-1/stages/analyst', {
      method: 'POST', headers, body: JSON.stringify({ artifact: {} }),
    });
    assert.equal(response.status, 403);
  });
});

test('stage endpoint enforces the research:stages scope', async () => {
  const harness = createHarness({ scopes: AUTOMATION_SCOPES.filter((s) => s !== 'research:stages') });
  const headers = authorizedHeaders(harness.token, {
    'x-horizon-run-id': 'run-h09x-1',
    'x-horizon-run-nonce': 'deadbeef'.repeat(8),
  });
  await withServer(harness.router, async (baseUrl) => {
    const response = await request(baseUrl, '/research/runs/run-h09x-1/stages/analyst', {
      method: 'POST', headers, body: JSON.stringify({ artifact: {} }),
    });
    assert.equal(response.status, 403);
  });
});

// ---------------------------------------------------------------------------
// 5. Scoped tools endpoint (router)
// ---------------------------------------------------------------------------

function makeRouterHarness({ runRepo = createInMemoryRunRepository([makeRun()]), executorOverrides = {} } = {}) {
  const executor = makeExecutor(executorOverrides);
  const resolveToolContext = async () => ({
    instrument_id: INSTRUMENT_ID,
    snapshot_id: SNAPSHOT_ID,
    position_id: 'pos-h09x-1',
    position_revision: 7,
    owner_id_internal: OWNER_A,
    cutoff_at: '2026-10-30T00:00:00.000Z',
    session_as_of: '2026-10-29',
  });
  return { executor, ...createHarness({ runRepo, toolExecutor: executor, resolveToolContext }) };
}

test('POST /runs/:runId/tools returns a bounded read result', async () => {
  const { router, token } = makeRouterHarness();
  const headers = authorizedHeaders(token, {
    'x-horizon-run-id': 'run-h09x-1',
    'x-horizon-run-nonce': 'deadbeef'.repeat(8),
  });
  await withServer(router, async (baseUrl) => {
    const response = await request(baseUrl, '/research/runs/run-h09x-1/tools', {
      method: 'POST', headers,
      body: JSON.stringify({ tool_name: 'get_market_history', arguments: {}, stage: 'evidence', request_id: 'req-1' }),
    });
    assert.equal(response.status, 200);
    assert.equal(response.body.tool_name, 'get_market_history');
    assert.equal(response.body.call_count, 1);
    assert.ok(response.body.response_bytes > 0);
    assert.equal(typeof response.body.result, 'object');
  });
});

test('tools endpoint rejects an unknown tool with 400', async () => {
  const { router, token } = makeRouterHarness();
  const headers = authorizedHeaders(token, {
    'x-horizon-run-id': 'run-h09x-1',
    'x-horizon-run-nonce': 'deadbeef'.repeat(8),
  });
  await withServer(router, async (baseUrl) => {
    const response = await request(baseUrl, '/research/runs/run-h09x-1/tools', {
      method: 'POST', headers,
      body: JSON.stringify({ tool_name: 'cat_etc_passwd', arguments: {}, stage: 'evidence', request_id: 'req-1' }),
    });
    assert.equal(response.status, 400);
  });
});

test('tools endpoint rejects a synthesis-only tool from the analyst stage with 403', async () => {
  const { router, token } = makeRouterHarness();
  const headers = authorizedHeaders(token, {
    'x-horizon-run-id': 'run-h09x-1',
    'x-horizon-run-nonce': 'deadbeef'.repeat(8),
  });
  await withServer(router, async (baseUrl) => {
    const response = await request(baseUrl, '/research/runs/run-h09x-1/tools', {
      method: 'POST', headers,
      body: JSON.stringify({ tool_name: 'get_position_context', arguments: {}, stage: 'analyst', request_id: 'req-1' }),
    });
    assert.equal(response.status, 403);
  });
});

test('tools endpoint rejects owner_id supplied in arguments with 400', async () => {
  const { router, token } = makeRouterHarness();
  const headers = authorizedHeaders(token, {
    'x-horizon-run-id': 'run-h09x-1',
    'x-horizon-run-nonce': 'deadbeef'.repeat(8),
  });
  await withServer(router, async (baseUrl) => {
    const response = await request(baseUrl, '/research/runs/run-h09x-1/tools', {
      method: 'POST', headers,
      body: JSON.stringify({ tool_name: 'get_market_history', arguments: { owner_id: 'attacker' }, stage: 'evidence', request_id: 'req-1' }),
    });
    assert.equal(response.status, 400);
  });
});

test('tools endpoint returns 429 when the stage call budget is exhausted', async () => {
  const { router, token } = makeRouterHarness({ executorOverrides: { executor: { callBudgets: { evidence: 1 } } } });
  const headers = authorizedHeaders(token, {
    'x-horizon-run-id': 'run-h09x-1',
    'x-horizon-run-nonce': 'deadbeef'.repeat(8),
  });
  await withServer(router, async (baseUrl) => {
    const first = await request(baseUrl, '/research/runs/run-h09x-1/tools', {
      method: 'POST', headers,
      body: JSON.stringify({ tool_name: 'get_market_history', arguments: {}, stage: 'evidence', request_id: 'req-a' }),
    });
    assert.equal(first.status, 200);
    const second = await request(baseUrl, '/research/runs/run-h09x-1/tools', {
      method: 'POST', headers,
      body: JSON.stringify({ tool_name: 'get_market_history', arguments: {}, stage: 'evidence', request_id: 'req-b' }),
    });
    assert.equal(second.status, 429);
  });
});

test('tools endpoint fails closed (503) when no tool runtime is configured', async () => {
  const harness = createHarness(); // no toolExecutor / resolveToolContext
  const headers = authorizedHeaders(harness.token, {
    'x-horizon-run-id': 'run-h09x-1',
    'x-horizon-run-nonce': 'deadbeef'.repeat(8),
  });
  await withServer(harness.router, async (baseUrl) => {
    const response = await request(baseUrl, '/research/runs/run-h09x-1/tools', {
      method: 'POST', headers,
      body: JSON.stringify({ tool_name: 'get_market_history', arguments: {}, stage: 'evidence', request_id: 'req-1' }),
    });
    assert.equal(response.status, 503);
  });
});

test('tools endpoint rejects an expired run lease with 409', async () => {
  const runRepo = createInMemoryRunRepository([makeRun({ lease_expires_at: '2026-10-30T11:00:00.000Z' })]);
  const { router, token } = makeRouterHarness({ runRepo });
  const headers = authorizedHeaders(token, {
    'x-horizon-run-id': 'run-h09x-1',
    'x-horizon-run-nonce': 'deadbeef'.repeat(8),
  });
  await withServer(router, async (baseUrl) => {
    const response = await request(baseUrl, '/research/runs/run-h09x-1/tools', {
      method: 'POST', headers,
      body: JSON.stringify({ tool_name: 'get_market_history', arguments: {}, stage: 'evidence', request_id: 'req-1' }),
    });
    assert.equal(response.status, 409);
  });
});
