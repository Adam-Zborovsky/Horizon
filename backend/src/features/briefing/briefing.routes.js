const express = require('express');
const briefingController = require('./briefing.controller');
const { createAutomationMiddleware } = require('../../middleware/automation.middleware');

function lazyUserAuth(req, res, next) {
  return require('../../middleware/auth.middleware')(req, res, next);
}

function createDefaultAutomationMiddleware() {
  return createAutomationMiddleware({
    configuration: () => {
      const env = require('../../config/env');
      return {
        token: env.AUTOMATION_SERVICE_TOKEN,
        scopes: env.AUTOMATION_SERVICE_SCOPES,
        ownerId: env.AUTOMATION_OWNER_ID,
        expiresAt: env.AUTOMATION_SERVICE_TOKEN_EXPIRES_AT,
      };
    },
  });
}

function rejectOwnerSpoofing(req, res, next) {
  const suppliedUserId = req.method === 'GET' ? req.query.userId : req.body && req.body.userId;
  if (suppliedUserId && suppliedUserId !== req.automation.ownerId) {
    return res.status(403).json({ code: 'automation_owner_denied', message: 'Automation request denied.' });
  }
  return next();
}

function createBriefingRouter({
  controller = briefingController,
  authMiddleware = lazyUserAuth,
  automationMiddleware = createDefaultAutomationMiddleware(),
} = {}) {
  const router = express.Router();

  /**
   * @route POST /api/v1/briefing
   * Updates the briefing state from the scoped automation identity.
   */
  router.post(
    '/',
    automationMiddleware({ requiredScopes: ['briefing:write'], requireOwner: true }),
    rejectOwnerSpoofing,
    controller.save,
  );

  /**
   * @route GET /api/v1/briefing/config/system
   * Returns configuration only for the owner bound to the service identity.
   */
  router.get(
    '/config/system',
    automationMiddleware({ requiredScopes: ['briefing:read'], requireOwner: true }),
    rejectOwnerSpoofing,
    controller.getConfigForSystem,
  );

  // All other briefing routes are protected by user JWT authentication.
  router.use(authMiddleware);

/**
 * @route GET /api/v1/briefing
 * Returns the most current briefing
 */
  router.get('/', controller.getLatest);

/**
 * @route POST /api/v1/briefing/trigger
 * Manually triggers the briefing generation workflow
 */
  router.post('/trigger', controller.triggerManual);

/**
 * @route GET /api/v1/briefing/status
 * Lightweight endpoint returning only the latest briefing timestamp
 */
  router.get('/status', controller.getLatestTimestamp);

/**
 * @route GET /api/v1/briefing/search
 * Search for tickers via autocomplete
 */
  router.get('/search', controller.searchTickers);

/**
 * @route GET /api/v1/briefing/config
 * Returns the current configuration (topics, tickers)
 */
  router.get('/config', controller.getConfig);

/**
 * @route GET /api/v1/briefing/history
 * List historical briefings
 */
  router.get('/history', controller.getHistory);

  router.get('/opportunity-stats/:ticker', controller.getOpportunityStats);
  router.put('/config/topic/:topicName', controller.toggleTopic);
  router.delete('/config/topic/:topicName', controller.removeTopic);
  router.get('/config/recommended', controller.getRecommendedTopics);

/**
 * @route PUT /api/v1/briefing/config
 * Updates the briefing configuration (topics, tickers)
 */
  router.put('/config', controller.updateConfig);

  return router;
}

module.exports = createBriefingRouter();
module.exports.createBriefingRouter = createBriefingRouter;
