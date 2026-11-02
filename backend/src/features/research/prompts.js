'use strict';

// H09 — bounded prompt/context construction for the grounded market synthesis.
//
// Responsibilities (SPEC §4 steps 5–6, CONTRACTS §9 "fixed bounded Node
// pipeline"):
//  - Build ONE frozen, digest-stamped market-synthesis context from existing
//    H06/H07/H08 artifacts. The context deliberately carries position state
//    and preferred horizon but NEVER purchase cost, quantity or opening date:
//    personal economics stay out of the market synthesis and shared caches.
//  - Render deterministic system/user/repair prompts with an explicit output
//    contract. No "comprehensive report" instructions; borrowed structure
//    from the primary research shape only.
//  - No tool dispatch, no model calls, no generalized runtime: this module is
//    pure text/data shaping with named budget constants enforced by code.

const crypto = require('node:crypto');

const { outlookHorizons } = require('./metrics');

const CONTEXT_BUDGETS = Object.freeze({
  MAX_CONTEXT_EVIDENCE_ITEMS: 20,
  MAX_EXCERPT_CHARS: 600,
  MAX_THESIS_SUMMARY_CHARS: 1200,
  MAX_CLAIMS_PER_SECTION_RENDER: 10,
  MAX_PRIOR_CHECKPOINTS: 20,
});

const ISO_DATE_AT_RE = /\d{4}-\d{2}-\d{2}(T[\d:.]+Z)?/g;
const HORIZON_TOKEN_RE = /\b(?:[1-3]|one|two|three)[\s-]*month(?:s)?\b/gi;
const QUARTER_TOKEN_RE = /\bQ[1-4]\b/gi;
// A numeric claim token: a decimal number (optionally percent/thousand-grouped)
// appearing outside date/horizon/quarter tokens. Deliberately conservative —
// unregistered numerals are sent to bounded repair, not silently accepted.
const NUMERIC_TOKEN_RE = /(?:^|[^\w.$])\d{1,3}(?:,\d{3})+(?:\.\d+)?|(?:^|[^\w.$])\d+(?:\.\d+)?/;

function boundedText(value, maxLength) {
  if (typeof value !== 'string') return '';
  return value.length <= maxLength ? value : `${value.slice(0, maxLength - 1)}…`;
}

function canonicalJson(value) {
  if (Array.isArray(value)) return value.map(canonicalJson);
  if (value && typeof value === 'object') {
    return Object.keys(value).sort().map((key) => [key, canonicalJson(value[key])]);
  }
  return value;
}

function contextDigest(frozenContext) {
  return crypto
    .createHash('sha256')
    .update(JSON.stringify(canonicalJson(frozenContext)))
    .digest('hex');
}

/**
 * Strip date/horizon/quarter tokens, then report whether a numeric claim
 * token remains. Dates and horizon labels are not prices (CONTRACTS §4).
 */
function containsUnregisteredNumericClaim(text) {
  if (typeof text !== 'string') return false;
  const stripped = text
    .replace(ISO_DATE_AT_RE, ' ')
    .replace(HORIZON_TOKEN_RE, ' ')
    .replace(QUARTER_TOKEN_RE, ' ');
  return NUMERIC_TOKEN_RE.test(stripped);
}

/**
 * Position slice allowed into the market synthesis: identity, state, horizon
 * preference. Everything else (cost, quantity, opened_on, revision-specific
 * economics) is dropped before it can reach the model or a shared cache.
 */
function positionSlice(position) {
  if (!position || typeof position !== 'object') {
    throw new TypeError('Expected a position object');
  }
  if (typeof position.state !== 'string') {
    throw new TypeError('Expected position.state');
  }
  return Object.freeze({
    position_id: typeof position.position_id === 'string' ? position.position_id : null,
    state: position.state,
    preferred_horizon_months: [1, 2, 3].includes(position.preferred_horizon_months)
      ? position.preferred_horizon_months
      : 3,
  });
}

function priorSlice(prior) {
  if (prior == null) return null;
  if (typeof prior !== 'object' || typeof prior.assessment_id !== 'string') {
    throw new TypeError('Expected a prior assessment slice or null');
  }
  return Object.freeze({
    assessment_id: prior.assessment_id,
    session_as_of: typeof prior.session_as_of === 'string' ? prior.session_as_of : null,
    market_thesis_summary: boundedText(prior.market_thesis_summary ?? '', CONTEXT_BUDGETS.MAX_THESIS_SUMMARY_CHARS),
    checkpoints: Object.freeze(
      (Array.isArray(prior.checkpoints) ? prior.checkpoints : [])
        .slice(0, CONTEXT_BUDGETS.MAX_PRIOR_CHECKPOINTS)
        .map((cp) => Object.freeze({
          id: cp.id,
          kind: cp.kind,
          condition: boundedText(cp.condition ?? '', 200),
          status: cp.status,
          // Prior judgments are prior decisions, not source facts.
          is_prior_decision: true,
        })),
    ),
  });
}

