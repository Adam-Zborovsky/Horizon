const app = require('./app');
const env = require('./config/env');
const connectDB = require('./config/db');
const { startScheduler } = require('./utils/scheduler');

const { PositionService, createMongoosePositionRepository } = require('./features/positions/position.service');
const {
  ResearchService,
  createMongooseRunRepository,
  createMongooseAssessmentRepository,
  createMongooseResearchSnapshotRepository,
  createMongooseCheckpointRepository,
} = require('./features/research/research.service');
const ResearchSnapshotModel = require('./features/research/research_snapshot.model');
const { createResearchAgentRuntime } = require('./features/research/agent_runtime');
const { createRunWorker } = require('./features/research/run_worker');
const {
  createAutomationRouter,
  createMongooseQueuedRunSource,
} = require('./features/research/automation.routes');
const {
  createAutomationMiddleware,
  createRunCallbackAuthorizer,
} = require('./middleware/automation.middleware');

// ---------------------------------------------------------------------------
// H15 — production composition.
//
// H15B left the owner-facing position/research routers conditional on
// injection; H10 left the automation router unmounted with the explicit note
// that the runs repository and the run worker's runLookup must share one
// store (H10 review O3 — H15 wiring responsibility). This module owns that
// wiring: every surface below is composed from the SAME runRepository
// instance, so runs queued by the user-facing service are visible to the
// scoped automation identity and to the bounded run worker without any
// second queue.
//
// Fail-closed posture (CONTRACTS §9): the automation surface requires an
// operator-provisioned model client identity and a scoped automation
// identity. Neither is provisioned in this repository, so startServer mounts
// /positions and /research and leaves /automation/research unmounted with an
// explicit log line — never a weakened or partial mount.
// ---------------------------------------------------------------------------

// Evidence snapshot lookup for the real research service: resolves an
// immutable input reference to its narrow {snapshot_id, instrument_id}
// projection (the shape ResearchService consumes), or null.
function createMongooseEvidenceSnapshotLookup({ model = ResearchSnapshotModel } = {}) {
  if (!model || typeof model.findOne !== 'function') {
    throw new TypeError('createMongooseEvidenceSnapshotLookup requires a snapshot model');
  }
  return async function lookupEvidenceSnapshot(snapshotId) {
    if (!snapshotId) return null;
    const doc = await model.findOne({ snapshot_id: String(snapshotId) })
      .select('snapshot_id instrument_id')
      .lean();
    return doc
      ? { snapshot_id: doc.snapshot_id, instrument_id: doc.instrument_id }
      : null;
  };
}

// Production services over the default mongoose models. One runRepository
// instance is returned to the caller so the automation surface (if composed)
// shares the same store — never a parallel queue.
function buildProductionServices({
  now = () => new Date(),
  deadlineSeconds = 900,
  leaseSeconds,
  evidenceSnapshotLookup = null,
} = {}) {
  const runRepository = createMongooseRunRepository();
  const researchService = new ResearchService({
    runRepository,
    assessmentRepository: createMongooseAssessmentRepository(),
    researchSnapshotRepository: createMongooseResearchSnapshotRepository(),
    checkpointRepository: createMongooseCheckpointRepository(),
    evidenceSnapshotLookup: evidenceSnapshotLookup || createMongooseEvidenceSnapshotLookup(),
    now,
    deadlineSeconds,
    ...(leaseSeconds !== undefined ? { leaseSeconds } : {}),
  });
  const positionService = new PositionService({
    positionRepository: createMongoosePositionRepository(),
    now,
  });
  return { runRepository, researchService, positionService };
}

// Compose the H10 automation surface: agent runtime + bounded run worker +
// automation router over ONE shared runs store, guarded by the scoped
// automation identity (never a user JWT). Every dependency is required and
// validated — a missing model client, input provider, runs store or scoped
// identity throws instead of mounting a weakened surface.
function composeAutomationSurface({
  modelClient,
  inputProvider,
  runRepository,
  assessmentRepository,
  researchSnapshotRepository,
  checkpointRepository,
  evidenceSnapshotLookup = null,
  automation: automationConfig = {},
  listQueuedRuns = null,
  now = () => new Date(),
  deadlineSeconds = 900,
  leaseSeconds,
  idFactory,
  assessmentIdFactory,
  snapshotIdFactory,
  checkpointIdFactory,
  isExchangeSession,
  logger = console,
} = {}) {
  if (!modelClient || typeof modelClient.complete !== 'function') {
    throw new TypeError('composeAutomationSurface requires an operator-provisioned model client ({ complete() })');
  }
  if (typeof inputProvider !== 'function') {
    throw new TypeError('composeAutomationSurface requires an input provider for the bounded run worker');
  }
  if (!runRepository || typeof runRepository.findById !== 'function') {
    throw new TypeError('composeAutomationSurface requires the shared run repository');
  }
  if (!assessmentRepository || !researchSnapshotRepository || !checkpointRepository) {
    throw new TypeError('composeAutomationSurface requires the assessment/snapshot/checkpoint repositories');
  }
  const { token, scopes, ownerId, expiresAt, maxBodyBytes } = automationConfig;
  if (!token || !Array.isArray(scopes) || scopes.length === 0 || !ownerId) {
    throw new TypeError('composeAutomationSurface requires a scoped automation identity (token, scopes, ownerId)');
  }

  const researchService = new ResearchService({
    runRepository,
    assessmentRepository,
    researchSnapshotRepository,
    checkpointRepository,
    evidenceSnapshotLookup,
    now,
    deadlineSeconds,
    ...(leaseSeconds !== undefined ? { leaseSeconds } : {}),
    ...(idFactory ? { idFactory } : {}),
    ...(assessmentIdFactory ? { assessmentIdFactory } : {}),
    ...(snapshotIdFactory ? { snapshotIdFactory } : {}),
    ...(checkpointIdFactory ? { checkpointIdFactory } : {}),
  });

  const agentRuntime = createResearchAgentRuntime({
    modelClient: { complete: (request) => modelClient.complete(request) },
    now,
    idFactory: assessmentIdFactory || (() => require('node:crypto').randomUUID()),
    isExchangeSession: isExchangeSession || defaultIsExchangeSession,
  });

  // H10 review O3: the worker's runLookup and the service share the SAME
  // runRepository instance — one persisted store for claims, status and
  // results.
  const worker = createRunWorker({
    researchService,
    agentRuntime,
    inputProvider,
    runLookup: (runId) => runRepository.findById(runId),
    now,
    logger,
  });

  const router = createAutomationRouter({
    researchService,
    runWorker: worker,
    runs: runRepository,
    automationMiddleware: createAutomationMiddleware({
      token,
      scopes,
      ownerId,
      ...(expiresAt !== undefined ? { expiresAt } : {}),
      ...(maxBodyBytes !== undefined ? { maxBodyBytes } : {}),
    }),
    callbackAuthorizer: createRunCallbackAuthorizer({ now }),
    listQueuedRuns: listQueuedRuns || createMongooseQueuedRunSource(),
    now,
  });

  return { researchService, runRepository, worker, router };
}

