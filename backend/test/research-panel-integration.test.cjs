'use strict';

// H15B — early position and research panel integration (backend slice).
//
// Exercises the ACTUAL application routing (backend/src/app.js) after the
// H15A accepted handoff: owner-scoped /positions and /research routers are
// mounted alongside the protected observed-history market route, with the
// 1 MiB transport parser and route-free /webhook preserved.
//
// Fixtures are hermetic in-memory repositories (no MongoDB, no network, no
// scheduler). Shapes are copied from backend/test/positions.test.cjs and
// backend/test/research-state.test.cjs so the same wire shapes are exercised.
//
// Wire reconciliation (controller release constraint, H14 review finding 5):
// the run wire deliberately RETAINS owner_id_internal (research.routes.js
// toPublicRunView strips only lease_nonce) because H11's ResearchRun.fromJson
// requires it; assessment views strip owner_id_internal. Both facts are
// asserted here against the real HTTP responses, never assumed.

const assert = require('node:assert/strict');
const http = require('node:http');
const test = require('node:test');

const { createApp } = require('../src/app');
const { PositionService } = require('../src/features/positions/position.service');
const { ResearchService } = require('../src/features/research/research.service');
const { createMarketRouter } = require('../src/features/market/market.routes');
const { MarketHistoryService } = require('../src/features/market/market.service');

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

const OWNER_A = 'owner-h15b-aaaa';
const OWNER_B = 'owner-h15b-bbbb';
const INSTRUMENT_ID = 'instrument-h15b-1';

const CANDIDATE_INPUT = Object.freeze({
  state: 'candidate',
  instrument: {
    instrument_id: INSTRUMENT_ID,
    symbol: 'NVDA',
    exchange: 'NASDAQ',
    currency: 'USD',
    provider_symbol: 'NVDA',
  },
  review_conditions: ['Enters below 90 on rising volume'],
});

const OWNED_CHANGES = Object.freeze({
  state: 'owned',
  average_cost: { amount: '310.50', currency: 'USD' },
  quantity: '10',
  opened_on: '2026-01-15',
});

function makePositionRepository(seed = []) {
  const docs = new Map();
  let nextId = 1;
  for (const doc of seed) {
    const id = doc.id || `pos-${nextId++}`;
    docs.set(id, {
      revision: 1,
      archived: false,
      owner_id: OWNER_A,
      preferred_horizon_months: 3,
      original_thesis: '',
      review_conditions: [],
      risk_context: null,
      created_at: new Date(Date.UTC(2026, 9, 31, 11, 0, nextId)).toISOString(),
      updated_at: new Date(Date.UTC(2026, 9, 31, 11, 0, nextId)).toISOString(),
      ...structuredClone(doc),
      id,
    });
  }
  return {
    docs,
    async findActive(ownerId, instrumentId) {
      for (const doc of docs.values()) {
        if (doc.owner_id === ownerId && doc.instrument.instrument_id === instrumentId && !doc.archived) {
          return structuredClone(doc);
        }
      }
      return null;
    },
    async listByOwner(ownerId) {
      return [...docs.values()]
        .filter((d) => d.owner_id === ownerId)
        .sort((a, b) => a.created_at.localeCompare(b.created_at))
        .map((d) => structuredClone(d));
    },
    async findById(id) {
      return docs.has(id) ? structuredClone(docs.get(id)) : null;
    },
    async insert(doc) {
      docs.set(doc.id, structuredClone(doc));
      return structuredClone(doc);
    },
    async update(doc) {
      docs.set(doc.id, structuredClone(doc));
      return structuredClone(doc);
    },
  };
}

