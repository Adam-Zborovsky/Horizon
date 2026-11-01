'use strict';

// H10 — automation surface for the thin n8n trigger/poll/delivery loop.
//
// CONTRACTS §8/§9: scoped service identity (never a user JWT, never the
// n8n-management key), run-bound lease nonce on callbacks, server-derived
// owner binding — no arbitrary callback userId — and honest persisted status.
// This router is isolated (like research.routes.js): the integration lane
// mounts it under the API prefix; nothing here touches app.js.
//
// Routes (designed to mount at /automation/research):
//   GET  /runs/queued            research:trigger  bounded claimable batch
//   GET  /runs/:runId/input      research:input    bound run input only (no
//                                                  economics, no lease nonce)
//   POST /runs/:runId/execute    research:execute  202 fresh claim (bounded
//                                                  Node pipeline started) or
//                                                  200 replayed status/result
//   GET  /runs/:runId/status     research:status   persisted status, honest
//   POST /runs/:runId/result     research:callback lease-bound delivery
//                                                  201 first / 200 identical
//                                                  duplicate / 409 conflict /
//                                                  422 invalid researched result

const crypto = require('node:crypto');
const express = require('express');

const ResearchRunModel = require('./research_run.model');
const { toStatusView } = require('./run_worker');
const { validateToolRequest } = require('./tool_registry');

const DEFAULT_QUEUED_LIMIT = 25;
const MAX_QUEUED_LIMIT = 100;

const ERROR_STATUS = Object.freeze({
  // 400 malformed request (route-level body/format problems)
  INVALID_DELIVERY: 400,
  // 403 authorization (service-level + H03 authorizer codes)
  OWNER_DENIED: 403,
  automation_owner_denied: 403,
  automation_scope_denied: 403,
  automation_callback_denied: 403,
  automation_nonce_denied: 403,
  automation_auth_unavailable: 401,
  // 404 not found / not owned (indistinguishable)
  RUN_NOT_FOUND: 404,
  NOT_FOUND: 404,
  // 409 conflicts (service-level + H03 authorizer codes)
  IDEMPOTENCY_CONFLICT: 409,
  RUN_ALREADY_ACTIVE: 409,
  RUN_ALREADY_CLAIMED: 409,
  INVALID_RUN_TRANSITION: 409,
  RUN_DEADLINE_EXCEEDED: 409,
  REVISION_CONFLICT: 409,
  SNAPSHOT_CONFLICT: 409,
  automation_lease_expired: 409,
  automation_replay_conflict: 409,
  automation_run_invalid: 409,
  // 409 stage/tool conflicts (H09X)
  INVALID_STAGE: 400,
  INVALID_STAGE_ARTIFACT: 400,
  STAGE_OUT_OF_ORDER: 409,
  STAGE_REPLAY_CONFLICT: 409,
  RUN_NOT_RUNNING: 409,
  RUNTIME_NOT_CONFIGURED: 503,
});

// Tool-request validation issue -> HTTP status (CONTRACTS §9 error table).
const TOOL_ISSUE_STATUS = Object.freeze({
  UNKNOWN_TOOL: 400,
  INVALID_STAGE: 400,
  INVALID_ARGUMENTS: 400,
  UNEXPECTED_FIELD: 400,
  FORBIDDEN_ARGUMENT: 400,
  INVALID_REQUEST_ID: 400,
  TOOL_NOT_ALLOWED_IN_STAGE: 403,
  SYNTHESIS_ONLY_STAGE: 403,
});

function constantTimeEquals(left, right) {
  if (typeof left !== 'string' || typeof right !== 'string') return false;
  const leftBuffer = Buffer.from(left);
  const rightBuffer = Buffer.from(right);
  return leftBuffer.length === rightBuffer.length && crypto.timingSafeEqual(leftBuffer, rightBuffer);
}

function statusForError(error) {
  return ERROR_STATUS[error && error.code] || null;
}

function sendError(res, status, code) {
  return res.status(status).json({ code, message: 'Automation request rejected.' });
}