// Exchange-session weekday predicate shared with the H09/H10 fixtures: a
// session date is a trading day when it falls Mon–Fri (UTC calendar view of
// the exchange-local date). Holiday calendars stay with the provider adapter.
function defaultIsExchangeSession(sessionDate) {
  const weekday = new Date(`${sessionDate}T00:00:00Z`).getUTCDay();
  return weekday >= 1 && weekday <= 5;
}

const startServer = async () => {
  // Connect to the database
  await connectDB();

  // Compose the production services (H15 wiring: shared runs store).
  const services = buildProductionServices({
    now: () => new Date(),
    deadlineSeconds: 900,
  });

  // Compose the H10 automation surface: agent runtime + bounded run worker +
  // automation router over ONE shared runs store, guarded by the scoped
  // automation identity (never a user JWT). Every dependency is required and
  // validated — a missing model client, input provider, runs store or scoped
  // identity throws instead of mounting a weakened surface.
  // The surface mounts ONLY when the operator provisions all of:
  // RESEARCH_LLM_BASE_URL / RESEARCH_LLM_API_KEY / RESEARCH_LLM_MODEL
  // (model client identity) AND AUTOMATION_SERVICE_TOKEN / _SCOPES /
  // _OWNER_ID. Partial provisioning stays unmounted (fail closed).
  let automationRouter = null;
  if (env.AUTOMATION_SERVICE_TOKEN && env.RESEARCH_LLM_API_KEY && env.RESEARCH_LLM_BASE_URL && env.RESEARCH_LLM_MODEL) {
    const { createOpenAICompatibleModelClient } = require('./features/research/model_client');
    const { createMongooseRunInputProvider } = require('./features/research/run_inputs');
    const PositionModel = require('./features/positions/position.model');
    const ResearchAssessmentModel = require('./features/research/research_assessment.model');
    const automationScopes = String(env.AUTOMATION_SERVICE_SCOPES || '')
      .split(',')
      .map((s) => s.trim())
      .filter(Boolean);
    const modelClient = createOpenAICompatibleModelClient({
      baseUrl: env.RESEARCH_LLM_BASE_URL,
      apiKey: env.RESEARCH_LLM_API_KEY,
      model: env.RESEARCH_LLM_MODEL,
    });
    ({ router: automationRouter } = composeAutomationSurface({
      modelClient,
      inputProvider: createMongooseRunInputProvider({
        positionModel: PositionModel,
        assessmentModel: ResearchAssessmentModel,
      }),
      runRepository: services.runRepository,
      assessmentRepository: createMongooseAssessmentRepository(),
      researchSnapshotRepository: createMongooseResearchSnapshotRepository(),
      checkpointRepository: createMongooseCheckpointRepository(),
      automation: {
        token: env.AUTOMATION_SERVICE_TOKEN,
        scopes: automationScopes,
        ownerId: env.AUTOMATION_OWNER_ID,
        expiresAt: env.AUTOMATION_SERVICE_TOKEN_EXPIRES_AT ?? null,
      },
    }));
    console.log(`🔌 Automation surface composed (model: ${env.RESEARCH_LLM_MODEL}; scopes: ${automationScopes.join(' ')})`);
  } else if (env.AUTOMATION_SERVICE_TOKEN) {
    console.warn('⏳ AUTOMATION_SERVICE_TOKEN is configured, but no model client identity is provisioned; /automation/research stays unmounted (fail closed).');
  }

  // Start the daily briefing scheduler (legacy flow; preserved unchanged).
  startScheduler();

  // Listen for requests — owner-facing position/research mounts are now
  // injected alongside the default H15A market slice; /automation/research
  // remains unmounted until the model client identity is provisioned.
  const expressApp = app.createApp({
    positionService: services.positionService,
    researchService: services.researchService,
    automationRouter,
  });
  const PORT = env.PORT;
  expressApp.listen(PORT, () => {
    console.log(`✅ Horizon Backend is running on port: ${PORT}`);
    console.log(`🌍 Environment: ${env.NODE_ENV}`);
    console.log(`🔗 API Prefix: ${env.API_PREFIX}`);
  });
};

if (require.main === module) {
  startServer().catch(err => {
    console.error('❌ Failed to start server:', err);
    process.exit(1);
  });
}

module.exports = {
  buildProductionServices,
  composeAutomationSurface,
  createMongooseEvidenceSnapshotLookup,
  defaultIsExchangeSession,
  startServer,
};
