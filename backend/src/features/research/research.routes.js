const express = require('express');

// CONTRACTS §9 read/run endpoints, as an isolated router. The integration lane
// (H15) mounts it under /api/v1/research; nothing here touches app.js. The
// owner is derived server-side from req.user (JWT middleware), never from a
// client-supplied field. User-facing run views never expose the automation
// lease nonce: that secret belongs to the scoped automation identity (H03),
// which reads it through the service, not the public API.
const ERROR_STATUS = Object.freeze({
  // 400 malformed request
  INVALID_INPUT: 400,
  MISSING_IDEMPOTENCY_KEY: 400,
  INVALID_RUN_OUTCOME: 400,
  INVALID_CHECKPOINT: 400,
  // 403 cross-owner callback denial
  OWNER_DENIED: 403,
  // 404 not found / not owned (indistinguishable)
  NOT_FOUND: 404,
  RUN_NOT_FOUND: 404,
  // 409 conflicts
  IDEMPOTENCY_CONFLICT: 409,
  RUN_ALREADY_ACTIVE: 409,
  RUN_ALREADY_CLAIMED: 409,
  INVALID_RUN_TRANSITION: 409,
  RUN_DEADLINE_EXCEEDED: 409,
  REVISION_CONFLICT: 409,
  SNAPSHOT_CONFLICT: 409,
  INVALID_CHECKPOINT_TRANSITION: 409,
});

function statusForError(error) {
  return ERROR_STATUS[error.code] || null;
}

function toPublicRunView(run) {
  if (!run) return run;
  const view = { ...run };
  delete view.lease_nonce;
  return view;
}

function toPublicAssessmentView(assessment) {
  if (!assessment) return assessment;
  const view = { ...assessment };
  delete view.owner_id_internal;
  return view;
}

function createResearchRouter({ researchService, authenticate = null } = {}) {
  if (!researchService
    || typeof researchService.queueRun !== 'function'
    || typeof researchService.getRun !== 'function'
    || typeof researchService.getPositionResearchState !== 'function'
    || typeof researchService.listAssessments !== 'function') {
    throw new TypeError('createResearchRouter requires a research service');
  }

  const router = express.Router();
  router.use(authenticate || require('../../middleware/auth.middleware'));

  router.get('/positions/:id/latest', async (req, res, next) => {
    try {
      const state = await researchService.getPositionResearchState({
        owner_id: String(req.user?._id || ''),
        position_id: req.params.id,
      });
      res.status(200).json({
        position_id: state.position_id,
        latest_assessment: toPublicAssessmentView(state.latest_assessment),
        run_state: {
          last_success: state.last_success,
          latest_attempt: state.latest_attempt,
        },
      });
    } catch (error) {
      next(error);
    }
  });

  router.get('/positions/:id/assessments', async (req, res, next) => {
    try {
      const limit = req.query.limit == null ? 20 : Number(req.query.limit);
      const page = await researchService.listAssessments({
        owner_id: String(req.user?._id || ''),
        position_id: req.params.id,
        cursor: typeof req.query.cursor === 'string' ? req.query.cursor : null,
        limit,
      });
      res.status(200).json({
        assessments: page.assessments.map(toPublicAssessmentView),
        next_cursor: page.next_cursor,
      });
    } catch (error) {
      next(error);
    }
  });

  router.post('/positions/:id/runs', async (req, res, next) => {
    try {
      const idempotencyKey = req.get('idempotency-key');
      if (!idempotencyKey || idempotencyKey.length === 0) {
        return next(Object.assign(new Error('Idempotency-Key header is required'), {
          code: 'MISSING_IDEMPOTENCY_KEY',
        }));
      }
      const body = req.body || {};
      const { run, idempotent_replay: idempotentReplay } = await researchService.queueRun({
        owner_id: String(req.user?._id || ''),
        position_id: req.params.id,
        position_revision: body.position_revision,
        run_kind: body.run_kind,
        idempotency_key: idempotencyKey,
        instrument_id: body.instrument_id,
        request_payload: body.request_payload,
      });
      // 202 for both first queue and persisted replay: same key + same request
      // returns the same run either way (CONTRACTS §8).
      return res.status(202).json({ run: toPublicRunView(run), idempotent_replay: idempotentReplay });
    } catch (error) {
      return next(error);
    }
  });

  router.get('/runs/:runId', async (req, res, next) => {
    try {
      const run = await researchService.getRun({
        owner_id: String(req.user?._id || ''),
        run_id: req.params.runId,
      });
      res.status(200).json({ run: toPublicRunView(run) });
    } catch (error) {
      next(error);
    }
  });

  // Error status forwarding: typed service errors map to contract statuses
  // before the global handler; unknown errors pass through untouched.
  router.use((error, req, res, next) => {
    const status = statusForError(error);
    if (status) {
      return res.status(status).json({ code: error.code, message: error.message });
    }
    return next(error);
  });

  return router;
}

module.exports = { createResearchRouter };
