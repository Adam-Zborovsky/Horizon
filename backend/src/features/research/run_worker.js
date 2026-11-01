'use strict';

// H10 — bounded run worker and daily run queueing.
//
// CONTRACTS §8/§9: Node owns the fixed bounded pipeline (H09 agent_runtime);
// n8n only triggers, polls persisted status and delivers validated bound
// results. This module owns the minimal run lifecycle glue: atomic persisted
// claims (research_service.claimRun), duplicate suppression (single in-flight
// execution per run), deadline enforcement with honest stalls, and bounded
// delivery of validated results. Advanced scheduling/leader redesign is H10X;
// generalized stage/tool/recovery runtime is H09X. Model clients, evidence
// inputs and repositories are injected; nothing here performs live calls,
// reads credentials or mutates shared state.

const crypto = require('node:crypto');

const validator = require('./result_validator');

const RUN_ID_MAX_LENGTH = 160;
const TERMINAL_STATUSES = Object.freeze(['succeeded', 'limited', 'failed', 'stalled', 'superseded']);

function workerError(code, message) {
  const error = new Error(message || code);
  error.code = code;
  return error;
}

function assertRunId(value) {
  if (typeof value !== 'string' || value.length === 0 || value.length > RUN_ID_MAX_LENGTH) {
    throw workerError('INVALID_INPUT', 'run_id must be a non-empty opaque string');
  }
  return value;
}

// Owner/automation-facing status view: never carries the lease nonce, owner
// internals or run input payloads. Failures, stalls and terminal result
// references are exposed exactly as persisted — success is never rewritten.
function toStatusView(run) {
  if (!run) return null;
  return {
    run_id: run.id,
    position_id: run.position_id,
    position_revision: run.position_revision,
    run_kind: run.run_kind,
    status: run.status,
    stage: run.stage,
    error_code: run.error_code ?? null,
    created_at: run.created_at,
    started_at: run.started_at ?? null,
    heartbeat_at: run.heartbeat_at ?? null,
    deadline_at: run.deadline_at,
    finished_at: run.finished_at ?? null,
    assessment_id: run.assessment_id ?? null,
    evidence_snapshot_id: run.evidence_snapshot_id ?? null,
  };
}

function safeErrorCode(error, fallback) {
  if (error && typeof error.code === 'string' && error.code.length > 0 && error.code.length <= 120
    && /^[A-Z0-9_]+$/.test(error.code)) {
    return error.code;
  }
  return fallback;
}

