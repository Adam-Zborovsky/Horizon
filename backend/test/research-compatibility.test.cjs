'use strict';

// H15 — application integration and legacy compatibility (backend half).
//
// Two integration surfaces are proven here against the REAL application
// composition (backend/src/app.js) and the REAL production composition
// helpers exported by backend/src/server.js:
//
//   1. The H10 automation surface mounts under the API prefix only when a
//      fully composed router is injected, guarded by the scoped automation
//      identity (never a user JWT), and the bounded run worker shares ONE
//      runs store with the owner-facing research service (H10 review O3:
//      H15 wiring responsibility). The full journey — user queues a run via
//      /research, the scoped service identity sees it via /automation,
//      the bounded worker completes it in-process, and the user-facing
//      router reports the same persisted result — is exercised end to end.
//
//   2. Legacy briefing/topic/opportunity compatibility (CONTRACTS §10):
//      legacy tickers are derived from active positions, a stale
//      tickers-only config PUT cannot wipe position-backed tickers
//      (bounded/explicit 409, never destructive replacement), and the
//      legacy factual enrichment neither fabricates history nor clobbers
//      rich currency-denominated price objects.
//
// Fixtures are hermetic in-memory repositories and hand-built wire shapes
// copied from backend/test/research-workflow.test.cjs and
// backend/test/research-panel-integration.test.cjs. No MongoDB, no network,
// no scheduler, no live model calls. The model client here is a fixture.

const assert = require('node:assert/strict');
const http = require('node:http');
const crypto = require('node:crypto');
const test = require('node:test');

const { createApp } = require('../src/app');
const {
  createRunWorker,
  toStatusView,
} = require('../src/features/research/run_worker');
const { ResearchService } = require('../src/features/research/research.service');
const { reconcileLegacyTickerUpdate } = require('../src/features/positions/position.service');
const { BriefingService } = require('../src/features/briefing/briefing.service');

// ---------------------------------------------------------------------------
// Fixtures (hermetic; synthetic; NOT observed market data)
// ---------------------------------------------------------------------------

const OWNER_A = 'owner-h15-aaaa';
const OWNER_B = 'owner-h15-bbbb';

const INSTRUMENT = Object.freeze({
  instrument_id: 'inst-h15-1',
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

const CLOCK_START = '2030-01-02T00:00:00.000Z';

function clockHarness() {
  const clock = { iso: CLOCK_START };
  return {
    now: () => new Date(clock.iso),
    nowIso: () => clock.iso,
    advanceSeconds(seconds) {
      clock.iso = new Date(new Date(clock.iso).getTime() + seconds * 1000).toISOString();
    },
  };
}

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
    snapshot_id: 'snap-h15-1',
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
    position_id: 'pos-h15-1',
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
  };
}

function createModelClient({ outputs = [] } = {}) {
  const state = { calls: [] };
  state.complete = async function complete(request) {
    state.calls.push(request);
    const output = outputs.length > 1 ? outputs.shift() : outputs[0];
    if (output === undefined) throw new Error('fixture model client exhausted');
    return { output };
  };
  return state;
}

function weekdayPredicate(sessionDate) {
  const weekday = new Date(`${sessionDate}T00:00:00Z`).getUTCDay();
  return weekday >= 1 && weekday <= 5;
}

function makeInputProvider() {
  return async (run) => ({
    snapshot: evidenceSnapshot(),
    metrics: METRICS,
    instrument: INSTRUMENT,
    position: ownedPosition({ position_id: run.position_id, revision: run.position_revision }),
    prior: null,
    currentPrice: { amount: '150.00', currency: 'USD', adjustment_basis: 'raw_purchase' },
  });
}

function makeIdFactories() {
  let runs = 0;
  let assessments = 0;
  let snapshots = 0;
  let checkpoints = 0;
  return {
    idFactory: () => `run-h15-${(runs += 1)}`,
    assessmentIdFactory: () => `assessment-h15-${(assessments += 1)}`,
    snapshotIdFactory: () => `snapshot-h15-${(snapshots += 1)}`,
    checkpointIdFactory: () => `checkpoint-h15-${(checkpoints += 1)}`,
  };
}

// Scoped-identity HTTP harness for the automation router fixtures.
function makeAutomationIdentity({ ownerId = OWNER_A } = {}) {
  return {
    token: crypto.randomBytes(32).toString('hex'),
    scopes: [...AUTOMATION_SCOPES],
    ownerId,
  };
}