/**
 * Freeze the bounded market-synthesis context. The caller supplies already
 * gathered/cutoff-filtered artifacts (H06 snapshot, H07 metric records, H08
 * run/prior). Items after the cutoff are dropped here and recorded as a gap;
 * the validator re-checks referenced items independently (defense in depth).
 */
function buildMarketSynthesisContext({
  instrument,
  sessionAsOf,
  cutoffAt,
  snapshot,
  metrics,
  position,
  prior,
  isExchangeSession,
} = {}) {
  if (!instrument || typeof instrument.instrument_id !== 'string') {
    throw new TypeError('Expected a resolved instrument identity');
  }
  if (!snapshot || snapshot.instrument_id !== instrument.instrument_id) {
    throw new TypeError('Snapshot must match the instrument identity');
  }
  if (typeof sessionAsOf !== 'string' || typeof cutoffAt !== 'string') {
    throw new TypeError('Expected session and cutoff strings');
  }
  if (snapshot.session_as_of !== sessionAsOf) {
    throw new TypeError('Snapshot session must match the assessment session');
  }
  if (typeof isExchangeSession !== 'function') {
    throw new TypeError('Expected isExchangeSession predicate');
  }

  const items = Array.isArray(snapshot.items) ? snapshot.items : [];
  const gaps = Array.isArray(snapshot.coverage?.gaps) ? [...snapshot.coverage.gaps] : [];

  const inCutoff = [];
  for (const item of items) {
    const availability = item.available_at || item.published_at;
    if (availability && availability > cutoffAt) {
      if (!gaps.includes('post_cutoff_evidence_excluded')) gaps.push('post_cutoff_evidence_excluded');
      continue;
    }
    inCutoff.push(item);
  }
  const truncated = inCutoff.length > CONTEXT_BUDGETS.MAX_CONTEXT_EVIDENCE_ITEMS;
  if (truncated && !gaps.includes('evidence_context_truncated')) {
    gaps.push('evidence_context_truncated');
  }
  const boundedItems = inCutoff
    .slice(0, CONTEXT_BUDGETS.MAX_CONTEXT_EVIDENCE_ITEMS)
    .map((item) => Object.freeze({
      id: item.id,
      kind: item.kind,
      title: boundedText(item.title ?? '', 200),
      source_name: boundedText(item.source_name ?? '', 200),
      published_at: item.published_at ?? null,
      available_at: item.available_at ?? null,
      coverage_status: item.coverage_status,
      excerpt: boundedText(item.excerpt ?? '', CONTEXT_BUDGETS.MAX_EXCERPT_CHARS),
      source_locator: item.source_locator ?? null,
    }));

  const metricRecords = (Array.isArray(metrics) ? metrics : [])
    .slice(0, CONTEXT_BUDGETS.MAX_CLAIMS_PER_SECTION_RENDER * 5)
    .map((metric) => Object.freeze({
      id: metric.id,
      value: metric.value,
      unit: metric.unit ?? null,
      currency: metric.currency ?? null,
      as_of: metric.as_of,
      basis: metric.basis,
      method: metric.method,
      method_version: metric.method_version,
    }));

  const coverage = Object.freeze({
    status: snapshot.coverage?.status ?? 'unavailable',
    gaps: Object.freeze(gaps),
  });

  const horizons = Object.freeze(
    outlookHorizons({ sessionAsOf, isExchangeSession }).map((h) => Object.freeze(h)),
  );

  const context = Object.freeze({
    context_kind: 'h09_market_synthesis',
    instrument_id: instrument.instrument_id,
    instrument: Object.freeze({
      instrument_id: instrument.instrument_id,
      symbol: instrument.symbol,
      exchange: instrument.exchange,
      currency: instrument.currency,
    }),
    session_as_of: sessionAsOf,
    cutoff_at: cutoffAt,
    coverage,
    horizons,
    evidence: Object.freeze(boundedItems),
    evidence_ids: Object.freeze(boundedItems.map((item) => item.id)),
    metrics: metricRecords,
    metric_ids: Object.freeze(metricRecords.map((metric) => metric.id)),
    position: positionSlice(position),
    prior: priorSlice(prior),
  });

  return Object.freeze({ context, digest: contextDigest(context) });
}

