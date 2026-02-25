const express = require('express');
const briefingController = require('./briefing.controller');
const authMiddleware = require('../../middleware/auth.middleware');

const router = express.Router();

/**
 * @route POST /api/v1/briefing
 * Updates the briefing state from agents/n8n
 * Note: Not protected by authMiddleware because it's called by external services.
 * In a production app, this would use an API key or webhook secret.
 */
router.post('/', briefingController.save);

// All other briefing routes are protected
router.use(authMiddleware);

/**
 * @route GET /api/v1/briefing
 * Returns the most current briefing
 */
router.get('/', briefingController.getLatest);

/**
 * @route POST /api/v1/briefing/trigger
 * Manually triggers the briefing generation workflow
 */
router.post('/trigger', briefingController.triggerManual);

/**
 * @route GET /api/v1/briefing/config
 * Returns the current configuration (topics, tickers)
 */
router.get('/config', briefingController.getConfig);

/**
 * @route GET /api/v1/briefing/history
 * List historical briefings
 */
router.get('/history', briefingController.getHistory);

router.put('/config/topic/:topicName', briefingController.toggleTopic);
router.delete('/config/topic/:topicName', briefingController.removeTopic);
router.get('/config/recommended', briefingController.getRecommendedTopics);

/**
 * @route PUT /api/v1/briefing/config
 * Updates the briefing configuration (topics, tickers)
 */
router.put('/config', briefingController.updateConfig);

module.exports = router;
