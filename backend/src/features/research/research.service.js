const crypto = require('node:crypto');

const ResearchRunModel = require('./research_run.model');
const ResearchAssessmentModel = require('./research_assessment.model');
const ResearchSnapshotModel = require('./research_snapshot.model');
const ThesisCheckpointModel = require('./thesis_state.model');
const PositionModel = require('../positions/position.model');
const { researchRunSchema, CONTRACT_VERSION } = require('./contracts');
const { STAGES, STAGE_ORDER, validateStage } = require('./tool_registry');

const RUN_KINDS = ResearchRunModel.RUN_KINDS;
const DEFAULT_DEADLINE_SECONDS = 900;
const DEFAULT_LEASE_SECONDS = 300;
const CHECKPOINT_KINDS = ThesisCheckpointModel.CHECKPOINT_KINDS;
const CHANGE_EVENT_KINDS = ThesisCheckpointModel.CHANGE_EVENT_KINDS;
const ASSESSMENT_STATUSES = ResearchAssessmentModel.ASSESSMENT_STATUSES;
const MAX_CHECKPOINT_EVENTS = 500;

function serviceError(code, message) {
  const error = new Error(message || code);
  error.code = code;
  return error;
}

function isDuplicateKeyError(error) {
  return Boolean(error) && (error.code === 11000 || error.code === '11000');
}

// Deterministic digest of the request payload: the idempotency contract
// ("same key + same request replays; same key + different request is 409")
// requires byte-stable serialization, so object keys are sorted recursively.
function canonicalize(value) {
  if (Array.isArray(value)) return value.map(canonicalize);
  if (value && typeof value === 'object') {
    return Object.keys(value).sort().map((key) => [key, canonicalize(value[key])]);
  }
  return value;
}

function payloadDigest(requestPayload) {
  return crypto.createHash('sha256')
    .update(JSON.stringify(canonicalize(requestPayload ?? null)))
    .digest('hex');
}

function iso(value) {
  return value instanceof Date ? value.toISOString() : value;
}