function createRunWorker({
  researchService,
  agentRuntime,
  inputProvider,
  runLookup,
  now = () => new Date(),
  deliveryIdFactory = () => `delivery-${crypto.randomUUID()}`,
  logger = null,
} = {}) {
  if (!researchService || typeof researchService.claimRun !== 'function'
    || typeof researchService.recordRunResult !== 'function'
    || typeof researchService.completeRun !== 'function'
    || typeof researchService.recoverAbandonedRuns !== 'function') {
    throw new TypeError('createRunWorker requires a research service with claim/record/complete/recovery support');
  }
  if (!agentRuntime || typeof agentRuntime.runMarketSynthesis !== 'function') {
    throw new TypeError('createRunWorker requires the H09 agent runtime');
  }
  if (typeof inputProvider !== 'function') {
    throw new TypeError('createRunWorker requires an injected input provider');
  }
  if (typeof runLookup !== 'function') {
    throw new TypeError('createRunWorker requires an injected run lookup');
  }

  // Duplicate suppression: one in-flight execution per run id. The entry is
  // registered synchronously before the first await, so concurrent triggers
  // share the same claim + pipeline instead of racing the persisted claim.
  const inflight = new Map();

  function logWarning(code, runId) {
    if (logger && typeof logger.warn === 'function') {
      // Codes only — never upstream payloads, prompts or credentials.
      logger.warn(`run_worker: run ${runId} failed with ${code}`);
    }
  }

  function beginRun(runId) {
    const entry = {};
    entry.claim = (async () => {
      const existing = await runLookup(runId);
      if (!existing) throw workerError('RUN_NOT_FOUND', `Run not found: ${runId}`);
      if (existing.status !== 'queued') {
        // Terminal or already-running (e.g. claimed by a previous process
        // whose lease is still valid): replay persisted status, never a
        // second claim. Lease renewal is H10X; expiry resolves at the
        // deadline through recovery.
        return { replayed: true, run: toStatusView(existing) };
      }
      if (existing.deadline_at <= now().toISOString()) {
        // An expired queue entry is superseded by recovery, never claimed:
        // claiming it would start work the deadline already forbids.
        await researchService.recoverAbandonedRuns();
        const refreshed = await runLookup(runId);
        return { replayed: true, run: toStatusView(refreshed ?? existing) };
      }
      try {
        const claimed = await researchService.claimRun({ run_id: runId });
        return {
          replayed: false,
          run: toStatusView(claimed),
          lease_nonce: claimed.lease_nonce,
          claimedRun: claimed,
        };
      } catch (error) {
        if (error && error.code === 'RUN_ALREADY_CLAIMED') {
          const current = await runLookup(runId);
          return { replayed: true, run: toStatusView(current) };
        }
        throw error;
      }
    })();
    entry.promise = entry.claim.then(async (receipt) => {
      if (receipt.replayed || !receipt.claimedRun) {
        return { replayed: true, run: receipt.run };
      }
      return runPipeline(runId, receipt.claimedRun);
    }).finally(() => {
      // Settlement frees the suppression slot: later triggers re-read the
      // persisted status instead of replaying a stale claim receipt.
      if (inflight.get(runId) === entry) inflight.delete(runId);
    });
    // Background continuations (the 202 path) must never surface as unhandled
    // rejections; callers observe settlement through whenSettled/executeRun.
    entry.promise.catch(() => {});
    return entry;
  }

  async function completeFailure(runId, errorCode) {
    try {
      await researchService.completeRun({
        run_id: runId,
        outcome: { status: 'failed', error_code: errorCode },
      });
    } catch (error) {
      // Deadline expiry cannot fake a completion: the recovery sweep stalls
      // the run (or supersedes the stale queue entry) instead.
      if (error && ['RUN_DEADLINE_EXCEEDED', 'REVISION_CONFLICT', 'INVALID_RUN_TRANSITION'].includes(error.code)) {
        await researchService.recoverAbandonedRuns();
      } else {
        throw error;
      }
    }
    const final = await runLookup(runId);
    return { replayed: false, run: toStatusView(final) };
  }

  async function runPipeline(runId, claimedRun) {
    let inputs;
    try {
      inputs = await inputProvider(claimedRun);
    } catch (error) {
      logWarning('INPUT_UNAVAILABLE', runId);
      return completeFailure(runId, 'INPUT_UNAVAILABLE');
    }

    // The persisted run carries its instrument inside run_input_ref (H08
    // schema); the H09 runtime binds the assessment on run.instrument_id, so
    // the worker composes the exact bound view before invoking the pipeline.
    const runtimeRun = {
      ...claimedRun,
      instrument_id: claimedRun.instrument_id
        ?? (claimedRun.run_input_ref && claimedRun.run_input_ref.instrument_id)
        ?? null,
    };

    const envelope = await agentRuntime.runMarketSynthesis({
      run: runtimeRun,
      snapshot: inputs.snapshot,
      metrics: inputs.metrics,
      instrument: inputs.instrument,
      position: inputs.position,
      prior: inputs.prior ?? null,
      currentPrice: inputs.currentPrice ?? null,
      deadlineAt: claimedRun.deadline_at,
    });

    if (envelope.status === 'failed') {
      logWarning(envelope.error_code || 'PIPELINE_FAILED', runId);
      return completeFailure(runId, envelope.error_code || 'PIPELINE_FAILED');
    }

    // The bounded pipeline finished, but the wall clock may not have: a
    // successful synthesis after deadline expiry is a stall, never a
    // recorded success (CONTRACTS §8).
    if (now().toISOString() > claimedRun.deadline_at) {
      logWarning('DEADLINE_EXCEEDED', runId);
      return completeFailure(runId, 'DEADLINE_EXCEEDED');
    }

    // Fail-closed delivery binding before persistence (CONTRACTS §8/§9).
    const delivery = validator.validateAssessmentDelivery(envelope.result.assessment, {
      run: runtimeRun,
      snapshot: {
        snapshot_id: inputs.snapshot.snapshot_id,
        instrument_id: inputs.snapshot.instrument_id,
        session_as_of: inputs.snapshot.session_as_of,
      },
    });
    if (!delivery.ok) {
      logWarning('DELIVERY_VALIDATION_FAILED', runId);
      return completeFailure(runId, 'DELIVERY_VALIDATION_FAILED');
    }

    try {
      const recorded = await researchService.recordRunResult({
        run_id: runId,
        // Server-derived binding: the worker records under the run owner
        // loaded from the claimed run, never from any client payload.
        caller_owner_id: claimedRun.owner_id_internal,
        delivery_id: deliveryIdFactory(),
        result: envelope.result,
      });
      const final = await runLookup(runId);
      return {
        replayed: false,
        run: toStatusView(final),
        assessment_id: recorded.assessment_id,
      };
    } catch (error) {
      logWarning(safeErrorCode(error, 'RESULT_RECORD_FAILED'), runId);
      return completeFailure(runId, safeErrorCode(error, 'RESULT_RECORD_FAILED'));
    }
  }

  // Non-blocking trigger receipt (the n8n execute path): claims once and
  // starts the bounded pipeline; returns the persisted/replayed status view
  // immediately. The lease nonce is returned only on a fresh claim.
  async function startRun({ run_id } = {}) {
    const runId = assertRunId(run_id);
    let entry = inflight.get(runId);
    if (!entry) {
      entry = beginRun(runId);
      inflight.set(runId, entry);
    }
    const receipt = await entry.claim;
    const { claimedRun, ...publicReceipt } = receipt;
    void claimedRun;
    return publicReceipt;
  }

  // Blocking execution: resolves with the terminal view of the run.
  async function executeRun({ run_id } = {}) {
    const runId = assertRunId(run_id);
    let entry = inflight.get(runId);
    if (!entry) {
      entry = beginRun(runId);
      inflight.set(runId, entry);
    }
    const receipt = await entry.claim;
    if (receipt.replayed) {
      // Either a concurrent trigger owns the pipeline (await its settlement)
      // or the run was already claimed/terminal (the promise resolves
      // immediately with the replay view).
      const final = await entry.promise;
      return { replayed: true, run: final.run };
    }
    const final = await entry.promise;
    return { replayed: false, run: final.run, assessment_id: final.assessment_id };
  }

  async function whenSettled(runId) {
    assertRunId(runId);
    const entry = inflight.get(runId);
    if (entry) {
      await entry.claim.catch(() => {});
      return entry.promise;
    }
    const run = await runLookup(runId);
    if (!run) throw workerError('RUN_NOT_FOUND', `Run not found: ${runId}`);
    return { replayed: true, run: toStatusView(run) };
  }

  async function replayRun({ run_id } = {}) {
    const runId = assertRunId(run_id);
    const run = await runLookup(runId);
    if (!run) throw workerError('RUN_NOT_FOUND', `Run not found: ${runId}`);
    return { replayed: true, run: toStatusView(run) };
  }

  async function recoverExpiredRuns() {
    return researchService.recoverAbandonedRuns();
  }

  return Object.freeze({
    startRun,
    executeRun,
    whenSettled,
    replayRun,
    recoverExpiredRuns,
  });
}