const MODEL_OUTPUT_CONTRACT = Object.freeze({
  market_thesis: {
    business_assessment: {
      summary: 'string',
      claims: [{ text: 'string', evidence_ids: ['id...'], metric_ids: ['id...'], claim_type: 'observed | interpretation | assumption' }],
    },
    price_technical_assessment: {
      summary: 'string',
      claims: [{ text: 'string', evidence_ids: ['id...'], metric_ids: ['id...'], claim_type: 'observed | interpretation | assumption' }],
    },
    valuation_assessment: {
      summary: 'string',
      claims: [{ text: 'string', evidence_ids: ['id...'], metric_ids: ['id...'], claim_type: 'observed | interpretation | assumption' }],
    },
    rationale: [{ text: 'string', evidence_ids: ['id...'], metric_ids: ['id...'], claim_type: 'observed | interpretation | assumption' }],
    counterevidence: [{ text: 'string', evidence_ids: ['id...'], metric_ids: ['id...'], claim_type: 'observed | interpretation | assumption' }],
  },
  recommendation: {
    action: 'hold | hold_no_add | add | reduce | exit | insufficient_evidence (for owned position) OR buy | wait | avoid | insufficient_evidence (for candidate position). All lowercase!',
    horizon_months: 1,
    headline: 'string',
    rationale: [{ text: 'string', evidence_ids: ['id...'], metric_ids: ['id...'], claim_type: 'observed | interpretation | assumption' }],
    countercase: [{ text: 'string', evidence_ids: ['id...'], metric_ids: ['id...'], claim_type: 'observed | interpretation | assumption' }],
    invalidation_conditions: [{ text: 'string', evidence_ids: ['id...'], metric_ids: ['id...'], claim_type: 'observed | interpretation | assumption' }],
    evidence_quality: 'string',
    predictive_uncertainty: 'string',
  },
  outlooks: [
    {
      horizon_months: 1,
      direction: 'positive | negative | mixed | insufficient_evidence',
      base_case: [{ text: 'string', evidence_ids: ['id...'], metric_ids: ['id...'], claim_type: 'observed | interpretation | assumption' }],
      upside_case: [{ text: 'string', evidence_ids: ['id...'], metric_ids: ['id...'], claim_type: 'observed | interpretation | assumption' }],
      downside_case: [{ text: 'string', evidence_ids: ['id...'], metric_ids: ['id...'], claim_type: 'observed | interpretation | assumption' }],
      catalysts: [{ text: 'string', evidence_ids: ['id...'], metric_ids: ['id...'], claim_type: 'observed | interpretation | assumption' }],
      invalidators: [{ text: 'string', evidence_ids: ['id...'], metric_ids: ['id...'], claim_type: 'observed | interpretation | assumption' }],
      data_limitations: ['string...'],
    },
  ],
  changes_since_previous: '{previous_assessment_id, previous_session_as_of, missing_report_sessions, thesis_changes, checkpoint_change_ids} or null (must be null only when no prior report exists)',
  checkpoints: [
    {
      kind: 'business_condition | fixed_observed_level | rolling_indicator',
      condition: 'string',
      status: 'active | triggered | retired',
      reason: 'string',
      metric_id: 'optional, required only for rolling_indicator',
      fixed_level: 0,
    },
  ],
  missing_data: ['string...'],
  numeric_projection: 'always omit — null is composed server-side (H07A held)',
});

function renderSynthesisSystemPrompt() {
  return [
    'You are the Horizon grounded market analyst. You produce ONE market synthesis for one instrument.',
    '',
    'Grounding rules (enforced by deterministic validators — violations fail the run):',
    '- Cite only evidence IDs and metric IDs that appear in the provided context. Invented sources or metrics are rejected.',
    '- Every claim_type "observed" claim must cite at least one evidence or metric ID.',
    '- Never state unregistered numbers in observed claims: dates, quarter labels and horizon labels are not prices; any other numeral must be a cited metric value.',
    '- Never reference the owner\'s entry price, position size, or any personal economics. They are not in your context and must not be guessed.',
    '- The recommendation action must be compatible with the provided position state.',
    '- Recommendation action must be exact lowercase (for owned: hold, hold_no_add, add, reduce, exit, insufficient_evidence).',
    '- Outlook direction must be lowercase (positive, negative, mixed, insufficient_evidence).',
    '- Every claim item in claims, rationale, counterevidence, countercase, invalidation_conditions, base_case, upside_case, downside_case, catalysts, and invalidators MUST be an object { text, evidence_ids: [], metric_ids: [], claim_type: "observed" | "interpretation" | "assumption" }.',
    '- Produce exactly three outlooks (1, 2 and 3 month). The server computes their calendar dates; never invent dates. Make the horizons materially distinct, never an identical copy.',
    '- Always provide the strongest counterevidence/countercase. No forced confidence, no forced hold bias.',
    '- When coverage is partial, say what is missing in missing_data. Distinguish "no material change" from "missing data".',
    '- Never invent a numeric projection; omit the field entirely.',
    '- Never invent events, dates, prices, history or verification results.',
    '',
    `Output contract (JSON only, no prose outside JSON): ${JSON.stringify(MODEL_OUTPUT_CONTRACT)}`,
  ].join('\n');
}

