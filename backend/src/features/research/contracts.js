const { z } = require('zod');

const CONTRACT_VERSION = 1;

const ISO_DATE_RE = /^(\d{4})-(\d{2})-(\d{2})$/;
const ISO_CURRENCY_RE = /^[A-Z]{3}$/;
const DECIMAL_RE = /^(?:0|[1-9]\d*)(?:\.\d+)?$/;
const UTC_TIMESTAMP_RE = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.(\d{1,3}))?Z$/;

const MAX_TEXT = 4000;
const DECIMAL_LIMITS = Object.freeze({ maxLength: 40, maxIntegerDigits: 24, maxFractionDigits: 12 });
const opaqueId = z.string().min(1).max(160);
const finiteNumber = z.number().finite();
const positiveFinite = finiteNumber.positive();
const boundedText = z.string().min(1).max(MAX_TEXT);

function daysInMonth(year, month) {
  return new Date(Date.UTC(year, month, 0)).getUTCDate();
}

function isValidDateParts(year, month, day) {
  return Number.isInteger(year)
    && year >= 1
    && year <= 9999
    && Number.isInteger(month)
    && month >= 1
    && month <= 12
    && Number.isInteger(day)
    && day >= 1
    && day <= daysInMonth(year, month);
}

function parseSessionDate(value) {
  const match = ISO_DATE_RE.exec(value);
  if (!match) return null;
  const [, year, month, day] = match.map(Number);
  return isValidDateParts(year, month, day) ? { year, month, day } : null;
}

function isValidUtcTimestamp(value) {
  const match = UTC_TIMESTAMP_RE.exec(value);
  if (!match) return false;
  const [, year, month, day, hour, minute, second] = match.map(Number);
  return isValidDateParts(year, month, day)
    && hour >= 0 && hour <= 23
    && minute >= 0 && minute <= 59
    && second >= 0 && second <= 59;
}

