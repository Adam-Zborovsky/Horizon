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
 * @route GET /api/v1/briefing/history
 * List historical briefings
 */
router.get('/history', briefingController.getHistory);

module.exports = router;
