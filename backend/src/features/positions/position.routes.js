const express = require('express');

const ERROR_STATUS = Object.freeze({
  // 400 malformed/invalid request
  INVALID_INPUT: 400,
  INVALID_STATE: 400,
  INVALID_INSTRUMENT: 400,
  INVALID_DECIMAL: 400,
  INVALID_CURRENCY: 400,
  INVALID_DATE: 400,
  INVALID_CANDIDATE_ECONOMICS: 400,
  INVALID_QUOTE: 400,
  UNKNOWN_FIELD: 400,
  OWNER_FIELD_NOT_WRITABLE: 400,
  MISSING_EXPECTED_REVISION: 400,
  // 404 not found / not owned (indistinguishable)
  NOT_FOUND: 404,
  // 409 conflicts
  DUPLICATE_POSITION: 409,
  REVISION_CONFLICT: 409,
  INVALID_TRANSITION: 409,
});

function statusForError(error) {
  return ERROR_STATUS[error.code] || null;
}

function createPositionRouter({ positionService, authenticate = null } = {}) {
  if (!positionService
    || typeof positionService.list !== 'function'
    || typeof positionService.get !== 'function'
    || typeof positionService.create !== 'function'
    || typeof positionService.update !== 'function') {
    throw new TypeError('createPositionRouter requires a position service');
  }

  const router = express.Router();
  router.use(authenticate || require('../../middleware/auth.middleware'));

  router.get('/', async (req, res, next) => {
    try {
      const positions = await positionService.list(String(req.user?._id || ''));
      res.status(200).json({ positions });
    } catch (error) {
      next(error);
    }
  });

  router.post('/', async (req, res, next) => {
    try {
      const position = await positionService.create(String(req.user?._id || ''), req.body);
      res.status(201).json(position);
    } catch (error) {
      next(error);
    }
  });

  router.patch('/:id', async (req, res, next) => {
    try {
      const { expected_revision: expectedRevision, changes } = req.body || {};
      const position = await positionService.update(String(req.user?._id || ''), req.params.id, {
        expected_revision: expectedRevision,
        changes,
      });
      res.status(200).json(position);
    } catch (error) {
      next(error);
    }
  });

  // Error status forwarding: map typed service errors before the global handler.
  router.use((error, req, res, next) => {
    const status = statusForError(error);
    if (status) {
      return res.status(status).json({ code: error.code, message: error.message });
    }
    return next(error);
  });

  return router;
}

module.exports = { createPositionRouter };
