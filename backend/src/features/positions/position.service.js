const crypto = require('node:crypto');
const PositionModel = require('./position.model');

const SCALE = 12n; // fixed-point scale for decimal money/quantity arithmetic
const SCALE_EXP = 12;
const ROUND_TO = 8; // decimal places kept in P/L outputs
const MAX_TOTAL_DIGITS = 18;
const MAX_FRACTION_DIGITS = 12;
const MAX_PRICE = 1e15;
const MAX_THESIS_LENGTH = 5000;
const MAX_REVIEW_CONDITIONS = 20;
const MAX_REVIEW_CONDITION_LENGTH = 500;

const POSITION_STATES = PositionModel.POSITION_STATES;

// Explicit user actions only; never auto-convert a hypothetical into a transaction.
const ALLOWED_TRANSITIONS = Object.freeze({
  candidate: Object.freeze(['owned']),
  owned: Object.freeze(['candidate']),
  legacy_unclassified: Object.freeze(['candidate', 'owned']),
});

const ALLOWED_FIELDS = Object.freeze([
  'state', 'instrument', 'average_cost', 'quantity', 'opened_on',
  'preferred_horizon_months', 'original_thesis', 'review_conditions',
  'risk_context', 'archived',
]);
const ALLOWED_FIELD_SET = new Set(ALLOWED_FIELDS);

const OWNER_FIELD_NAMES = Object.freeze(['owner_id', 'user_id', 'owner', 'userId']);
const ECONOMICS_FIELDS = Object.freeze(['average_cost', 'quantity', 'opened_on']);
const ISO_CURRENCY = /^[A-Z]{3}$/;
const DECIMAL_STRING = /^[0-9]+(\.[0-9]+)?$/;
const DATE_ONLY = /^(\d{4})-(\d{2})-(\d{2})$/;

function serviceError(code, message) {
  const error = new Error(message);
  error.code = code;
  return error;
}

// Legacy tickers are unresolved strings: nothing about exchange, currency,
// cost or ownership may be inferred from them.
function legacyInstrumentId(ticker) {
  return `legacy-ticker-${String(ticker).toUpperCase()}`;
}

// ---------------------------------------------------------------------------
// Decimal helpers — bounded decimal strings, fixed-point BigInt arithmetic
// ---------------------------------------------------------------------------
function assertDecimalString(value, field) {
  if (typeof value !== 'string' || !DECIMAL_STRING.test(value)) {
    throw serviceError('INVALID_DECIMAL', `${field} must be a bounded decimal string of digits (no signs, exponents, or separators)`);
  }
  const [intPart, fracPart = ''] = value.split('.');
  if (intPart.length + fracPart.length > MAX_TOTAL_DIGITS) {
    throw serviceError('INVALID_DECIMAL', `${field} exceeds ${MAX_TOTAL_DIGITS} total digits`);
  }
  if (fracPart.length > MAX_FRACTION_DIGITS) {
    throw serviceError('INVALID_DECIMAL', `${field} exceeds ${MAX_FRACTION_DIGITS} fraction digits`);
  }
  const scaled = BigInt(intPart + fracPart.padEnd(SCALE_EXP, '0').slice(0, SCALE_EXP));
  if (scaled === 0n) {
    throw serviceError('INVALID_DECIMAL', `${field} must be strictly positive`);
  }
  return scaled;
}

function numberToScaled(value, field) {
  if (typeof value !== 'number' || !Number.isFinite(value)) {
    throw serviceError('INVALID_QUOTE', `${field} must be a finite JSON number`);
  }
  if (value <= 0) {
    throw serviceError('INVALID_QUOTE', `${field} must be strictly positive`);
  }
  if (value >= MAX_PRICE) {
    throw serviceError('INVALID_QUOTE', `${field} exceeds the supported magnitude`);
  }
  let text = String(value);
  if (text.includes('e') || text.includes('E')) {
    text = value.toFixed(SCALE_EXP);
  }
  return assertDecimalString(text, field);
}

// Round a fixed-point value at SCALE_EXP decimals half-up (away from zero) to `places`.
function roundScaled(scaledValue, places) {
  const drop = 10n ** BigInt(SCALE_EXP - places);
  const half = drop / 2n;
  const negative = scaledValue < 0n;
  const magnitude = negative ? -scaledValue : scaledValue;
  const quotient = magnitude / drop;
  const remainder = magnitude % drop;
  const rounded = remainder * 2n >= drop ? quotient + 1n : quotient;
  return negative ? -rounded : rounded;
}