function makeRunRepository(initial = []) {
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

function makeAssessmentRepository(initial = []) {
  const records = [...initial];
  const clone = (value) => structuredClone(value);
  return {
    records,
    async create(assessment) {
      records.push(clone(assessment));
      return clone(assessment);
    },
    async findById(id) {
      return clone(records.find((entry) => entry.id === id)) || null;
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
      const next = candidates.length > limit
        ? `${page[page.length - 1].generated_at}|${page[page.length - 1].id}` : null;
      return { assessments: clone(page), next_cursor: next };
    },
  };
}

function makeSnapshotRepository() {
  const records = [];
  return {
    records,
    async latestForCacheKey(cacheKey) {
      return records.filter((entry) => entry.cache_key === cacheKey).at(-1) || null;
    },
    async create(snapshot) {
      records.push(structuredClone(snapshot));
      return structuredClone(snapshot);
    },
    async findById(id) {
      return structuredClone(records.find((entry) => entry.snapshot_id === id)) || null;
    },
  };
}

function makeCheckpointRepository() {
  const records = [];
  const clone = (value) => structuredClone(value);
  return {
    records,
    async create(checkpoint) {
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

let clockIso = '2030-01-01T00:00:00.000Z';
function advanceClock(seconds) {
  clockIso = new Date(new Date(clockIso).getTime() + seconds * 1000).toISOString();
}

function makeServices() {
  const positionService = new PositionService({
    positionRepository: makePositionRepository(),
    now: () => new Date(clockIso),
  });
  const runRepository = makeRunRepository();
  const assessmentRepository = makeAssessmentRepository();
  const researchService = new ResearchService({
    runRepository,
    assessmentRepository,
    researchSnapshotRepository: makeSnapshotRepository(),
    checkpointRepository: makeCheckpointRepository(),
    evidenceSnapshotLookup: async (snapshotId) => (
      snapshotId === 'snapshot-evidence-h15b-1'
        ? { snapshot_id: snapshotId, instrument_id: INSTRUMENT_ID }
        : null
    ),
    now: () => new Date(clockIso),
  });
  return { positionService, researchService, runRepository, assessmentRepository };
}

// Two-owner auth: each bearer token maps to a distinct owner id.
function makeAuth() {
  return function authenticate(req, res, next) {
    const header = req.headers.authorization;
    if (!header || !header.startsWith('Bearer ')) {
      return res.status(401).json({ message: 'Not authorized, no token provided' });
    }
    const token = header.slice(7).trim();
    if (token === 'token-owner-a') {
      req.user = { _id: OWNER_A };
      return next();
    }
    if (token === 'token-owner-b') {
      req.user = { _id: OWNER_B };
      return next();
    }
    return res.status(401).json({ message: 'Not authorized, token failed' });
  };
}

function makeApp(services = makeServices()) {
  const app = createApp({
    positionService: services.positionService,
    researchService: services.researchService,
    authenticate: makeAuth(),
    logging: false,
  });
  return { app, services };
}

async function withTestServer(app, fn) {
  const server = http.createServer(app);
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  try {
    const { port } = server.address();
    await fn(`http://127.0.0.1:${port}`);
  } finally {
    await new Promise((resolve, reject) => server.close((err) => (err ? reject(err) : resolve())));
  }
}

async function api(baseUrl, method, path, { token = 'token-owner-a', body, headers = {} } = {}) {
  const res = await fetch(`${baseUrl}${path}`, {
    method,
    headers: {
      ...(token ? { authorization: `Bearer ${token}` } : {}),
      ...(body !== undefined ? { 'content-type': 'application/json' } : {}),
      ...headers,
    },
    ...(body !== undefined ? { body: JSON.stringify(body) } : {}),
  });
  const text = await res.text();
  let parsed = null;
  try {
    parsed = JSON.parse(text);
  } catch {
    parsed = text;
  }
  return { status: res.status, body: parsed };
}

async function createCandidate(baseUrl, overrides = {}) {
  const res = await api(baseUrl, 'POST', '/api/v1/positions', {
    body: { ...structuredClone(CANDIDATE_INPUT), ...overrides },
  });
  assert.equal(res.status, 201, `candidate create failed: ${JSON.stringify(res.body)}`);
  return res.body;
}

async function queueAndDeliverSuccess(baseUrl, positionId, {
  revision = 1,
  keyPrefix = 'key-h15b',
} = {}) {
  advanceClock(60);
  const queued = await api(baseUrl, 'POST', `/api/v1/research/positions/${positionId}/runs`, {
    body: {
      position_revision: revision,
      run_kind: 'manual_refresh',
      instrument_id: INSTRUMENT_ID,
      request_payload: { trigger: 'fixture' },
    },
    headers: { 'idempotency-key': `${keyPrefix}-${positionId}-${revision}` },
  });
  assert.equal(queued.status, 202, `queue failed: ${JSON.stringify(queued.body)}`);
  return queued.body.run;
}

// ---------------------------------------------------------------------------
// Mount and preserved invariants
// ---------------------------------------------------------------------------

test('H15B: owner-scoped positions and research routes are reachable through real application routing', async () => {
  const { app } = makeApp();
  await withTestServer(app, async (baseUrl) => {
    const listed = await api(baseUrl, 'GET', '/api/v1/positions');
    assert.equal(listed.status, 200);
    assert.deepEqual(listed.body, { positions: [] });

    const created = await createCandidate(baseUrl);
    assert.equal(created.state, 'candidate');
    assert.equal(created.revision, 1);
    assert.equal(created.instrument.instrument_id, INSTRUMENT_ID);
    assert.equal(created.original_thesis, null,
      'absent thesis must serialize as null on the wire');

    const refetched = await api(baseUrl, 'GET', '/api/v1/positions');
    assert.equal(refetched.status, 200);
    assert.equal(refetched.body.positions.length, 1);

    // The H15A protected observed-history market route is still mounted and
    // fail-closed (default resolver answers 404 for unknown instruments).
    const market = await api(baseUrl, 'GET', `/api/v1/market/instruments/${INSTRUMENT_ID}/history?range=1D`);
    assert.equal(market.status, 404);
    assert.equal(market.body.error.code, 'INSTRUMENT_NOT_FOUND');

    // Legacy webhook mount remains route-free; the transport parser limit and
    // /health behavior are preserved.
    const webhook = await api(baseUrl, 'POST', '/webhook', { body: { any: 'payload' }, token: null });
    assert.equal(webhook.status, 404);
    const health = await api(baseUrl, 'GET', '/health', { token: null });
    assert.equal(health.status, 200);
    assert.equal(health.body.status, 'healthy');
  });
});

test('H15B: default factory without services leaves /positions and /research unmounted (H15A 404 contract)', async () => {
  const app = createApp({ logging: false });
  await withTestServer(app, async (baseUrl) => {
    assert.equal((await api(baseUrl, 'GET', '/api/v1/positions')).status, 404);
    assert.equal((await api(baseUrl, 'GET', '/api/v1/research/positions/pos-1/latest')).status, 404);
  });
});

// ---------------------------------------------------------------------------
// Candidate / owned / unknown economics
// ---------------------------------------------------------------------------

test('H15B: candidate carries no economics; owned promotion records it; unknown economics rejected', async () => {
  const { app, services } = makeApp();
  await withTestServer(app, async (baseUrl) => {
    const candidate = await createCandidate(baseUrl);

    const listed = await api(baseUrl, 'GET', '/api/v1/positions');
    assert.equal(listed.body.positions[0].average_cost, null);
    assert.equal(listed.body.positions[0].quantity, null);

    // Candidate promotion with full economics succeeds.
    const promoted = await api(baseUrl, 'PATCH', `/api/v1/positions/${candidate.id}`, {
      body: { expected_revision: candidate.revision, changes: structuredClone(OWNED_CHANGES) },
    });
    assert.equal(promoted.status, 200);
    assert.equal(promoted.body.state, 'owned');
    assert.equal(promoted.body.average_cost.amount, '310.50');
    assert.equal(promoted.body.quantity, '10');
    assert.equal(promoted.body.revision, 2);

    // Unknown economics on a fresh candidate: quantity on a candidate is a
    // typed 400, never silently coerced or stored.
    const second = await createCandidate(baseUrl, {
      instrument: { ...CANDIDATE_INPUT.instrument, instrument_id: 'instrument-h15b-2' },
    });
    const badEconomics = await api(baseUrl, 'PATCH', `/api/v1/positions/${second.id}`, {
      body: { expected_revision: second.revision, changes: { quantity: '5' } },
    });
    assert.equal(badEconomics.status, 400);
    assert.equal(badEconomics.body.code, 'INVALID_CANDIDATE_ECONOMICS');

    // An unknown lifecycle state is rejected outright.
    const unknownState = await api(baseUrl, 'POST', '/api/v1/positions', {
      body: {
        ...structuredClone(CANDIDATE_INPUT),
        instrument: { ...CANDIDATE_INPUT.instrument, instrument_id: 'instrument-h15b-3' },
        state: 'mystery_state',
      },
    });
    assert.equal(unknownState.status, 400);
  });
});

// ---------------------------------------------------------------------------
// Revision conflicts
// ---------------------------------------------------------------------------

test('H15B: stale expected_revision is a typed 409 conflict', async () => {
  const { app, services } = makeApp();
  await withTestServer(app, async (baseUrl) => {
    const candidate = await createCandidate(baseUrl);
    const conflict = await api(baseUrl, 'PATCH', `/api/v1/positions/${candidate.id}`, {
      body: { expected_revision: candidate.revision + 5, changes: { original_thesis: 'stale writer' } },
    });
    assert.equal(conflict.status, 409);
    assert.equal(conflict.body.code, 'REVISION_CONFLICT');

    // The rejected writer changed nothing.
    const fresh = await api(baseUrl, 'GET', '/api/v1/positions');
    assert.equal(fresh.body.positions[0].original_thesis, null);
    assert.equal(fresh.body.positions[0].revision, candidate.revision);
  });
});

// ---------------------------------------------------------------------------
// Owner isolation
// ---------------------------------------------------------------------------

test('H15B: owner B cannot see, change or research owner A position (indistinguishable denial)', async () => {
  const { app, services } = makeApp();
  await withTestServer(app, async (baseUrl) => {
    const candidate = await createCandidate(baseUrl);

    const crossList = await api(baseUrl, 'GET', '/api/v1/positions', { token: 'token-owner-b' });
    assert.equal(crossList.status, 200);
    assert.equal(crossList.body.positions.length, 0, 'list is scoped to the caller');

    const crossGet = await api(baseUrl, 'GET', '/api/v1/positions', { token: 'token-owner-b' });
    assert.equal(crossGet.body.positions.length, 0);

    const crossPatch = await api(baseUrl, 'PATCH', `/api/v1/positions/${candidate.id}`, {
      token: 'token-owner-b',
      body: { expected_revision: candidate.revision, changes: structuredClone(OWNED_CHANGES) },
    });
    assert.equal(crossPatch.status, 404, 'cross-owner update is indistinguishable from missing');
    assert.equal(crossPatch.body.code, 'NOT_FOUND');

    // The research owner is derived server-side: owner B's view of the same
    // position id is a truthful all-null state (no runs/assessments exist for
    // B), never owner A's data.
    const crossLatest = await api(baseUrl, 'GET', `/api/v1/research/positions/${candidate.id}/latest`, {
      token: 'token-owner-b',
    });
    assert.equal(crossLatest.status, 200);
    assert.equal(crossLatest.body.latest_assessment, null);
    assert.equal(crossLatest.body.run_state.last_success, null);
    assert.equal(crossLatest.body.run_state.latest_attempt, null);

    // A run queued by owner B for the same position id is scoped to B.
    const crossRun = await api(baseUrl, 'POST', `/api/v1/research/positions/${candidate.id}/runs`, {
      token: 'token-owner-b',
      body: {
        position_revision: 1,
        run_kind: 'manual_refresh',
        instrument_id: INSTRUMENT_ID,
        request_payload: { trigger: 'fixture' },
      },
      headers: { 'idempotency-key': 'key-cross-owner' },
    });
    assert.equal(crossRun.status, 202);
    assert.equal(crossRun.body.run.owner_id_internal, OWNER_B);
    assert.notEqual(crossRun.body.run.id, candidate.id);

    // Anonymous requests are rejected on both mounts.
    assert.equal((await api(baseUrl, 'GET', '/api/v1/positions', { token: null })).status, 401);
    assert.equal((await api(baseUrl, 'GET', `/api/v1/research/positions/${candidate.id}/latest`, { token: null })).status, 401);
  });
});

// ---------------------------------------------------------------------------
// Research state: truthful unavailable, latest-attempt vs latest-success,
// idempotent replay, wire reconciliation
// ---------------------------------------------------------------------------

test('H15B: research latest with no runs is a truthful 200 unavailable state, never an error', async () => {
  const { app, services } = makeApp();
  await withTestServer(app, async (baseUrl) => {
    const candidate = await createCandidate(baseUrl);
    const latest = await api(baseUrl, 'GET', `/api/v1/research/positions/${candidate.id}/latest`);
    assert.equal(latest.status, 200);
    assert.equal(latest.body.position_id, candidate.id);
    assert.equal(latest.body.latest_assessment, null);
    assert.equal(latest.body.run_state.last_success, null);
    assert.equal(latest.body.run_state.latest_attempt, null);
  });
});

test('H15B: queued run is 202, replayed by idempotency key, and the run wire reconciles with the H11 model', async () => {
  const { app, services } = makeApp();
  await withTestServer(app, async (baseUrl) => {
    const candidate = await createCandidate(baseUrl);
    const requestBody = {
      position_revision: 1,
      run_kind: 'manual_refresh',
      instrument_id: INSTRUMENT_ID,
      request_payload: { trigger: 'fixture' },
    };
    const first = await api(baseUrl, 'POST', `/api/v1/research/positions/${candidate.id}/runs`, {
      body: requestBody,
      headers: { 'idempotency-key': 'key-replay-1' },
    });
    assert.equal(first.status, 202);
    assert.equal(first.body.idempotent_replay, false);

    const replay = await api(baseUrl, 'POST', `/api/v1/research/positions/${candidate.id}/runs`, {
      body: requestBody,
      headers: { 'idempotency-key': 'key-replay-1' },
    });
    assert.equal(replay.status, 202);
    assert.equal(replay.body.idempotent_replay, true);
    assert.equal(replay.body.run.id, first.body.run.id,
      'same key + same request returns the persisted run');

    // Wire reconciliation: run views keep owner_id_internal (H11
    // ResearchRun.fromJson requires it) and never expose the automation
    // lease secret.
    assert.equal(typeof first.body.run.owner_id_internal, 'string');
    assert.equal(first.body.run.owner_id_internal, OWNER_A);
    assert.equal(Object.prototype.hasOwnProperty.call(first.body.run, 'lease_nonce'), false,
      'the automation lease nonce is never on the public run wire');

    // Missing Idempotency-Key is a typed 400.
    const missing = await api(baseUrl, 'POST', `/api/v1/research/positions/${candidate.id}/runs`, {
      body: requestBody,
    });
    assert.equal(missing.status, 400);
    assert.equal(missing.body.code, 'MISSING_IDEMPOTENCY_KEY');

    // Same key, different payload: 409 conflict, never silent reuse.
    const conflict = await api(baseUrl, 'POST', `/api/v1/research/positions/${candidate.id}/runs`, {
      body: { ...requestBody, request_payload: { trigger: 'different' } },
      headers: { 'idempotency-key': 'key-replay-1' },
    });
    assert.equal(conflict.status, 409);
    assert.equal(conflict.body.code, 'IDEMPOTENCY_CONFLICT');
  });
});

test('H15B: delivered success lands in run_state.last_success and latest_assessment; latest_attempt tracks a later failure', async () => {
  const { app, services } = makeApp();
  await withTestServer(app, async (baseUrl) => {
    const candidate = await createCandidate(baseUrl);

    advanceClock(60);
    const queued = await queueAndDeliverSuccess(baseUrl, candidate.id);
    // Claim + deliver through the same service instance the router holds:
    // the app factory wires routers from the injected services, so completing
    // the run via the service is the same code path the worker uses.
    const runId = queued.id;
    await services.researchService.claimRun({ run_id: runId });
    const delivered = await services.researchService.recordRunResult({
      run_id: runId,
      caller_owner_id: OWNER_A,
      delivery_id: 'delivery-success-1',
      result: {
        evidence_snapshot_id: 'snapshot-evidence-h15b-1',
        position_revision: 1,
        session_as_of: '2030-01-01',
        status: 'complete',
        assessment: {
          market_thesis: { business: 'Structured business assessment from bounded pipeline' },
          recommendation: { action: 'wait', horizon_months: 3 },
        },
      },
    });
    assert.ok(delivered.assessment_id);

    let latest = await api(baseUrl, 'GET', `/api/v1/research/positions/${candidate.id}/latest`);
    assert.equal(latest.status, 200);
    assert.ok(latest.body.latest_assessment);
    assert.equal(latest.body.latest_assessment.run_id, runId);
    assert.equal(latest.body.run_state.last_success.run_id, runId);
    assert.equal(latest.body.run_state.latest_attempt.run_id, runId);

    // A later failed attempt must not rewrite the existing success.
    advanceClock(120);
    const failed = await queueAndDeliverSuccess(baseUrl, candidate.id, {
      keyPrefix: 'key-h15b-fail',
    });
    await services.researchService.claimRun({ run_id: failed.id });
    await services.researchService.completeRun({
      run_id: failed.id,
      outcome: { status: 'failed', error_code: 'PIPELINE_VALIDATION_FAILED' },
    });

    latest = await api(baseUrl, 'GET', `/api/v1/research/positions/${candidate.id}/latest`);
    assert.equal(latest.body.run_state.last_success.run_id, runId,
      'existing success is never rewritten by a later failure');
    assert.equal(latest.body.run_state.latest_attempt.run_id, failed.id);
    assert.equal(latest.body.run_state.latest_attempt.status, 'failed');
    assert.equal(latest.body.run_state.latest_attempt.error_code, 'PIPELINE_VALIDATION_FAILED');
    assert.ok(latest.body.latest_assessment, 'the prior success still grounds the panel');
    assert.equal(latest.body.latest_assessment.run_id, runId);

    // Assessment views strip owner_id_internal (public wire is owner-free).
    assert.equal(Object.prototype.hasOwnProperty.call(latest.body.latest_assessment, 'owner_id_internal'), false);
  });
});

test('H15B: a limited result counts as last_success and stays distinct from a later failed attempt', async () => {
  const { app, services } = makeApp();
  await withTestServer(app, async (baseUrl) => {
    const candidate = await createCandidate(baseUrl);
    advanceClock(60);
    const run = await queueAndDeliverSuccess(baseUrl, candidate.id, { keyPrefix: 'key-limited' });
    await services.researchService.claimRun({ run_id: run.id });
    const delivered = await services.researchService.recordRunResult({
      run_id: run.id,
      caller_owner_id: OWNER_A,
      delivery_id: 'delivery-limited-1',
      result: {
        evidence_snapshot_id: 'snapshot-evidence-h15b-1',
        position_revision: 1,
        session_as_of: '2030-01-01',
        status: 'limited',
        missing_data: ['Projection data limited to 90 days of observed bars.'],
        assessment: {
          market_thesis: { business: 'Limited but grounded business assessment' },
          recommendation: { action: 'wait', horizon_months: 3 },
        },
      },
    });
    assert.ok(delivered.assessment_id);

    const latest = await api(baseUrl, 'GET', `/api/v1/research/positions/${candidate.id}/latest`);
    assert.equal(latest.body.run_state.last_success.run_id, run.id,
      'limited delivery is a success for grounding purposes');
    assert.ok(latest.body.latest_assessment);
    assert.equal(latest.body.run_state.last_success.status, 'limited');
  });
});

test('H15B: prior-report changes — a new revision supersedes stale runs and never mutates prior assessments', async () => {
  const { app, services } = makeApp();
  await withTestServer(app, async (baseUrl) => {
    const candidate = await createCandidate(baseUrl);

    // Success at revision 1 grounds the panel.
    advanceClock(60);
    const successRun = await queueAndDeliverSuccess(baseUrl, candidate.id, { keyPrefix: 'key-rev1' });
    await services.researchService.claimRun({ run_id: successRun.id });
    await services.researchService.recordRunResult({
      run_id: successRun.id,
      caller_owner_id: OWNER_A,
      delivery_id: 'delivery-rev1',
      result: {
        evidence_snapshot_id: 'snapshot-evidence-h15b-1',
        position_revision: 1,
        session_as_of: '2030-01-01',
        status: 'complete',
        assessment: {
          market_thesis: { business: 'Revision 1 grounded assessment' },
          recommendation: { action: 'wait', horizon_months: 3 },
        },
      },
    });

    // A queued run at revision 1 is still pending when the position changes.
    advanceClock(60);
    const staleRun = await queueAndDeliverSuccess(baseUrl, candidate.id, { keyPrefix: 'key-rev1b' });

    // Position edit bumps the revision.
    advanceClock(60);
    const patched = await api(baseUrl, 'PATCH', `/api/v1/positions/${candidate.id}`, {
      body: { expected_revision: 1, changes: { original_thesis: 'Updated thesis after earnings' } },
    });
    assert.equal(patched.status, 200);
    assert.equal(patched.body.revision, 2);

    // Queueing at the new revision supersedes the stale queued run.
    advanceClock(60);
    const freshRun = await queueAndDeliverSuccess(baseUrl, candidate.id, {
      keyPrefix: 'key-rev2',
      revision: 2,
    });
    assert.equal(freshRun.position_revision, 2);

    const staleView = await api(baseUrl, 'GET', `/api/v1/research/runs/${staleRun.id}`);
    assert.equal(staleView.status, 200);
    assert.equal(staleView.body.run.status, 'superseded',
      'runs queued against a superseded revision are marked superseded');

    // The revision-1 assessment is immutable history: unchanged session and
    // thesis content, still retrievable through the paginated history.
    const history = await api(baseUrl, 'GET', `/api/v1/research/positions/${candidate.id}/assessments`);
    assert.equal(history.status, 200);
    const rev1 = history.body.assessments.find((a) => a.position_revision === 1);
    assert.ok(rev1, 'the revision-1 assessment remains in immutable history');
    assert.equal(rev1.session_as_of, '2030-01-01');
    assert.equal(rev1.artifact_kind, 'judgment');
    // The grounded contract assessment is carried nested under `assessment`.
    assert.equal(rev1.assessment.market_thesis.business, 'Revision 1 grounded assessment');
    assert.equal(Object.prototype.hasOwnProperty.call(rev1, 'owner_id_internal'), false);
  });
});

// ---------------------------------------------------------------------------
// Owner-scoped observed history slice with a resolved instrument (integration
// of the market mount with the position instrument identity)
// ---------------------------------------------------------------------------

test('H15B: observed market history for a resolved instrument stays isolated from research snapshots', async () => {
  const marketBars = Object.freeze([
    {
      time: '2030-01-01T14:30:00Z',
      session_date: '2030-01-01',
      open: 100.5,
      high: 103.0,
      low: 99.0,
      close: 102.5,
      volume: 12000,
      adjusted_close: null,
      is_final: true,
    },
  ]);
  const marketService = new MarketHistoryService({
    provider: {
      async fetchHistory() {
        return {
          bars: marketBars,
          actual_resolution: '5m',
          exchange_timezone: 'America/New_York',
          adjustment_basis: 'raw_ohlc_unadjusted',
          delay_status: 'delayed',
          as_of: '2030-01-01T14:30:00Z',
          fetched_at: '2030-01-01T15:00:00Z',
          source: { name: 'Test provider', provider: 'test_provider' },
          warnings: [],
        };
      },
    },
    snapshotRepository: makeSnapshotRepository(),
    now: () => new Date(clockIso),
    instrumentResolver: async (id) => (id === INSTRUMENT_ID ? {
      instrument_id: INSTRUMENT_ID,
      symbol: 'NVDA',
      exchange: 'NASDAQ',
      currency: 'USD',
      provider_symbol: 'NVDA',
    } : null),
  });
  const marketRouter = createMarketRouter({ marketService, authenticate: makeAuth() });
  const { app, services } = makeApp();
  // A variant factory that mounts the observed-history market router for a
  // resolved instrument identity alongside the position/research mounts.
  const appWithMarket = createApp({
    marketRouter,
    positionService: services.positionService,
    researchService: services.researchService,
    authenticate: makeAuth(),
    logging: false,
  });
  await withTestServer(appWithMarket, async (baseUrl) => {
    const candidate = await createCandidate(baseUrl);
    const history = await api(baseUrl, 'GET', `/api/v1/market/instruments/${INSTRUMENT_ID}/history?range=1D`);
    assert.equal(history.status, 200);
    assert.equal(history.body.data_status, 'available');
    assert.equal(history.body.bars.length, 1);
    assert.equal(history.body.instrument.instrument_id, INSTRUMENT_ID);

    // The research side still reports a truthful unavailable state: market
    // observations and research snapshots are separate stores, and no run has
    // been queued for the position.
    const latest = await api(baseUrl, 'GET', `/api/v1/research/positions/${candidate.id}/latest`);
    assert.equal(latest.status, 200);
    assert.equal(latest.body.latest_assessment, null);
    assert.equal(latest.body.run_state.last_success, null);
  });
});
