'use strict';

// H09X — the typed, server-owned tool registry for the generalized research
// runtime (released follow-up, CONTRACTS §9 / SPEC §4).
//
// This module is pure data + validation + budget accounting. It knows the ten
// typed tool names, their per-stage allowlists, and the named budget constants;
// it NEVER holds or executes any data access. Actual reads are server-owned
// resolver functions injected by the caller and bound to one run/instrument/
// cutoff — a model request can only name a registered tool and bounded
// reference arguments (metric/evidence/filing ids, ranges), never a URL,
// command, code, owner id, or raw query.
//
// Enforced in code (not prompts):
//   - per-stage tool allowlists (synthesis-only tools can't run elsewhere);
//   - per-run/stage call budget (named constants; exhaustion recorded);
//   - per-result response-size cap;
//   - idempotent retry cache so a retried request never re-charges the budget.
//
// Nothing here performs live calls, filesystem access, network I/O, SQL, or
// credential reads.

const crypto = require('node:crypto');

// -- Stage vocabulary (enum; never arbitrary code or a model name) ----------

const STAGES = Object.freeze(['evidence', 'analyst', 'synthesis', 'reviewer', 'delivery']);

const STAGE_ORDER = Object.freeze({
  evidence: 0,
  analyst: 1,
  synthesis: 2,
  reviewer: 3,
  delivery: 4,
});

function validateStage(stage) {
  return typeof stage === 'string' && Object.prototype.hasOwnProperty.call(STAGE_ORDER, stage);
}

// -- Budgets (named code constants) -----------------------------------------

const TOOL_BUDGETS = Object.freeze({
  // SPEC §4: "analyst up to eight read calls per instrument and one bounded
  // follow-up retrieval pass".
  ANALYST_MAX_READ_CALLS: 8,
  ANALYST_MAX_RETRIEVAL_PASSES: 1,
  // SPEC §4: "synthesis reads one exact position revision".
  SYNTHESIS_MAX_POSITION_READS: 1,
  // SPEC §4: "reviewer uses supplied evidence with no independent web tool".
  REVIEWER_MAX_WEB_TOOLS: 0,
  MAX_TOOL_RESULT_BYTES: 64 * 1024,
  MAX_REQUEST_ID_LENGTH: 128,
  MAX_METRIC_IDS: 20,
  MAX_EVIDENCE_IDS: 20,
  MAX_ARG_STRING_LENGTH: 160,
});

// Per-stage call budget: how many tool calls a single run may make in each
// stage. A stage budget of zero tools (reviewer) means only the deterministic
// validator may run there — never an independent web/analyst tool.
const STAGE_CALL_BUDGETS = Object.freeze({
  evidence: TOOL_BUDGETS.ANALYST_MAX_READ_CALLS,
  analyst: TOOL_BUDGETS.ANALYST_MAX_READ_CALLS,
  synthesis: TOOL_BUDGETS.SYNTHESIS_MAX_POSITION_READS,
  reviewer: 1, // validate_research_result only (deterministic, no model)
  delivery: 1,
});

// -- Tool definitions --------------------------------------------------------

// Allowed argument keys are the ONLY keys a tool may receive, beyond which a
// global blocklist applies. These are bounded reference selectors, never
// authorities. `owner_id` is deliberately absent from every tool: ownership is
// server-derived from the run, never supplied by the model (CONTRACTS §9).
const TOOL_DEFINITIONS = [
  {
    name: 'get_market_history',
    allowed_stages: ['evidence', 'analyst'],
    description: 'Vetted instrument/range, observed OHLCV and provenance',
    arg_keys: ['range', 'resolution'],
    ranges: ['1D', '1W', '1M', '3M', '6M', '1Y'],
    resolutions: ['5m', '30m', '1d'],
  },
  {
    name: 'get_market_metrics',
    allowed_stages: ['analyst'],
    description: 'Code-computed indicators, drawdown and relative performance',
    arg_keys: ['metric_ids'],
  },
  {
    name: 'get_financial_facts',
    allowed_stages: ['evidence', 'analyst'],
    description: 'Filing-linked values with period/unit/basis',
    arg_keys: ['period'],
  },
  {
    name: 'get_filing_excerpt',
    allowed_stages: ['analyst'],
    description: 'Known filing/evidence ID and bounded section, no arbitrary URL',
    arg_keys: ['filing_id', 'section'],
    required: ['filing_id'],
  },
  {
    name: 'get_earnings_context',
    allowed_stages: ['analyst'],
    description: 'Verified earnings release/guidance/call excerpts or explicit unavailable',
    arg_keys: [],
  },
  {
    name: 'get_material_news',
    allowed_stages: ['evidence', 'analyst'],
    description: 'Dated material passages/headlines with exact coverage status',
    arg_keys: ['limit'],
  },
  {
    name: 'get_confirmed_events',
    allowed_stages: ['analyst'],
    description: 'Source-backed event dates, not guessed earnings calendars',
    arg_keys: [],
  },
  {
    name: 'get_prior_thesis',
    allowed_stages: ['analyst', 'synthesis'],
    description: 'Earlier judgments/checkpoints labeled as prior decisions, not facts',
    arg_keys: [],
  },
  {
    name: 'get_position_context',
    allowed_stages: ['synthesis'],
    synthesis_only: true,
    description: 'Owner-bound revision, cost and deterministic P/L, never shared cache',
    arg_keys: [],
  },
  {
    name: 'validate_research_result',
    allowed_stages: ['reviewer', 'delivery'],
    description: 'Deterministic schema/numeric/cutoff/authorization checks plus semantic findings',
    arg_keys: ['result'],
    required: ['result'],
  },
];