function scaledToString(scaledValue, places = SCALE_EXP) {
  const negative = scaledValue < 0n;
  const magnitude = negative ? -scaledValue : scaledValue;
  const digits = magnitude.toString().padStart(places + 1, '0');
  const intPart = digits.slice(0, digits.length - places);
  let fracPart = digits.slice(digits.length - places).replace(/0+$/, '');
  let text = fracPart ? `${intPart}.${fracPart}` : intPart;
  if (negative) text = `-${text}`;
  return text;
}

function multiplyScaled(a, b) {
  // Both at SCALE_EXP: product is at 2*SCALE_EXP; rescale with half-up rounding.
  const product = a * b;
  const drop = 10n ** SCALE;
  const quotient = product / drop;
  const remainder = product % drop;
  const rounded = remainder * 2n >= drop ? quotient + 1n : quotient;
  return rounded; // back at SCALE_EXP
}

// ---------------------------------------------------------------------------
// Field validation
// ---------------------------------------------------------------------------
function assertIsoCurrency(value, field) {
  if (typeof value !== 'string' || !ISO_CURRENCY.test(value)) {
    throw serviceError('INVALID_CURRENCY', `${field} must be an ISO 4217 uppercase currency code`);
  }
}

function assertDateOnly(value, field) {
  if (typeof value !== 'string' || !DATE_ONLY.test(value)) {
    throw serviceError('INVALID_DATE', `${field} must be a date-only string (YYYY-MM-DD)`);
  }
  const [, year, month, day] = DATE_ONLY.exec(value);
  const date = new Date(Date.UTC(Number(year), Number(month) - 1, Number(day)));
  if (date.getUTCFullYear() !== Number(year)
    || date.getUTCMonth() !== Number(month) - 1
    || date.getUTCDate() !== Number(day)) {
    throw serviceError('INVALID_DATE', `${field} is not a valid calendar date: ${value}`);
  }
}

function validateAverageCost(value) {
  if (value === null || value === undefined) return null;
  if (typeof value !== 'object' || Array.isArray(value)) {
    throw serviceError('INVALID_INPUT', 'average_cost must be an object or null');
  }
  for (const key of Object.keys(value)) {
    if (!['amount', 'currency', 'basis'].includes(key)) {
      throw serviceError('UNKNOWN_FIELD', `average_cost.${key} is not an accepted field`);
    }
  }
  if (value.amount === undefined || value.currency === undefined) {
    throw serviceError('INVALID_INPUT', 'average_cost requires amount and currency');
  }
  const amount = assertDecimalString(value.amount, 'average_cost.amount');
  assertIsoCurrency(value.currency, 'average_cost.currency');
  const basis = value.basis === undefined ? 'raw_purchase' : value.basis;
  if (!PositionModel.COST_BASES.includes(basis)) {
    throw serviceError('INVALID_INPUT', `average_cost.basis must be one of ${PositionModel.COST_BASES.join(', ')}`);
  }
  return { amount: value.amount, currency: value.currency, basis };
}

function validateQuantity(value) {
  if (value === null || value === undefined) return null;
  assertDecimalString(value, 'quantity');
  return value;
}

function validateOpenedOn(value) {
  if (value === null || value === undefined) return null;
  assertDateOnly(value, 'opened_on');
  return value;
}

function validateInstrument(value) {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) {
    throw serviceError('INVALID_INSTRUMENT', 'instrument must be an object');
  }
  for (const key of Object.keys(value)) {
    if (!['instrument_id', 'symbol', 'exchange', 'currency', 'provider_symbol'].includes(key)) {
      throw serviceError('UNKNOWN_FIELD', `instrument.${key} is not an accepted field`);
    }
  }
  const { instrument_id, symbol, exchange = null, currency = null, provider_symbol = null } = value;
  if (typeof instrument_id !== 'string' || instrument_id.length === 0) {
    throw serviceError('INVALID_INSTRUMENT', 'instrument.instrument_id is required');
  }
  if (typeof symbol !== 'string' || symbol.length === 0) {
    throw serviceError('INVALID_INSTRUMENT', 'instrument.symbol is required');
  }
  for (const [field, val] of [['exchange', exchange], ['provider_symbol', provider_symbol]]) {
    if (val !== null && typeof val !== 'string') {
      throw serviceError('INVALID_INSTRUMENT', `instrument.${field} must be a string or null`);
    }
  }
  if (currency !== null) assertIsoCurrency(currency, 'instrument.currency');
  return { instrument_id, symbol, exchange, currency, provider_symbol };
}

