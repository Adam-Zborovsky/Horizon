'use strict';

// H17 — full hermetic integration and failure injection.
//
// Exercises the COMPLETE composed application surface (backend/src/app.js +
// backend/src/server.js composeAutomationSurface) over one shared runs store:
//
//   candidate add -> research run -> owned transition -> cost edit ->
//   market history (chart ranges) -> snapshot/source/forecast reads ->
//   failed/stalled/superseded journeys with injected failures:
//   provider failure, model/schema failure, evidence starvation,
//   deadline/timeout stall, process restart recovery, concurrent position
//   edit during generation, callback replay/conflict, and source (evidence
//   snapshot) injection. Ticker coverage is accounted across MULTIPLE
//   configured instruments, never only one.
//
// Fixtures are hermetic in-memory repositories and scripted model clients
// (no MongoDB, no network, no scheduler, no live model calls, no secrets).
// Wire shapes follow backend/test/research-compatibility.test.cjs (H15,
// controller-verified) and backend/test/positions.test.cjs.
//
// Interfaces consumed (accepted upstream evidence): H01 contracts, H03
// fail-closed automation auth + lease nonce, H04 positions wire, H05/H08 run
// lifecycle (deadline/stall/recovery), H06 evidence binding, H07 frozen
// metrics, H09 agent runtime (economics.status authoritative), H10 automation
// poll, H11 repaired repository shapes (top-level getLatest wire), H15 glue.

const assert = require('node:assert/strict');
const http = require('node:http');
const crypto = require('node:crypto');
const test = require('node:test');

const { createApp } = require('../src/app');
const { composeAutomationSurface } = require('../src/server');
const { PositionService } = require('../src/features/positions/position.service');
const { MarketHistoryService } = require('../src/features/market/market.service');
const { createMarketRouter } = require('../src/features/market/market.routes');

// ---------------------------------------------------------------------------
// Instruments, clock, fixtures (synthetic; NOT observed market data)
// ---------------------------------------------------------------------------

const OWNER_A = 'owner-h17-aaaa';
const OWNER_B = 'owner-h17-bbbb';

const INSTRUMENT_MAIN = Object.freeze({
  instrument_id: 'instrument-h17-main',
  symbol: 'TEST',
  exchange: 'XNYS',
  currency: 'USD',
  provider_symbol: 'TEST',
});

const INSTRUMENT_SECOND = Object.freeze({
  instrument_id: 'instrument-h17-second',
  symbol: 'OTHR',
  exchange: 'XNAS',
  currency: 'USD',
  provider_symbol: 'OTHR',
});

const CLOCK_START = '2030-01-02T15:00:00.000Z';

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

function weekdayPredicate(sessionDate) {
  const weekday = new Date(`${sessionDate}T00:00:00Z`).getUTCDay();
  return weekday >= 1 && weekday <= 5;
}

function duplicate(code, message) {
  const error = new Error(message || code);
  error.code = code;
  return error;
}

function evidenceItem(id, kind, availableAt) {
  return {
    id,
    instrument_id: 'set-by-fixture',
    kind,
    title: `Fixture ${id}`,
    source_url: `https://fixture.example/${id}`,
    source_name: 'Fixture Source',
    published_at: availableAt,
    retrieved_at: '2030-01-01T20:00:00.000Z',
    available_at: availableAt,
    reporting_period: null,
    excerpt: `Fixture excerpt for ${id}.`,
    source_locator: null,
    facts: [],
    coverage_status: 'available',
  };
}

// Evidence snapshot fixture per instrument. Item ids and the metric id are the
// exact grounded references the valid synthesis fixture cites.
function fixtureEvidenceSnapshot(instrument, { snapshotId, coverage = 'available', gaps = [] } = {}) {
  return {
    snapshot_id: snapshotId,
    instrument_id: instrument.instrument_id,
    session_as_of: '2030-01-01',
    cutoff_at: '2030-01-01T20:00:00.000Z',
    coverage: { status: coverage, gaps: [...gaps] },
    items: [
      { ...evidenceItem('ev-filing', 'filing', '2030-01-01T14:00:00.000Z'), instrument_id: instrument.instrument_id },
      { ...evidenceItem('ev-news', 'news', '2030-01-01T16:00:00.000Z'), instrument_id: instrument.instrument_id },
    ],
  };
}

function fixtureMetrics(instrument, snapshotId, close) {
  return [
    {
      id: 'm-close',
      instrument_id: instrument.instrument_id,
      value: close,
      unit: 'USD',
      currency: 'USD',
      as_of: '2030-01-01',
      basis: 'raw_close',
      method: 'last_close',
      method_version: 'v1',
      input_evidence_ids: ['ev-filing'],
      input_snapshot_ids: [snapshotId],
    },
  ];
}

function claim(text, { evidence = ['ev-filing'], metrics = [], type = 'observed' } = {}) {
  return { text, evidence_ids: evidence, metric_ids: metrics, claim_type: type };
}