// Daily run queueing: one daily_update run per non-archived position per UTC
// day. Persisted idempotency (owner + position + key) makes duplicate
// schedules, restarts and double-fired crons safe: same key replays, never
// duplicates. One invalid position is reported and skipped, never fatal to
// the batch.
async function queueDailyUpdateRuns({
  researchService,
  positions,
  now = () => new Date(),
} = {}) {
  if (!researchService || typeof researchService.queueRun !== 'function') {
    throw new TypeError('queueDailyUpdateRuns requires a research service');
  }
  if (!Array.isArray(positions)) {
    throw new TypeError('queueDailyUpdateRuns requires a positions array');
  }
  const sessionDate = now().toISOString().slice(0, 10);
  const queued = [];
  const errors = [];
  for (const position of positions) {
    if (!position || typeof position.position_id !== 'string' || typeof position.owner_id !== 'string') {
      errors.push({ position_id: position ? String(position.position_id ?? 'unknown') : 'unknown', error_code: 'INVALID_INPUT' });
      continue;
    }
    const idempotencyKey = `daily_update:${sessionDate}:${position.position_id}`;
    try {
      const { run, idempotent_replay } = await researchService.queueRun({
        owner_id: position.owner_id,
        position_id: position.position_id,
        position_revision: position.revision,
        run_kind: 'daily_update',
        request_class: 'daily_update',
        idempotency_key: idempotencyKey,
        instrument_id: position.instrument_id,
        request_payload: { trigger: 'scheduled_daily', session_date: sessionDate },
      });
      queued.push({ run_id: run.id, position_id: position.position_id, idempotent_replay });
    } catch (error) {
      errors.push({
        position_id: position.position_id,
        error_code: safeErrorCode(error, 'QUEUE_FAILED'),
      });
    }
  }
  return { queued, errors };
}

module.exports = {
  TERMINAL_STATUSES,
  createRunWorker,
  queueDailyUpdateRuns,
  toStatusView,
};
