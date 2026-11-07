const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const env = require('./config/env');
const briefingRoutes = require('./features/briefing/briefing.routes');
const webhookRoutes = require('./features/briefing/webhook.routes');
const authRoutes = require('./features/auth/auth.routes');
const errorHandler = require('./middleware/error.middleware');
const { createMarketRouter } = require('./features/market/market.routes');
const { MarketHistoryService } = require('./features/market/market.service');
const { createPositionRouter } = require('./features/positions/position.routes');
const { createResearchRouter } = require('./features/research/research.routes');

function createApp({
  marketService = null,
  marketRouter = null,
  positionService = null,
  positionRouter = null,
  researchService = null,
  researchRouter = null,
  // Optional explicit lookup for composed deployments/tests whose position
  // store is not the default Mongoose model.
  positionLookup = null,
  automationRouter = null,
  runWorker = null,
  authenticate = null,
  instrumentResolver = null,
  jsonLimit = '1mb',
  logging = (env.NODE_ENV !== 'test'),
} = {}) {
  const app = express();

  // Standard middleware
  app.use(helmet());
  app.use(cors());
  if (logging) {
    app.use(morgan('dev'));
  }

  // Transport-level parser limit reduced from legacy 50mb to prevent memory-exhaustion DoS
  app.use(express.json({ limit: jsonLimit }));
  app.use(express.urlencoded({ extended: true, limit: jsonLimit }));

  // Health Check
  app.get('/health', (req, res) => {
    res.status(200).json({ status: 'healthy', version: '1.0.0' });
  });

  // API Routes
  app.use(`${env.API_PREFIX}/auth`, authRoutes);
  app.use(`${env.API_PREFIX}/briefing`, briefingRoutes);

  // Market Routes (H15A: early protected observed-history slice)
  const effectiveMarketRouter = marketRouter || createMarketRouter({
    marketService: marketService || new MarketHistoryService({
      instrumentResolver: instrumentResolver || (async () => null),
    }),
    authenticate,
  });
  app.use(`${env.API_PREFIX}/market`, effectiveMarketRouter);

  // Owner-scoped position and research mounts (H15B). Routers are only
  // mounted when a service (or router) is injected: the default factory keeps
  // these paths unmounted (404) until wired, preserving the H15A contract.
  const effectivePositionRouter = positionRouter
    || (positionService ? createPositionRouter({ positionService, authenticate }) : null);
  if (effectivePositionRouter) {
    app.use(`${env.API_PREFIX}/positions`, effectivePositionRouter);
  }

  const effectiveResearchRouter = researchRouter
    || (researchService ? createResearchRouter({
        researchService,
        // PositionService enforces the same indistinguishable-not-found owner
        // boundary for non-Mongoose compositions. Production otherwise uses
        // the router's owner-scoped default model lookup.
        positionLookup: positionLookup || (positionService && typeof positionService.get === 'function'
          ? async (positionId, ownerId) => {
            try {
              return await positionService.get(ownerId, positionId);
            } catch (_) {
              return null;
            }
          }
          : undefined),
        onRunQueued: runWorker ? (run) => runWorker.startRun({ run_id: run.id }) : null,
        authenticate,
      }) : null);
  if (effectiveResearchRouter) {
    app.use(`${env.API_PREFIX}/research`, effectiveResearchRouter);
  }

  // Automation surface (H15 integration of the H10 automation router).
  // Mounted ONLY when a fully composed router is injected: the default
  // factory keeps /api/v1/automation/research unmounted (404) until the
  // scoped service identity, shared runs store and bounded run worker are
  // wired (server.js composeAutomationSurface). This preserves the H15A/H15B
  // conditional-mount contract.
  if (automationRouter) {
    app.use(`${env.API_PREFIX}/automation/research`, automationRouter);
  }

  // Webhook Routes (unversioned legacy mount point; remains route-free until guarded)
  app.use('/webhook', webhookRoutes);

  // Error status forwarding adapter (maps error.status / error.statusCode to res.status before errorHandler)
  app.use((err, req, res, next) => {
    const errorStatus = err.status || err.statusCode;
    if (errorStatus && res.statusCode === 200) {
      res.status(errorStatus);
    }
    next(err);
  });

  // Error Handling
  app.use(errorHandler);

  return app;
}

const defaultApp = createApp();
defaultApp.createApp = createApp;

module.exports = defaultApp;
module.exports.createApp = createApp;
