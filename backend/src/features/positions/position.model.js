const mongoose = require('mongoose');

const POSITION_STATES = Object.freeze(['candidate', 'owned', 'legacy_unclassified']);
const COST_BASES = Object.freeze(['raw_purchase', 'split_reconciled']);
const ISO_CURRENCY = /^[A-Z]{3}$/;
const DECIMAL_STRING = /^[0-9]+(\.[0-9]+)?$/;
const DATE_ONLY = /^(\d{4})-(\d{2})-(\d{2})$/;
// Must agree with the service's authoritative assertDecimalString bound:
// <= 18 total digits, <= 12 fraction digits, strictly positive.
const MAX_TOTAL_DIGITS = 18;
const MAX_FRACTION_DIGITS = 12;

function isPositiveDecimalString(value) {
  if (typeof value !== 'string' || !DECIMAL_STRING.test(value)) return false;
  const [intPart, fracPart = ''] = value.split('.');
  if (intPart.length + fracPart.length > MAX_TOTAL_DIGITS) return false;
  if (fracPart.length > MAX_FRACTION_DIGITS) return false;
  return BigInt(intPart + fracPart) > 0n;
}

function isIsoCurrency(value) {
  return typeof value === 'string' && ISO_CURRENCY.test(value);
}

function isCalendarDateOnly(value) {
  if (typeof value !== 'string') return false;
  const match = DATE_ONLY.exec(value);
  if (!match) return false;
  const [, year, month, day] = match;
  const date = new Date(Date.UTC(Number(year), Number(month) - 1, Number(day)));
  return date.getUTCFullYear() === Number(year)
    && date.getUTCMonth() === Number(month) - 1
    && date.getUTCDate() === Number(day);
}

const averageCostSchema = new mongoose.Schema({
  amount: {
    type: String,
    required: true,
    validate: {
      validator: isPositiveDecimalString,
      message: 'average_cost.amount must be a strictly positive bounded decimal string',
    },
  },
  currency: {
    type: String,
    required: true,
    validate: {
      validator: isIsoCurrency,
      message: 'average_cost.currency must be an ISO 4217 uppercase currency code',
    },
  },
  basis: {
    type: String,
    enum: COST_BASES,
    default: 'raw_purchase',
  },
}, { _id: false });

const instrumentSchema = new mongoose.Schema({
  instrument_id: { type: String, required: true, immutable: true },
  symbol: { type: String, required: true, immutable: true },
  exchange: { type: String, default: null, immutable: true },
  currency: {
    type: String,
    default: null,
    immutable: true,
    validate: {
      validator: (value) => value === null || isIsoCurrency(value),
      message: 'instrument.currency must be an ISO 4217 uppercase currency code or null',
    },
  },
  provider_symbol: { type: String, default: null, immutable: true },
}, { _id: false });

// Durable, fail-closed mutex for publication of an assessment for one exact
// position revision. It deliberately has no expiry: a timed unlock could let
// a delayed publisher insert after a newer position edit.
const publicationGuardSchema = new mongoose.Schema({
  token: { type: String, required: true, immutable: true },
  assessment_id: { type: String, required: true, immutable: true },
  position_revision: { type: Number, required: true, min: 1, immutable: true },
  acquired_at: { type: Date, required: true, immutable: true },
}, { _id: false });

const positionSchema = new mongoose.Schema({
  // Opaque string identifiers per CONTRACTS §1: pos-<uuid> from the service
  // idFactory and deterministic legacy-mig-* migration ids. Must remain a
  // String — Mongoose's default ObjectId type would reject both.
  _id: { type: String },
  // Server-derived owner from JWT; never writable by clients.
  owner_id: { type: String, required: true, immutable: true, index: true },
  instrument: { type: instrumentSchema, required: true },
  state: { type: String, enum: POSITION_STATES, required: true },
  average_cost: {
    type: averageCostSchema,
    default: null,
    validate: {
      validator: function validateAverageCostForState(value) {
        // Candidate and legacy_unclassified records never carry executed economics.
        if (this.state === 'owned') return true;
        return value === null || value === undefined;
      },
      message: 'average_cost is forbidden while state is not owned: no executed cost may be inferred',
    },
  },
  quantity: {
    type: String,
    default: null,
    validate: {
      validator: function validateQuantityForState(value) {
        if (this.state !== 'owned') return value === null || value === undefined;
        return value === null || isPositiveDecimalString(value);
      },
      message: 'quantity must be null or a strictly positive bounded decimal string (fractional shares allowed); forbidden while state is not owned',
    },
  },
  opened_on: {
    type: String,
    default: null,
    validate: {
      validator: function validateOpenedOnForState(value) {
        if (this.state !== 'owned') return value === null || value === undefined;
        return value === null || isCalendarDateOnly(value);
      },
      message: 'opened_on must be null or a valid exchange-local session date (YYYY-MM-DD); forbidden while state is not owned',
    },
  },
  preferred_horizon_months: { type: Number, enum: [1, 2, 3], default: 3 },
  original_thesis: { type: String, default: '', maxlength: 5000 },
  review_conditions: {
    type: [String],
    default: [],
    validate: {
      validator: (list) => list.length <= 20 && list.every((c) => typeof c === 'string' && c.length > 0 && c.length <= 500),
      message: 'review_conditions must be at most 20 non-empty strings of at most 500 characters',
    },
  },
  risk_context: { type: mongoose.Schema.Types.Mixed, default: null },
  archived: { type: Boolean, default: false, index: true },
  revision: { type: Number, min: 1, default: 1 },
  // Internal synchronization state; never exposed by position serialization.
  publication_guard: { type: publicationGuardSchema, default: null, select: false },
}, {
  timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' },
  strict: 'throw',
});

// Duplicate active identity guard: one active position per owner + instrument.
// Archived documents are excluded so re-tracking after archival is possible.
positionSchema.index(
  { owner_id: 1, 'instrument.instrument_id': 1 },
  { unique: true, partialFilterExpression: { archived: false } },
);

module.exports = mongoose.models.Position || mongoose.model('Position', positionSchema);
module.exports.POSITION_STATES = POSITION_STATES;
module.exports.COST_BASES = COST_BASES;