// Valid synthesis fixture (proven to pass the H09 validator in H15 evidence).
// `action` must be state-compatible: candidate positions may only receive
// buy/wait/avoid/insufficient_evidence (CONTRACTS §5).
function validSynthesis({ action = 'wait' } = {}) {
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
      action,
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

// Deliberately schema-invalid synthesis for the schema-failure injection.
function invalidSynthesis() {
  return {
    market_thesis: { business_assessment: { summary: 'incomplete' } },
    recommendation: { action: 'not_a_valid_action' },
    outlooks: [],
  };
}

// ---------------------------------------------------------------------------
// Scripted model client (hermetic; no live calls)
// ---------------------------------------------------------------------------

function createModelClient() {
  const state = { calls: [], queue: [], blocks: [] };
  state.enqueueOutput = (output) => state.queue.push({ type: 'output', output });
  state.enqueueError = (error) => state.queue.push({ type: 'error', error });
  state.enqueueBlock = () => {
    let resolve;
    const promise = new Promise((res) => { resolve = res; });
    const block = { type: 'block', promise, resolve };
    state.queue.push(block);
    state.blocks.push(block);
    return block;
  };
  state.complete = async (request) => {
    state.calls.push(request);
    const behavior = state.queue.shift();
    if (!behavior) throw new Error('fixture model client exhausted');
    if (behavior.type === 'error') throw behavior.error;
    if (behavior.type === 'block') return { output: await behavior.promise };
    return { output: structuredClone(behavior.output) };
  };
  return state;
}

// ---------------------------------------------------------------------------
// Hermetic in-memory repositories
// ---------------------------------------------------------------------------

function createInMemoryPositionRepository() {
  const docs = new Map();
  let nextId = 1;
  return {
    docs,
    nextIdLabel: () => `pos-h17-${nextId += 1}`,
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

function createInMemoryMarketSnapshotRepository(initial = []) {
  const rows = [...initial];
  return {
    rows,
    async latestForCacheKey(cacheKey) {
      return rows.filter((entry) => entry.cache_key === cacheKey).at(-1) || null;
    },
    async findById(id) {
      return rows.find((entry) => entry.snapshot_id === id) || null;
    },
    async create(snapshot) {
      rows.push(structuredClone(snapshot));
      return structuredClone(snapshot);
    },
  };
}

// ---------------------------------------------------------------------------
// HTTP harness
// ---------------------------------------------------------------------------

function makeAutomationIdentity({ ownerId = OWNER_A } = {}) {
  return {
    token: crypto.randomBytes(32).toString('hex'),
    scopes: ['research:trigger', 'research:input', 'research:status', 'research:execute', 'research:callback'],
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

function jsonRequest(method, pathName, { headers = {}, body } = {}) {
  return {
    method,
    headers: { 'content-type': 'application/json', ...headers },
    ...(body !== undefined ? { body: JSON.stringify(body) } : {}),
  };
}

let harnessCounter = 0;

// Full composed harness: positions + research + market + automation over ONE
// shared runs store, an injected clock, and a scripted model client.
function createHarness({
  deadlineSeconds = 900,
  leaseSeconds = 300,
  positionRepository = createInMemoryPositionRepository(),
  runRepository = createInMemoryRunRepository(),
  assessmentRepository = createInMemoryAssessmentRepository(),
  researchSnapshotRepository = createInMemoryResearchSnapshotRepository(),
  checkpointRepository = createInMemoryCheckpointRepository(),
  modelClient = createModelClient(),
} = {}) {
  const clock = clockHarness();
  const identity = makeAutomationIdentity();
  const suffix = `s${(harnessCounter += 1)}`;
  let runCount = 0;
  let assessmentCount = 0;
  let snapshotCount = 0;
  let checkpointCount = 0;
  const factories = {
    idFactory: () => `run-h17-${suffix}-${(runCount += 1)}`,
    assessmentIdFactory: () => `assessment-h17-${suffix}-${(assessmentCount += 1)}`,
    snapshotIdFactory: () => `snapshot-h17-${suffix}-${(snapshotCount += 1)}`,
    checkpointIdFactory: () => `checkpoint-h17-${suffix}-${(checkpointCount += 1)}`,
  };

  const positionService = new PositionService({
    positionRepository,
    now: clock.now,
    idFactory: () => positionRepository.nextIdLabel(),
  });

  // Evidence snapshot store: the source-injection seam. recordRunResult
  // verifies deliveries against the registered instrument-bound snapshots.
  const evidenceSnapshots = new Map();
  const evidenceSnapshotLookup = async (snapshotId) => {
    const snapshot = evidenceSnapshots.get(snapshotId);
    return snapshot ? { snapshot_id: snapshot.snapshot_id, instrument_id: snapshot.instrument_id } : null;
  };
  const registerEvidence = (snapshot) => {
    evidenceSnapshots.set(snapshot.snapshot_id, snapshot);
    return snapshot;
  };

  const listQueuedRuns = async ({ ownerId, limit, nowIso }) => runRepository.records
    .filter((run) => run.owner_id_internal === ownerId && run.status === 'queued' && run.deadline_at > nowIso)
    .sort((a, b) => a.created_at.localeCompare(b.created_at))
    .slice(0, limit)
    .map((run) => ({
      run_id: run.id,
      position_id: run.position_id,
      position_revision: run.position_revision,
      run_kind: run.run_kind,
      status: run.status,
      created_at: run.created_at,
      deadline_at: run.deadline_at,
    }));

  // The input provider resolves the LIVE position document at claim time, so
  // a concurrent edit after claim is observable to the pipeline exactly the
  // way production resolution would observe it. Evidence per instrument comes
  // from evidenceFor (overridable per test); defaults are registered below.
  const evidenceFor = new Map();
  const inputProvider = async (claimedRun) => {
    const doc = await positionRepository.findById(claimedRun.position_id);
    if (!doc) throw new Error('fixture: position missing for run');
    const instrumentId = doc.instrument.instrument_id;
    const evidence = evidenceFor.get(instrumentId)
      || (instrumentId === INSTRUMENT_SECOND.instrument_id
        ? defaultSecondEvidence
        : defaultMainEvidence);
    return {
      snapshot: structuredClone(evidence.snapshot),
      metrics: structuredClone(evidence.metrics),
      instrument: structuredClone(doc.instrument),
      position: {
        position_id: doc.id,
        instrument_id: instrumentId,
        state: doc.state,
        revision: doc.revision,
        average_cost: doc.average_cost ? structuredClone(doc.average_cost) : null,
        quantity: doc.quantity,
        opened_on: doc.opened_on,
        preferred_horizon_months: doc.preferred_horizon_months,
      },
      prior: null,
      currentPrice: instrumentId === INSTRUMENT_SECOND.instrument_id
        ? { amount: '75.00', currency: 'USD', adjustment_basis: 'raw_purchase' }
        : { amount: '150.00', currency: 'USD', adjustment_basis: 'raw_purchase' },
    };
  };

  function makeSurface(overrides = {}) {
    return composeAutomationSurface({
      modelClient,
      inputProvider,
      runRepository,
      assessmentRepository,
      researchSnapshotRepository,
      checkpointRepository,
      evidenceSnapshotLookup,
      automation: overrides.automation || {
        token: identity.token,
        scopes: [...identity.scopes],
        ownerId: identity.ownerId,
      },
      listQueuedRuns,
      now: clock.now,
      deadlineSeconds,
      leaseSeconds,
      ...factories,
      isExchangeSession: weekdayPredicate,
      logger: { warn: () => {} },
      ...overrides,
    });
  }

  const primary = makeSurface();

  // Observed-history market slice with a fixture provider (never real data).
  let marketSnapCount = 0;
  const marketBars5m = Object.freeze([
    {
      time: '2030-01-01T14:30:00Z', session_date: '2030-01-01',
      open: 148.0, high: 151.0, low: 147.5, close: 150.0, volume: 1200,
      adjusted_close: null, is_final: true,
    },
    {
      time: '2030-01-01T14:35:00Z', session_date: '2030-01-01',
      open: 150.0, high: 150.8, low: 149.2, close: 149.6, volume: 900,
      adjusted_close: null, is_final: true,
    },
  ]);
  const marketBars1d = Object.freeze([
    {
      time: '2029-12-03T14:30:00Z', session_date: '2029-12-03',
      open: 140.0, high: 143.0, low: 139.0, close: 142.0, volume: 150000,
      adjusted_close: null, is_final: true,
    },
    {
      time: '2030-01-01T14:30:00Z', session_date: '2030-01-01',
      open: 148.0, high: 151.0, low: 147.5, close: 150.0, volume: 160000,
      adjusted_close: null, is_final: true,
    },
  ]);
  const marketService = new MarketHistoryService({
    provider: {
      async fetchHistory(instrument, { resolution }) {
        const bars = resolution === '5m' ? marketBars5m : marketBars1d;
        return {
          bars: bars.map((bar) => ({ ...bar })),
          actual_resolution: resolution,
          exchange_timezone: 'America/New_York',
          adjustment_basis: 'raw_ohlc_unadjusted',
          delay_status: 'delayed',
          as_of: '2030-01-01T20:00:00Z',
          fetched_at: clock.nowIso(),
          source: { name: 'Fixture provider', provider: 'fixture_provider' },
          warnings: [],
        };
      },
    },
    snapshotRepository: createInMemoryMarketSnapshotRepository(),
    now: clock.now,
    snapshotIdFactory: () => `market-snap-${suffix}-${(marketSnapCount += 1)}`,
    instrumentResolver: async (id) => [INSTRUMENT_MAIN, INSTRUMENT_SECOND]
      .find((instrument) => instrument.instrument_id === id) || null,
  });
  const marketRouter = createMarketRouter({ marketService, authenticate: makeUserAuth() });

  const app = createApp({
    marketRouter,
    positionService,
    researchService: primary.researchService,
    automationRouter: primary.router,
    authenticate: makeUserAuth(),
    logging: false,
  });

  // Default per-instrument evidence registered for source binding.
  const defaultMainSnapshot = registerEvidence(fixtureEvidenceSnapshot(INSTRUMENT_MAIN, {
    snapshotId: `snap-h17-main-${suffix}`,
  }));
  const defaultSecondSnapshot = registerEvidence(fixtureEvidenceSnapshot(INSTRUMENT_SECOND, {
    snapshotId: `snap-h17-second-${suffix}`,
  }));
  const defaultMainMetrics = fixtureMetrics(INSTRUMENT_MAIN, defaultMainSnapshot.snapshot_id, 150);
  const defaultSecondMetrics = fixtureMetrics(INSTRUMENT_SECOND, defaultSecondSnapshot.snapshot_id, 75);
  const defaultMainEvidence = { snapshot: defaultMainSnapshot, metrics: defaultMainMetrics };
  const defaultSecondEvidence = { snapshot: defaultSecondSnapshot, metrics: defaultSecondMetrics };
  evidenceFor.set(INSTRUMENT_MAIN.instrument_id, defaultMainEvidence);
  evidenceFor.set(INSTRUMENT_SECOND.instrument_id, defaultSecondEvidence);

  return {
    clock,
    identity,
    app,
    positionService,
    positionRepository,
    runRepository,
    assessmentRepository,
    researchSnapshotRepository,
    checkpointRepository,
    evidenceSnapshots,
    evidenceFor,
    registerEvidence,
    modelClient,
    worker: primary.worker,
    researchService: primary.researchService,
    makeSurface,
    factories,
    marketService,
  };
}

// ---------------------------------------------------------------------------
// Shared journey steps
// ---------------------------------------------------------------------------

async function createCandidate(baseUrl, instrument = INSTRUMENT_MAIN, extra = {}) {
  const created = await request(baseUrl, '/api/v1/positions', jsonRequest('POST', '/api/v1/positions', {
    headers: { authorization: 'Bearer token-owner-a' },
    body: {
      state: 'candidate',
      instrument,
      review_conditions: ['Enters below 90 on rising volume'],
      ...extra,
    },
  }));
  assert.equal(created.status, 201, `candidate create failed: ${JSON.stringify(created.body)}`);
  return created.body;
}

async function queueRun(baseUrl, positionId, { revision, instrumentId, key, payload }) {
  return request(baseUrl, `/api/v1/research/positions/${positionId}/runs`, jsonRequest('POST', '', {
    headers: { authorization: 'Bearer token-owner-a', 'idempotency-key': key },
    body: {
      position_revision: revision,
      run_kind: 'manual_refresh',
      instrument_id: instrumentId,
      request_payload: payload || { trigger: 'h17-fixture' },
    },
  }));
}

async function executeRun(baseUrl, harness, runId) {
  return request(baseUrl, `/api/v1/automation/research/runs/${runId}/execute`, jsonRequest('POST', '', {
    headers: authorizedAutomationHeaders(harness.identity),
  }));
}

async function automationStatus(baseUrl, harness, runId) {
  return request(baseUrl, `/api/v1/automation/research/runs/${runId}/status`, {
    headers: authorizedAutomationHeaders(harness.identity),
  });
}

async function ownerGet(baseUrl, pathName) {
  return request(baseUrl, pathName, { headers: { authorization: 'Bearer token-owner-a' } });
}

// ---------------------------------------------------------------------------
// Section A — candidate add -> research -> owned transition -> cost edit
// ---------------------------------------------------------------------------

test('A1: candidate add produces the full contract wire and rejects duplicates/unknown fields', async () => {
  const harness = createHarness();
  await withTestServer(harness.app, async (baseUrl) => {
    const candidate = await createCandidate(baseUrl);
    assert.equal(candidate.state, 'candidate');
    assert.equal(candidate.revision, 1);
    assert.equal(candidate.instrument.instrument_id, INSTRUMENT_MAIN.instrument_id);
    assert.deepEqual(
      Object.keys(candidate.instrument).sort(),
      ['currency', 'exchange', 'instrument_id', 'provider_symbol', 'symbol'],
    );
    assert.equal(candidate.average_cost, null);
    assert.equal(candidate.quantity, null);
    assert.equal(candidate.opened_on, null);
    assert.deepEqual(candidate.review_conditions, ['Enters below 90 on rising volume']);
    assert.equal(Object.prototype.hasOwnProperty.call(candidate, 'owner_id'), false);

    // Duplicate active identity -> 409.
    const duplicateCreate = await request(baseUrl, '/api/v1/positions', jsonRequest('POST', '/api/v1/positions', {
      headers: { authorization: 'Bearer token-owner-a' },
      body: { state: 'candidate', instrument: INSTRUMENT_MAIN },
    }));
    assert.equal(duplicateCreate.status, 409);
    assert.equal(duplicateCreate.body.code, 'DUPLICATE_POSITION');

    // Unknown write fields are rejected (CONTRACTS §1).
    const unknownField = await request(baseUrl, '/api/v1/positions', jsonRequest('POST', '/api/v1/positions', {
      headers: { authorization: 'Bearer token-owner-a' },
      body: { state: 'candidate', instrument: INSTRUMENT_SECOND, owner_id: OWNER_B, bogus: 1 },
    }));
    assert.equal(unknownField.status, 400);

    // The list endpoint is an envelope and stays owner-scoped.
    const listA = await ownerGet(baseUrl, '/api/v1/positions');
    assert.equal(listA.status, 200);
    assert.equal(listA.body.positions.length, 1);
    const listB = await request(baseUrl, '/api/v1/positions', { headers: { authorization: 'Bearer token-owner-b' } });
    assert.equal(listB.status, 200);
    assert.equal(listB.body.positions.length, 0);
  });
});

test('A2: run queueing honors persisted idempotency and single-active-run semantics', async () => {
  const harness = createHarness();
  await withTestServer(harness.app, async (baseUrl) => {
    const candidate = await createCandidate(baseUrl);

    const missingKey = await request(baseUrl, `/api/v1/research/positions/${candidate.id}/runs`, jsonRequest('POST', '', {
      headers: { authorization: 'Bearer token-owner-a' },
      body: { position_revision: 1, run_kind: 'manual_refresh', instrument_id: INSTRUMENT_MAIN.instrument_id, request_payload: {} },
    }));
    assert.equal(missingKey.status, 400);
    assert.equal(missingKey.body.code, 'MISSING_IDEMPOTENCY_KEY');

    const first = await queueRun(baseUrl, candidate.id, {
      revision: 1, instrumentId: INSTRUMENT_MAIN.instrument_id, key: 'key-a2-1',
    });
    assert.equal(first.status, 202);
    assert.equal(first.body.idempotent_replay, false);
    const runId = first.body.run.id;

    const replay = await queueRun(baseUrl, candidate.id, {
      revision: 1, instrumentId: INSTRUMENT_MAIN.instrument_id, key: 'key-a2-1',
    });
    assert.equal(replay.status, 202);
    assert.equal(replay.body.idempotent_replay, true);
    assert.equal(replay.body.run.id, runId);

    const conflict = await queueRun(baseUrl, candidate.id, {
      revision: 1, instrumentId: INSTRUMENT_MAIN.instrument_id, key: 'key-a2-1',
      payload: { trigger: 'different' },
    });
    assert.equal(conflict.status, 409);
    assert.equal(conflict.body.code, 'IDEMPOTENCY_CONFLICT');

    const secondActive = await queueRun(baseUrl, candidate.id, {
      revision: 1, instrumentId: INSTRUMENT_MAIN.instrument_id, key: 'key-a2-2',
      payload: { trigger: 'other' },
    });
    assert.equal(secondActive.status, 409);
    assert.equal(secondActive.body.code, 'RUN_ALREADY_ACTIVE');
  });
});

test('A3: candidate research journey — automation surface, input binding, publish, honest status', async () => {
  const harness = createHarness();
  harness.modelClient.enqueueOutput(validSynthesis());
  await withTestServer(harness.app, async (baseUrl) => {
    const candidate = await createCandidate(baseUrl);

    const queued = await queueRun(baseUrl, candidate.id, {
      revision: 1, instrumentId: INSTRUMENT_MAIN.instrument_id, key: 'key-a3-1',
    });
    assert.equal(queued.status, 202);
    const runId = queued.body.run.id;

    // The scoped automation identity sees the same run; no economics leak.
    const listed = await request(baseUrl, '/api/v1/automation/research/runs/queued', {
      headers: authorizedAutomationHeaders(harness.identity),
    });
    assert.equal(listed.status, 200);
    assert.equal(listed.body.runs.length, 1);
    assert.equal(listed.body.runs[0].run_id, runId);

    const inputView = await request(baseUrl, `/api/v1/automation/research/runs/${runId}/input`, {
      headers: authorizedAutomationHeaders(harness.identity),
    });
    assert.equal(inputView.status, 200);
    assert.equal(inputView.body.run_id, runId);
    assert.equal(inputView.body.instrument_id, INSTRUMENT_MAIN.instrument_id);
    assert.equal(inputView.body.snapshot_id != null, true);
    assert.equal(JSON.stringify(inputView.body).includes('average_cost'), false);
    assert.equal(JSON.stringify(inputView.body).includes('lease_nonce'), false);

    // Execute claims the run and returns the lease nonce ONLY here.
    const executed = await executeRun(baseUrl, harness, runId);
    assert.equal(executed.status, 202);
    assert.equal(executed.body.status, 'accepted');
    assert.equal(typeof executed.body.lease_nonce, 'string');
    assert.ok(executed.body.lease_nonce.length > 0);
    await harness.worker.whenSettled(runId);

    // User-facing run view: no lease nonce, honest terminal status.
    const runView = await ownerGet(baseUrl, `/api/v1/research/runs/${runId}`);
    assert.equal(runView.status, 200);
    assert.equal(runView.body.run.status, 'succeeded');
    assert.equal(Object.prototype.hasOwnProperty.call(runView.body.run, 'lease_nonce'), false);

    // Candidate assessment: economics unavailable, candidate action set,
    // exactly three server-dated outlooks, numeric projection null (H07A held).
    const latest = await ownerGet(baseUrl, `/api/v1/research/positions/${candidate.id}/latest`);
    assert.equal(latest.status, 200);
    assert.equal(latest.body.position_id, candidate.id);
    const assessment = latest.body.latest_assessment;
    assert.ok(assessment, 'candidate run published an assessment');
    assert.equal(assessment.position_revision, 1);
    assert.equal(assessment.instrument_id, INSTRUMENT_MAIN.instrument_id);
    assert.equal(assessment.status, 'complete');
    assert.deepEqual(assessment.assessment.economics, { status: 'unavailable', reason: 'state_without_executed_economics' });
    assert.equal(assessment.assessment.position_context.state, 'candidate');
    assert.equal(assessment.assessment.position_context.economics_status, 'unavailable');
    assert.equal(assessment.assessment.position_context.average_cost, undefined);
    assert.ok(['buy', 'wait', 'avoid', 'insufficient_evidence'].includes(assessment.assessment.recommendation.action));
    assert.equal(assessment.assessment.outlooks.length, 3);
    assert.deepEqual(assessment.assessment.outlooks.map((o) => o.horizon_months), [1, 2, 3]);
    for (const outlook of assessment.assessment.outlooks) {
      assert.ok(outlook.calendar_target_date >= assessment.session_as_of);
      assert.ok(outlook.evaluation_session_date <= outlook.calendar_target_date);
      assert.ok(outlook.evaluation_session_date >= assessment.session_as_of);
      assert.equal(outlook.numeric_projection, null);
    }
    assert.equal(assessment.assessment.outlooks[0].calendar_target_date, '2030-02-01');

    // H11 repaired latest wire: last_success and latest_attempt are separate.
    assert.equal(latest.body.run_state.last_success.run_id, runId);
    assert.equal(latest.body.run_state.last_success.assessment_id, assessment.id);
    assert.equal(latest.body.run_state.latest_attempt.run_id, runId);
    assert.equal(latest.body.run_state.latest_attempt.status, 'succeeded');
    assert.equal(Object.prototype.hasOwnProperty.call(assessment, 'owner_id_internal'), false);

    // Cross-owner reads are indistinguishable denials.
    const crossOwner = await request(baseUrl, `/api/v1/research/runs/${runId}`, {
      headers: { authorization: 'Bearer token-owner-b' },
    });
    assert.equal(crossOwner.status, 404);
    const latestB = await request(baseUrl, `/api/v1/research/positions/${candidate.id}/latest`, {
      headers: { authorization: 'Bearer token-owner-b' },
    });
    assert.equal(latestB.status, 200);
    assert.equal(latestB.body.latest_assessment, null);
    assert.equal(latestB.body.run_state.last_success, null);
  });
});

test('A4: owned transition -> economics computed; cost edit -> thesis unchanged, P/L recomputed', async () => {
  const harness = createHarness();
  await withTestServer(harness.app, async (baseUrl) => {
    const candidate = await createCandidate(baseUrl);

    // Candidate research at revision 1 (candidate action set: 'wait').
    harness.modelClient.enqueueOutput(validSynthesis({ action: 'wait' }));
    const run1 = await queueRun(baseUrl, candidate.id, {
      revision: 1, instrumentId: INSTRUMENT_MAIN.instrument_id, key: 'key-a4-1',
    });
    await executeRun(baseUrl, harness, run1.body.run.id);
    await harness.worker.whenSettled(run1.body.run.id);
    const before = await ownerGet(baseUrl, `/api/v1/research/positions/${candidate.id}/latest`);
    const candidateAssessment = before.body.latest_assessment;
    assert.equal(candidateAssessment.assessment.recommendation.action, 'wait');

    // Candidate records must not carry executed economics (CONTRACTS §2).
    const badCandidateEconomics = await request(baseUrl, `/api/v1/positions/${candidate.id}`, jsonRequest('PATCH', '', {
      headers: { authorization: 'Bearer token-owner-a' },
      body: { expected_revision: 1, changes: { average_cost: { amount: '100.00', currency: 'USD' } } },
    }));
    assert.equal(badCandidateEconomics.status, 400);
    assert.equal(badCandidateEconomics.body.code, 'INVALID_CANDIDATE_ECONOMICS');

    // Explicit user transition to owned (revision 2).
    const owned = await request(baseUrl, `/api/v1/positions/${candidate.id}`, jsonRequest('PATCH', '', {
      headers: { authorization: 'Bearer token-owner-a' },
      body: {
        expected_revision: 1,
        changes: {
          state: 'owned',
          average_cost: { amount: '100.00', currency: 'USD' },
          quantity: '10',
          opened_on: '2029-06-01',
        },
      },
    }));
    assert.equal(owned.status, 200, JSON.stringify(owned.body));
    assert.equal(owned.body.revision, 2);
    assert.equal(owned.body.state, 'owned');
    assert.equal(owned.body.average_cost.amount, '100.00');

    // Stale expected_revision -> 409 REVISION_CONFLICT.
    const stale = await request(baseUrl, `/api/v1/positions/${candidate.id}`, jsonRequest('PATCH', '', {
      headers: { authorization: 'Bearer token-owner-a' },
      body: { expected_revision: 1, changes: { original_thesis: 'stale' } },
    }));
    assert.equal(stale.status, 409);
    assert.equal(stale.body.code, 'REVISION_CONFLICT');

    // Research at revision 2: deterministic server economics join.
    harness.modelClient.enqueueOutput(validSynthesis({ action: 'hold' }));
    const run2 = await queueRun(baseUrl, candidate.id, {
      revision: 2, instrumentId: INSTRUMENT_MAIN.instrument_id, key: 'key-a4-2',
    });
    await executeRun(baseUrl, harness, run2.body.run.id);
    await harness.worker.whenSettled(run2.body.run.id);
    const after = await ownerGet(baseUrl, `/api/v1/research/positions/${candidate.id}/latest`);
    const ownedAssessment = after.body.latest_assessment;
    assert.equal(ownedAssessment.position_revision, 2);
    assert.deepEqual(ownedAssessment.assessment.economics, {
      status: 'available',
      currency: 'USD',
      average_cost: 100,
      current_price: 150,
      quantity: 10,
      absolute_pl: 500,
      percent_pl: 0.5,
      excluded_adjustments: ['fees', 'dividends'],
    });
    assert.equal(ownedAssessment.assessment.position_context.economics_status, 'available');
    assert.deepEqual(ownedAssessment.assessment.position_context.average_cost, { amount: '100.00', currency: 'USD' });

    // The market thesis is never derived from cost: identical synthesis in,
    // identical market thesis out; only position economics differ. The
    // state-compatible action legitimately moves wait -> hold on transition.
    assert.deepEqual(ownedAssessment.assessment.market_thesis, candidateAssessment.assessment.market_thesis);
    assert.equal(ownedAssessment.assessment.recommendation.action, 'hold');
    assert.notDeepEqual(ownedAssessment.assessment.economics, candidateAssessment.assessment.economics);

    // Cost edit (revision 3) changes economics, never the market thesis.
    const costEdit = await request(baseUrl, `/api/v1/positions/${candidate.id}`, jsonRequest('PATCH', '', {
      headers: { authorization: 'Bearer token-owner-a' },
      body: { expected_revision: 2, changes: { average_cost: { amount: '120.00', currency: 'USD' } } },
    }));
    assert.equal(costEdit.status, 200);
    assert.equal(costEdit.body.revision, 3);

    harness.modelClient.enqueueOutput(validSynthesis({ action: 'hold' }));
    const run3 = await queueRun(baseUrl, candidate.id, {
      revision: 3, instrumentId: INSTRUMENT_MAIN.instrument_id, key: 'key-a4-3',
    });
    await executeRun(baseUrl, harness, run3.body.run.id);
    await harness.worker.whenSettled(run3.body.run.id);
    const afterEdit = await ownerGet(baseUrl, `/api/v1/research/positions/${candidate.id}/latest`);
    assert.equal(afterEdit.body.latest_assessment.position_revision, 3);
    assert.equal(afterEdit.body.latest_assessment.assessment.economics.absolute_pl, 300);
    assert.equal(afterEdit.body.latest_assessment.assessment.economics.percent_pl, 0.25);
    assert.deepEqual(
      afterEdit.body.latest_assessment.assessment.market_thesis,
      candidateAssessment.assessment.market_thesis,
      'cost edit must not change the market thesis',
    );
    assert.deepEqual(
      afterEdit.body.latest_assessment.assessment.recommendation,
      ownedAssessment.assessment.recommendation,
      'cost edit must not change the recommendation',
    );

    // Immutable history: three assessments, paginated.
    const history = await ownerGet(baseUrl, `/api/v1/research/positions/${candidate.id}/assessments`);
    assert.equal(history.status, 200);
    assert.equal(history.body.assessments.length, 3);
    assert.equal(history.body.next_cursor, null);
    const page = await ownerGet(baseUrl, `/api/v1/research/positions/${candidate.id}/assessments?limit=2`);
    assert.equal(page.body.assessments.length, 2);
    assert.ok(page.body.next_cursor);
    for (const entry of history.body.assessments) {
      assert.equal(entry.artifact_kind, 'judgment');
    }
  });
});

// ---------------------------------------------------------------------------
// Section B — observed history for the chart ranges (source of chart data)
// ---------------------------------------------------------------------------

test('B1: chart ranges resolve with truthful resolutions, provenance and OHLC integrity', async () => {
  const harness = createHarness();
  await withTestServer(harness.app, async (baseUrl) => {
    const day = await ownerGet(baseUrl, `/api/v1/market/instruments/${INSTRUMENT_MAIN.instrument_id}/history?range=1D`);
    assert.equal(day.status, 200);
    assert.equal(day.body.data_status, 'available');
    assert.equal(day.body.requested_resolution, '5m');
    assert.equal(day.body.actual_resolution, '5m');
    assert.equal(day.body.delay_status, 'delayed');
    assert.notEqual(day.body.delay_status, 'realtime');
    assert.equal(day.body.adjustment_basis, 'raw_ohlc_unadjusted');
    assert.equal(day.body.instrument.instrument_id, INSTRUMENT_MAIN.instrument_id);
    assert.ok(day.body.snapshot_id);
    assert.equal(day.body.bars.length, 2);
    for (const bar of day.body.bars) {
      assert.ok(bar.low <= Math.min(bar.open, bar.close) && Math.max(bar.open, bar.close) <= bar.high);
      assert.ok(Number.isFinite(bar.close) && bar.close > 0);
    }

    const month = await ownerGet(baseUrl, `/api/v1/market/instruments/${INSTRUMENT_MAIN.instrument_id}/history?range=1M`);
    assert.equal(month.status, 200);
    assert.equal(month.body.actual_resolution, '1d');
    assert.equal(month.body.range, '1M');
    assert.equal(month.body.bars.length, 2);

    // A second configured instrument is served by the same surface.
    const second = await ownerGet(baseUrl, `/api/v1/market/instruments/${INSTRUMENT_SECOND.instrument_id}/history?range=1Y`);
    assert.equal(second.status, 200);
    assert.equal(second.body.data_status, 'available');
    assert.equal(second.body.instrument.instrument_id, INSTRUMENT_SECOND.instrument_id);

    // Unauthenticated reads are rejected.
    const anon = await request(baseUrl, `/api/v1/market/instruments/${INSTRUMENT_MAIN.instrument_id}/history?range=1D`);
    assert.equal(anon.status, 401);
  });
});

test('B2: unsupported resolutions and unknown instruments degrade truthfully', async () => {
  const harness = createHarness();
  await withTestServer(harness.app, async (baseUrl) => {
    const unsupported = await ownerGet(baseUrl, `/api/v1/market/instruments/${INSTRUMENT_MAIN.instrument_id}/history?range=1W&resolution=1m`);
    assert.equal(unsupported.status, 200);
    assert.equal(unsupported.body.data_status, 'unavailable');
    assert.equal(unsupported.body.unavailable_reason, 'UNSUPPORTED_RESOLUTION');
    assert.deepEqual(unsupported.body.bars, []);

    const badRange = await ownerGet(baseUrl, `/api/v1/market/instruments/${INSTRUMENT_MAIN.instrument_id}/history?range=5Y`);
    assert.equal(badRange.status, 400);

    const unknown = await ownerGet(baseUrl, '/api/v1/market/instruments/instrument-h17-missing/history?range=1D');
    assert.equal(unknown.status, 404);
  });
});

// ---------------------------------------------------------------------------
// Section C — failure injection
// ---------------------------------------------------------------------------

test('C1: provider failure injection fails the run honestly; last success stays separate', async () => {
  const harness = createHarness();
  await withTestServer(harness.app, async (baseUrl) => {
    const candidate = await createCandidate(baseUrl);

    harness.modelClient.enqueueOutput(validSynthesis());
    const good = await queueRun(baseUrl, candidate.id, {
      revision: 1, instrumentId: INSTRUMENT_MAIN.instrument_id, key: 'key-c1-good',
    });
    await executeRun(baseUrl, harness, good.body.run.id);
    await harness.worker.whenSettled(good.body.run.id);

    harness.modelClient.enqueueError(new Error('fixture provider outage'));
    const bad = await queueRun(baseUrl, candidate.id, {
      revision: 1, instrumentId: INSTRUMENT_MAIN.instrument_id, key: 'key-c1-bad',
      payload: { trigger: 'retry-after-outage' },
    });
    assert.equal(bad.status, 202);
    await executeRun(baseUrl, harness, bad.body.run.id);
    const settled = await harness.worker.whenSettled(bad.body.run.id);
    assert.equal(settled.run.status, 'failed');
    assert.equal(settled.run.error_code, 'MODEL_CLIENT_FAILED');

    const latest = await ownerGet(baseUrl, `/api/v1/research/positions/${candidate.id}/latest`);
    assert.equal(latest.body.run_state.last_success.run_id, good.body.run.id, 'last success is never rewritten');
    assert.equal(latest.body.run_state.latest_attempt.run_id, bad.body.run.id);
    assert.equal(latest.body.run_state.latest_attempt.status, 'failed');
    assert.equal(latest.body.run_state.latest_attempt.error_code, 'MODEL_CLIENT_FAILED');
    // The earlier successful assessment remains the published latest.
    assert.ok(latest.body.latest_assessment, 'the earlier success must remain the published latest');
    assert.equal(latest.body.latest_assessment.id, harness.assessmentRepository.records[0].id);
  });
});

test('C2: schema failure injection is bounded at two synthesis attempts', async () => {
  const harness = createHarness();
  harness.modelClient.enqueueOutput(invalidSynthesis());
  harness.modelClient.enqueueOutput(invalidSynthesis());
  await withTestServer(harness.app, async (baseUrl) => {
    const candidate = await createCandidate(baseUrl);
    const queued = await queueRun(baseUrl, candidate.id, {
      revision: 1, instrumentId: INSTRUMENT_MAIN.instrument_id, key: 'key-c2-1',
    });
    await executeRun(baseUrl, harness, queued.body.run.id);
    const settled = await harness.worker.whenSettled(queued.body.run.id);
    assert.equal(settled.run.status, 'failed');
    assert.equal(settled.run.error_code, 'SYNTHESIS_VALIDATION_FAILED');
    assert.equal(harness.modelClient.calls.length, 2, 'CONTRACTS §8: at most two synthesis/repair attempts');
    assert.equal(harness.assessmentRepository.records.length, 0, 'no invalid assessment is persisted');
    assert.equal(harness.assessmentRepository.records.filter((a) => a.run_id === queued.body.run.id).length, 0);
  });
});

test('C3: unavailable evidence coverage fails the run before any model call', async () => {
  // The harness input provider binds evidence per instrument, so starvation is
  // exercised through a dedicated surface whose provider returns an
  // unavailable snapshot (the same seams composeAutomationSurface exposes).
  const harness = createHarness();
  const emptySnapshot = fixtureEvidenceSnapshot(INSTRUMENT_MAIN, {
    snapshotId: 'snap-h17-starved', coverage: 'unavailable', gaps: ['no_sources_available'],
  });
  const starvedSurface = harness.makeSurface({
    modelClient: harness.modelClient,
    inputProvider: async (claimedRun) => {
      const doc = await harness.positionRepository.findById(claimedRun.position_id);
      if (!doc) throw new Error('fixture: position missing for run');
      return {
        snapshot: emptySnapshot,
        metrics: [],
        instrument: structuredClone(doc.instrument),
        position: {
          position_id: doc.id, instrument_id: doc.instrument.instrument_id,
          state: doc.state, revision: doc.revision,
          average_cost: doc.average_cost ? structuredClone(doc.average_cost) : null,
          quantity: doc.quantity,
          opened_on: doc.opened_on,
          preferred_horizon_months: doc.preferred_horizon_months,
        },
        prior: null,
        currentPrice: null,
      };
    },
    now: harness.clock.now,
  });
  const app = createApp({
    positionService: harness.positionService,
    researchService: starvedSurface.researchService,
    automationRouter: starvedSurface.router,
    authenticate: makeUserAuth(),
    logging: false,
  });
  await withTestServer(app, async (baseUrl) => {
    const candidate = await createCandidate(baseUrl);
    const queued = await queueRun(baseUrl, candidate.id, {
      revision: 1, instrumentId: INSTRUMENT_MAIN.instrument_id, key: 'key-c3-1',
    });
    const executed = await executeRun(baseUrl, { identity: harness.identity, worker: starvedSurface.worker }, queued.body.run.id);
    assert.equal(executed.status, 202);
    const settled = await starvedSurface.worker.whenSettled(queued.body.run.id);
    assert.equal(settled.run.status, 'failed');
    assert.equal(settled.run.error_code, 'INSUFFICIENT_EVIDENCE');
    assert.equal(harness.modelClient.calls.length, 0, 'no model call may burn on an empty context');
    assert.equal(harness.assessmentRepository.records.length, 0);
  });
});

test('C4: partial coverage publishes an explicitly limited assessment with visible gaps', async () => {
  const harness = createHarness();
  const partialSnapshot = fixtureEvidenceSnapshot(INSTRUMENT_MAIN, {
    snapshotId: 'snap-h17-partial', coverage: 'partial', gaps: ['transcript_coverage_missing'],
  });
  const partialSurface = harness.makeSurface({
    modelClient: harness.modelClient,
    inputProvider: async (claimedRun) => {
      const doc = await harness.positionRepository.findById(claimedRun.position_id);
      if (!doc) throw new Error('fixture: position missing for run');
      return {
        snapshot: partialSnapshot,
        metrics: fixtureMetrics(INSTRUMENT_MAIN, partialSnapshot.snapshot_id, 150),
        instrument: structuredClone(doc.instrument),
        position: {
          position_id: doc.id, instrument_id: doc.instrument.instrument_id,
          state: doc.state, revision: doc.revision,
          average_cost: doc.average_cost ? structuredClone(doc.average_cost) : null,
          quantity: doc.quantity,
          opened_on: doc.opened_on,
          preferred_horizon_months: doc.preferred_horizon_months,
        },
        prior: null,
        currentPrice: null,
      };
    },
    now: harness.clock.now,
  });
  harness.modelClient.enqueueOutput(validSynthesis());
  // The partial snapshot must be registered with the evidence snapshot lookup
  // so the bounded pipeline's delivery binding resolves it (SNAPSHOT_CONFLICT
  // otherwise), exactly as the harness registers its default snapshots.
  harness.registerEvidence(partialSnapshot);
  const app = createApp({
    positionService: harness.positionService,
    researchService: partialSurface.researchService,
    automationRouter: partialSurface.router,
    authenticate: makeUserAuth(),
    logging: false,
  });
  await withTestServer(app, async (baseUrl) => {
    const candidate = await createCandidate(baseUrl);
    const queued = await queueRun(baseUrl, candidate.id, {
      revision: 1, instrumentId: INSTRUMENT_MAIN.instrument_id, key: 'key-c4-1',
    });
    await executeRun(baseUrl, { identity: harness.identity, worker: partialSurface.worker }, queued.body.run.id);
    const settled = await partialSurface.worker.whenSettled(queued.body.run.id);
    assert.equal(settled.run.status, 'limited');
    const latest = await ownerGet(baseUrl, `/api/v1/research/positions/${candidate.id}/latest`);
    assert.equal(latest.body.latest_assessment.status, 'limited');
    assert.ok(latest.body.latest_assessment.assessment.missing_data.includes('transcript_coverage_missing'),
      'coverage gaps must be visible in the published assessment');
    assert.equal(latest.body.run_state.last_success.status, 'limited');
  });
});

test('C5: deadline timeout injection stalls a running run and supersedes an expired queue entry', async () => {
  const harness = createHarness({ deadlineSeconds: 2 });
  await withTestServer(harness.app, async (baseUrl) => {
    const candidate = await createCandidate(baseUrl);

    // (a) Running run whose model answer arrives after the deadline: the
    // success is refused and recovery stalls the run (never fake completion).
    const block = harness.modelClient.enqueueBlock();
    const running = await queueRun(baseUrl, candidate.id, {
      revision: 1, instrumentId: INSTRUMENT_MAIN.instrument_id, key: 'key-c5-running',
    });
    await executeRun(baseUrl, harness, running.body.run.id);
    harness.clock.advanceSeconds(3600);
    block.resolve(validSynthesis());
    const settled = await harness.worker.whenSettled(running.body.run.id);
    assert.equal(settled.run.status, 'stalled');
    assert.equal(settled.run.error_code, 'RUN_STALLED');

    // (b) Queue entry whose deadline expires before any trigger: recovery
    // supersedes it and execute replays instead of claiming.
    const queuedStale = await queueRun(baseUrl, candidate.id, {
      revision: 1, instrumentId: INSTRUMENT_MAIN.instrument_id, key: 'key-c5-stale',
      payload: { trigger: 'queued-then-expired' },
    });
    harness.clock.advanceSeconds(3600);
    const replayed = await executeRun(baseUrl, harness, queuedStale.body.run.id);
    assert.equal(replayed.status, 200);
    assert.equal(replayed.body.replayed, true);
    assert.equal(replayed.body.run.status, 'superseded');
  });
});

test('C6: restart recovery over the shared persisted store stalls orphans without duplicates', async () => {
  const harness = createHarness({ deadlineSeconds: 2 });
  await withTestServer(harness.app, async (baseUrl) => {
    const candidate = await createCandidate(baseUrl);

    // Process A claims a run and hangs mid-model-call.
    harness.modelClient.enqueueBlock(); // never resolved: the "crashed" process
    const orphan = await queueRun(baseUrl, candidate.id, {
      revision: 1, instrumentId: INSTRUMENT_MAIN.instrument_id, key: 'key-c6-1',
    });
    const executed = await executeRun(baseUrl, harness, orphan.body.run.id);
    assert.equal(executed.status, 202);

    // Process B starts from the SAME shared store (persisted claim state).
    // The orphan's deadline (deadlineSeconds: 2) must first expire before the
    // recovery sweep can observe it; advance the shared clock past it.
    harness.clock.advanceSeconds(3600);
    const restarted = harness.makeSurface({ now: harness.clock.now });
    const recovered = await restarted.worker.recoverExpiredRuns();
    assert.deepEqual(recovered, { stalled: 1, superseded: 0 });

    const status = await automationStatus(baseUrl, { identity: harness.identity }, orphan.body.run.id);
    assert.equal(status.status, 200);
    assert.equal(status.body.run.status, 'stalled');
    assert.equal(status.body.run.error_code, 'RUN_STALLED');

    // Re-execute of the stalled orphan replays; no duplicate claim/assessment.
    // The restarted worker (a fresh process) has no in-flight entry, so it
    // reads the persisted 'stalled' state and replays it without a second
    // claim — exactly what the primary HTTP surface (which still holds the
    // blocked in-flight claim) cannot demonstrate.
    const replay = await restarted.worker.startRun({ run_id: orphan.body.run.id });
    assert.equal(replay.replayed, true);
    assert.equal(replay.run.status, 'stalled');
    assert.equal(harness.assessmentRepository.records.length, 0);
  });
});

test('C7: concurrent position edit during generation supersedes the in-flight run', async () => {
  const harness = createHarness();
  await withTestServer(harness.app, async (baseUrl) => {
    const candidate = await createCandidate(baseUrl);

    // Generation in flight at revision 1.
    const block = harness.modelClient.enqueueBlock();
    const stale = await queueRun(baseUrl, candidate.id, {
      revision: 1, instrumentId: INSTRUMENT_MAIN.instrument_id, key: 'key-c7-stale',
    });
    const executed = await executeRun(baseUrl, harness, stale.body.run.id);
    assert.equal(executed.status, 202);

    // Concurrent explicit edit bumps the revision, then the user queues a
    // fresh run: queueing the newer revision supersedes the in-flight run.
    const owned = await request(baseUrl, `/api/v1/positions/${candidate.id}`, jsonRequest('PATCH', '', {
      headers: { authorization: 'Bearer token-owner-a' },
      body: {
        expected_revision: 1,
        changes: {
          state: 'owned',
          average_cost: { amount: '100.00', currency: 'USD' },
          quantity: '10',
          opened_on: '2029-06-01',
        },
      },
    }));
    assert.equal(owned.status, 200);
    harness.modelClient.enqueueOutput(validSynthesis());
    const fresh = await queueRun(baseUrl, candidate.id, {
      revision: 2, instrumentId: INSTRUMENT_MAIN.instrument_id, key: 'key-c7-fresh',
    });
    assert.equal(fresh.status, 202);

    // The stale pipeline finishes: publication against superseded economics
    // is refused, the run stays superseded, and no stale assessment persists.
    block.resolve(validSynthesis());
    const settled = await harness.worker.whenSettled(stale.body.run.id);
    assert.equal(settled.run.status, 'superseded');
    assert.equal(harness.assessmentRepository.records.filter((a) => a.run_id === stale.body.run.id).length, 0);

    // The fresh revision-2 run completes and is the only published result.
    harness.modelClient.enqueueOutput(validSynthesis({ action: 'hold' }));
    await executeRun(baseUrl, harness, fresh.body.run.id);
    await harness.worker.whenSettled(fresh.body.run.id);
    const latest = await ownerGet(baseUrl, `/api/v1/research/positions/${candidate.id}/latest`);
    assert.equal(latest.body.latest_assessment.position_revision, 2);
    assert.equal(latest.body.latest_assessment.assessment.economics.status, 'available');
    const history = await ownerGet(baseUrl, `/api/v1/research/positions/${candidate.id}/assessments`);
    assert.equal(history.body.assessments.length, 1);
    assert.deepEqual(history.body.assessments.map((a) => a.position_revision), [2]);
  });
});

test('C8: callback authorization — replay idempotency, source injection and lease binding', async () => {
  const harness = createHarness();
  await withTestServer(harness.app, async (baseUrl) => {
    const candidate = await createCandidate(baseUrl);
    const mainSnapshotId = [...harness.evidenceSnapshots.values()]
      .find((snapshot) => snapshot.instrument_id === INSTRUMENT_MAIN.instrument_id).snapshot_id;
    const secondSnapshotId = [...harness.evidenceSnapshots.values()]
      .find((snapshot) => snapshot.instrument_id === INSTRUMENT_SECOND.instrument_id).snapshot_id;

    const queued = await queueRun(baseUrl, candidate.id, {
      revision: 1, instrumentId: INSTRUMENT_MAIN.instrument_id, key: 'key-c8-1',
    });
    const runId = queued.body.run.id;
    // Claim with a blocked pipeline so delivery is exercised through the
    // automation callback route exactly as n8n would.
    harness.modelClient.enqueueBlock();
    const executed = await executeRun(baseUrl, harness, runId);
    assert.equal(executed.status, 202);
    const nonce = executed.body.lease_nonce;
    const deliveryHeaders = (deliveryId, extra = {}) => authorizedAutomationHeaders(harness.identity, {
      'x-horizon-run-id': runId,
      'x-horizon-run-nonce': nonce,
      'x-horizon-delivery-id': deliveryId,
      ...extra,
    });
    const baseResult = () => ({
      // Body-supplied owner must be ignored: ownership is server-derived.
      owner_id: OWNER_B,
      position_revision: 1,
      evidence_snapshot_id: mainSnapshotId,
      session_as_of: '2030-01-01',
      status: 'complete',
      assessment: { market_thesis: { business: 'manual delivery' }, recommendation: { action: 'wait', horizon_months: 3 } },
    });

    // Wrong nonce -> 403.
    const wrongNonce = await request(baseUrl, `/api/v1/automation/research/runs/${runId}/result`, jsonRequest('POST', '', {
      headers: deliveryHeaders('delivery-c8-nonce', { 'x-horizon-run-nonce': 'not-the-lease-nonce' }),
      body: baseResult(),
    }));
    assert.equal(wrongNonce.status, 403);
    assert.equal(wrongNonce.body.code, 'automation_nonce_denied');

    // Unknown evidence snapshot (source injection) -> 409 SNAPSHOT_CONFLICT.
    const unknownSource = await request(baseUrl, `/api/v1/automation/research/runs/${runId}/result`, jsonRequest('POST', '', {
      headers: deliveryHeaders('delivery-c8-unknown'),
      body: { ...baseResult(), evidence_snapshot_id: 'snap-h17-never-registered' },
    }));
    assert.equal(unknownSource.status, 409);
    assert.equal(unknownSource.body.code, 'SNAPSHOT_CONFLICT');

    // Evidence snapshot bound to ANOTHER instrument -> 409.
    const wrongInstrument = await request(baseUrl, `/api/v1/automation/research/runs/${runId}/result`, jsonRequest('POST', '', {
      headers: deliveryHeaders('delivery-c8-wronginst'),
      body: { ...baseResult(), evidence_snapshot_id: secondSnapshotId },
    }));
    assert.equal(wrongInstrument.status, 409);
    assert.equal(wrongInstrument.body.code, 'SNAPSHOT_CONFLICT');

    // First valid delivery -> 201.
    const first = await request(baseUrl, `/api/v1/automation/research/runs/${runId}/result`, jsonRequest('POST', '', {
      headers: deliveryHeaders('delivery-c8-first'),
      body: baseResult(),
    }));
    assert.equal(first.status, 201, JSON.stringify(first.body));
    assert.equal(first.body.idempotent, false);
    const assessmentId = first.body.assessment_id;
    assert.ok(assessmentId);

    // Identical replay -> 200 idempotent, same assessment.
    const replay = await request(baseUrl, `/api/v1/automation/research/runs/${runId}/result`, jsonRequest('POST', '', {
      headers: deliveryHeaders('delivery-c8-first'),
      body: baseResult(),
    }));
    assert.equal(replay.status, 200);
    assert.equal(replay.body.idempotent, true);
    assert.equal(replay.body.assessment_id, assessmentId);

    // Same delivery id, different body -> 409 replay conflict.
    const conflicting = await request(baseUrl, `/api/v1/automation/research/runs/${runId}/result`, jsonRequest('POST', '', {
      headers: deliveryHeaders('delivery-c8-first'),
      body: { ...baseResult(), assessment: { market_thesis: { business: 'tampered' } } },
    }));
    assert.equal(conflicting.status, 409);
    assert.equal(conflicting.body.code, 'automation_replay_conflict');

    // New delivery id after terminal success -> refused (no result rewrite).
    const lateDelivery = await request(baseUrl, `/api/v1/automation/research/runs/${runId}/result`, jsonRequest('POST', '', {
      headers: deliveryHeaders('delivery-c8-2'),
      body: { ...baseResult(), assessment: { market_thesis: { business: 'late delivery' } } },
    }));
    assert.equal(lateDelivery.status, 409);
    assert.equal(lateDelivery.body.code, 'INVALID_RUN_TRANSITION');

    // The persisted assessment is the first delivery only.
    const stored = harness.assessmentRepository.records.find((a) => a.run_id === runId);
    assert.equal(stored.id, assessmentId);
    assert.equal(stored.assessment.market_thesis.business, 'manual delivery');
    const latest = await ownerGet(baseUrl, `/api/v1/research/positions/${candidate.id}/latest`);
    assert.equal(latest.body.latest_assessment.id, assessmentId);

    // Expired lease -> 409 even with otherwise-valid headers.
    const queued2 = await queueRun(baseUrl, candidate.id, {
      revision: 1, instrumentId: INSTRUMENT_MAIN.instrument_id, key: 'key-c8-2',
      payload: { trigger: 'lease-expiry' },
    });
    harness.modelClient.enqueueBlock();
    const executed2 = await executeRun(baseUrl, harness, queued2.body.run.id);
    assert.equal(executed2.status, 202);
    harness.clock.advanceSeconds(3600);
    const expiredLease = await request(baseUrl, `/api/v1/automation/research/runs/${queued2.body.run.id}/result`, jsonRequest('POST', '', {
      headers: authorizedAutomationHeaders(harness.identity, {
        'x-horizon-run-id': queued2.body.run.id,
        'x-horizon-run-nonce': executed2.body.lease_nonce,
        'x-horizon-delivery-id': 'delivery-c8-3',
      }),
      body: baseResult(),
    }));
    assert.equal(expiredLease.status, 409);
    assert.equal(expiredLease.body.code, 'automation_lease_expired');
  });
});

// ---------------------------------------------------------------------------
// Section D — all configured tickers accounted for, gaps visible
// ---------------------------------------------------------------------------

test('D1: every configured instrument gets its own bound run/assessment; coverage gaps visible', async () => {
  const harness = createHarness();
  await withTestServer(harness.app, async (baseUrl) => {
    const main = await createCandidate(baseUrl, INSTRUMENT_MAIN);
    const second = await createCandidate(baseUrl, INSTRUMENT_SECOND);

    // MAIN instrument: full coverage -> complete assessment.
    harness.modelClient.enqueueOutput(validSynthesis());
    const mainQueued = await queueRun(baseUrl, main.id, {
      revision: 1, instrumentId: INSTRUMENT_MAIN.instrument_id, key: 'key-d1-main',
    });
    assert.equal(mainQueued.status, 202);
    await executeRun(baseUrl, harness, mainQueued.body.run.id);
    const mainSettled = await harness.worker.whenSettled(mainQueued.body.run.id);
    assert.equal(mainSettled.run.status, 'succeeded');

    // SECOND instrument: partial coverage -> limited result with the gap. The
    // primary automation surface serves BOTH configured instruments; only the
    // evidence fixture differs.
    const partialSecondSnapshot = fixtureEvidenceSnapshot(INSTRUMENT_SECOND, {
      snapshotId: 'snap-h17-second-partial', coverage: 'partial', gaps: ['news_coverage_missing'],
    });
    harness.evidenceSnapshots.set(partialSecondSnapshot.snapshot_id, partialSecondSnapshot);
    harness.evidenceFor.set(INSTRUMENT_SECOND.instrument_id, {
      snapshot: partialSecondSnapshot,
      metrics: fixtureMetrics(INSTRUMENT_SECOND, partialSecondSnapshot.snapshot_id, 75),
    });
    harness.modelClient.enqueueOutput(validSynthesis());
    const secondQueued = await queueRun(baseUrl, second.id, {
      revision: second.revision, instrumentId: INSTRUMENT_SECOND.instrument_id, key: 'key-d1-second',
    });
    assert.equal(secondQueued.status, 202);
    const secondExecuted = await executeRun(baseUrl, harness, secondQueued.body.run.id);
    assert.equal(secondExecuted.status, 202, 'the primary surface serves the second instrument too');
    const secondSettled = await harness.worker.whenSettled(secondQueued.body.run.id);
    assert.equal(secondSettled.run.status, 'limited');

    // Both configured instruments are accounted for in the owner list.
    const list = await ownerGet(baseUrl, '/api/v1/positions');
    assert.deepEqual(list.body.positions.map((p) => p.instrument.instrument_id).sort(), [
      INSTRUMENT_MAIN.instrument_id,
      INSTRUMENT_SECOND.instrument_id,
    ].sort());

    // MAIN: complete assessment bound to its instrument.
    const mainLatest = await ownerGet(baseUrl, `/api/v1/research/positions/${main.id}/latest`);
    assert.equal(mainLatest.body.latest_assessment.status, 'complete');
    assert.equal(mainLatest.body.latest_assessment.instrument_id, INSTRUMENT_MAIN.instrument_id);

    // SECOND: limited assessment with the visible coverage gap.
    const secondLatest = await ownerGet(baseUrl, `/api/v1/research/positions/${second.id}/latest`);
    assert.equal(secondLatest.body.latest_assessment.status, 'limited');
    assert.equal(secondLatest.body.latest_assessment.instrument_id, INSTRUMENT_SECOND.instrument_id);
    assert.ok(secondLatest.body.latest_assessment.assessment.missing_data.includes('news_coverage_missing'),
      'the second instrument coverage gap must be visible, not silently dropped');
    assert.equal(secondLatest.body.run_state.last_success.status, 'limited');

    // Both instruments are served by observed history.
    const mainHistory = await ownerGet(baseUrl, `/api/v1/market/instruments/${INSTRUMENT_MAIN.instrument_id}/history?range=1D`);
    const secondHistory = await ownerGet(baseUrl, `/api/v1/market/instruments/${INSTRUMENT_SECOND.instrument_id}/history?range=1M`);
    assert.equal(mainHistory.body.data_status, 'available');
    assert.equal(secondHistory.body.data_status, 'available');
  });
});