function calendarTargetDate(sessionAsOf, horizonMonths) {
  const source = parseSessionDate(sessionAsOf);
  if (!source || !Number.isInteger(horizonMonths) || horizonMonths < 1 || horizonMonths > 3) {
    throw new RangeError('Expected a valid session date and a one-to-three month horizon');
  }
  const targetMonthIndex = (source.month - 1) + horizonMonths;
  const year = source.year + Math.floor(targetMonthIndex / 12);
  const month = (targetMonthIndex % 12) + 1;
  if (year > 9999) {
    throw new RangeError('Calendar target exceeds the supported year range');
  }
  const day = Math.min(source.day, daysInMonth(year, month));
  return `${String(year).padStart(4, '0')}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
}

function previousCalendarDate(sessionDateValue) {
  const date = parseSessionDate(sessionDateValue);
  if (!date) throw new RangeError('Expected a valid session date');
  const value = new Date(Date.UTC(date.year, date.month - 1, date.day));
  value.setUTCDate(value.getUTCDate() - 1);
  return value.toISOString().slice(0, 10);
}

function evaluationSessionDate(calendarTarget, isExchangeSession) {
  if (typeof isExchangeSession !== 'function' || !parseSessionDate(calendarTarget)) {
    throw new TypeError('Expected a valid calendar target and exchange-session predicate');
  }
  let candidate = calendarTarget;
  for (let attempts = 0; attempts < 32; attempts += 1) {
    if (isExchangeSession(candidate)) return candidate;
    candidate = previousCalendarDate(candidate);
  }
  throw new RangeError('No exchange session found within 32 calendar days of target');
}

const utcTimestamp = z.string().regex(UTC_TIMESTAMP_RE, 'Expected a UTC ISO timestamp').refine(
  isValidUtcTimestamp,
  'Expected a real UTC calendar instant',
);
const sessionDate = z.string().regex(ISO_DATE_RE, 'Expected an ISO date').refine(
  (value) => parseSessionDate(value) !== null,
  'Expected a real calendar date',
);
const isoCurrency = z.string().regex(ISO_CURRENCY_RE, 'Expected an ISO 4217 currency');
const positiveDecimal = z.string().regex(DECIMAL_RE, 'Expected a decimal string').superRefine((value, ctx) => {
  const [integer, fraction = ''] = value.split('.');
  if (value.length > DECIMAL_LIMITS.maxLength
    || integer.length > DECIMAL_LIMITS.maxIntegerDigits
    || fraction.length > DECIMAL_LIMITS.maxFractionDigits) {
    ctx.addIssue({ code: z.ZodIssueCode.custom, message: 'Decimal exceeds bounded precision or range' });
  }
  if (!/[1-9]/.test(value)) {
    ctx.addIssue({ code: z.ZodIssueCode.custom, message: 'Expected a positive decimal string' });
  }
});
const versions = z.record(z.string().max(80), boundedText).superRefine((value, ctx) => {
  if (Object.keys(value).length > 20) {
    ctx.addIssue({ code: z.ZodIssueCode.custom, message: 'Versions cannot exceed 20 entries' });
  }
});

const moneyInput = z.object({
  amount: positiveDecimal,
  currency: isoCurrency,
}).strict();

const moneyNumber = z.object({
  amount: positiveFinite,
  currency: isoCurrency,
}).strict();

const riskContext = z.object({
  constraints: z.array(boundedText).min(1).max(20),
  portfolio_context: z.string().max(MAX_TEXT).nullable(),
  declared_at: utcTimestamp,
  source: z.literal('user_declared'),
}).strict();

const instrument = z.object({
  instrument_id: opaqueId,
  symbol: z.string().min(1).max(32),
  exchange: z.string().min(1).max(32),
  currency: isoCurrency,
  provider_symbol: z.string().min(1).max(80),
}).passthrough();

const positionWrite = z.object({
  instrument_id: opaqueId,
  state: z.enum(['candidate', 'owned', 'legacy_unclassified']),
  average_cost: moneyInput.nullable().optional(),
  quantity: positiveDecimal.nullable().optional(),
  opened_on: sessionDate.nullable().optional(),
  preferred_horizon_months: z.union([z.literal(1), z.literal(2), z.literal(3)]).optional(),
  original_thesis: z.string().max(MAX_TEXT).nullable().optional(),
  review_conditions: z.array(boundedText).max(20).nullable().optional(),
  risk_context: riskContext.nullable().optional(),
  archived: z.boolean().optional(),
  expected_revision: z.number().int().positive().optional(),
}).strict().superRefine((position, ctx) => {
  if (position.state === 'candidate') {
    for (const field of ['average_cost', 'quantity', 'opened_on']) {
      if (position[field] != null) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          path: [field],
          message: 'Candidate records cannot carry executed economics or an opening date',
        });
      }
    }
  }
});

const marketBar = z.object({
  time: utcTimestamp,
  session_date: sessionDate,
  open: positiveFinite,
  high: positiveFinite,
  low: positiveFinite,
  close: positiveFinite,
  volume: z.number().int().nonnegative().nullable(),
  adjusted_close: positiveFinite.nullable(),
  is_final: z.boolean(),
}).strict().superRefine((bar, ctx) => {
  if (bar.low > Math.min(bar.open, bar.close) || bar.high < Math.max(bar.open, bar.close)) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      path: ['low'],
      message: 'OHLC must satisfy low <= min(open, close) <= max(open, close) <= high',
    });
  }
});

const reportingPeriod = z.object({
  start: sessionDate.nullable(),
  end: sessionDate.nullable(),
  label: z.string().max(160).nullable(),
}).strict().superRefine((period, ctx) => {
  if (period.start != null && period.end != null && period.start > period.end) {
    ctx.addIssue({ code: z.ZodIssueCode.custom, path: ['end'], message: 'Reporting period end cannot precede start' });
  }
});

const evidenceFact = z.object({
  id: opaqueId,
  label: boundedText,
  value: z.union([finiteNumber, boundedText]),
  unit: z.string().max(80).nullable(),
  currency: isoCurrency.nullable(),
  basis: z.string().max(160).nullable(),
  reporting_period: reportingPeriod.nullable(),
}).passthrough();

const evidenceItem = z.object({
  id: opaqueId,
  instrument_id: opaqueId,
  kind: z.enum(['filing', 'earnings_release', 'transcript', 'company_ir', 'news', 'market_data', 'corporate_action', 'event_calendar']),
  title: boundedText,
  source_url: z.string().url(),
  source_name: boundedText,
  published_at: utcTimestamp.nullable(),
  retrieved_at: utcTimestamp,
  available_at: utcTimestamp.nullable(),
  reporting_period: reportingPeriod.nullable(),
  excerpt: z.string().max(MAX_TEXT).nullable(),
  source_locator: z.string().max(1000).nullable(),
  facts: z.array(evidenceFact).max(100),
  coverage_status: z.enum(['available', 'partial', 'unavailable', 'headline_only']),
}).passthrough();

const claim = z.object({
  text: boundedText,
  evidence_ids: z.array(opaqueId).max(50),
  metric_ids: z.array(opaqueId).max(50),
  claim_type: z.enum(['observed', 'interpretation', 'assumption']),
}).passthrough().superRefine((value, ctx) => {
  for (const field of ['evidence_ids', 'metric_ids']) {
    if (new Set(value[field]).size !== value[field].length) {
      ctx.addIssue({ code: z.ZodIssueCode.custom, path: [field], message: 'References must be unique' });
    }
  }
});

const calibrationEvidence = z.object({
  model_version: boundedText,
  held_out_evaluation: boundedText,
  coverage_definition: boundedText,
  validation_evidence_ids: z.array(opaqueId).min(1).max(50),
}).passthrough();

const numericProjection = z.object({
  id: opaqueId,
  assessment_id: opaqueId,
  instrument_id: opaqueId,
  evidence_snapshot_id: opaqueId,
  anchor_time: utcTimestamp,
  anchor_price_metric_id: opaqueId,
  target_session_date: sessionDate,
  kind: z.enum(['conditional_scenario', 'volatility_reference', 'calibrated_forecast']),
  method: boundedText,
  method_version: boundedText,
  input_metric_ids: z.array(opaqueId).min(1).max(50),
  assumption_ids: z.array(opaqueId).max(50),
  lower: positiveFinite.nullable(),
  central: positiveFinite.nullable(),
  upper: positiveFinite.nullable(),
  currency: isoCurrency,
  adjustment_basis: z.string().min(1).max(80),
  calibration: calibrationEvidence.nullable(),
  valid_until: utcTimestamp.nullable(),
  limitations: z.array(boundedText).max(50),
}).passthrough().superRefine((projection, ctx) => {
  const values = [projection.lower, projection.central, projection.upper].filter((value) => value != null);
  if (values.length === 0) {
    ctx.addIssue({ code: z.ZodIssueCode.custom, path: ['lower'], message: 'At least one projection bound is required' });
  }
  if (projection.lower != null && projection.central != null && projection.lower > projection.central) {
    ctx.addIssue({ code: z.ZodIssueCode.custom, path: ['lower'], message: 'lower cannot exceed central' });
  }
  if (projection.central != null && projection.upper != null && projection.central > projection.upper) {
    ctx.addIssue({ code: z.ZodIssueCode.custom, path: ['central'], message: 'central cannot exceed upper' });
  }
  if (projection.lower != null && projection.upper != null && projection.lower > projection.upper) {
    ctx.addIssue({ code: z.ZodIssueCode.custom, path: ['lower'], message: 'lower cannot exceed upper' });
  }
  if (projection.kind === 'conditional_scenario' && projection.assumption_ids.length === 0) {
    ctx.addIssue({ code: z.ZodIssueCode.custom, path: ['assumption_ids'], message: 'Conditional scenarios require explicit assumptions' });
  }
  if (projection.kind === 'calibrated_forecast' && projection.calibration == null) {
    ctx.addIssue({ code: z.ZodIssueCode.custom, path: ['calibration'], message: 'Calibrated forecasts require calibration evidence' });
  }
  if (projection.valid_until != null && projection.valid_until < projection.anchor_time) {
    ctx.addIssue({ code: z.ZodIssueCode.custom, path: ['valid_until'], message: 'Projection validity cannot end before its anchor' });
  }
});

const outlook = z.object({
  horizon_months: z.union([z.literal(1), z.literal(2), z.literal(3)]),
  calendar_target_date: sessionDate,
  evaluation_session_date: sessionDate,
  direction: z.enum(['positive', 'negative', 'mixed', 'insufficient_evidence']),
  base_case: z.array(claim).max(20),
  upside_case: z.array(claim).max(20),
  downside_case: z.array(claim).max(20),
  catalysts: z.array(claim).max(20),
  invalidators: z.array(claim).max(20),
  numeric_projection: numericProjection.nullable(),
  data_limitations: z.array(boundedText).max(50),
}).passthrough();

const thesisSection = z.object({
  summary: boundedText,
  claims: z.array(claim).max(50),
}).passthrough();

const marketThesis = z.object({
  business_assessment: thesisSection,
  price_technical_assessment: thesisSection,
  valuation_assessment: thesisSection,
  rationale: z.array(claim).max(50),
  counterevidence: z.array(claim).max(50),
}).passthrough();

const assessmentPositionContext = z.object({
  position_id: opaqueId.nullable(),
  instrument_id: opaqueId,
  state: z.enum(['candidate', 'owned', 'legacy_unclassified']),
  revision: z.number().int().positive().nullable(),
  average_cost: moneyInput.nullable().optional(),
  quantity: positiveDecimal.nullable().optional(),
  opened_on: sessionDate.nullable().optional(),
  economics_status: z.enum(['available', 'partial', 'unavailable']).optional(),
}).passthrough().superRefine((context, ctx) => {
  if (context.state === 'candidate') {
    for (const field of ['average_cost', 'quantity', 'opened_on']) {
      if (context[field] != null) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          path: [field],
          message: 'Candidate assessment context cannot carry executed economics or an opening date',
        });
      }
    }
  }
});

const checkpoint = z.object({
  id: opaqueId,
  instrument_id: opaqueId,
  kind: z.enum(['rolling_indicator', 'fixed_observed_level', 'business_condition']),
  metric_id: opaqueId.nullable(),
  fixed_level: positiveFinite.nullable(),
  condition: boundedText,
  created_at: utcTimestamp,
  updated_at: utcTimestamp,
  status: z.enum(['active', 'triggered', 'retired']),
  reason: boundedText,
  source_assessment_id: opaqueId,
}).passthrough().superRefine((value, ctx) => {
  if (value.updated_at < value.created_at) {
    ctx.addIssue({ code: z.ZodIssueCode.custom, path: ['updated_at'], message: 'Checkpoint update cannot precede creation' });
  }
  if (value.kind === 'rolling_indicator' && value.metric_id == null) {
    ctx.addIssue({ code: z.ZodIssueCode.custom, path: ['metric_id'], message: 'Rolling checkpoints require a metric reference' });
  }
  if (value.kind === 'rolling_indicator' && value.fixed_level != null) {
    ctx.addIssue({ code: z.ZodIssueCode.custom, path: ['fixed_level'], message: 'Rolling checkpoints cannot carry a fixed observed level' });
  }
  if (value.kind === 'fixed_observed_level' && value.fixed_level == null) {
    ctx.addIssue({ code: z.ZodIssueCode.custom, path: ['fixed_level'], message: 'Fixed-level checkpoints require a positive observed level' });
  }
  if (value.kind === 'fixed_observed_level' && value.metric_id != null) {
    ctx.addIssue({ code: z.ZodIssueCode.custom, path: ['metric_id'], message: 'Fixed-level checkpoints cannot carry a metric reference' });
  }
  if (value.kind === 'business_condition' && (value.metric_id != null || value.fixed_level != null)) {
    ctx.addIssue({ code: z.ZodIssueCode.custom, path: ['kind'], message: 'Business-condition checkpoints cannot carry a metric reference or fixed level' });
  }
});

const thesisChange = z.object({
  component: boundedText,
  status: z.enum(['strengthened', 'weakened', 'unchanged', 'untested', 'corrected']),
  reason: boundedText,
  evidence_ids: z.array(opaqueId).max(50),
}).passthrough();

const changesSincePrevious = z.object({
  previous_assessment_id: opaqueId.nullable(),
  previous_session_as_of: sessionDate.nullable(),
  missing_report_sessions: z.array(sessionDate).max(100),
  thesis_changes: z.array(thesisChange).max(100),
  checkpoint_change_ids: z.array(opaqueId).max(100),
}).passthrough();

const recommendation = z.object({
  action: z.enum(['buy', 'wait', 'avoid', 'hold', 'hold_no_add', 'add', 'reduce', 'exit', 'insufficient_evidence']),
  horizon_months: z.union([z.literal(1), z.literal(2), z.literal(3)]),
  headline: boundedText,
  rationale: z.array(claim).max(50),
  countercase: z.array(claim).max(50),
  invalidation_conditions: z.array(claim).max(50),
  evidence_quality: boundedText,
  predictive_uncertainty: boundedText,
}).passthrough();

const stateActions = {
  candidate: new Set(['buy', 'wait', 'avoid', 'insufficient_evidence']),
  owned: new Set(['hold', 'hold_no_add', 'add', 'reduce', 'exit', 'insufficient_evidence']),
  legacy_unclassified: new Set(['insufficient_evidence']),
};

const researchAssessment = z.object({
  id: opaqueId,
  contract_version: z.literal(CONTRACT_VERSION),
  position_id: opaqueId.nullable(),
  position_revision: z.number().int().positive().nullable(),
  instrument_id: opaqueId,
  run_id: opaqueId,
  evidence_snapshot_id: opaqueId,
  generated_at: utcTimestamp,
  session_as_of: sessionDate,
  status: z.enum(['complete', 'limited']),
  market_thesis: marketThesis,
  recommendation,
  position_context: assessmentPositionContext,
  changes_since_previous: changesSincePrevious.nullable(),
  checkpoints: z.array(checkpoint).max(100),
  outlooks: z.array(outlook).length(3),
  missing_data: z.array(boundedText).max(100),
  next_review: utcTimestamp.nullable(),
  versions,
}).passthrough().superRefine((assessment, ctx) => {
  const horizons = assessment.outlooks.map((entry) => entry.horizon_months).sort();
  if (horizons.join(',') !== '1,2,3') {
    ctx.addIssue({ code: z.ZodIssueCode.custom, path: ['outlooks'], message: 'Exactly one 1, 2, and 3 month outlook is required' });
  }
  if (!stateActions[assessment.position_context.state].has(assessment.recommendation.action)) {
    ctx.addIssue({ code: z.ZodIssueCode.custom, path: ['recommendation', 'action'], message: 'Action is incompatible with the position state' });
  }
  if (assessment.position_context.state === 'legacy_unclassified' && assessment.position_id != null && assessment.position_revision == null) {
    ctx.addIssue({ code: z.ZodIssueCode.custom, path: ['position_revision'], message: 'Position-specific assessments require a revision' });
  }
  if (assessment.position_context.position_id !== assessment.position_id
    || assessment.position_context.instrument_id !== assessment.instrument_id
    || assessment.position_context.revision !== assessment.position_revision) {
    ctx.addIssue({ code: z.ZodIssueCode.custom, path: ['position_context'], message: 'Position context must match the assessment identity and revision' });
  }
  for (const entry of assessment.outlooks) {
    let expectedTarget;
    try {
      expectedTarget = calendarTargetDate(assessment.session_as_of, entry.horizon_months);
    } catch (error) {
      ctx.addIssue({ code: z.ZodIssueCode.custom, path: ['session_as_of'], message: error.message });
      continue;
    }
    if (entry.calendar_target_date !== expectedTarget) {
      ctx.addIssue({ code: z.ZodIssueCode.custom, path: ['outlooks'], message: 'Outlook target must use contract month-end clamping' });
    }
    if (entry.evaluation_session_date < assessment.session_as_of) {
      ctx.addIssue({ code: z.ZodIssueCode.custom, path: ['outlooks'], message: 'Evaluation session cannot predate the assessment session' });
    }
    if (entry.evaluation_session_date > entry.calendar_target_date) {
      ctx.addIssue({ code: z.ZodIssueCode.custom, path: ['outlooks'], message: 'Evaluation session cannot be after its calendar target' });
    }
    const projection = entry.numeric_projection;
    if (projection != null && (projection.assessment_id !== assessment.id
      || projection.instrument_id !== assessment.instrument_id
      || projection.evidence_snapshot_id !== assessment.evidence_snapshot_id
      || projection.target_session_date !== entry.evaluation_session_date)) {
      ctx.addIssue({ code: z.ZodIssueCode.custom, path: ['outlooks'], message: 'Projection identity must match its assessment, snapshot, instrument, and evaluation session' });
    }
  }
  for (const item of assessment.checkpoints) {
    if (item.instrument_id !== assessment.instrument_id || item.source_assessment_id !== assessment.id) {
      ctx.addIssue({ code: z.ZodIssueCode.custom, path: ['checkpoints'], message: 'Checkpoint identity must match its assessment and instrument' });
    }
  }
});

const positionContext = z.object({
  average_cost: moneyInput.nullable(),
  current_price: moneyNumber.nullable(),
  quantity: positiveDecimal.nullable(),
  adjustment_basis: z.string().min(1).max(80).nullable(),
}).strict().superRefine((context, ctx) => {
  if (context.average_cost && context.current_price && context.average_cost.currency !== context.current_price.currency) {
    ctx.addIssue({ code: z.ZodIssueCode.custom, path: ['current_price', 'currency'], message: 'Cross-currency economics require a sourced FX policy' });
  }
});

const researchRun = z.object({
  id: opaqueId,
  position_id: opaqueId,
  owner_id_internal: opaqueId,
  position_revision: z.number().int().positive(),
  run_kind: z.enum(['deep_research', 'daily_update', 'manual_refresh']),
  idempotency_key: z.string().min(1).max(255),
  status: z.enum(['queued', 'running', 'succeeded', 'limited', 'failed', 'stalled', 'superseded']),
  stage: z.string().min(1).max(80),
  created_at: utcTimestamp,
  started_at: utcTimestamp.nullable(),
  heartbeat_at: utcTimestamp.nullable(),
  deadline_at: utcTimestamp,
  finished_at: utcTimestamp.nullable(),
  evidence_snapshot_id: opaqueId.nullable(),
  assessment_id: opaqueId.nullable(),
  error_code: z.string().min(1).max(120).nullable(),
  retry_count: z.number().int().min(0).max(2),
  versions,
}).passthrough().superRefine((run, ctx) => {
  const terminalStatuses = new Set(['succeeded', 'limited', 'failed', 'stalled', 'superseded']);
  const addIssue = (path, message) => ctx.addIssue({ code: z.ZodIssueCode.custom, path: [path], message });
  if (run.deadline_at < run.created_at) addIssue('deadline_at', 'Run deadline cannot precede creation');
  if (run.started_at != null && run.started_at < run.created_at) addIssue('started_at', 'Run start cannot precede creation');
  if (run.heartbeat_at != null && (run.started_at == null || run.heartbeat_at < run.started_at)) {
    addIssue('heartbeat_at', 'Heartbeat requires a started run and cannot precede its start');
  }
  if (run.finished_at != null && (run.started_at == null || run.finished_at < run.started_at)) {
    addIssue('finished_at', 'Finished runs must have started and cannot finish before start');
  }
  if (run.heartbeat_at != null && run.finished_at != null && run.heartbeat_at > run.finished_at) {
    addIssue('heartbeat_at', 'Heartbeat cannot be after run completion');
  }
  if (run.status === 'queued') {
    if (run.started_at != null || run.heartbeat_at != null || run.finished_at != null
      || run.evidence_snapshot_id != null || run.assessment_id != null || run.error_code != null) {
      addIssue('status', 'Queued runs cannot contain active, result, or error state');
    }
  }
  if (run.status === 'running') {
    if (run.started_at == null || run.finished_at != null || run.assessment_id != null || run.error_code != null) {
      addIssue('status', 'Running runs require a start and cannot contain terminal result or error state');
    }
  }
  if (terminalStatuses.has(run.status) && run.finished_at == null) {
    addIssue('finished_at', 'Terminal runs require a completion timestamp');
  }
  if (['succeeded', 'limited'].includes(run.status)) {
    if (run.assessment_id == null || run.evidence_snapshot_id == null || run.error_code != null) {
      addIssue('assessment_id', 'Successful or limited runs require a snapshot and assessment without an error code');
    }
    if (run.finished_at != null && run.finished_at > run.deadline_at) {
      addIssue('finished_at', 'Successful or limited runs cannot complete after their deadline');
    }
  }
  if (['failed', 'stalled'].includes(run.status)) {
    if (run.started_at == null || run.assessment_id != null || run.error_code == null) {
      addIssue('status', 'Failed or stalled runs require start, terminal error, and no assessment');
    }
  }
  if (run.status === 'stalled' && run.finished_at != null && run.finished_at < run.deadline_at) {
    addIssue('finished_at', 'Stalled runs cannot finish before their deadline');
  }
  if (run.status === 'superseded' && (run.assessment_id != null || run.error_code != null)) {
    addIssue('status', 'Superseded runs cannot publish an assessment or terminal error');
  }
});

const historyResponse = z.object({
  contract_version: z.literal(CONTRACT_VERSION),
  instrument,
  snapshot_id: opaqueId.nullable(),
  range: z.enum(['1D', '1W', '1M', '3M', '6M', '1Y']),
  requested_resolution: z.string().min(1).max(20),
  actual_resolution: z.string().min(1).max(20),
  exchange_timezone: z.string().min(1).max(80),
  session_mode: z.enum(['regular', 'extended']),
  adjustment_basis: z.string().min(1).max(80),
  as_of: utcTimestamp.nullable(),
  fetched_at: utcTimestamp,
  data_status: z.enum(['available', 'partial', 'unavailable']),
  delay_status: z.enum(['realtime', 'delayed', 'unknown']),
  is_stale: z.boolean(),
  available_ranges: z.array(z.enum(['1D', '1W', '1M', '3M', '6M', '1Y'])).max(6),
  bars: z.array(marketBar).max(5000),
  warnings: z.array(z.unknown()).max(100),
  next_cursor: z.string().min(1).max(500).nullable(),
  unavailable_reason: z.string().min(1).max(500).nullable().optional(),
}).passthrough().superRefine((response, ctx) => {
  if (response.data_status === 'unavailable' && (response.bars.length !== 0 || !response.unavailable_reason)) {
    ctx.addIssue({ code: z.ZodIssueCode.custom, path: ['unavailable_reason'], message: 'Unavailable history requires an empty result and machine-readable reason' });
  }
  if (response.is_stale && response.delay_status === 'realtime') {
    ctx.addIssue({ code: z.ZodIssueCode.custom, path: ['delay_status'], message: 'Stale cache data cannot claim realtime delivery' });
  }
  const seen = new Set();
  let previousTime = null;
  for (const bar of response.bars) {
    const key = `${bar.session_date}|${bar.time}`;
    if (seen.has(key)) {
      ctx.addIssue({ code: z.ZodIssueCode.custom, path: ['bars'], message: 'Bars must be unique by session bucket' });
      break;
    }
    seen.add(key);
    if (previousTime != null && bar.time <= previousTime) {
      ctx.addIssue({ code: z.ZodIssueCode.custom, path: ['bars'], message: 'Bars must be ascending by time' });
      break;
    }
    previousTime = bar.time;
  }
});

const schemas = Object.freeze({
  positionWrite,
  marketBar,
  evidenceItem,
  claim,
  numericProjection,
  researchAssessment,
  researchRun,
  positionContext,
  historyResponse,
});

module.exports = {
  CONTRACT_VERSION,
  DECIMAL_LIMITS,
  calendarTargetDate,
  evaluationSessionDate,
  schemas,
  positionWriteSchema: positionWrite,
  marketBarSchema: marketBar,
  evidenceItemSchema: evidenceItem,
  claimSchema: claim,
  numericProjectionSchema: numericProjection,
  researchAssessmentSchema: researchAssessment,
  researchRunSchema: researchRun,
  positionContextSchema: positionContext,
  historyResponseSchema: historyResponse,
};