function renderClaim(claimText) {
  return boundedText(claimText, 400);
}

function renderSynthesisUserPrompt(frozenContext) {
  const ctx = frozenContext;
  const lines = [];
  lines.push(`INSTRUMENT ${ctx.instrument.symbol} (${ctx.instrument.exchange}, ${ctx.instrument.currency}) id=${ctx.instrument_id}`);
  lines.push(`SESSION_AS_OF ${ctx.session_as_of} | CUTOFF ${ctx.cutoff_at}`);
  lines.push(`POSITION_STATE ${ctx.position.state} | PREFERRED_HORIZON_MONTHS ${ctx.position.preferred_horizon_months}`);
  if (ctx.position.position_id) lines.push(`POSITION_ID ${ctx.position.position_id}`);
  lines.push(`COVERAGE ${ctx.coverage.status}${ctx.coverage.gaps.length ? ` | GAPS: ${ctx.coverage.gaps.join(', ')}` : ''}`);
  lines.push('');
  lines.push('SERVER-COMPUTED HORIZON DATES (do not invent):');
  for (const h of ctx.horizons) {
    lines.push(`  ${h.horizon_months}m -> calendar_target ${h.calendar_target_date}, evaluation_session ${h.evaluation_session_date}`);
  }
  lines.push('');
  lines.push(`CODE-COMPUTED METRICS (cite by ID; ${ctx.metrics.length}):`);
  for (const metric of ctx.metrics) {
    lines.push(`  ${metric.id}: value=${metric.value} unit=${metric.unit ?? 'n/a'} currency=${metric.currency ?? 'n/a'} as_of=${metric.as_of} basis=${metric.basis} method=${metric.method}/${metric.method_version}`);
  }
  lines.push('');
  lines.push(`SOURCE EXCERPTS (cite by ID; ${ctx.evidence.length}):`);
  for (const item of ctx.evidence) {
    lines.push(`  ${item.id} [${item.kind}, ${item.coverage_status}] ${item.title} — ${item.source_name} (available_at ${item.available_at ?? item.published_at ?? 'unknown'})`);
    if (item.excerpt) lines.push(`    excerpt: ${renderClaim(item.excerpt)}`);
  }
  lines.push('');
  if (ctx.prior) {
    lines.push(`PRIOR REPORT (a prior decision, NOT evidence) id=${ctx.prior.assessment_id} session=${ctx.prior.session_as_of ?? 'unknown'}`);
    if (ctx.prior.market_thesis_summary) lines.push(`  prior summary: ${ctx.prior.market_thesis_summary}`);
    for (const cp of ctx.prior.checkpoints) {
      lines.push(`  checkpoint ${cp.id} [${cp.kind}/${cp.status}] ${cp.condition}`);
    }
    lines.push('  changes_since_previous is REQUIRED and must reference this prior assessment id.');
  } else {
    lines.push('PRIOR REPORT: none. changes_since_previous MUST be null.');
  }
  lines.push('');
  lines.push('Produce the JSON synthesis now.');
  return lines.join('\n');
}

function renderRepairPrompt(frozenContext, issues) {
  const listed = issues
    .map((issue, index) => `  ${index + 1}. [${issue.code}] ${issue.path || ''}: ${issue.message}`)
    .join('\n');
  return [
    'REPAIR ATTEMPT. Your previous synthesis was rejected by deterministic validation for exactly these issues:',
    listed || '  (unspecified issues)',
    '',
    'Fix every listed issue. Cite only IDs present in the frozen context below. Do not add a numeric projection.',
    '',
    'FROZEN CONTEXT (unchanged from the previous attempt):',
    renderSynthesisUserPrompt(frozenContext),
  ].join('\n');
}

module.exports = {
  CONTEXT_BUDGETS,
  MODEL_OUTPUT_CONTRACT,
  buildMarketSynthesisContext,
  containsUnregisteredNumericClaim,
  contextDigest,
  positionSlice,
  renderRepairPrompt,
  renderSynthesisSystemPrompt,
  renderSynthesisUserPrompt,
};