// Production wiring helper: owner-scoped, deadline-filtered claimable batch
// straight off the run model. Bounded by limit; exposes no economics.
function createMongooseQueuedRunSource(runModel = ResearchRunModel) {
  if (!runModel || typeof runModel.find !== 'function') {
    throw new TypeError('createMongooseQueuedRunSource requires a run model');
  }
  return async function listQueuedRuns({ ownerId, limit = DEFAULT_QUEUED_LIMIT, nowIso }) {
    const records = await runModel.find({
      owner_id_internal: ownerId,
      status: 'queued',
      deadline_at: { $gt: new Date(nowIso) },
    })
      .select('id position_id position_revision run_kind status stage created_at deadline_at')
      .sort({ created_at: 1 })
      .limit(limit)
      .lean();
    return records.map((record) => ({
      run_id: record.id ?? record._id,
      position_id: record.position_id,
      position_revision: record.position_revision,
      run_kind: record.run_kind,
      status: record.status,
      created_at: record.created_at,
      deadline_at: record.deadline_at,
    }));
  };
}

function createAutomationRouter({
  researchService,
  runWorker,
  runs,
  automationMiddleware,
  callbackAuthorizer,
  listQueuedRuns,
  now = () => new Date(),
  queuedLimit = DEFAULT_QUEUED_LIMIT,
  toolExecutor = null,
  resolveToolContext = null,
} = {}) {
  if (!researchService || typeof researchService.recordRunResult !== 'function') {
    throw new TypeError('createAutomationRouter requires a research service');
  }
  if (!runWorker || typeof runWorker.startRun !== 'function' || typeof runWorker.whenSettled !== 'function') {
    throw new TypeError('createAutomationRouter requires the H10 run worker');
  }
  if (!runs || typeof runs.findById !== 'function') {
    throw new TypeError('createAutomationRouter requires a run repository (findById)');
  }
  if (typeof automationMiddleware !== 'function') {
    throw new TypeError('createAutomationRouter requires the automation middleware factory');
  }
  if (!callbackAuthorizer || typeof callbackAuthorizer.authorize !== 'function') {
    throw new TypeError('createAutomationRouter requires the H03 run callback authorizer');
  }
  if (typeof listQueuedRuns !== 'function') {
    throw new TypeError('createAutomationRouter requires an injected queued-run source');
  }
  if (!Number.isSafeInteger(queuedLimit) || queuedLimit < 1 || queuedLimit > MAX_QUEUED_LIMIT) {
    throw new TypeError(`queuedLimit must be an integer between 1 and ${MAX_QUEUED_LIMIT}`);
  }

  const router = express.Router();

  // Loads the run and enforces the server-derived owner binding. Cross-owner
  // and missing ids are indistinguishable 404s (CONTRACTS §9).
  async function loadOwnedRun(req, res) {
    const run = await runs.findById(req.params.runId);
    if (!run || run.owner_id_internal !== req.automation.ownerId) {
      sendError(res, 404, 'RUN_NOT_FOUND');
      return null;
    }
    return run;
  }

  // H09X lease-bound stage/tool authorization. Stage and tool requests carry the
  // same run lease nonce as delivery (CONTRACTS §9): the caller must present the
  // current lease nonce for the exact run, and an expired lease is rejected so a
  // stale caller can never replay or re-charge work past its window.
  function authorizeRunLease(req, run) {
    const leaseExpiresAt = run.lease_expires_at ? new Date(run.lease_expires_at) : null;
    if (!leaseExpiresAt || Number.isNaN(leaseExpiresAt.getTime()) || leaseExpiresAt.getTime() <= now().getTime()) {
      const error = new Error('Run lease expired');
      error.code = 'automation_lease_expired';
      throw error;
    }
    const runId = req.get('x-horizon-run-id');
    const nonce = req.get('x-horizon-run-nonce');
    if (runId !== run.id || typeof nonce !== 'string' || !constantTimeEquals(nonce, run.lease_nonce)) {
      const error = new Error('Run lease nonce denied');
      error.code = 'automation_nonce_denied';
      throw error;
    }
  }

  // -- Trigger: bounded claimable batch --------------------------------------
  router.get('/runs/queued', automationMiddleware({ requiredScopes: ['research:trigger'], requireOwner: true }), async (req, res, next) => {
    try {
      let limit = queuedLimit;
      if (req.query.limit !== undefined) {
        const parsed = Number(req.query.limit);
        if (!Number.isSafeInteger(parsed) || parsed < 1 || parsed > MAX_QUEUED_LIMIT) {
          return sendError(res, 400, 'INVALID_INPUT');
        }
        limit = parsed;
      }
      const records = await listQueuedRuns({
        ownerId: req.automation.ownerId,
        limit,
        nowIso: now().toISOString(),
      });
      return res.status(200).json({
        runs: records,
        truncated: Array.isArray(records) && records.length >= limit,
      });
    } catch (error) {
      return next(error);
    }
  });

  // -- Bound run input only ---------------------------------------------------
  router.get('/runs/:runId/input', automationMiddleware({ requiredScopes: ['research:input'], requireOwner: true }), async (req, res, next) => {
    try {
      const run = await loadOwnedRun(req, res);
      if (!run) return undefined;
      const inputRef = run.run_input_ref ?? {};
      return res.status(200).json({
        run_id: run.id,
        position_id: run.position_id,
        position_revision: run.position_revision,
        run_kind: run.run_kind,
        instrument_id: inputRef.instrument_id ?? null,
        snapshot_id: run.input_snapshot_id ?? null,
        request_payload: inputRef.request_payload ?? null,
        deadline_at: run.deadline_at,
        status: run.status,
      });
      // Deliberately omitted: lease nonce, owner internals, position
      // economics. Private economics is injected server-side during
      // synthesis only (CONTRACTS §9), never returned by this endpoint.
    } catch (error) {
      return next(error);
    }
  });

  // -- Execute: claim + start the fixed bounded Node pipeline ------------------
  router.post('/runs/:runId/execute', automationMiddleware({ requiredScopes: ['research:execute'], requireOwner: true }), async (req, res, next) => {
    try {
      const run = await loadOwnedRun(req, res);
      if (!run) return undefined;
      const receipt = await runWorker.startRun({ run_id: run.id });
      if (receipt.replayed) {
        // Already claimed/terminal: persisted status/result without duplicate
        // model execution (CONTRACTS §9 execute row).
        return res.status(200).json({
          run_id: run.id,
          replayed: true,
          run: receipt.run,
        });
      }
      return res.status(202).json({
        run_id: run.id,
        status: 'accepted',
        lease_nonce: receipt.lease_nonce,
        run: receipt.run,
      });
    } catch (error) {
      const mapped = statusForError(error);
      if (mapped) return sendError(res, mapped, error.code);
      return next(error);
    }
  });

  // -- Poll: persisted status, honest ------------------------------------------
  router.get('/runs/:runId/status', automationMiddleware({ requiredScopes: ['research:status'], requireOwner: true }), async (req, res, next) => {
    try {
      const run = await loadOwnedRun(req, res);
      if (!run) return undefined;
      const view = toStatusView(run);
      const result = ['succeeded', 'limited'].includes(run.status)
        ? { assessment_id: run.assessment_id, evidence_snapshot_id: run.evidence_snapshot_id }
        : run.status === 'failed' || run.status === 'stalled'
          ? { error_code: run.error_code }
          : null;
      return res.status(200).json({ run: view, result });
    } catch (error) {
      return next(error);
    }
  });

  // -- Delivery: lease-bound validated result -----------------------------------
  router.post('/runs/:runId/result', automationMiddleware({ requiredScopes: ['research:callback'], requireOwner: true }), async (req, res, next) => {
    try {
      const run = await loadOwnedRun(req, res);
      if (!run) return undefined;
      const deliveryId = req.get('x-horizon-delivery-id');
      if (typeof deliveryId !== 'string' || deliveryId.length === 0 || deliveryId.length > 128) {
        return sendError(res, 400, 'INVALID_DELIVERY');
      }
      let authorized;
      try {
        authorized = callbackAuthorizer.authorize(req, run);
      } catch (error) {
        if (error instanceof Error === false || error.code === undefined) throw error;
        return sendError(res, statusForError(error) ?? 403, error.code);
      }
      try {
        const recorded = await researchService.recordRunResult({
          run_id: run.id,
          // Ownership is server-derived from the scoped automation identity
          // and the persisted run — any body-supplied userId is ignored.
          caller_owner_id: req.automation.ownerId,
          delivery_id: deliveryId,
          result: req.body,
        });
        const status = authorized.idempotent || recorded.idempotent ? 200 : 201;
        return res.status(status).json({
          run_id: run.id,
          assessment_id: recorded.assessment_id,
          idempotent: Boolean(authorized.idempotent || recorded.idempotent),
        });
      } catch (error) {
        if (error && error.code === 'INVALID_INPUT') {
          // Well-formed request, invalid researched result (CONTRACTS §9):
          // deterministic 422. The client owns retry policy; a bounded
          // client stops instead of looping.
          return sendError(res, 422, 'INVALID_RESULT');
        }
        const mapped = statusForError(error);
        if (mapped) return sendError(res, mapped, error.code);
        return next(error);
      }
    } catch (error) {
      return next(error);
    }
  });

  // -- Stage replay: record/replay a validated pipeline-stage artifact -------
  // (H09X held follow-up, now released). The stage is an enum, never arbitrary
  // code or a model name. Recording an already-recorded stage with an identical
  // artifact is idempotent — no re-execution, no model re-charge — and a
  // different artifact is a conflict. Immutable input references and deadlines
  // are preserved by the service, never rewritten here.
  router.post('/runs/:runId/stages/:stage', automationMiddleware({ requiredScopes: ['research:stages'], requireOwner: true }), async (req, res, next) => {
    try {
      const run = await loadOwnedRun(req, res);
      if (!run) return undefined;
      authorizeRunLease(req, run);
      const recorded = await researchService.advanceStage({
        run_id: run.id,
        stage: req.params.stage,
        artifact: req.body && req.body.artifact,
      });
      return res.status(200).json({
        run_id: run.id,
        replayed: recorded.replayed,
        stage: recorded.stage,
        artifact: recorded.artifact,
        recorded_at: recorded.recorded_at,
      });
    } catch (error) {
      const mapped = statusForError(error);
      if (mapped) return sendError(res, mapped, error.code);
      return next(error);
    }
  });

  // -- Tools: server-owned allowlisted tools bound to run/instrument/cutoff -----
  // (H09X). The request body may carry ONLY tool_name/arguments/stage/request_id
  // (CONTRACTS §9); it is validated against the server-owned typed registry, then
  // executed by an injected resolver that enforces the per-stage call budget, the
  // per-result response-size cap and idempotent retries. No arbitrary URL,
  // command, code, owner id or raw database query is ever accepted.
  router.post('/runs/:runId/tools', automationMiddleware({ requiredScopes: ['research:tools'], requireOwner: true }), async (req, res, next) => {
    try {
      const run = await loadOwnedRun(req, res);
      if (!run) return undefined;
      authorizeRunLease(req, run);
      if (!toolExecutor || typeof toolExecutor.execute !== 'function' || typeof resolveToolContext !== 'function') {
        return sendError(res, 503, 'RUNTIME_NOT_CONFIGURED');
      }
      const verdict = validateToolRequest(req.body);
      if (!verdict.ok) {
        return sendError(res, TOOL_ISSUE_STATUS[verdict.issue_code] ?? 400, verdict.issue_code);
      }
      const boundContext = await resolveToolContext(run);
      const outcome = await toolExecutor.execute({
        run_id: run.id,
        stage: verdict.stage,
        tool: verdict.tool,
        arguments: verdict.arguments,
        request_id: verdict.request_id,
        boundContext,
      });
      if (!outcome.ok) {
        return sendError(res, outcome.status ?? 500, outcome.code);
      }
      return res.status(200).json(outcome);
    } catch (error) {
      const mapped = statusForError(error);
      if (mapped) return sendError(res, mapped, error.code);
      return next(error);
    }
  });

  return router;
}

module.exports = {
  MAX_QUEUED_LIMIT,
  createAutomationRouter,
  createMongooseQueuedRunSource,
};