function authorizedAutomationHeaders(identity, extra = {}) {
  return {
    authorization: `Bearer ${identity.token}`,
    'content-type': 'application/json',
    ...extra,
  };
}

function makeUserAuth() {
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
    return res.status(401).json({ message: 'Not authorized, invalid token' });
  };
}

async function withTestServer(app, fn) {
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

// ---------------------------------------------------------------------------
// Section A — the automation surface mounts only when composed (app.js)
// ---------------------------------------------------------------------------

test('A1: default app keeps /api/v1/automation/research unmounted (404 until wired)', async () => {
  const app = createApp({ logging: false });
  await withTestServer(app, async (baseUrl) => {
    const response = await request(baseUrl, '/api/v1/automation/research/runs/queued');
    assert.equal(response.status, 404);
  });
});

test('A2: mounted automation router demands the scoped service identity (401 without bearer)', async () => {
  const harness = createAutomationHarness();
  const app = createApp({ automationRouter: harness.router, logging: false });
  await withTestServer(app, async (baseUrl) => {
    const response = await request(baseUrl, '/api/v1/automation/research/runs/queued');
    assert.equal(response.status, 401);
    assert.equal(response.body.code, 'automation_auth_required');
  });
});

test('A3: automation router rejects a valid bearer lacking the required scope (403)', async () => {
  const harness = createAutomationHarness();
  const app = createApp({ automationRouter: harness.router, logging: false });
  await withTestServer(app, async (baseUrl) => {
    const readIdentity = harness.identity;
    // A token bound to the identity is presented, but the queued-list route
    // requires research:trigger; a read-only scope set must be denied.
    const narrow = {
      token: readIdentity.token,
      scopes: ['research:status'],
      ownerId: readIdentity.ownerId,
    };
      // Re-mount with a narrower identity instead of mutating the first one.
    const narrowRouter = harness.composeWithIdentity(narrow);
    const narrowApp = createApp({ automationRouter: narrowRouter, logging: false });
    await withTestServer(narrowApp, async (narrowUrl) => {
      const response = await request(narrowUrl, '/api/v1/automation/research/runs/queued', {
        headers: authorizedAutomationHeaders(narrow),
      });
      assert.equal(response.status, 403);
      assert.equal(response.body.code, 'automation_scope_denied');
    });
    void readIdentity;
  });
});

test('A4: scoped service identity lists its queued runs without economics exposure', async () => {
  const harness = createAutomationHarness();
  // Queue a run through the service first (same shared store).
  const { run } = await harness.service.queueRun({
    owner_id: OWNER_A,
    position_id: 'pos-h15-1',
    position_revision: 7,
    run_kind: 'manual_refresh',
    idempotency_key: 'key-a4-1',
    instrument_id: INSTRUMENT.instrument_id,
    request_payload: { trigger: 'fixture' },
  });
  const app = createApp({ automationRouter: harness.router, logging: false });
  await withTestServer(app, async (baseUrl) => {
    const response = await request(baseUrl, '/api/v1/automation/research/runs/queued', {
      headers: authorizedAutomationHeaders(harness.identity),
    });
    assert.equal(response.status, 200);
    assert.ok(Array.isArray(response.body.runs));
    assert.equal(response.body.runs.length, 1);
    assert.equal(response.body.runs[0].run_id, run.id);
    // No economics, no lease nonce in the queued listing.
    const listed = JSON.stringify(response.body);
    assert.ok(!listed.includes('average_cost'));
    assert.ok(!listed.includes('lease_nonce'));
  });
});

// ---------------------------------------------------------------------------
// Section B — one shared runs store across user research + automation + worker
// ---------------------------------------------------------------------------

test('B1: end-to-end journey — user queue, scoped automation view, bounded worker, persisted result', async () => {
  const harness = createAutomationHarness();
  const app = createApp({
    researchService: harness.service,
    authenticate: makeUserAuth(),
    automationRouter: harness.router,
    logging: false,
  });
  await withTestServer(app, async (baseUrl) => {
    // 1. The user queues a run through the owner-facing research router.
    const queued = await request(baseUrl, '/api/v1/research/positions/pos-h15-1/runs', {
      method: 'POST',
      headers: {
        authorization: 'Bearer token-owner-a',
        'content-type': 'application/json',
        'idempotency-key': 'key-b1-1',
      },
      body: JSON.stringify({
        position_revision: 7,
        run_kind: 'manual_refresh',
        instrument_id: INSTRUMENT.instrument_id,
        request_payload: { trigger: 'fixture' },
      }),
    });
    assert.equal(queued.status, 202);
    const runId = queued.body.run.id;

    // 2. The scoped automation identity sees the same run via its own mount.
    const listed = await request(baseUrl, '/api/v1/automation/research/runs/queued', {
      headers: authorizedAutomationHeaders(harness.identity),
    });
    assert.equal(listed.status, 200);
    assert.equal(listed.body.runs.length, 1);
    assert.equal(listed.body.runs[0].run_id, runId);

    // 3. Trigger executes the bounded in-process worker pipeline.
    const executed = await request(baseUrl, `/api/v1/automation/research/runs/${runId}/execute`, {
      method: 'POST',
      headers: authorizedAutomationHeaders(harness.identity),
    });
    assert.equal(executed.status, 202);

    // 4. The worker settles against the SAME shared runs store.
    await harness.worker.whenSettled(runId);

    // 5. The user-facing router reports the persisted terminal status.
    const status = await request(baseUrl, `/api/v1/research/runs/${runId}`, {
      headers: { authorization: 'Bearer token-owner-a' },
    });
    assert.equal(status.status, 200);
    assert.equal(status.body.run.status, 'succeeded');
    assert.ok(status.body.run.assessment_id);

    // 6. Re-execute of a terminal run replays (200) without a new assessment.
    const replay = await request(baseUrl, `/api/v1/automation/research/runs/${runId}/execute`, {
      method: 'POST',
      headers: authorizedAutomationHeaders(harness.identity),
    });
    assert.equal(replay.status, 200);
    assert.equal(harness.assessmentRepository.records.length, 1);
  });
});

test('B2: composing the automation surface without a model client fails closed (TypeError)', () => {
  const clock = clockHarness();
  const runRepository = createInMemoryRunRepository();
  assert.throws(
    () => composeAutomationSurface({
      inputProvider: makeInputProvider(),
      runRepository,
      assessmentRepository: createInMemoryAssessmentRepository(),
      researchSnapshotRepository: createInMemoryResearchSnapshotRepository(),
      checkpointRepository: createInMemoryCheckpointRepository(),
      automation: makeAutomationIdentity(),
      listQueuedRuns: async () => [],
      now: clock.now,
    }),
    (error) => error instanceof TypeError && /model client/i.test(error.message),
  );
});

test('B3: composing the automation surface without a shared runs store or input provider fails closed', () => {
  const clock = clockHarness();
  assert.throws(
    () => composeAutomationSurface({
      modelClient: createModelClient({ outputs: [validSynthesis()] }),
      inputProvider: makeInputProvider(),
      automation: makeAutomationIdentity(),
      listQueuedRuns: async () => [],
      now: clock.now,
    }),
    (error) => error instanceof TypeError && /run repository/i.test(error.message),
  );
  assert.throws(
    () => composeAutomationSurface({
      modelClient: createModelClient({ outputs: [validSynthesis()] }),
      runRepository: createInMemoryRunRepository(),
      automation: makeAutomationIdentity(),
      listQueuedRuns: async () => [],
      now: clock.now,
    }),
    (error) => error instanceof TypeError && /input provider/i.test(error.message),
  );
});

test('B4: composing the automation surface without a scoped service identity fails closed', () => {
  const clock = clockHarness();
  assert.throws(
    () => composeAutomationSurface({
      modelClient: createModelClient({ outputs: [validSynthesis()] }),
      inputProvider: makeInputProvider(),
      runRepository: createInMemoryRunRepository(),
      assessmentRepository: createInMemoryAssessmentRepository(),
      researchSnapshotRepository: createInMemoryResearchSnapshotRepository(),
      checkpointRepository: createInMemoryCheckpointRepository(),
      automation: { token: 'x', scopes: [], ownerId: OWNER_A },
      listQueuedRuns: async () => [],
      now: clock.now,
    }),
    (error) => error instanceof TypeError && /scope|identity/i.test(error.message),
  );
});

// ---------------------------------------------------------------------------
// Section C — legacy briefing compatibility (CONTRACTS §10)
// ---------------------------------------------------------------------------

function createFakeConfigModel(seed = {}) {
  const store = new Map();
  return {
    store,
    async findOneAndUpdate(query, update, options) {
      const userId = String(query.user);
      if (!store.has(userId)) {
        const doc = {
          user: userId,
          topics: [],
          tickers: [],
          saveCount: 0,
          ...seed,
        };
        doc.save = async () => {
          doc.saveCount += 1;
          return doc;
        };
        store.set(userId, doc);
      }
      return store.get(userId);
    },
  };
}

function createFakeBriefingModel() {
  const docs = [];
  class FakeBriefing {
    constructor(args) {
      Object.assign(this, structuredClone(args));
      this.createdAt = new Date();
      this.updatedAt = new Date();
    }

    async save() {
      docs.push(this);
      return this;
    }
  }
  FakeBriefing.docs = docs;
  FakeBriefing.findOne = async (query) => {
    const mine = docs.filter((doc) => doc.user === query.user)
      .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
    return mine[0] || null;
  };
  return FakeBriefing;
}

// Active-position fixture source: mirrors the default mongoose-backed lookup
// shape ({id, archived, instrument}) without MongoDB.
function makePositionSource(positionsByOwner) {
  return async (userId) => positionsByOwner[String(userId)] || [];
}

function makeFactualProvider(rows) {
  return async (tickers) => tickers
    .map((ticker) => rows.find((row) => row.ticker === ticker.toUpperCase()) || null)
    .filter(Boolean);
}

function makeBriefingService({
  seedConfig = {},
  positionsByOwner = {},
  factualRows = [],
  userRecord = { _id: 'user-h15-1', username: 'fixture-user' },
} = {}) {
  const configModel = createFakeConfigModel(seedConfig);
  const briefingModel = createFakeBriefingModel();
  const listActivePositions = makePositionSource(positionsByOwner);
  const marketDataProvider = makeFactualProvider(factualRows);
  const service = new BriefingService({
    briefingModel,
    configModel,
    listActivePositions,
    marketDataProvider,
    userModel: { findById: async () => userRecord },
    workflowFetch: async () => ({ ok: true }),
  });
  return { service, configModel, briefingModel };
}

test('C1: a stale tickers-only config PUT that would drop position-backed tickers is refused with 409 (non-destructive)', async () => {
  const { service, configModel } = makeBriefingService({
    seedConfig: { tickers: ['MSFT', 'AAPL'] },
    positionsByOwner: {
      [OWNER_A]: [{
        id: 'pos-msft-1',
        archived: false,
        instrument: { instrument_id: 'legacy-ticker-MSFT', symbol: 'MSFT', provider_symbol: null },
      }],
    },
  });
  await assert.rejects(
    () => service.updateConfig(OWNER_A, { tickers: ['AAPL'] }),
    (error) => {
      assert.equal(error.status, 409);
      assert.ok(Array.isArray(error.details));
      assert.equal(error.details[0].ticker, 'MSFT');
      assert.deepEqual(error.details[0].active_position_ids, ['pos-msft-1']);
      return true;
    },
  );
  // Nothing was written: the stored config is unchanged (non-destructive).
  const stored = configModel.store.get(String(OWNER_A));
  assert.deepEqual(stored.tickers, ['MSFT', 'AAPL']);
  assert.equal(stored.saveCount, 0);
});

test('C2: a config PUT that does not touch position-backed tickers is accepted', async () => {
  const { service, configModel } = makeBriefingService({
    seedConfig: { tickers: ['MSFT', 'AAPL', 'OLD'] },
    positionsByOwner: {
      [OWNER_A]: [{
        id: 'pos-msft-1',
        archived: false,
        instrument: { instrument_id: 'legacy-ticker-MSFT', symbol: 'MSFT', provider_symbol: null },
      }],
    },
  });
  // MSFT (position-backed) is retained; OLD has no position and may go.
  const saved = await service.updateConfig(OWNER_A, { tickers: ['MSFT', 'AAPL', 'NVDA'] });
  assert.deepEqual(saved.tickers, ['MSFT', 'AAPL', 'NVDA']);
  assert.equal(configModel.store.get(String(OWNER_A)).saveCount, 1);
});

test('C3: legacy tickers are derived from active positions (provider_symbol, then symbol), deduped', async () => {
  const { service } = makeBriefingService({
    seedConfig: { tickers: ['msft', 'TEST'] },
    positionsByOwner: {
      [OWNER_A]: [
        { id: 'p1', archived: false, instrument: { instrument_id: 'inst-1', symbol: 'TEST', provider_symbol: 'TEST' } },
        { id: 'p2', archived: false, instrument: { instrument_id: 'inst-2', symbol: 'ACME', provider_symbol: 'ACME.Y' } },
        { id: 'p3', archived: true, instrument: { instrument_id: 'inst-3', symbol: 'GONE', provider_symbol: null } },
      ],
    },
  });
  const effective = await service.getEffectiveTickers(OWNER_A);
  assert.deepEqual(effective, ['MSFT', 'TEST', 'ACME.Y']);
});

test('C4: a briefing covering position-derived tickers is not falsely flagged as hallucination', async () => {
  const { service, briefingModel } = makeBriefingService({
    // Config knows nothing about MSFT; only the active position does.
    seedConfig: { tickers: ['AAPL'] },
    positionsByOwner: {
      [OWNER_A]: [{
        id: 'pos-msft-1',
        archived: false,
        instrument: { instrument_id: 'legacy-ticker-MSFT', symbol: 'MSFT', provider_symbol: null },
      }],
    },
    factualRows: [],
  });
  const saved = await service.save(OWNER_A, {
    data: { opportunities: [{ ticker: 'MSFT', note: 'model-reported position instrument' }] },
    source: 'n8n',
  });
  assert.ok(saved);
  assert.equal(briefingModel.docs.length, 1);
  const storedItem = saved.data.opportunities[0];
  // No factual row exists; the item is honestly marked invalid, never dropped
  // and never enriched with an invented price.
  assert.equal(storedItem.is_invalid, true);
  assert.equal(storedItem.price, undefined);
});

test('C5: legacy factual enrichment writes the numeric legacy shape but never clobbers rich currency-denominated prices, and never fabricates history', async () => {
  const { service, briefingModel } = makeBriefingService({
    seedConfig: { tickers: ['AAPL', 'NVDA'] },
    positionsByOwner: {},
    factualRows: [
      { ticker: 'AAPL', price: 42.5, change: 0.1, name: 'Factual Apple' },
      { ticker: 'NVDA', price: 42.5, change: -0.2, name: 'Factual Nvidia' },
    ],
  });
  const saved = await service.save(OWNER_A, {
    data: {
      opportunities: [
        { ticker: 'AAPL', price: { amount: '123.00', currency: 'USD' }, name: 'Typed price' },
        { ticker: 'NVDA' },
      ],
    },
    source: 'n8n',
  });
  assert.ok(saved);
  const [rich, legacy] = saved.data.opportunities;
  // Rich typed price survives untouched — no silent latest-price overwrite.
  assert.deepEqual(rich.price, { amount: '123.00', currency: 'USD' });
  // Legacy tickers-only item receives the factual numeric enrichment.
  assert.equal(legacy.price, 42.5);
  assert.equal(legacy.change, -0.2);
  // No synthetic history is manufactured for either shape.
  assert.equal(rich.history, undefined);
  assert.equal(legacy.history, undefined);
  assert.equal(briefingModel.docs.length, 1);
  void briefingModel;
});

test('C6: legacy consumers keep working — getLatest parses stored string JSON and filters disabled topics', async () => {
  const { service } = makeBriefingService({
    seedConfig: {
      topics: [{ name: 'news', enabled: false }],
      tickers: ['AAPL'],
    },
    positionsByOwner: {},
  });
  // Seed a stored briefing as a raw JSON string (legacy persistence shape).
  const stored = {
    user: String(OWNER_A),
    data: JSON.stringify({ news: { items: [1] }, opportunities: [{ ticker: 'AAPL' }] }),
    source: 'n8n',
  };
  stored.save = async () => stored;
  const configModel = { findOneAndUpdate: async () => makeConfigDoc({ topics: [{ name: 'news', enabled: false }] }) };
  const briefingModel = {
    findOne: (query) => ({
      sort: async () => stored,
    }),
  };
  const legacyService = new BriefingService({
    briefingModel,
    configModel,
    listActivePositions: async () => [],
    marketDataProvider: async () => [],
    userModel: { findById: async () => ({ _id: 'u', username: 'x' }) },
    workflowFetch: async () => ({ ok: true }),
  });
  const latest = await legacyService.getLatest(OWNER_A);
  assert.ok(latest);
  // Disabled topic filtered; other topics preserved.
  assert.equal(latest.data.news, undefined);
  assert.deepEqual(latest.data.opportunities, [{ ticker: 'AAPL' }]);
});

test('C7: the legacy workflow payload derives tickers from active positions', async () => {
  const fetchCalls = [];
  const configModel = createFakeConfigModel({ tickers: ['AAPL'] });
  const briefingModel = createFakeBriefingModel();
  const service = new BriefingService({
    briefingModel,
    configModel,
    listActivePositions: makePositionSource({
      [OWNER_A]: [{
        id: 'pos-msft-1',
        archived: false,
        instrument: { instrument_id: 'legacy-ticker-MSFT', symbol: 'MSFT', provider_symbol: null },
      }],
    }),
    marketDataProvider: async () => [],
    userModel: { findById: async () => ({ _id: 'user-h15-1', username: 'fixture-user' }) },
    workflowFetch: async (url, options) => {
      fetchCalls.push({ url, body: JSON.parse(options.body) });
      return { ok: true };
    },
  });
  // N8N_WEBHOOK_URL comes from the loaded config; the injected fetch records
  // the call instead of performing it. Force the URL through the env shim.
  const env = require('../src/config/env');
  const previousWebhookUrl = env.N8N_WEBHOOK_URL;
  const writableEnv = env;
  writableEnv.N8N_WEBHOOK_URL = 'https://fixture.invalid/webhook';
  try {
    await service.triggerWorkflow(OWNER_A, 'scheduled_daily');
  } finally {
    writableEnv.N8N_WEBHOOK_URL = previousWebhookUrl;
  }
  assert.equal(fetchCalls.length, 1);
  const tickers = fetchCalls[0].body.config.tickers.map((t) => t.toUpperCase());
  assert.ok(tickers.includes('AAPL'), 'config tickers remain in the legacy payload');
  assert.ok(tickers.includes('MSFT'), 'position-derived tickers are added to the legacy payload');
});

// ---------------------------------------------------------------------------
// Shared helpers used by sections A/B
// ---------------------------------------------------------------------------

function makeConfigDoc(seed = {}) {
  const doc = { user: 'u', topics: [], tickers: [], ...seed };
  doc.save = async () => doc;
  return doc;
}

function composeAutomationSurface(options) {
  // Imported late so the red run fails with a clear missing-binding error,
  // not a require crash, once the export exists this is the production
  // composition helper under test.
  return require('../src/server').composeAutomationSurface(options);
}

function createAutomationHarness() {
  const clock = clockHarness();
  const runRepository = createInMemoryRunRepository();
  const assessmentRepository = createInMemoryAssessmentRepository();
  const researchSnapshotRepository = createInMemoryResearchSnapshotRepository();
  const checkpointRepository = createInMemoryCheckpointRepository();
  const identity = makeAutomationIdentity();
  const factories = makeIdFactories();
  const modelClient = createModelClient({ outputs: [validSynthesis()] });
  const researchService = new ResearchService({
    runRepository,
    assessmentRepository,
    researchSnapshotRepository,
    checkpointRepository,
    evidenceSnapshotLookup: async (snapshotId) => (snapshotId
      ? { snapshot_id: snapshotId, instrument_id: INSTRUMENT.instrument_id }
      : null),
    now: clock.now,
    deadlineSeconds: 900,
    ...factories,
  });
  const agentRuntime = require('../src/features/research/agent_runtime').createResearchAgentRuntime({
    modelClient: { complete: modelClient.complete },
    now: clock.now,
    idFactory: factories.assessmentIdFactory,
    isExchangeSession: weekdayPredicate,
  });
  const worker = createRunWorker({
    researchService,
    agentRuntime,
    inputProvider: makeInputProvider(),
    runLookup: (runId) => runRepository.findById(runId),
    now: clock.now,
  });
  const { createAutomationRouter } = require('../src/features/research/automation.routes');
  const { createAutomationMiddleware, createRunCallbackAuthorizer } = require('../src/middleware/automation.middleware');
  const queuedSource = async ({ ownerId, limit, nowIso }) => runRepository.records
    .filter((run) => run.owner_id_internal === ownerId && run.status === 'queued' && run.deadline_at > nowIso)
    .sort((a, b) => a.created_at.localeCompare(b.created_at))
    .slice(0, limit)
    .map(toStatusView);
  const buildRouter = (activeIdentity) => createAutomationRouter({
    researchService,
    runWorker: worker,
    runs: runRepository,
    automationMiddleware: createAutomationMiddleware({
      token: activeIdentity.token,
      scopes: activeIdentity.scopes,
      ownerId: activeIdentity.ownerId,
      maxBodyBytes: 64 * 1024,
    }),
    callbackAuthorizer: createRunCallbackAuthorizer({ now: clock.now }),
    listQueuedRuns: queuedSource,
    now: clock.now,
  });
  return {
    service: researchService,
    assessmentRepository,
    runRepository,
    worker,
    identity,
    router: buildRouter(identity),
    composeWithIdentity: buildRouter,
  };
}
