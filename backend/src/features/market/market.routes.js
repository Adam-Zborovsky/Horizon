const express = require('express');

function createMarketRouter({ marketService, authenticate = null } = {}) {
  if (!marketService || typeof marketService.getHistory !== 'function') {
    throw new TypeError('createMarketRouter requires a market service');
  }

  const router = express.Router();
  router.use(authenticate || require('../../middleware/auth.middleware'));

  router.get('/instruments/:instrumentId/history', async (req, res, next) => {
    try {
      const response = await marketService.getHistory({
        ownerId: String(req.user?._id || ''),
        instrumentId: req.params.instrumentId,
        range: req.query.range,
        resolution: req.query.resolution,
        snapshotId: req.query.snapshot_id,
      });
      res.status(200).json(response);
    } catch (error) {
      next(error);
    }
  });

  return router;
}

module.exports = { createMarketRouter };