function isPlainObject(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

function assertOwnerScopedId(value, field) {
  if (typeof value !== 'string' || value.length === 0 || value.length > 160) {
    throw serviceError('INVALID_INPUT', `${field} must be a non-empty opaque string`);
  }
  return value;
}

// ---------------------------------------------------------------------------
// Mongoose repository factories. The service core operates on ISO strings and
// plain objects; these adapters own the Date conversion and the atomic
// compare-and-set operations. Storage-level uniqueness backs the service
// guarantees (persisted idempotency, single active run, one assessment/run).
// ---------------------------------------------------------------------------

function createMongooseRunRepository(model = ResearchRunModel) {
  const fromDoc = (record) => {
    if (!record) return null;
    const plain = record.toObject ? record.toObject() : record;
    return {
      id: plain._id,
      position_id: plain.position_id,
      owner_id_internal: plain.owner_id_internal,
      position_revision: plain.position_revision,
      run_kind: plain.run_kind,
      request_class: plain.request_class,
      idempotency_key: plain.idempotency_key,
      payload_digest: plain.payload_digest,
      status: plain.status,
      stage: plain.stage,
      created_at: iso(plain.created_at),
      started_at: plain.started_at ? iso(plain.started_at) : null,
      heartbeat_at: plain.heartbeat_at ? iso(plain.heartbeat_at) : null,
      deadline_at: iso(plain.deadline_at),
      finished_at: plain.finished_at ? iso(plain.finished_at) : null,
      evidence_snapshot_id: plain.evidence_snapshot_id ?? null,
      assessment_id: plain.assessment_id ?? null,
      error_code: plain.error_code ?? null,
      retry_count: plain.retry_count ?? 0,
      lease_nonce: plain.lease_nonce ?? null,
      lease_expires_at: plain.lease_expires_at ? iso(plain.lease_expires_at) : null,
      input_snapshot_id: plain.input_snapshot_id,
      run_input_ref: plain.run_input_ref,
      run_result_ref: plain.run_result_ref ?? null,
      versions: plain.versions,
    };
  };
  const toDoc = (run) => ({
    ...run,
    _id: run.id,
    created_at: new Date(run.created_at),
    started_at: run.started_at ? new Date(run.started_at) : null,
    heartbeat_at: run.heartbeat_at ? new Date(run.heartbeat_at) : null,
    deadline_at: new Date(run.deadline_at),
    finished_at: run.finished_at ? new Date(run.finished_at) : null,
    lease_expires_at: run.lease_expires_at ? new Date(run.lease_expires_at) : null,
  });
  const datePatch = (patch) => {
    const mapped = { ...patch };
    for (const field of ['started_at', 'heartbeat_at', 'finished_at', 'lease_expires_at']) {
      if (mapped[field] != null) mapped[field] = new Date(mapped[field]);
    }
    return mapped;
  };
  return {
    async findByIdempotency(ownerId, positionId, idempotencyKey) {
      return fromDoc(await model.findOne({
        owner_id_internal: ownerId,
        position_id: positionId,
        idempotency_key: idempotencyKey,
      }).lean());
    },
    async findActive({ positionId, positionRevision, runKind }) {
      return fromDoc(await model.findOne({
        position_id: positionId,
        position_revision: positionRevision,
        request_class: runKind,
        status: { $in: ['queued', 'running'] },
      }).lean());
    },
    async create(run) {
      try {
        await model.create(toDoc(run));
      } catch (error) {
        if (error && (error.code === 11000 || error.name === 'MongoServerError')) {
          throw serviceError('DUPLICATE_RUN', 'Run id or idempotency key already persisted');
        }
        throw error;
      }
      return structuredClone(run);
    },
    async findById(runId) {
      return fromDoc(await model.findOne({ _id: runId }).lean());
    },
    async claimQueued(runId, patch) {
      return fromDoc(await model.findOneAndUpdate(
        { _id: runId, status: 'queued' },
        { $set: datePatch(patch) },
        { returnDocument: 'after', lean: true },
      ));
    },
    async updateIfStatus(runId, expectedStatuses, patch) {
      return fromDoc(await model.findOneAndUpdate(
        { _id: runId, status: { $in: expectedStatuses } },
        { $set: datePatch(patch) },
        { returnDocument: 'after', lean: true },
      ));
    },
    async supersedeStale({ ownerId, positionId, beforeRevision, excludeRunId, finishedAt }) {
      const result = await model.updateMany(
        {
          owner_id_internal: ownerId,
          position_id: positionId,
          position_revision: { $lt: beforeRevision },
          status: { $in: ['queued', 'running'] },
          _id: { $ne: excludeRunId },
        },
        { $set: { status: 'superseded', finished_at: new Date(finishedAt) } },
      );
      return result.modifiedCount ?? 0;
    },
    async findExpired(nowIso) {
      const records = await model.find({
        status: { $in: ['queued', 'running'] },
        deadline_at: { $lte: new Date(nowIso) },
      }).lean();
      return records.map(fromDoc);
    },
    async findLatestAttempt(ownerId, positionId) {
      return fromDoc(await model.findOne({
        owner_id_internal: ownerId,
        position_id: positionId,
      }).sort({ created_at: -1, _id: -1 }).lean());
    },
    async findLatestSuccess(ownerId, positionId) {
      return fromDoc(await model.findOne({
        owner_id_internal: ownerId,
        position_id: positionId,
        status: { $in: ['succeeded', 'limited'] },
      }).sort({ finished_at: -1, _id: -1 }).lean());
    },
  };
}

function createMongooseAssessmentRepository(
  model = ResearchAssessmentModel,
  { positionModel = PositionModel } = {},
) {
  const fromDoc = (record) => {
    if (!record) return null;
    const plain = record.toObject ? record.toObject() : record;
    return {
      id: plain._id,
      run_id: plain.run_id,
      position_id: plain.position_id,
      owner_id_internal: plain.owner_id_internal,
      position_revision: plain.position_revision,
      instrument_id: plain.instrument_id,
      evidence_snapshot_id: plain.evidence_snapshot_id,
      generated_at: iso(plain.generated_at),
      session_as_of: plain.session_as_of,
      status: plain.status,
      artifact_kind: plain.artifact_kind,
      assessment: plain.assessment,
    };
  };
  const readLean = async (query, { includePublicationGuard = false } = {}) => {
    if (!query) return null;
    if (includePublicationGuard && typeof query.select === 'function') query = query.select('+publication_guard');
    if (typeof query.lean === 'function') return query.lean();
    return query;
  };
  const guardAssessmentFilter = (guard, position) => ({
    _id: guard.assessment_id,
    position_id: position._id,
    owner_id_internal: position.owner_id,
    position_revision: guard.position_revision,
  });

  // A guard can be reclaimed only when the immutable assessment it names is
  // already durably present and is bound to the same position/owner/revision.
  // That is proof that a prior publisher cannot later insert a *new* judgment:
  // the unique run_id index makes a second insert impossible. In every other
  // case (including a worker paused before insert), leave the guard intact.
  const reconcileCompletedGuard = async ({ positionId, ownerId, apply = false } = {}) => {
    if (!positionModel || typeof positionModel.findOne !== 'function') {
      throw serviceError('PUBLICATION_GUARD_UNAVAILABLE', 'Position storage does not support publication guard inspection');
    }
    const position = await readLean(positionModel.findOne({
      _id: positionId,
      owner_id: ownerId,
      publication_guard: { $ne: null },
    }), { includePublicationGuard: true });
    if (!position) return { status: 'NO_GUARD' };
    const guard = position.publication_guard;
    if (!guard || typeof guard.token !== 'string' || typeof guard.assessment_id !== 'string'
      || !Number.isSafeInteger(guard.position_revision)) {
      return { status: 'BLOCKED_INVALID_GUARD' };
    }
    const persisted = await readLean(model.findOne(guardAssessmentFilter(guard, position)));
    if (!persisted) {
      return {
        status: 'BLOCKED_UNPROVEN',
        assessment_id: guard.assessment_id,
        guard_token: guard.token,
      };
    }
    if (!apply) {
      return { status: 'PROVEN_DRY_RUN', assessment_id: guard.assessment_id, guard_token: guard.token };
    }
    const released = await positionModel.findOneAndUpdate(
      {
        _id: position._id,
        owner_id: position.owner_id,
        revision: guard.position_revision,
        'publication_guard.token': guard.token,
        'publication_guard.assessment_id': guard.assessment_id,
      },
      { $set: { publication_guard: null } },
      { returnDocument: 'after', lean: true },
    );
    return released
      ? { status: 'RECONCILED', assessment_id: guard.assessment_id, guard_token: guard.token }
      : { status: 'RACE_LOST', assessment_id: guard.assessment_id, guard_token: guard.token };
  };
  const createIfCurrent = async (assessment, { retriedAfterOtherCompletedGuard = false } = {}) => {
    if (!positionModel || typeof positionModel.findOneAndUpdate !== 'function') {
      throw serviceError('PUBLICATION_GUARD_UNAVAILABLE', 'Position storage does not support atomic publication guards');
    }
    const token = crypto.randomUUID();
    const acquiredAt = new Date();
    let acquired = false;
    // Never clear a guard after an indeterminate write failure. A network or
    // write-concern timeout can be reported before the server finishes the
    // insert, so releasing then would permit an edit before a delayed insert.
    // A resolved insert and a duplicate-key response are terminal outcomes.
    let publicationWriteSettled = false;
    try {
      const position = await positionModel.findOneAndUpdate(
        {
          _id: assessment.position_id,
          owner_id: assessment.owner_id_internal,
          revision: assessment.position_revision,
          'instrument.instrument_id': assessment.instrument_id,
          publication_guard: null,
        },
        { $set: { publication_guard: {
          token,
          assessment_id: assessment.id,
          position_revision: assessment.position_revision,
          acquired_at: acquiredAt,
        } } },
        { returnDocument: 'after', lean: true },
      );
      if (!position) {
        if (typeof positionModel.findOne !== 'function') return null;
        const reconciliation = await reconcileCompletedGuard({
          positionId: assessment.position_id,
          ownerId: assessment.owner_id_internal,
          apply: true,
        });
        if (reconciliation.status !== 'RECONCILED') return null;
        const existing = await readLean(model.findOne({
          run_id: assessment.run_id,
          _id: reconciliation.assessment_id,
        }));
        if (existing) return fromDoc(existing);
        // A different completed run's guard was proved and released. It is
        // not this run's result; retry once against the unchanged position.
        return retriedAfterOtherCompletedGuard
          ? null
          : createIfCurrent(assessment, { retriedAfterOtherCompletedGuard: true });
      }
      acquired = true;
      try {
        await model.create({ ...assessment, _id: assessment.id, generated_at: new Date(assessment.generated_at) });
        publicationWriteSettled = true;
      } catch (error) {
        if (isDuplicateKeyError(error)) {
          publicationWriteSettled = true;
          throw serviceError('DUPLICATE_ASSESSMENT', 'An assessment for this run already exists');
        }
        throw error;
      }
      return structuredClone(assessment);
    } finally {
      if (acquired && publicationWriteSettled) {
        await positionModel.findOneAndUpdate(
          {
            _id: assessment.position_id,
            owner_id: assessment.owner_id_internal,
            revision: assessment.position_revision,
            'publication_guard.token': token,
            'publication_guard.assessment_id': assessment.id,
          },
          { $set: { publication_guard: null } },
          { returnDocument: 'after', lean: true },
        );
      }
    }
  };
  return {
    async create(assessment) {
      try {
        await model.create({ ...assessment, _id: assessment.id, generated_at: new Date(assessment.generated_at) });
      } catch (error) {
        if (error && (error.code === 11000 || error.name === 'MongoServerError')) {
          throw serviceError('DUPLICATE_ASSESSMENT', 'An assessment for this run already exists');
        }
        throw error;
      }
      return structuredClone(assessment);
    },
    // Publication is a cross-collection operation. Standalone MongoDB cannot
    // transact it, so acquire a durable guard on the exact Position revision
    // before inserting. Position edits atomically require publication_guard
    // to be null. Thus either an edit wins first (acquisition returns null) or
    // publication wins and the edit is refused until the insert completes.
    // The guard deliberately has no expiry: reclaiming by time would let a
    // delayed publisher insert after a newer position edit.
    createIfCurrent,
    async findById(assessmentId) {
      return fromDoc(await model.findOne({ _id: assessmentId }).lean());
    },
    // Operator-facing, proof-gated reconciliation. This intentionally cannot
    // clear a guard whose assessment is absent: a delayed old worker might
    // still be about to insert in that case.
    async reconcileCompletedPublicationGuard({ position_id, owner_id, apply = false } = {}) {
      return reconcileCompletedGuard({ positionId: position_id, ownerId: owner_id, apply });
    },
    async findByRunId(runId) {
      return fromDoc(await model.findOne({ run_id: runId }).lean());
    },
    async latestForPosition(ownerId, positionId, excludeId = null) {
      const filter = { owner_id_internal: ownerId, position_id: positionId };
      if (excludeId) filter._id = { $ne: excludeId };
      return fromDoc(await model.findOne(filter).sort({ generated_at: -1, _id: -1 }).lean());
    },
    async listByPosition(ownerId, positionId, { cursor = null, limit = 20 } = {}) {
      const filter = { owner_id_internal: ownerId, position_id: positionId };
      if (cursor) {
        const separator = cursor.lastIndexOf('|');
        const cursorDate = new Date(cursor.slice(0, separator));
        const cursorId = cursor.slice(separator + 1);
        filter.$or = [
          { generated_at: { $lt: cursorDate } },
          { generated_at: cursorDate, _id: { $lt: cursorId } },
        ];
      }
      const records = await model.find(filter)
        .sort({ generated_at: -1, _id: -1 })
        .limit(limit + 1)
        .lean();
      const page = records.slice(0, limit).map(fromDoc);
      const nextCursor = records.length > limit
        ? `${page[page.length - 1].generated_at}|${page[page.length - 1].id}`
        : null;
      return { assessments: page, next_cursor: nextCursor };
    },
  };
}

function createMongooseResearchSnapshotRepository(model = ResearchSnapshotModel) {
  const fromDoc = (record) => {
    if (!record) return null;
    const plain = record.toObject ? record.toObject() : record;
    return {
      snapshot_id: plain.snapshot_id,
      run_id: plain.run_id,
      owner_id_internal: plain.owner_id_internal,
      position_id: plain.position_id,
      position_revision: plain.position_revision,
      instrument_id: plain.instrument_id,
      payload_digest: plain.payload_digest,
      request_payload: plain.request_payload,
      created_at: iso(plain.created_at),
    };
  };
  return {
    async create(snapshot) {
      try {
        await model.create({ ...snapshot, created_at: new Date(snapshot.created_at) });
      } catch (error) {
        if (error && (error.code === 11000 || error.name === 'MongoServerError')) {
          throw serviceError('DUPLICATE_SNAPSHOT', 'Run input snapshot already persisted');
        }
        throw error;
      }
      return structuredClone(snapshot);
    },
    async findById(snapshotId) {
      return fromDoc(await model.findOne({ snapshot_id: snapshotId }).lean());
    },
  };
}

function createMongooseCheckpointRepository(model = ThesisCheckpointModel) {
  const fromDoc = (record) => {
    if (!record) return null;
    const plain = record.toObject ? record.toObject() : record;
    return {
      checkpoint_id: plain.checkpoint_id,
      owner_id_internal: plain.owner_id_internal,
      instrument_id: plain.instrument_id,
      kind: plain.kind,
      metric_id: plain.metric_id ?? null,
      fixed_level: plain.fixed_level ?? null,
      condition: plain.condition ?? null,
      status: plain.status,
      reason: plain.reason ?? null,
      source_assessment_id: plain.source_assessment_id ?? null,
      predecessor_checkpoint_id: plain.predecessor_checkpoint_id ?? null,
      replacement_checkpoint_id: plain.replacement_checkpoint_id ?? null,
      history: (plain.history || []).map((event) => ({
        ...event,
        at: iso(event.at),
      })),
    };
  };
  return {
    async create(checkpoint) {
      try {
        await model.create({ ...checkpoint, _id: checkpoint.checkpoint_id });
      } catch (error) {
        if (error && (error.code === 11000 || error.name === 'MongoServerError')) {
          throw serviceError('DUPLICATE_CHECKPOINT', 'Checkpoint id already persisted');
        }
        throw error;
      }
      return structuredClone(checkpoint);
    },
    async findById(ownerId, checkpointId) {
      return fromDoc(await model.findOne({
        _id: checkpointId,
        owner_id_internal: ownerId,
      }).lean());
    },
    async listByInstrument(ownerId, instrumentId) {
      const records = await model.find({
        owner_id_internal: ownerId,
        instrument_id: instrumentId,
      }).sort({ created_at: 1 }).lean();
      return records.map(fromDoc);
    },
    async update(checkpointId, patch) {
      const mapped = { ...patch };
      if (mapped.history) {
        mapped.history = mapped.history.map((event) => ({ ...event, at: new Date(event.at) }));
      }
      const record = await model.findOneAndUpdate(
        { _id: checkpointId },
        { $set: mapped },
        { returnDocument: 'after', lean: true },
      );
      return fromDoc(record);
    },
  };
}

// ---------------------------------------------------------------------------

class ResearchService {
  constructor({
    runRepository,
    assessmentRepository,
    researchSnapshotRepository,
    checkpointRepository,
    evidenceSnapshotLookup = null,
    now = () => new Date(),
    idFactory = () => `run-${crypto.randomUUID()}`,
    assessmentIdFactory = () => `assessment-${crypto.randomUUID()}`,
    snapshotIdFactory = () => `snapshot-run-${crypto.randomUUID()}`,
    checkpointIdFactory = () => `checkpoint-${crypto.randomUUID()}`,
    deadlineSeconds = DEFAULT_DEADLINE_SECONDS,
    leaseSeconds = DEFAULT_LEASE_SECONDS,
  } = {}) {
    if (!runRepository || typeof runRepository.claimQueued !== 'function') {
      throw new TypeError('ResearchService requires a run repository with atomic claim support');
    }
    if (!assessmentRepository || typeof assessmentRepository.create !== 'function') {
      throw new TypeError('ResearchService requires an assessment repository');
    }
    if (!researchSnapshotRepository || typeof researchSnapshotRepository.create !== 'function') {
      throw new TypeError('ResearchService requires a research snapshot repository');
    }
    if (!checkpointRepository || typeof checkpointRepository.update !== 'function') {
      throw new TypeError('ResearchService requires a checkpoint repository');
    }
    this.runRepository = runRepository;
    this.assessmentRepository = assessmentRepository;
    this.researchSnapshotRepository = researchSnapshotRepository;
    this.checkpointRepository = checkpointRepository;
    // Callback binding: snapshot existence and instrument match. Absent
    // lookup means the binding cannot be verified, so result delivery fails
    // closed (SNAPSHOT_CONFLICT) rather than trusting unverified references.
    this.evidenceSnapshotLookup = evidenceSnapshotLookup;
    this.now = now;
    this.idFactory = idFactory;
    this.assessmentIdFactory = assessmentIdFactory;
    this.snapshotIdFactory = snapshotIdFactory;
    this.checkpointIdFactory = checkpointIdFactory;
    this.deadlineSeconds = deadlineSeconds;
    this.leaseSeconds = leaseSeconds;
  }

  // -- Run queueing (persisted idempotency) ---------------------------------

  async queueRun(request) {
    const ownerId = assertOwnerScopedId(request.owner_id, 'owner_id');
    const positionId = assertOwnerScopedId(request.position_id, 'position_id');
    const idempotencyKey = assertOwnerScopedId(request.idempotency_key, 'idempotency_key');
    // H08 review F1: the snapshot and assessment models require instrument_id
    // (required: true, CONTRACTS §4/§5), so an instrument-less queue is a
    // malformed request — rejected here, never coerced to a null instrument.
    const instrumentId = assertOwnerScopedId(request.instrument_id, 'instrument_id');
    if (!Number.isSafeInteger(request.position_revision) || request.position_revision < 1) {
      throw serviceError('INVALID_INPUT', 'position_revision must be a positive integer');
    }
    if (!RUN_KINDS.includes(request.run_kind)) {
      throw serviceError('INVALID_INPUT', `run_kind must be one of ${RUN_KINDS.join(', ')}`);
    }
    if (!isPlainObject(request.request_payload)) {
      throw serviceError('INVALID_INPUT', 'request_payload must be a plain JSON object');
    }
    const deadlineSeconds = Number.isSafeInteger(request.deadlineSeconds) && request.deadlineSeconds > 0
      ? request.deadlineSeconds
      : this.deadlineSeconds;
    const digest = payloadDigest(request.request_payload);

    const existing = await this.runRepository.findByIdempotency(ownerId, positionId, idempotencyKey);
    if (existing) {
      if (existing.payload_digest !== digest) {
        throw serviceError('IDEMPOTENCY_CONFLICT', 'Idempotency key was already used with a different payload');
      }
      return { run: this.#runView(existing), idempotent_replay: true };
    }

    const active = await this.runRepository.findActive({
      positionId,
      positionRevision: request.position_revision,
      runKind: request.run_kind,
    });
    if (active) {
      throw serviceError('RUN_ALREADY_ACTIVE', 'An active run already exists for this position revision and request class');
    }

    const now = this.now();
    const createdAt = now.toISOString();
    const deadlineAt = new Date(now.getTime() + deadlineSeconds * 1000).toISOString();
    const runId = this.idFactory();
    const snapshotId = this.snapshotIdFactory();
    const snapshot = {
      snapshot_id: snapshotId,
      run_id: runId,
      owner_id_internal: ownerId,
      position_id: positionId,
      position_revision: request.position_revision,
      instrument_id: instrumentId,
      payload_digest: digest,
      request_payload: structuredClone(request.request_payload),
      created_at: createdAt,
    };
    await this.researchSnapshotRepository.create(snapshot);

    const run = {
      id: runId,
      position_id: positionId,
      owner_id_internal: ownerId,
      position_revision: request.position_revision,
      run_kind: request.run_kind,
      request_class: request.run_kind,
      idempotency_key: idempotencyKey,
      payload_digest: digest,
      status: 'queued',
      stage: 'queued',
      created_at: createdAt,
      started_at: null,
      heartbeat_at: null,
      deadline_at: deadlineAt,
      finished_at: null,
      evidence_snapshot_id: null,
      assessment_id: null,
      error_code: null,
      retry_count: 0,
      lease_nonce: null,
      lease_expires_at: null,
      input_snapshot_id: snapshotId,
      // Immutable input reference: what was asked, of which revision.
      run_input_ref: {
        payload_digest: digest,
        instrument_id: instrumentId,
        position_revision: request.position_revision,
        run_kind: request.run_kind,
        request_payload: structuredClone(request.request_payload),
        snapshot_id: snapshotId,
      },
      run_result_ref: null,
      versions: { contract_version: String(CONTRACT_VERSION), service: 'h08-research-state' },
    };

    try {
      researchRunSchema.parse(this.#runView(run));
      await this.runRepository.create(run);
    } catch (error) {
      if (error && error.code === 'DUPLICATE_RUN') {
        // Lost a create race: the winner is either an identical replay or a
        // conflicting payload; re-derive from the persisted record.
        const winner = await this.runRepository.findByIdempotency(ownerId, positionId, idempotencyKey);
        if (winner && winner.payload_digest === digest) {
          return { run: this.#runView(winner), idempotent_replay: true };
        }
        const activeWinner = await this.runRepository.findActive({
          positionId,
          positionRevision: request.position_revision,
          runKind: request.run_kind,
        });
        if (activeWinner) {
          throw serviceError('RUN_ALREADY_ACTIVE', 'An active run already exists for this position revision and request class');
        }
        throw serviceError('IDEMPOTENCY_CONFLICT', 'Idempotency key was already used with a different payload');
      }
      if (error instanceof Error && error.name === 'ZodError') {
        throw serviceError('INVALID_INPUT', `Run document violates the canonical contract: ${error.message}`);
      }
      throw error;
    }

    // Queueing a newer revision explicitly supersedes older incomplete runs
    // for the same position: publication against stale economics is refused
    // later (REVISION_CONFLICT), never silently attached to new economics.
    await this.runRepository.supersedeStale({
      ownerId,
      positionId,
      beforeRevision: request.position_revision,
      excludeRunId: runId,
      finishedAt: createdAt,
    });

    return { run: this.#runView(run), idempotent_replay: false };
  }

  // -- Claims, leases, heartbeats -------------------------------------------

  async claimRun({ run_id } = {}) {
    assertOwnerScopedId(run_id, 'run_id');
    const run = await this.runRepository.findById(run_id);
    if (!run) throw serviceError('RUN_NOT_FOUND', `Run not found: ${run_id}`);
    if (run.status !== 'queued') {
      throw serviceError('RUN_ALREADY_CLAIMED', `Run ${run_id} is ${run.status}, not claimable`);
    }
    const now = this.now();
    const leaseNonce = crypto.randomBytes(32).toString('hex');
    const claimPatch = {
      status: 'running',
      stage: 'claimed',
      started_at: now.toISOString(),
      heartbeat_at: now.toISOString(),
      lease_nonce: leaseNonce,
      lease_expires_at: new Date(now.getTime() + this.leaseSeconds * 1000).toISOString(),
    };
    const claimed = await this.runRepository.claimQueued(run_id, claimPatch);
    if (!claimed) {
      throw serviceError('RUN_ALREADY_CLAIMED', `Run ${run_id} was claimed concurrently`);
    }
    return this.#runView(claimed);
  }

  async heartbeatRun({ run_id, stage } = {}) {
    assertOwnerScopedId(run_id, 'run_id');
    if (typeof stage !== 'string' || stage.length === 0 || stage.length > 80) {
      throw serviceError('INVALID_INPUT', 'stage must be a non-empty string of at most 80 characters');
    }
    const run = await this.runRepository.findById(run_id);
    if (!run) throw serviceError('RUN_NOT_FOUND', `Run not found: ${run_id}`);
    const now = this.now();
    if (run.status === 'running' && run.deadline_at <= now.toISOString()) {
      throw serviceError('RUN_DEADLINE_EXCEEDED', `Run ${run_id} is past its deadline and must be recovered`);
    }
    const updated = await this.runRepository.updateIfStatus(run_id, ['running'], {
      stage,
      heartbeat_at: now.toISOString(),
    });
    if (!updated) {
      throw serviceError('INVALID_RUN_TRANSITION', `Run ${run_id} is not running; heartbeat refused`);
    }
    return this.#runView(updated);
  }

  // -- Terminal transitions ---------------------------------------------------

  async completeRun({ run_id, outcome } = {}) {
    assertOwnerScopedId(run_id, 'run_id');
    if (!outcome || !['succeeded', 'limited', 'failed'].includes(outcome.status)) {
      throw serviceError('INVALID_RUN_OUTCOME', 'outcome.status must be succeeded, limited, or failed');
    }
    const run = await this.runRepository.findById(run_id);
    if (!run) throw serviceError('RUN_NOT_FOUND', `Run not found: ${run_id}`);
    if (run.status === 'superseded') {
      // Superseded economics can never publish: the assessment must rerun
      // against the exact current revision (CONTRACTS §5).
      throw serviceError('REVISION_CONFLICT', `Run ${run_id} was superseded by a newer position revision`);
    }
    if (run.status !== 'running') {
      throw serviceError('INVALID_RUN_TRANSITION', `Run ${run_id} is ${run.status}; only running runs complete`);
    }
    const now = this.now();
    const nowIso = now.toISOString();
    if (nowIso > run.deadline_at) {
      // Deadline enforcement keeps "success after expiry" impossible: the
      // recovery sweep will stall the run instead of faking completion.
      throw serviceError('RUN_DEADLINE_EXCEEDED', `Run ${run_id} passed its deadline at ${run.deadline_at}`);
    }
    let patch;
    if (outcome.status === 'failed') {
      if (typeof outcome.error_code !== 'string' || outcome.error_code.length === 0
        || outcome.error_code.length > 120
        || outcome.evidence_snapshot_id != null || outcome.assessment_id != null) {
        throw serviceError('INVALID_RUN_OUTCOME', 'failed outcome requires only an error code');
      }
      patch = {
        status: 'failed',
        stage: 'failed',
        finished_at: nowIso,
        error_code: outcome.error_code,
        run_result_ref: { error_code: outcome.error_code, recorded_at: nowIso },
      };
    } else {
      if (typeof outcome.evidence_snapshot_id !== 'string'
        || typeof outcome.assessment_id !== 'string') {
        throw serviceError('INVALID_RUN_OUTCOME', 'succeeded/limited outcomes require evidence snapshot and assessment references');
      }
      patch = {
        status: outcome.status,
        stage: 'completed',
        finished_at: nowIso,
        evidence_snapshot_id: outcome.evidence_snapshot_id,
        assessment_id: outcome.assessment_id,
        run_result_ref: {
          evidence_snapshot_id: outcome.evidence_snapshot_id,
          assessment_id: outcome.assessment_id,
          recorded_at: nowIso,
        },
      };
    }
    const updated = await this.runRepository.updateIfStatus(run_id, ['running'], patch);
    if (!updated) {
      throw serviceError('INVALID_RUN_TRANSITION', `Run ${run_id} changed state concurrently`);
    }
    return this.#runView(updated);
  }

  // -- Result callbacks (duplicate-assessment protection + binding) ----------

  async recordRunResult({ run_id, caller_owner_id, delivery_id, result } = {}) {
    assertOwnerScopedId(run_id, 'run_id');
    assertOwnerScopedId(caller_owner_id, 'caller_owner_id');
    if (typeof delivery_id !== 'string' || delivery_id.length === 0 || delivery_id.length > 128) {
      throw serviceError('INVALID_INPUT', 'delivery_id must be a non-empty string of at most 128 characters');
    }
    if (!isPlainObject(result)) {
      throw serviceError('INVALID_INPUT', 'result must be a plain JSON object');
    }
    const run = await this.runRepository.findById(run_id);
    if (!run) throw serviceError('RUN_NOT_FOUND', `Run not found: ${run_id}`);
    if (run.owner_id_internal !== caller_owner_id) {
      throw serviceError('OWNER_DENIED', 'Result delivery is bound to the run owner');
    }
    const digest = payloadDigest(result);

    // Idempotent replay of an already-recorded identical result.
    if (run.status === 'succeeded' || run.status === 'limited') {
      if (run.run_result_ref && run.run_result_ref.result_digest === digest) {
        return { assessment_id: run.assessment_id, idempotent: true };
      }
      throw serviceError('INVALID_RUN_TRANSITION', `Run ${run_id} already recorded a different result`);
    }
    if (run.status !== 'running') {
      throw serviceError('INVALID_RUN_TRANSITION', `Run ${run_id} is ${run.status}; results are accepted from running runs only`);
    }
    if (run.run_result_ref && run.run_result_ref.delivery_id === delivery_id
      && run.run_result_ref.result_digest === digest) {
      return { assessment_id: run.assessment_id, idempotent: true };
    }

    // Binding: exact position revision and verified evidence snapshot.
    if (result.position_revision !== run.position_revision) {
      throw serviceError('REVISION_CONFLICT', `Result revision ${result.position_revision} does not match run revision ${run.position_revision}`);
    }
    if (typeof result.evidence_snapshot_id !== 'string') {
      throw serviceError('INVALID_INPUT', 'result.evidence_snapshot_id must be a string');
    }
    if (!this.evidenceSnapshotLookup) {
      throw serviceError('SNAPSHOT_CONFLICT', 'Snapshot binding is not configured; refusing unverified result');
    }
    const snapshot = await this.evidenceSnapshotLookup(result.evidence_snapshot_id);
    if (!snapshot) {
      throw serviceError('SNAPSHOT_CONFLICT', `Evidence snapshot not found: ${result.evidence_snapshot_id}`);
    }
    // H08 review F1: instrument binding is strict. Both sides are guaranteed
    // non-null at creation (queueRun requires a non-empty instrument_id; the
    // snapshot/assessment models require the field), so a null on either side
    // is itself a mismatch — the previous `both truthy` guard was a bypass.
    const boundInstrument = run.run_input_ref ? run.run_input_ref.instrument_id : null;
    if (snapshot.instrument_id !== boundInstrument) {
      throw serviceError('SNAPSHOT_CONFLICT', 'Evidence snapshot does not match the run instrument');
    }
    if (!ASSESSMENT_STATUSES.includes(result.status)) {
      throw serviceError('INVALID_INPUT', 'result.status must be complete or limited');
    }
    // H08 review O2 (same silent-null class as F1): session_as_of is required
    // on the assessment model (non-null String), so an absent or non-string
    // value is a malformed delivery — never normalized to null. Deep format
    // validation (date shape) remains H09's boundary.
    if (typeof result.session_as_of !== 'string' || result.session_as_of.length === 0) {
      throw serviceError('INVALID_INPUT', 'result.session_as_of must be a non-empty string');
    }

    const nowIso = this.now().toISOString();
    const assessmentId = this.assessmentIdFactory();
    let assessmentIdResolved = assessmentId;
    let assessmentCreated = true;
    try {
      const assessment = {
        id: assessmentId,
        run_id,
        position_id: run.position_id,
        owner_id_internal: run.owner_id_internal,
        position_revision: run.position_revision,
        instrument_id: boundInstrument,
        evidence_snapshot_id: result.evidence_snapshot_id,
        generated_at: nowIso,
        session_as_of: result.session_as_of,
        status: result.status,
        artifact_kind: 'judgment',
        assessment: structuredClone(result.assessment ?? {}),
      };
      // The production adapter provides createIfCurrent: a transactionally
      // fenced owner/revision/instrument check at the persistence boundary.
      // Lightweight repositories used by isolated tests may only expose
      // create(), but production never falls back to that unsafe path.
      const persisted = typeof this.assessmentRepository.createIfCurrent === 'function'
        ? await this.assessmentRepository.createIfCurrent(assessment)
        : await this.assessmentRepository.create(assessment);
      if (!persisted) {
        throw serviceError('REVISION_CONFLICT', 'Position owner, revision, or instrument changed before assessment publication');
      }
      // Safe stale-guard reconciliation can return the immutable assessment
      // inserted before a crash. Bind the run to that persisted winner, not to
      // this retry's newly generated candidate id.
      assessmentIdResolved = persisted.id;
    } catch (error) {
      if (error && error.code === 'DUPLICATE_ASSESSMENT') {
        // Concurrent callback won the race: resolve to the single persisted
        // assessment idempotently instead of creating a duplicate.
        const existing = await this.assessmentRepository.findByRunId(run_id);
        if (!existing) throw error;
        assessmentIdResolved = existing.id;
        assessmentCreated = false;
      } else {
        throw error;
      }
    }

    if (assessmentCreated) {
      const updated = await this.runRepository.updateIfStatus(run_id, ['running'], {
        status: result.status === 'complete' ? 'succeeded' : 'limited',
        stage: 'completed',
        finished_at: nowIso,
        evidence_snapshot_id: result.evidence_snapshot_id,
        assessment_id: assessmentIdResolved,
        run_result_ref: {
          delivery_id,
          result_digest: digest,
          evidence_snapshot_id: result.evidence_snapshot_id,
          assessment_id: assessmentIdResolved,
          recorded_at: nowIso,
        },
      });
      if (!updated) {
        // Lost the terminal transition race: another callback recorded an
        // identical result. The unique run_id index already prevented a
        // duplicate assessment; report the winner idempotently.
        const winner = await this.runRepository.findById(run_id);
        return {
          assessment_id: (winner && winner.assessment_id) || assessmentIdResolved,
          idempotent: true,
        };
      }
    }
    return { assessment_id: assessmentIdResolved, idempotent: !assessmentCreated };
  }

  // -- Restart / deadline recovery --------------------------------------------

  async recoverAbandonedRuns() {
    const nowIso = this.now().toISOString();
    const expired = await this.runRepository.findExpired(nowIso);
    let stalled = 0;
    let superseded = 0;
    for (const run of expired) {
      if (run.status === 'running') {
        const updated = await this.runRepository.updateIfStatus(run.id, ['running'], {
          status: 'stalled',
          stage: 'stalled',
          finished_at: nowIso,
          error_code: 'RUN_STALLED',
        });
        if (updated) stalled += 1;
      } else {
        const updated = await this.runRepository.updateIfStatus(run.id, ['queued'], {
          status: 'superseded',
          stage: 'superseded',
          finished_at: nowIso,
        });
        if (updated) superseded += 1;
      }
    }
    return { stalled, superseded };
  }

  // -- Generalized stage replay / recovery (H09X) ------------------------------

  // Persists a validated pipeline-stage artifact and advances the run's stage
  // monotonically forward. Replaying an already-recorded stage with an
  // identical artifact is idempotent (no re-execution, no re-charge); a
  // different artifact is a conflict. Immutable input references
  // (run_input_ref / input_snapshot_id / deadline_at / position_revision) are
  // never touched. Stage artifacts live under run_result_ref.stage_artifacts
  // only while the run is running; terminal transitions replace run_result_ref.
  async advanceStage({ run_id, stage, artifact } = {}) {
    assertOwnerScopedId(run_id, 'run_id');
    if (!validateStage(stage)) {
      throw serviceError('INVALID_STAGE', `stage must be one of ${STAGES.join(', ')}`);
    }
    if (!isPlainObject(artifact)) {
      throw serviceError('INVALID_STAGE_ARTIFACT', 'artifact must be a plain JSON object');
    }
    const run = await this.runRepository.findById(run_id);
    if (!run) throw serviceError('RUN_NOT_FOUND', `Run not found: ${run_id}`);
    if (run.status !== 'running') {
      throw serviceError('INVALID_RUN_TRANSITION', `Run ${run_id} is ${run.status}; stages advance on running runs only`);
    }
    const nowIso = this.now().toISOString();
    if (nowIso > run.deadline_at) {
      throw serviceError('RUN_DEADLINE_EXCEEDED', `Run ${run_id} passed its deadline at ${run.deadline_at}`);
    }
    const currentIndex = validateStage(run.stage) ? STAGE_ORDER[run.stage] : -1;
    const targetIndex = STAGE_ORDER[stage];
    if (targetIndex < currentIndex) {
      throw serviceError('STAGE_OUT_OF_ORDER', `Stage ${stage} precedes current stage ${run.stage}`);
    }
    const existing = (run.run_result_ref && run.run_result_ref.stage_artifacts) || {};
    const digest = payloadDigest(artifact);
    if (existing[stage]) {
      if (existing[stage].digest !== digest) {
        throw serviceError('STAGE_REPLAY_CONFLICT', `Stage ${stage} already recorded a different artifact`);
      }
      return {
        run: this.#runView(run),
        replayed: true,
        stage,
        artifact: structuredClone(existing[stage].artifact),
        recorded_at: existing[stage].recorded_at,
      };
    }
    const updated = await this.runRepository.updateIfStatus(run_id, ['running'], {
      stage,
      run_result_ref: {
        ...(run.run_result_ref ?? null),
        stage_artifacts: {
          ...existing,
          [stage]: { artifact: structuredClone(artifact), digest, recorded_at: nowIso },
        },
      },
    });
    if (!updated) {
      throw serviceError('INVALID_RUN_TRANSITION', `Run ${run_id} changed state concurrently`);
    }
    return {
      run: this.#runView(updated),
      replayed: false,
      stage,
      artifact: structuredClone(artifact),
      recorded_at: nowIso,
    };
  }

  // Reads a persisted stage artifact without re-executing anything. Returns
  // {replayed:true, artifact, recorded_at} when the stage was already
  // recorded, {replayed:false} otherwise. Never mutates the run.
  async replayStage({ run_id, stage } = {}) {
    assertOwnerScopedId(run_id, 'run_id');
    if (!validateStage(stage)) {
      throw serviceError('INVALID_STAGE', `stage must be one of ${STAGES.join(', ')}`);
    }
    const run = await this.runRepository.findById(run_id);
    if (!run) throw serviceError('RUN_NOT_FOUND', `Run not found: ${run_id}`);
    const artifacts = (run.run_result_ref && run.run_result_ref.stage_artifacts) || {};
    const record = artifacts[stage];
    if (record) {
      return {
        replayed: true,
        stage,
        artifact: structuredClone(record.artifact),
        recorded_at: record.recorded_at,
        run: this.#runView(run),
      };
    }
    return { replayed: false, stage, artifact: null, recorded_at: null, run: this.#runView(run) };
  }

  // Generalized resumable recovery. A running run within its deadline is
  // reported resumable with its persisted stage artifacts and its immutable
  // input references exposed for a safe resume — nothing is re-executed and no
  // model call is re-charged. A running run past its deadline is handed to the
  // existing recovery sweep (stalled/superseded), never silently resumed.
  async recoverIncompleteRun({ run_id } = {}) {
    assertOwnerScopedId(run_id, 'run_id');
    const run = await this.runRepository.findById(run_id);
    if (!run) throw serviceError('RUN_NOT_FOUND', `Run not found: ${run_id}`);
    const nowIso = this.now().toISOString();
    const lastStage = validateStage(run.stage) ? run.stage : null;
    if (run.status === 'running' && nowIso > run.deadline_at) {
      await this.recoverAbandonedRuns();
      const refreshed = await this.runRepository.findById(run_id);
      return {
        resumable: false,
        recovered: true,
        run: this.#runView(refreshed ?? run),
        last_stage: validateStage(refreshed?.stage) ? refreshed.stage : null,
        stage_artifacts: (refreshed?.run_result_ref && refreshed.run_result_ref.stage_artifacts) || {},
      };
    }
    if (run.status !== 'running') {
      return {
        resumable: false,
        recovered: false,
        run: this.#runView(run),
        last_stage: lastStage,
        stage_artifacts: (run.run_result_ref && run.run_result_ref.stage_artifacts) || {},
      };
    }
    return {
      resumable: true,
      recovered: false,
      run: this.#runView(run),
      last_stage: lastStage,
      stage_artifacts: structuredClone((run.run_result_ref && run.run_result_ref.stage_artifacts) || {}),
      immutable: {
        input_snapshot_id: run.input_snapshot_id,
        run_input_ref: structuredClone(run.run_input_ref),
        deadline_at: run.deadline_at,
        position_revision: run.position_revision,
        created_at: run.created_at,
      },
    };
  }

  // -- Owner-scoped read state -------------------------------------------------

  async getPositionResearchState({ owner_id, position_id } = {}) {
    const ownerId = assertOwnerScopedId(owner_id, 'owner_id');
    const positionId = assertOwnerScopedId(position_id, 'position_id');
    const [latestAssessment, latestAttempt, lastSuccess] = await Promise.all([
      this.assessmentRepository.latestForPosition(ownerId, positionId),
      this.runRepository.findLatestAttempt(ownerId, positionId),
      this.runRepository.findLatestSuccess(ownerId, positionId),
    ]);
    // Last success and latest attempt are reported separately: an existing
    // success is never rewritten by a later failure.
    return {
      position_id: positionId,
      latest_assessment: latestAssessment ? this.#assessmentView(latestAssessment) : null,
      last_success: lastSuccess ? {
        run_id: lastSuccess.id,
        status: lastSuccess.status,
        assessment_id: lastSuccess.assessment_id,
        evidence_snapshot_id: lastSuccess.evidence_snapshot_id,
        finished_at: lastSuccess.finished_at,
      } : null,
      latest_attempt: latestAttempt ? {
        run_id: latestAttempt.id,
        status: latestAttempt.status,
        stage: latestAttempt.stage,
        started_at: latestAttempt.started_at,
        finished_at: latestAttempt.finished_at,
        error_code: latestAttempt.error_code,
        deadline_at: latestAttempt.deadline_at,
      } : null,
    };
  }

  async listAssessments({ owner_id, position_id, cursor = null, limit = 20 } = {}) {
    const ownerId = assertOwnerScopedId(owner_id, 'owner_id');
    const positionId = assertOwnerScopedId(position_id, 'position_id');
    if (!Number.isSafeInteger(limit) || limit < 1 || limit > 100) {
      throw serviceError('INVALID_INPUT', 'limit must be an integer between 1 and 100');
    }
    const page = await this.assessmentRepository.listByPosition(ownerId, positionId, { cursor, limit });
    return {
      assessments: page.assessments.map((entry) => this.#assessmentView(entry)),
      next_cursor: page.next_cursor,
    };
  }

  async getRun({ owner_id, run_id } = {}) {
    const ownerId = assertOwnerScopedId(owner_id, 'owner_id');
    assertOwnerScopedId(run_id, 'run_id');
    const run = await this.runRepository.findById(run_id);
    // Cross-owner and missing ids are indistinguishable (CONTRACTS §9).
    if (!run || run.owner_id_internal !== ownerId) {
      throw serviceError('RUN_NOT_FOUND', `Run not found: ${run_id}`);
    }
    return this.#runView(run);
  }

  // -- Thesis memory: checkpoints ----------------------------------------------

  async createCheckpoint({
    owner_id,
    instrument_id,
    kind,
    metric_id = null,
    fixed_level = null,
    condition = null,
    source_assessment_id = null,
    predecessor_checkpoint_id = null,
  } = {}) {
    const ownerId = assertOwnerScopedId(owner_id, 'owner_id');
    const instrumentId = assertOwnerScopedId(instrument_id, 'instrument_id');
    if (!CHECKPOINT_KINDS.includes(kind)) {
      throw serviceError('INVALID_CHECKPOINT', `kind must be one of ${CHECKPOINT_KINDS.join(', ')}`);
    }
    if (kind === 'rolling_indicator') {
      if (typeof metric_id !== 'string' || metric_id.length === 0 || fixed_level != null) {
        throw serviceError('INVALID_CHECKPOINT', 'rolling_indicator requires metric_id and forbids fixed_level');
      }
    } else if (kind === 'fixed_observed_level') {
      if (fixed_level == null || !Number.isFinite(fixed_level) || metric_id != null) {
        throw serviceError('INVALID_CHECKPOINT', 'fixed_observed_level requires a finite fixed_level and forbids metric_id');
      }
    } else if (kind === 'business_condition') {
      if (typeof condition !== 'string' || condition.length === 0 || condition.length > 500
        || metric_id != null || fixed_level != null) {
        throw serviceError('INVALID_CHECKPOINT', 'business_condition requires condition text and forbids metric_id/fixed_level');
      }
    }
    const checkpointId = this.checkpointIdFactory();
    const checkpoint = {
      checkpoint_id: checkpointId,
      owner_id_internal: ownerId,
      instrument_id: instrumentId,
      kind,
      metric_id: metric_id ?? null,
      fixed_level: fixed_level ?? null,
      condition: condition ?? null,
      status: 'active',
      reason: null,
      source_assessment_id: source_assessment_id ?? null,
      predecessor_checkpoint_id: predecessor_checkpoint_id ?? null,
      replacement_checkpoint_id: null,
      history: [],
    };
    await this.checkpointRepository.create(checkpoint);
    return structuredClone(checkpoint);
  }

  async recordCheckpointChange({ owner_id, checkpoint_id, event } = {}) {
    const ownerId = assertOwnerScopedId(owner_id, 'owner_id');
    assertOwnerScopedId(checkpoint_id, 'checkpoint_id');
    if (!event || !CHANGE_EVENT_KINDS.includes(event.event_kind)) {
      throw serviceError('INVALID_INPUT', `event_kind must be one of ${CHANGE_EVENT_KINDS.join(', ')}`);
    }
    if (typeof event.reason !== 'string' || event.reason.length === 0 || event.reason.length > 500) {
      throw serviceError('INVALID_INPUT', 'event.reason must be a non-empty string of at most 500 characters');
    }
    const checkpoint = await this.checkpointRepository.findById(ownerId, checkpoint_id);
    if (!checkpoint) {
      throw serviceError('NOT_FOUND', `Checkpoint not found: ${checkpoint_id}`);
    }
    const allowedTransitions = {
      active: ['triggered', 'retired', 'replaced'],
      triggered: ['replaced'],
      retired: [],
    };
    if (!allowedTransitions[checkpoint.status].includes(event.event_kind)) {
      throw serviceError('INVALID_CHECKPOINT_TRANSITION', `Checkpoint is ${checkpoint.status}; ${event.event_kind} is not permitted`);
    }
    if (event.event_kind === 'replaced' && event.replacement_checkpoint_id) {
      const replacement = await this.checkpointRepository.findById(ownerId, event.replacement_checkpoint_id);
      if (!replacement) {
        throw serviceError('INVALID_CHECKPOINT', `Replacement checkpoint not found: ${event.replacement_checkpoint_id}`);
      }
    }
    const nowIso = this.now().toISOString();
    const newStatus = event.event_kind === 'triggered' ? 'triggered' : 'retired';
    const historyEntry = {
      at: nowIso,
      event_kind: event.event_kind,
      previous_status: checkpoint.status,
      new_status: newStatus,
      reason: event.reason,
      evidence_ids: Array.isArray(event.evidence_ids) ? [...event.evidence_ids] : [],
      source_assessment_id: event.source_assessment_id ?? null,
      observed_value: event.observed_value ?? null,
      replacement_checkpoint_id: event.replacement_checkpoint_id ?? null,
    };
    if (checkpoint.history.length >= MAX_CHECKPOINT_EVENTS) {
      throw serviceError('INVALID_CHECKPOINT_TRANSITION', 'Checkpoint history is full');
    }
    const updated = await this.checkpointRepository.update(checkpoint_id, {
      status: newStatus,
      reason: event.reason,
      source_assessment_id: historyEntry.source_assessment_id,
      replacement_checkpoint_id: historyEntry.replacement_checkpoint_id,
      history: [...checkpoint.history, historyEntry],
    });
    return updated;
  }

  async listCheckpoints({ owner_id, instrument_id } = {}) {
    const ownerId = assertOwnerScopedId(owner_id, 'owner_id');
    const instrumentId = assertOwnerScopedId(instrument_id, 'instrument_id');
    return this.checkpointRepository.listByInstrument(ownerId, instrumentId);
  }

  // -- changes_since_previous (CONTRACTS §6) ------------------------------------

  async buildChangesSincePrevious({ owner_id, position_id, current_assessment_id } = {}) {
    const ownerId = assertOwnerScopedId(owner_id, 'owner_id');
    const positionId = assertOwnerScopedId(position_id, 'position_id');
    assertOwnerScopedId(current_assessment_id, 'current_assessment_id');
    const current = await this.assessmentRepository.findById(current_assessment_id);
    if (!current || current.owner_id_internal !== ownerId || current.position_id !== positionId) {
      throw serviceError('NOT_FOUND', `Assessment not found: ${current_assessment_id}`);
    }
    const previous = await this.assessmentRepository.latestForPosition(ownerId, positionId, current_assessment_id);
    let checkpointEvents = [];
    if (current.instrument_id) {
      const checkpoints = await this.checkpointRepository.listByInstrument(ownerId, current.instrument_id);
      checkpointEvents = checkpoints
        .flatMap((checkpoint) => checkpoint.history.map((event) => ({
          checkpoint_id: checkpoint.checkpoint_id,
          kind: checkpoint.kind,
          ...event,
        })))
        .sort((a, b) => b.at.localeCompare(a.at))
        .slice(0, 50);
    }
    return {
      current_assessment_id,
      // Prior generated judgments are identified as judgments — they are
      // analysis outputs, never source evidence.
      previous: previous ? {
        id: previous.id,
        run_id: previous.run_id,
        session_as_of: previous.session_as_of,
        generated_at: previous.generated_at,
        status: previous.status,
        artifact_kind: 'judgment',
        is_evidence: false,
      } : null,
      checkpoint_events: checkpointEvents,
    };
  }

  // -- Views ---------------------------------------------------------------------

  #runView(run) {
    // User/automation run views are plain JSON with ISO timestamp strings;
    // the canonical researchRun schema parses them (passthrough allows the
    // lease_* fields required by the H03 callback authorizer).
    return structuredClone(run);
  }

  #assessmentView(assessment) {
    return structuredClone(assessment);
  }
}

module.exports = {
  ResearchService,
  createMongooseRunRepository,
  createMongooseAssessmentRepository,
  createMongooseResearchSnapshotRepository,
  createMongooseCheckpointRepository,
  payloadDigest,
};