function validateEconomicsForState(state, economics) {
  if (state === 'candidate' || state === 'legacy_unclassified') {
    for (const field of ECONOMICS_FIELDS) {
      if (economics[field] !== null && economics[field] !== undefined) {
        throw serviceError(
          'INVALID_CANDIDATE_ECONOMICS',
          `${field} is forbidden for state ${state}: no executed cost/quantity/open date may be inferred`,
        );
      }
    }
    return { average_cost: null, quantity: null, opened_on: null };
  }
  return {
    average_cost: validateAverageCost(economics.average_cost),
    quantity: validateQuantity(economics.quantity),
    opened_on: validateOpenedOn(economics.opened_on),
  };
}

function rejectWritableOwnerFields(payload) {
  if (typeof payload !== 'object' || payload === null) return;
  for (const field of OWNER_FIELD_NAMES) {
    if (field in payload) {
      throw serviceError('OWNER_FIELD_NOT_WRITABLE', `${field} is server-derived from the authenticated identity and never writable`);
    }
  }
}

function rejectUnknownFields(payload, label) {
  for (const key of Object.keys(payload)) {
    if (!ALLOWED_FIELD_SET.has(key)) {
      throw serviceError('UNKNOWN_FIELD', `${label}.${key} is not an accepted field`);
    }
  }
}

