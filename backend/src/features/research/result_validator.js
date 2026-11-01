'use strict';

// H09 — fail-closed validation of model synthesis output and delivered
// assessments. This module is the "deep 422 validation" boundary scoped to H09
// by the H08 review (O2): H08's recordRunResult checks transport-level binding;
// THIS module rejects fabricated metrics/sources, post-cutoff facts,
// state-incompatible actions, unregistered numerals, invented horizon dates,
// broken continuity and held numeric projections BEFORE anything is persisted.
//
// Deterministic only: no model calls, no network, no randomness. Fail closed
// means: any doubt produces an issue and ok=false; the pipeline converts that
// into a bounded repair attempt or a real failed status.

const { researchAssessmentSchema } = require('./contracts');
const { containsUnregisteredNumericClaim } = require('./prompts');

// The frozen evaluation protocol: this exact defect set is planted in fixtures
// and must fail closed. Order is part of the frozen protocol.
const PLANTED_DEFECT_CODES = Object.freeze([
  'FABRICATED_SOURCE',
  'FABRICATED_METRIC',
  'UNSUPPORTED_CLAIM',
  'UNREGISTERED_NUMBER',
  'POST_CUTOFF_REFERENCE',
  'STATE_INCOMPATIBLE_ACTION',
  'INVENTED_HORIZON_DATE',
  'IDENTICAL_HORIZON_COPY',
  'CONTINUITY_MISMATCH',
  'FABRICATED_CHECKPOINT_REFERENCE',
  'MISSING_COUNTERCASE',
  'LIMITED_WITHOUT_MISSING_DATA',
  'NUMERIC_PROJECTION_HELD',
]);

// CONTRACTS §5 candidate/owned/legacy action sets. Mirrored locally because
// contracts.js does not export the table and H09 must not modify existing files.
const STATE_ACTIONS = Object.freeze({
  candidate: Object.freeze(new Set(['buy', 'wait', 'avoid', 'insufficient_evidence'])),
  owned: Object.freeze(new Set(['hold', 'hold_no_add', 'add', 'reduce', 'exit', 'insufficient_evidence'])),
  legacy_unclassified: Object.freeze(new Set(['insufficient_evidence'])),
});

const DIRECTIONS = Object.freeze(['positive', 'negative', 'mixed', 'insufficient_evidence']);
const CHECKPOINT_KINDS = Object.freeze(['rolling_indicator', 'fixed_observed_level', 'business_condition']);
const CHECKPOINT_STATUSES = Object.freeze(['active', 'triggered', 'retired']);
const CLAIM_TYPES = Object.freeze(['observed', 'interpretation', 'assumption']);

function issue(code, path, message) {
  return { code, path: path || '', message };
}