const TOOLS = Object.freeze(
  Object.fromEntries(TOOL_DEFINITIONS.map((definition) => [
    definition.name,
    Object.freeze({
      name: definition.name,
      allowed_stages: Object.freeze([...definition.allowed_stages]),
      synthesis_only: definition.synthesis_only === true,
      description: definition.description,
      // Argument schema must survive into the frozen registry entry: argument
      // validation reads arg_keys/ranges/resolutions/required off the tool
      // object, not off the private definitions array.
      arg_keys: Object.freeze([...(definition.arg_keys ?? [])]),
      ranges: definition.ranges ? Object.freeze([...definition.ranges]) : undefined,
      resolutions: definition.resolutions ? Object.freeze([...definition.resolutions]) : undefined,
      required: definition.required ? Object.freeze([...definition.required]) : undefined,
    }),
  ])),
);

const SYNTHESIS_ONLY_TOOLS = Object.freeze(
  TOOL_DEFINITIONS.filter((definition) => definition.synthesis_only === true).map((definition) => definition.name),
);

// Argument keys that are rejected for every tool regardless of its schema.
// These represent authorities (owner id, credentials), side effects (command,
// code, sql, filesystem) and out-of-band destinations (url) that a bounded
// read tool can never legitimately need.
const FORBIDDEN_ARGUMENT_KEYS = Object.freeze([
  'owner_id',
  'user_id',
  'url',
  'uri',
  'command',
  'cmd',
  'code',
  'sql',
  'query',
  'eval',
  'path',
  'file',
  'token',
  'key',
  'secret',
  'credential',
  'credentials',
  'password',
  'host',
  'hostname',
  'endpoint',
]);

// ---------------------------------------------------------------------------
// Validation
// ---------------------------------------------------------------------------