function serialize(doc) {
  return {
    id: doc.id,
    instrument: structuredClone(doc.instrument),
    state: doc.state,
    average_cost: doc.average_cost ? structuredClone(doc.average_cost) : null,
    quantity: doc.quantity,
    opened_on: doc.opened_on,
    preferred_horizon_months: doc.preferred_horizon_months,
    // H11 cross-lane empty-thesis repair: the wire never carries an empty
    // original_thesis — a stored '' (pre-repair default, legacy rows) is
    // normalized to null so optionalBoundedText on the Dart side parses it.
    original_thesis: doc.original_thesis === '' ? null : doc.original_thesis,
    review_conditions: [...(doc.review_conditions || [])],
    risk_context: doc.risk_context ? structuredClone(doc.risk_context) : null,
    archived: doc.archived,
    revision: doc.revision,
    created_at: doc.created_at,
    updated_at: doc.updated_at,
  };
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------
class PositionService {
  constructor({
    positionRepository,
    now = () => new Date(),
    idFactory = () => `pos-${crypto.randomUUID()}`,
  } = {}) {
    if (!positionRepository
      || typeof positionRepository.findActive !== 'function'
      || typeof positionRepository.listByOwner !== 'function'
      || typeof positionRepository.findById !== 'function'
      || typeof positionRepository.insert !== 'function'
      || typeof positionRepository.update !== 'function') {
      throw new TypeError('PositionService requires a position repository');
    }
    this.repository = positionRepository;
    this.now = now;
    this.idFactory = idFactory;
  }

  async list(ownerId) {
    const docs = await this.repository.listByOwner(String(ownerId));
    return docs.map(serialize);
  }

  async get(ownerId, id) {
    const doc = await this.repository.findById(String(id));
    if (!doc || doc.owner_id !== String(ownerId)) {
      // Indistinguishable: not-found and not-owned are the same denial.
      throw serviceError('NOT_FOUND', 'Position not found');
    }
    return serialize(doc);
  }

  async create(ownerId, input) {
    if (typeof input !== 'object' || input === null || Array.isArray(input)) {
      throw serviceError('INVALID_INPUT', 'request body must be a JSON object');
    }
    rejectWritableOwnerFields(input);
    rejectUnknownFields(input, 'position');

    if (!POSITION_STATES.includes(input.state)) {
      throw serviceError('INVALID_STATE', `state must be one of ${POSITION_STATES.join(', ')}`);
    }
    const instrument = validateInstrument(input.instrument);
    const economics = validateEconomicsForState(input.state, {
      average_cost: input.average_cost,
      quantity: input.quantity,
      opened_on: input.opened_on,
    });

    const preferred = input.preferred_horizon_months === undefined ? 3 : input.preferred_horizon_months;
    if (![1, 2, 3].includes(preferred)) {
      throw serviceError('INVALID_INPUT', 'preferred_horizon_months must be 1, 2 or 3');
    }
    // H11 cross-lane empty-thesis repair: absent original_thesis defaults to
    // null (never ''). Validation is unchanged for strings (type + overlength);
    // an explicit null is treated as absent per CONTRACTS §2 (optional field).
    const thesis = input.original_thesis === undefined ? null : input.original_thesis;
    if (thesis !== null && (typeof thesis !== 'string' || thesis.length > MAX_THESIS_LENGTH)) {
      throw serviceError('INVALID_INPUT', `original_thesis must be a string of at most ${MAX_THESIS_LENGTH} characters`);
    }
    const conditions = input.review_conditions === undefined ? [] : input.review_conditions;
    if (!Array.isArray(conditions) || conditions.length > MAX_REVIEW_CONDITIONS
      || conditions.some((c) => typeof c !== 'string' || c.length === 0 || c.length > MAX_REVIEW_CONDITION_LENGTH)) {
      throw serviceError('INVALID_INPUT', `review_conditions must be at most ${MAX_REVIEW_CONDITIONS} non-empty strings of at most ${MAX_REVIEW_CONDITION_LENGTH} characters`);
    }
    if (input.risk_context !== undefined && input.risk_context !== null
      && (typeof input.risk_context !== 'object' || Array.isArray(input.risk_context))) {
      throw serviceError('INVALID_INPUT', 'risk_context must be an object or null');
    }
    if (input.archived !== undefined && typeof input.archived !== 'boolean') {
      throw serviceError('INVALID_INPUT', 'archived must be a boolean');
    }

    const duplicate = await this.repository.findActive(String(ownerId), instrument.instrument_id);
    if (duplicate) {
      throw serviceError('DUPLICATE_POSITION', 'An active position for this instrument already exists');
    }

    const now = this.now();
    const doc = {
      id: this.idFactory(),
      owner_id: String(ownerId),
      instrument,
      state: input.state,
      average_cost: economics.average_cost,
      quantity: economics.quantity,
      opened_on: economics.opened_on,
      preferred_horizon_months: preferred,
      original_thesis: thesis,
      review_conditions: conditions,
      risk_context: input.risk_context === undefined ? null : input.risk_context,
      archived: input.archived === undefined ? false : input.archived,
      revision: 1,
      created_at: now.toISOString(),
      updated_at: now.toISOString(),
    };
    const inserted = await this.repository.insert(doc);
    return serialize(inserted);
  }

  async update(ownerId, id, { expected_revision: expectedRevision, changes } = {}) {
    if (typeof changes !== 'object' || changes === null || Array.isArray(changes)) {
      throw serviceError('INVALID_INPUT', 'changes must be a JSON object of explicitly changed fields');
    }
    rejectWritableOwnerFields(changes);
    rejectUnknownFields(changes, 'changes');

    if (expectedRevision === undefined || expectedRevision === null) {
      throw serviceError('MISSING_EXPECTED_REVISION', 'expected_revision is required for optimistic concurrency');
    }
    if (!Number.isInteger(expectedRevision) || expectedRevision < 1) {
      throw serviceError('INVALID_INPUT', 'expected_revision must be a positive integer');
    }

    const doc = await this.repository.findById(String(id));
    if (!doc || doc.owner_id !== String(ownerId)) {
      throw serviceError('NOT_FOUND', 'Position not found');
    }
    if (doc.revision !== expectedRevision) {
      throw serviceError('REVISION_CONFLICT', `expected_revision ${expectedRevision} does not match current revision ${doc.revision}`);
    }

    const next = structuredClone(doc);
    let targetState = doc.state;
    if (changes.state !== undefined && changes.state !== doc.state) {
      if (!POSITION_STATES.includes(changes.state)) {
        throw serviceError('INVALID_STATE', `state must be one of ${POSITION_STATES.join(', ')}`);
      }
      if (!ALLOWED_TRANSITIONS[doc.state].includes(changes.state)) {
        throw serviceError('INVALID_TRANSITION', `transition ${doc.state} -> ${changes.state} is not allowed`);
      }
      targetState = changes.state;
    }
    next.state = targetState;

    // Owned -> candidate after closing clears active economics (reversible archival of history stays via revision).
    const clearEconomics = doc.state === 'owned' && targetState === 'candidate';

    if (changes.average_cost !== undefined || clearEconomics) {
      next.average_cost = clearEconomics && changes.average_cost === undefined
        ? null
        : validateAverageCost(changes.average_cost === undefined ? next.average_cost : changes.average_cost);
    }
    if (changes.quantity !== undefined || clearEconomics) {
      next.quantity = clearEconomics && changes.quantity === undefined
        ? null
        : validateQuantity(changes.quantity === undefined ? next.quantity : changes.quantity);
    }
    if (changes.opened_on !== undefined || clearEconomics) {
      next.opened_on = clearEconomics && changes.opened_on === undefined
        ? null
        : validateOpenedOn(changes.opened_on === undefined ? next.opened_on : changes.opened_on);
    }
    // Transitioned-into states without executed economics must not keep any.
    validateEconomicsForState(targetState, {
      average_cost: next.average_cost,
      quantity: next.quantity,
      opened_on: next.opened_on,
    });

    if (changes.preferred_horizon_months !== undefined) {
      if (![1, 2, 3].includes(changes.preferred_horizon_months)) {
        throw serviceError('INVALID_INPUT', 'preferred_horizon_months must be 1, 2 or 3');
      }
      next.preferred_horizon_months = changes.preferred_horizon_months;
    }
    if (changes.original_thesis !== undefined) {
      if (typeof changes.original_thesis !== 'string' || changes.original_thesis.length > MAX_THESIS_LENGTH) {
        throw serviceError('INVALID_INPUT', `original_thesis must be a string of at most ${MAX_THESIS_LENGTH} characters`);
      }
      next.original_thesis = changes.original_thesis;
    }
    if (changes.review_conditions !== undefined) {
      const conditions = changes.review_conditions;
      if (!Array.isArray(conditions) || conditions.length > MAX_REVIEW_CONDITIONS
        || conditions.some((c) => typeof c !== 'string' || c.length === 0 || c.length > MAX_REVIEW_CONDITION_LENGTH)) {
        throw serviceError('INVALID_INPUT', `review_conditions must be at most ${MAX_REVIEW_CONDITIONS} non-empty strings of at most ${MAX_REVIEW_CONDITION_LENGTH} characters`);
      }
      next.review_conditions = conditions;
    }
    if (changes.risk_context !== undefined) {
      if (changes.risk_context !== null
        && (typeof changes.risk_context !== 'object' || Array.isArray(changes.risk_context))) {
        throw serviceError('INVALID_INPUT', 'risk_context must be an object or null');
      }
      next.risk_context = changes.risk_context;
    }
    if (changes.archived !== undefined) {
      if (typeof changes.archived !== 'boolean') {
        throw serviceError('INVALID_INPUT', 'archived must be a boolean');
      }
      if (doc.archived && changes.archived === false) {
        const duplicate = await this.repository.findActive(doc.owner_id, doc.instrument.instrument_id);
        if (duplicate && duplicate.id !== doc.id) {
          throw serviceError('DUPLICATE_POSITION', 'Another active position for this instrument already exists');
        }
      }
      next.archived = changes.archived;
    }

    next.revision = doc.revision + 1;
    next.updated_at = this.now().toISOString();
    const saved = await this.repository.update(next);
    return serialize(saved);
  }

  // Code-calculated P/L. Percent requires valid cost and a current price in
  // matching currency and a compatible split basis; absolute additionally
  // requires quantity. Never approximates FX and never infers missing values.
  computeProfitLoss(position, { current_price: currentPrice, currency, adjustment_basis: adjustmentBasis = 'raw' }) {
    if (position.state !== 'owned') {
      return { status: 'unavailable', reason: 'position_not_owned' };
    }
    if (!position.average_cost) {
      // Unknown cost stays null: ask in UI, never invent.
      return { status: 'unavailable', reason: 'unknown_cost' };
    }
    const price = numberToScaled(currentPrice, 'current_price');
    const cost = assertDecimalString(position.average_cost.amount, 'average_cost.amount');
    assertIsoCurrency(position.average_cost.currency, 'average_cost.currency');
    if (currency !== position.average_cost.currency) {
      return { status: 'unavailable', reason: 'currency_mismatch' };
    }
    const costBasis = position.average_cost.basis || 'raw_purchase';
    const requiredBasis = costBasis === 'raw_purchase' ? 'raw' : 'split_adjusted';
    if (adjustmentBasis !== requiredBasis) {
      return {
        status: 'unavailable',
        reason: 'split_basis_unreconciled',
        explanation: `cost basis is ${costBasis}; current price basis is ${adjustmentBasis}`,
      };
    }

    const difference = price - cost; // scale 12
    // percent = (price - cost) / cost * 100, computed at scale 12 with half-up division rounding
    const percentNumerator = difference * 100n * (10n ** SCALE);
    const percentQuotient = percentNumerator / cost;
    const percentRemainder = percentNumerator % cost;
    const percentScaled = percentRemainder * 2n >= cost ? percentQuotient + 1n : percentQuotient;
    const result = {
      status: 'available',
      percent: scaledToString(roundScaled(percentScaled, ROUND_TO), ROUND_TO),
      absolute: null,
      fees_included: false,
      dividends_included: false,
      label: 'user cost reference, not market support or fair value',
    };
    if (position.quantity) {
      const quantity = assertDecimalString(position.quantity, 'quantity');
      const absoluteScaled = multiplyScaled(difference, quantity);
      result.absolute = {
        amount: scaledToString(roundScaled(absoluteScaled, ROUND_TO), ROUND_TO),
        currency: position.average_cost.currency,
      };
    }
    return result;
  }
}

// ---------------------------------------------------------------------------
// Migration planner — pure functions over isolated fixture data.
// Additive, dry-run-first, reversible at the document level.
// Legacy tickers import as legacy_unclassified with null economics: no cost,
// quantity, open date, currency or exchange is inferred from a bare ticker.
// ---------------------------------------------------------------------------
function planLegacyMigration({ configs, existingPositions = [], now = new Date() }) {
  const configsList = Array.isArray(configs) ? configs : [];
  const activeByKey = new Set();
  for (const position of existingPositions) {
    if (!position || position.archived) continue;
    if (!position.owner_id || !position.instrument) continue;
    activeByKey.add(`${position.owner_id}|${position.instrument.instrument_id}`);
  }

  const changes = [];
  let tickersSeen = 0;
  let duplicatesSkipped = 0;
  const timestamp = now instanceof Date ? now.toISOString() : new Date(now).toISOString();

  for (const config of configsList) {
    if (!config || !config.owner_id) continue;
    const tickers = Array.isArray(config.tickers) ? config.tickers : [];
    const seenPerOwner = new Set();
    for (const rawTicker of tickers) {
      if (typeof rawTicker !== 'string') continue;
      const ticker = rawTicker.trim().toUpperCase();
      if (!ticker || seenPerOwner.has(ticker)) continue;
      seenPerOwner.add(ticker);
      tickersSeen += 1;

      const instrumentId = legacyInstrumentId(ticker);
      if (activeByKey.has(`${config.owner_id}|${instrumentId}`)) {
        duplicatesSkipped += 1;
        continue;
      }
      const positionId = `legacy-mig-${config.owner_id}-${ticker}`;
      changes.push({
        op: 'insert_position',
        collection: 'positions',
        position_id: positionId,
        owner_id: config.owner_id,
        document: {
          id: positionId,
          owner_id: config.owner_id,
          instrument: {
            instrument_id: instrumentId,
            symbol: ticker,
            exchange: null,
            currency: null,
            provider_symbol: null,
          },
          state: 'legacy_unclassified',
          average_cost: null,
          quantity: null,
          opened_on: null,
          preferred_horizon_months: 3,
          original_thesis: '',
          review_conditions: [],
          risk_context: null,
          archived: false,
          revision: 1,
          created_at: timestamp,
          updated_at: timestamp,
        },
      });
    }
  }

  return {
    migration: 'positions-legacy-unclassified',
    dry_run: true,
    generated_at: timestamp,
    source_counts: {
      briefing_configs_scanned: configsList.filter((c) => c && c.owner_id).length,
      tickers_seen: tickersSeen,
    },
    planned: {
      positions_to_create: changes.length,
      duplicates_skipped: duplicatesSkipped,
    },
    changes,
    rollback: {
      description: 'Reversible at the document level: delete exactly the positions this migration inserted, identified by their deterministic legacy-mig-* ids. Users, briefings and existing tickers are untouched.',
      steps: changes.map((change) => ({
        op: 'delete_position_by_id',
        collection: 'positions',
        position_id: change.position_id,
      })),
    },
  };
}

// Stale legacy tickers update policy (CONTRACTS §10): legacy tickers are
// derived from active positions and an old client's tickers-only PUT must not
// wipe positions through stale replacement. Conflicting updates are
// bounded/explicit, never destructive.
function reconcileLegacyTickerUpdate({ activePositions = [], previousTickers = [], incomingTickers = [] }) {
  const normalize = (list) => (Array.isArray(list) ? list : [])
    .filter((t) => typeof t === 'string')
    .map((t) => t.trim().toUpperCase())
    .filter(Boolean);
  const previous = normalize(previousTickers);
  const incoming = normalize(incomingTickers);
  const previousSet = new Set(previous);
  const incomingSet = new Set(incoming);

  const additions = incoming.filter((t) => !previousSet.has(t));
  const removals = previous.filter((t) => !incomingSet.has(t));

  const allowedRemovals = [];
  const blockedRemovals = [];
  for (const ticker of removals) {
    const dependents = activePositions.filter((p) => p && !p.archived && p.instrument && (
      p.instrument.instrument_id === legacyInstrumentId(ticker)
      || (typeof p.instrument.symbol === 'string' && p.instrument.symbol.toUpperCase() === ticker)
    ));
    if (dependents.length > 0) {
      blockedRemovals.push({ ticker, active_position_ids: dependents.map((p) => p.id) });
    } else {
      allowedRemovals.push(ticker);
    }
  }

  const conflict = blockedRemovals.length > 0;
  return {
    status: conflict ? 'conflict' : 'ok',
    additions,
    allowed_removals: allowedRemovals,
    blocked_removals: blockedRemovals,
    message: conflict
      ? 'Stale tickers-only update refused: removing tickers that back active positions is destructive replacement. Classify/archive those positions explicitly, then retry.'
      : 'Legacy ticker update accepted; positions derived from active positions are unaffected.',
  };
}

// ---------------------------------------------------------------------------
// Mongoose repository adapter (used by the real app; tests inject fakes)
// ---------------------------------------------------------------------------
function mapRecord(record) {
  if (!record) return null;
  const plain = typeof record.toObject === 'function' ? record.toObject({ depopulate: true }) : record;
  return {
    id: String(plain._id),
    owner_id: plain.owner_id,
    instrument: structuredClone(plain.instrument),
    state: plain.state,
    average_cost: plain.average_cost ? structuredClone(plain.average_cost) : null,
    quantity: plain.quantity,
    opened_on: plain.opened_on,
    preferred_horizon_months: plain.preferred_horizon_months,
    original_thesis: plain.original_thesis,
    review_conditions: [...(plain.review_conditions || [])],
    risk_context: plain.risk_context ? structuredClone(plain.risk_context) : null,
    archived: plain.archived,
    revision: plain.revision,
    created_at: plain.created_at instanceof Date ? plain.created_at.toISOString() : plain.created_at,
    updated_at: plain.updated_at instanceof Date ? plain.updated_at.toISOString() : plain.updated_at,
  };
}

function createMongoosePositionRepository(model = PositionModel) {
  return {
    async findActive(ownerId, instrumentId) {
      const record = await model.findOne({
        owner_id: String(ownerId),
        'instrument.instrument_id': instrumentId,
        archived: false,
      }).lean();
      return mapRecord(record);
    },
    async listByOwner(ownerId) {
      const records = await model.find({ owner_id: String(ownerId) }).sort({ created_at: 1 }).lean();
      return records.map(mapRecord);
    },
    async findById(id) {
      const record = await model.findById(id).lean();
      return mapRecord(record);
    },
    async insert(doc) {
      const created = await model.create({ ...doc, _id: doc.id });
      return mapRecord(created);
    },
    async update(doc) {
      const record = await model.findById(doc.id);
      if (!record) throw serviceError('NOT_FOUND', 'Position not found');
      record.set({
        state: doc.state,
        average_cost: doc.average_cost,
        quantity: doc.quantity,
        opened_on: doc.opened_on,
        preferred_horizon_months: doc.preferred_horizon_months,
        original_thesis: doc.original_thesis,
        review_conditions: doc.review_conditions,
        risk_context: doc.risk_context,
        archived: doc.archived,
        revision: doc.revision,
      });
      const saved = await record.save();
      return mapRecord(saved);
    },
  };
}

module.exports = {
  PositionService,
  createMongoosePositionRepository,
  planLegacyMigration,
  reconcileLegacyTickerUpdate,
  legacyInstrumentId,
  serviceError,
  ALLOWED_TRANSITIONS,
};
