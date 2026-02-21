const express = require('express');
const briefingController = require('./briefing.controller');

const router = express.Router();

/**
 * @route GET /api/v1/briefing
 * Returns the most current briefing
 */
router.get('/', briefingController.getLatest);

/**
 * @route POST /api/v1/briefing
 * Updates the briefing state from agents
 */
router.post('/', briefingController.save);

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

/**
 * @route PUT /api/v1/briefing/config
 * Updates the briefing configuration (topics, tickers)
 */
router.put('/config', briefingController.updateConfig);

module.exports = router;