function isPlainObject(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

function issue(code, path, message) {
  return { code, path, message };
}

function isBoundedString(value) {
  return typeof value === 'string' && value.length > 0 && value.length <= TOOL_BUDGETS.MAX_ARG_STRING_LENGTH;
}

function validateArgumentValue(tool, key, value, issues) {
  switch (key) {
    case 'range':
      if (typeof value !== 'string' || !tool.ranges.includes(value)) {
        issues.push(issue('INVALID_ARGUMENTS', `arguments.${key}`, `range must be one of ${tool.ranges.join(', ')}`));
      }
      break;
    case 'resolution':
      if (typeof value !== 'string' || !tool.resolutions.includes(value)) {
        issues.push(issue('INVALID_ARGUMENTS', `arguments.${key}`, `resolution must be one of ${tool.resolutions.join(', ')}`));
      }
      break;
    case 'metric_ids':
    case 'evidence_ids':
      if (!Array.isArray(value) || value.length === 0 || value.length > TOOL_BUDGETS.MAX_METRIC_IDS
        || !value.every(isBoundedString)) {
        issues.push(issue('INVALID_ARGUMENTS', `arguments.${key}`, `${key} must be a bounded array of string ids`));
      }
      break;
    case 'filing_id':
    case 'section':
    case 'period':
      if (!isBoundedString(value)) {
        issues.push(issue('INVALID_ARGUMENTS', `arguments.${key}`, `${key} must be a bounded string`));
      }
      break;
    case 'limit':
      if (!Number.isSafeInteger(value) || value < 1 || value > 20) {
        issues.push(issue('INVALID_ARGUMENTS', `arguments.${key}`, 'limit must be an integer between 1 and 20'));
      }
      break;
    case 'result':
      if (!isPlainObject(value)) {
        issues.push(issue('INVALID_ARGUMENTS', `arguments.${key}`, 'result must be a plain object'));
      }
      break;
    default:
      issues.push(issue('UNEXPECTED_FIELD', `arguments.${key}`, `unknown argument for tool ${tool.name}`));
  }
}

function validateToolArguments(tool, argumentsValue) {
  const issues = [];
  if (!isPlainObject(argumentsValue)) {
    return [issue('INVALID_ARGUMENTS', 'arguments', 'arguments must be a plain object')];
  }
  for (const key of Object.keys(argumentsValue)) {
    if (FORBIDDEN_ARGUMENT_KEYS.includes(key)) {
      issues.push(issue('FORBIDDEN_ARGUMENT', `arguments.${key}`, `argument ${key} is never accepted`));
    } else if (!tool.arg_keys.includes(key)) {
      issues.push(issue('UNEXPECTED_FIELD', `arguments.${key}`, `unknown argument for tool ${tool.name}`));
    }
  }
  for (const key of (tool.required ?? [])) {
    if (!Object.prototype.hasOwnProperty.call(argumentsValue, key)) {
      issues.push(issue('INVALID_ARGUMENTS', `arguments.${key}`, `${key} is required`));
    }
  }
  if (issues.length > 0) return issues;
  for (const [key, value] of Object.entries(argumentsValue)) {
    validateArgumentValue(tool, key, value, issues);
  }
  return issues;
}

const REQUEST_KEYS = Object.freeze(['tool_name', 'arguments', 'stage', 'request_id']);

/**
 * Validates a raw tool request body. Returns {ok, tool, stage, arguments,
 * request_id} on success, or {ok:false, issues, issue_code} on failure. The
 * request may carry ONLY tool_name/arguments/stage/request_id (CONTRACTS §9);
 * any other key — especially owner_id/url/command/code/sql — is rejected.
 */
function validateToolRequest(request) {
  if (!isPlainObject(request)) {
    return { ok: false, issues: [issue('INVALID_ARGUMENTS', '', 'tool request must be a plain object')], issue_code: 'INVALID_ARGUMENTS' };
  }
  const issues = [];

  for (const key of Object.keys(request)) {
    if (!REQUEST_KEYS.includes(key)) {
      issues.push(issue('UNEXPECTED_FIELD', key, `unexpected request field ${key}`));
    }
  }
  if (issues.length > 0) {
    return { ok: false, issues, issue_code: 'UNEXPECTED_FIELD' };
  }

  const { tool_name: toolName, arguments: args, stage, request_id: requestId } = request;

  if (typeof toolName !== 'string' || !Object.prototype.hasOwnProperty.call(TOOLS, toolName)) {
    return { ok: false, issues: [issue('UNKNOWN_TOOL', 'tool_name', `unknown tool ${String(toolName)}`)], issue_code: 'UNKNOWN_TOOL' };
  }
  const tool = TOOLS[toolName];

  if (!validateStage(stage)) {
    return { ok: false, issues: [issue('INVALID_STAGE', 'stage', 'stage must be a registered pipeline stage')], issue_code: 'INVALID_STAGE' };
  }

  if (!tool.allowed_stages.includes(stage)) {
    if (tool.synthesis_only) {
      return { ok: false, issues: [issue('SYNTHESIS_ONLY_STAGE', 'stage', `tool ${toolName} is synthesis-only`)], issue_code: 'SYNTHESIS_ONLY_STAGE' };
    }
    return { ok: false, issues: [issue('TOOL_NOT_ALLOWED_IN_STAGE', 'stage', `tool ${toolName} is not allowed in stage ${stage}`)], issue_code: 'TOOL_NOT_ALLOWED_IN_STAGE' };
  }

  if (typeof requestId !== 'string' || requestId.length === 0 || requestId.length > TOOL_BUDGETS.MAX_REQUEST_ID_LENGTH) {
    return { ok: false, issues: [issue('INVALID_REQUEST_ID', 'request_id', 'request_id must be a bounded non-empty string')], issue_code: 'INVALID_REQUEST_ID' };
  }

  const argIssues = validateToolArguments(tool, args);
  if (argIssues.length > 0) {
    return { ok: false, issues: argIssues, issue_code: argIssues[0].code };
  }

  return {
    ok: true,
    tool,
    stage,
    arguments: args,
    request_id: requestId,
  };
}

// ---------------------------------------------------------------------------
// Executor (budget accounting + resolver dispatch)
// ---------------------------------------------------------------------------

function safeResponseBytes(value) {
  try {
    return Buffer.byteLength(JSON.stringify(value));
  } catch {
    return Number.POSITIVE_INFINITY;
  }
}

/**
 * Builds a server-owned tool executor. `resolvers` maps a registered tool name
 * to `async (arguments, boundContext) => result` — the only place real reads
 * happen; they are injected and bound to one run/instrument/cutoff by the
 * caller. The executor enforces the per-stage call budget, the per-result
 * response-size cap, and an idempotent retry cache so a retried request_id is
 * served from cache and never re-charges the budget.
 */
function createToolExecutor({
  resolvers,
  callBudgets = STAGE_CALL_BUDGETS,
  responseSizeLimit = TOOL_BUDGETS.MAX_TOOL_RESULT_BYTES,
} = {}) {
  if (!resolvers || typeof resolvers !== 'object') {
    throw new TypeError('createToolExecutor requires injected resolvers');
  }
  if (!Number.isSafeInteger(responseSizeLimit) || responseSizeLimit < 1) {
    throw new TypeError('responseSizeLimit must be a positive integer');
  }
  const counters = new Map();
  const cache = new Map();

  function budgetFor(stage) {
    const limit = callBudgets[stage];
    return Number.isSafeInteger(limit) ? limit : STAGE_CALL_BUDGETS[stage] ?? 0;
  }

  return {
    async execute({ run_id: runId, stage, tool, arguments: args, request_id: requestId, boundContext }) {
      if (!tool || !Object.prototype.hasOwnProperty.call(TOOLS, tool.name)) {
        return { ok: false, code: 'TOOL_NOT_REGISTERED', status: 400, run_id: runId, tool_name: tool?.name ?? null, stage };
      }
      if (!validateStage(stage)) {
        return { ok: false, code: 'INVALID_STAGE', status: 400, run_id: runId, tool_name: tool.name, stage };
      }
      if (!tool.allowed_stages.includes(stage)) {
        return { ok: false, code: 'TOOL_NOT_ALLOWED_IN_STAGE', status: 403, run_id: runId, tool_name: tool.name, stage };
      }

      const cacheKey = `${runId}:${requestId}`;
      if (cache.has(cacheKey)) {
        const cached = cache.get(cacheKey);
        return { ...cached, budget: cached.budget };
      }

      const counterKey = `${runId}:${stage}`;
      const used = counters.get(counterKey) ?? 0;
      const limit = budgetFor(stage);
      if (used >= limit) {
        return { ok: false, code: 'CALL_BUDGET_EXHAUSTED', status: 429, run_id: runId, tool_name: tool.name, stage, call_count: used, budget: { limit, remaining: 0 } };
      }

      const resolver = resolvers[tool.name];
      if (typeof resolver !== 'function') {
        return { ok: false, code: 'TOOL_NOT_REGISTERED', status: 400, run_id: runId, tool_name: tool.name, stage, call_count: used, budget: { limit, remaining: limit - used } };
      }

      counters.set(counterKey, used + 1);
      const callCount = used + 1;

      let result;
      try {
        result = await resolver(args, boundContext);
      } catch (error) {
        return { ok: false, code: 'RESOLVER_FAILED', status: 500, run_id: runId, tool_name: tool.name, stage, call_count: callCount, budget: { limit, remaining: limit - callCount } };
      }

      const responseBytes = safeResponseBytes(result);
      if (responseBytes > responseSizeLimit) {
        return { ok: false, code: 'RESPONSE_TOO_LARGE', status: 413, run_id: runId, tool_name: tool.name, stage, response_bytes: responseBytes, call_count: callCount, budget: { limit, remaining: limit - callCount } };
      }

      const outcome = {
        ok: true,
        run_id: runId,
        tool_name: tool.name,
        stage,
        result,
        response_bytes: responseBytes,
        call_count: callCount,
        budget: { limit, remaining: limit - callCount },
      };
      cache.set(cacheKey, outcome);
      return outcome;
    },
  };
}

module.exports = {
  STAGES,
  STAGE_ORDER,
  STAGE_CALL_BUDGETS,
  SYNTHESIS_ONLY_TOOLS,
  TOOLS,
  TOOL_BUDGETS,
  validateStage,
  validateToolRequest,
  createToolExecutor,
};