function isPlainObject(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

function isNonEmptyString(value) {
  return typeof value === 'string' && value.length > 0;
}

/**
 * Evidence index: id -> availability. Accepts the builder's array form or a
 * plain id-keyed object (used by tests to inject defense-in-depth fixtures).
 */
function buildEvidenceIndex(ctx) {
  const index = new Map();
  const source = Array.isArray(ctx.evidence)
    ? ctx.evidence
    : (isPlainObject(ctx.evidence) ? Object.values(ctx.evidence) : []);
  for (const item of source) {
    if (item && isNonEmptyString(item.id)) index.set(item.id, item);
  }
  return index;
}

function availabilityOf(item) {
  return item.available_at || item.published_at || null;
}

function claimPaths(output) {
  const paths = [];
  const thesis = output.market_thesis;
  if (isPlainObject(thesis)) {
    for (const section of ['business_assessment', 'price_technical_assessment', 'valuation_assessment']) {
      if (isPlainObject(thesis[section])) paths.push([`market_thesis.${section}.claims`, thesis[section].claims]);
    }
    paths.push(['market_thesis.rationale', thesis.rationale]);
    paths.push(['market_thesis.counterevidence', thesis.counterevidence]);
  }
  const recommendation = output.recommendation;
  if (isPlainObject(recommendation)) {
    paths.push(['recommendation.rationale', recommendation.rationale]);
    paths.push(['recommendation.countercase', recommendation.countercase]);
    paths.push(['recommendation.invalidation_conditions', recommendation.invalidation_conditions]);
  }
  for (const [index, outlook] of (Array.isArray(output.outlooks) ? output.outlooks : []).entries()) {
    if (!isPlainObject(outlook)) continue;
    for (const field of ['base_case', 'upside_case', 'downside_case', 'catalysts', 'invalidators']) {
      paths.push([`outlooks[${index}].${field}`, outlook[field]]);
    }
  }
  return paths.filter(([, value]) => value !== undefined);
}

/**
 * Validate every claim reference and grounding rule. Returns an issues array.
 */
function checkClaims(output, ctx, evidenceIndex, metricIds) {
  const issues = [];
  for (const [path, claims] of claimPaths(output)) {
    if (!Array.isArray(claims)) {
      issues.push(issue('MISSING_FIELD', path, 'Expected an array of claims'));
      continue;
    }
    for (const [index, entry] of claims.entries()) {
      const claimPath = `${path}[${index}]`;
      if (!isPlainObject(entry) || !isNonEmptyString(entry.text)) {
        issues.push(issue('MISSING_FIELD', claimPath, 'Expected a claim object with non-empty text'));
        continue;
      }
      const evidenceIds = Array.isArray(entry.evidence_ids) ? entry.evidence_ids : [];
      const metricRefs = Array.isArray(entry.metric_ids) ? entry.metric_ids : [];
      for (const id of evidenceIds) {
        const item = evidenceIndex.get(id);
        if (!item) {
          issues.push(issue('FABRICATED_SOURCE', `${claimPath}.evidence_ids`, `Unknown evidence id: ${id}`));
          continue;
        }
        const availability = availabilityOf(item);
        if (availability && ctx.cutoff_at && availability > ctx.cutoff_at) {
          issues.push(issue('POST_CUTOFF_REFERENCE', `${claimPath}.evidence_ids`, `Evidence ${id} became available after the cutoff`));
        }
      }
      for (const id of metricRefs) {
        if (!metricIds.has(id)) {
          issues.push(issue('FABRICATED_METRIC', `${claimPath}.metric_ids`, `Unknown metric id: ${id}`));
        }
      }
      if (entry.claim_type === 'observed') {
        if (evidenceIds.length === 0 && metricRefs.length === 0) {
          issues.push(issue('UNSUPPORTED_CLAIM', claimPath, 'Observed claims require at least one evidence or metric reference'));
        }
        if (metricRefs.length === 0 && containsUnregisteredNumericClaim(entry.text)) {
          issues.push(issue('UNREGISTERED_NUMBER', claimPath, 'Observed claim states a numeral without a metric reference'));
        }
      } else if (!CLAIM_TYPES.includes(entry.claim_type)) {
        issues.push(issue('MISSING_FIELD', `${claimPath}.claim_type`, 'Expected observed, interpretation or assumption'));
      }
    }
  }
  return issues;
}

function checkCheckpoints(proposed, ctx, metricIds) {
  const issues = [];
  if (proposed === undefined || proposed === null) return issues;
  if (!Array.isArray(proposed)) {
    return [issue('MISSING_FIELD', 'checkpoints', 'Expected an array of proposed checkpoints')];
  }
  for (const [index, cp] of proposed.entries()) {
    const path = `checkpoints[${index}]`;
    if (!isPlainObject(cp)) {
      issues.push(issue('MISSING_FIELD', path, 'Expected a checkpoint object'));
      continue;
    }
    if (!CHECKPOINT_KINDS.includes(cp.kind)) {
      issues.push(issue('MISSING_FIELD', `${path}.kind`, 'Expected a contract checkpoint kind'));
    }
    if (!CHECKPOINT_STATUSES.includes(cp.status)) {
      issues.push(issue('MISSING_FIELD', `${path}.status`, 'Expected active, triggered or retired'));
    }
    if (!isNonEmptyString(cp.condition) || !isNonEmptyString(cp.reason)) {
      issues.push(issue('MISSING_FIELD', path, 'Checkpoints require condition and reason'));
    }
    if (cp.kind === 'rolling_indicator') {
      if (!isNonEmptyString(cp.metric_id) || !metricIds.has(cp.metric_id)) {
        issues.push(issue('FABRICATED_METRIC', `${path}.metric_id`, 'Rolling checkpoints require a known metric reference'));
      }
      if (cp.fixed_level != null) {
        issues.push(issue('MISSING_FIELD', `${path}.fixed_level`, 'Rolling checkpoints cannot carry a fixed level'));
      }
    }
    if (cp.kind === 'fixed_observed_level') {
      if (typeof cp.fixed_level !== 'number' || !Number.isFinite(cp.fixed_level) || cp.fixed_level <= 0) {
        issues.push(issue('MISSING_FIELD', `${path}.fixed_level`, 'Fixed-level checkpoints require a positive observed level'));
      }
      if (cp.metric_id != null) {
        issues.push(issue('MISSING_FIELD', `${path}.metric_id`, 'Fixed-level checkpoints cannot carry a metric reference'));
      }
    }
    if (cp.kind === 'business_condition' && (cp.metric_id != null || cp.fixed_level != null)) {
      issues.push(issue('MISSING_FIELD', path, 'Business-condition checkpoints cannot carry metric or level representations'));
    }
  }
  return issues;
}

function horizonKey(outlook) {
  return JSON.stringify({
    direction: outlook.direction,
    base_case: outlook.base_case,
    upside_case: outlook.upside_case,
    downside_case: outlook.downside_case,
  });
}

/**
 * Validate a raw model synthesis output against the frozen bounded context.
 * Returns {ok, issues} — never throws for model output problems.
 */
function validateSynthesisOutput(output, ctx) {
  if (!isPlainObject(output)) {
    return { ok: false, issues: [issue('MISSING_FIELD', '', 'Expected a JSON object synthesis')] };
  }
  const issues = [];
  const evidenceIndex = buildEvidenceIndex(ctx);
  const metricIds = new Set(Array.isArray(ctx.metric_ids) ? ctx.metric_ids : []);

  // 1. Shape: market thesis sections, rationale, counterevidence.
  if (!isPlainObject(output.market_thesis)) {
    issues.push(issue('MISSING_FIELD', 'market_thesis', 'Market thesis is required'));
  } else {
    for (const section of ['business_assessment', 'price_technical_assessment', 'valuation_assessment']) {
      const entry = output.market_thesis[section];
      if (!isPlainObject(entry) || !isNonEmptyString(entry.summary) || !Array.isArray(entry.claims)) {
        issues.push(issue('MISSING_FIELD', `market_thesis.${section}`, 'Thesis sections require summary and claims'));
      }
    }
    if (!Array.isArray(output.market_thesis.rationale) || output.market_thesis.rationale.length === 0) {
      issues.push(issue('MISSING_FIELD', 'market_thesis.rationale', 'A direct source-backed rationale is required'));
    }
    if (!Array.isArray(output.market_thesis.counterevidence) || output.market_thesis.counterevidence.length === 0) {
      issues.push(issue('MISSING_COUNTERCASE', 'market_thesis.counterevidence', 'The strongest counterevidence is required'));
    }
  }
  if (!isPlainObject(output.recommendation)) {
    issues.push(issue('MISSING_FIELD', 'recommendation', 'A direct recommendation is required'));
  } else {
    if (!Array.isArray(output.recommendation.countercase) || output.recommendation.countercase.length === 0) {
      issues.push(issue('MISSING_COUNTERCASE', 'recommendation.countercase', 'The recommendation countercase is required'));
    }
    for (const field of ['headline', 'evidence_quality', 'predictive_uncertainty']) {
      if (!isNonEmptyString(output.recommendation[field])) {
        issues.push(issue('MISSING_FIELD', `recommendation.${field}`, `${field} is required`));
      }
    }
    if (![1, 2, 3].includes(output.recommendation.horizon_months)) {
      issues.push(issue('MISSING_FIELD', 'recommendation.horizon_months', 'horizon_months must be 1, 2 or 3'));
    }
  }

  // 2. State-compatible direct action.
  const state = ctx.position?.state;
  const action = output.recommendation?.action;
  if (typeof state === 'string' && STATE_ACTIONS[state]) {
    if (!STATE_ACTIONS[state].has(action)) {
      issues.push(issue('STATE_INCOMPATIBLE_ACTION', 'recommendation.action', `Action ${JSON.stringify(action)} is not allowed for state ${state}`));
    }
  } else {
    issues.push(issue('MISSING_FIELD', 'position.state', 'Context lacks a known position state'));
  }

  // 3. Outlooks: exactly 1/2/3, server dates, distinct content, no projections.
  const outlooks = Array.isArray(output.outlooks) ? output.outlooks : [];
  const horizonSet = outlooks.map((o) => (isPlainObject(o) ? o.horizon_months : null)).sort();
  if (horizonSet.join(',') !== '1,2,3') {
    issues.push(issue('INCOMPLETE_HORIZONS', 'outlooks', 'Exactly one 1, 2 and 3 month outlook is required'));
  }
  const serverDates = new Map(
    (Array.isArray(ctx.horizons) ? ctx.horizons : []).map((h) => [h.horizon_months, h]),
  );
  const seenKeys = new Map();
  for (const [index, outlook] of outlooks.entries()) {
    const path = `outlooks[${index}]`;
    if (!isPlainObject(outlook)) {
      issues.push(issue('MISSING_FIELD', path, 'Expected an outlook object'));
      continue;
    }
    const server = serverDates.get(outlook.horizon_months);
    if (server) {
      if (outlook.calendar_target_date !== undefined && outlook.calendar_target_date !== server.calendar_target_date) {
        issues.push(issue('INVENTED_HORIZON_DATE', `${path}.calendar_target_date`, 'Outlook dates are computed by the server; supplied dates must match the contract derivation'));
      }
      if (outlook.evaluation_session_date !== undefined && outlook.evaluation_session_date !== server.evaluation_session_date) {
        issues.push(issue('INVENTED_HORIZON_DATE', `${path}.evaluation_session_date`, 'Outlook dates are computed by the server; supplied dates must match the contract derivation'));
      }
    }
    if (!DIRECTIONS.includes(outlook.direction)) {
      issues.push(issue('MISSING_FIELD', `${path}.direction`, 'Expected a contract direction'));
    }
    for (const field of ['base_case', 'upside_case', 'downside_case']) {
      if (!Array.isArray(outlook[field]) || outlook[field].length === 0) {
        issues.push(issue('MISSING_FIELD', `${path}.${field}`, 'Outlook cases are required'));
      }
    }
    if (outlook.numeric_projection != null) {
      issues.push(issue('NUMERIC_PROJECTION_HELD', `${path}.numeric_projection`, 'Numeric projections are a held follow-up; the server composes null'));
    }
    const key = horizonKey(outlook);
    if (seenKeys.has(key)) {
      issues.push(issue('IDENTICAL_HORIZON_COPY', path, `Outlook ${index} is an identical copy of outlook ${seenKeys.get(key)}`));
    } else {
      seenKeys.set(key, index);
    }
  }

  // 4. Claims, checkpoints.
  issues.push(...checkClaims(output, ctx, evidenceIndex, metricIds));
  issues.push(...checkCheckpoints(output.checkpoints, ctx, metricIds));

  // 5. Prior-report/checkpoint continuity.
  if (ctx.prior) {
    const changes = output.changes_since_previous;
    if (!isPlainObject(changes) || changes.previous_assessment_id !== ctx.prior.assessment_id) {
      issues.push(issue('CONTINUITY_MISMATCH', 'changes_since_previous', `A prior report exists (${ctx.prior.assessment_id}); changes must reference it`));
    } else if (ctx.prior.session_as_of && changes.previous_session_as_of !== ctx.prior.session_as_of) {
      issues.push(issue('CONTINUITY_MISMATCH', 'changes_since_previous.previous_session_as_of', 'Previous session must match the prior report'));
    } else {
      const priorCheckpointIds = new Set((ctx.prior.checkpoints ?? []).map((cp) => cp.id));
      for (const id of Array.isArray(changes.checkpoint_change_ids) ? changes.checkpoint_change_ids : []) {
        if (!priorCheckpointIds.has(id)) {
          issues.push(issue('FABRICATED_CHECKPOINT_REFERENCE', 'changes_since_previous.checkpoint_change_ids', `Unknown prior checkpoint id: ${id}`));
        }
      }
    }
  } else if (output.changes_since_previous !== null) {
    issues.push(issue('CONTINUITY_MISMATCH', 'changes_since_previous', 'No prior report exists; changes_since_previous must be null'));
  }

  // 6. Limited honesty: partial/unavailable coverage requires explicit gaps.
  if (ctx.coverage && ctx.coverage.status !== 'available') {
    const missing = Array.isArray(output.missing_data) ? output.missing_data : [];
    if (missing.length === 0) {
      issues.push(issue('LIMITED_WITHOUT_MISSING_DATA', 'missing_data', 'Partial coverage requires explicit missing data'));
    }
  }

  return { ok: issues.length === 0, issues };
}

/**
 * Delivery-boundary validation: canonical schema plus exact binding to the
 * run and evidence snapshot. Used before recordRunResult-style persistence.
 */
function validateAssessmentDelivery(assessment, { run, snapshot } = {}) {
  const issues = [];
  const parsed = researchAssessmentSchema.safeParse(assessment);
  if (!parsed.success) {
    for (const problem of parsed.error.issues) {
      issues.push(issue('SCHEMA_INVALID', problem.path.join('.'), problem.message));
    }
  }
  if (!isPlainObject(run) || !isPlainObject(snapshot)) {
    issues.push(issue('BINDING_MISMATCH', '', 'Run and snapshot references are required'));
    return { ok: false, issues };
  }
  if (!isPlainObject(assessment)) {
    return { ok: false, issues };
  }
  const bindings = [
    ['run_id', assessment.run_id, run.id],
    ['position_revision', assessment.position_revision, run.position_revision],
    ['instrument_id', assessment.instrument_id, run.instrument_id],
    ['instrument_id(snapshot)', snapshot.instrument_id, run.instrument_id],
    ['evidence_snapshot_id', assessment.evidence_snapshot_id, snapshot.snapshot_id],
    ['session_as_of', assessment.session_as_of, snapshot.session_as_of],
  ];
  for (const [field, actual, expected] of bindings) {
    if (actual !== expected) {
      issues.push(issue('BINDING_MISMATCH', field, `Assessment ${field} ${JSON.stringify(actual)} does not bind the exact reference ${JSON.stringify(expected)}`));
    }
  }
  return { ok: issues.length === 0, issues };
}

function parseAssessment(assessment) {
  return researchAssessmentSchema.parse(assessment);
}

module.exports = {
  PLANTED_DEFECT_CODES,
  STATE_ACTIONS,
  containsUnregisteredNumericClaim,
  parseAssessment,
  validateAssessmentDelivery,
  validateSynthesisOutput,
};
