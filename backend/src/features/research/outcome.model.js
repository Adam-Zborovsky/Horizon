const mongoose = require('mongoose');

const FORECAST_DIRECTIONS = Object.freeze(['positive', 'negative', 'mixed', 'insufficient_evidence']);
const STRATEGY_KINDS = Object.freeze(['strategy_appropriate', 'no_change', 'no_llm']);
const LEDGER_STATUSES = Object.freeze(['pending', 'settled']);
const HORIZON_MONTHS = Object.freeze([1, 2, 3]);

// Contract: docs/horizon/CONTRACTS.md §10 forward outcome ledger, plus
// docs/horizon/evidence/evaluation-protocol.md (frozen H16 protocol). One
// append-only record per (assessment, horizon). The forecast half
// (assessment identity, direction, issue/evaluation dates, benchmark,
// strategy and version snapshot) is immutable at write time; the outcome
// half (status pending->settled, realized_outcome, settled_at) is appended
// exactly once by the service and never rewritten. Storage-level uniqueness
// on (assessment_id, horizon_months) and (ledger_id) backs the service's
// idempotency and rewrite-prevention guarantees.
const forecastLedgerEntrySchema = new mongoose.Schema({
  _id: { type: String, required: true },
  ledger_id: { type: String, required: true, unique: true, immutable: true, index: true },
  owner_id_internal: { type: String, required: true, immutable: true, index: true },
  assessment_id: { type: String, required: true, immutable: true, index: true },
  instrument_id: { type: String, required: true, immutable: true, index: true },
  horizon_months: { type: Number, enum: HORIZON_MONTHS, required: true, immutable: true },
  direction: { type: String, enum: FORECAST_DIRECTIONS, required: true, immutable: true },
  issue_session_date: { type: String, required: true, immutable: true },
  evaluation_session_date: { type: String, required: true, immutable: true },
  benchmark: { type: mongoose.Schema.Types.Mixed, required: true, immutable: true },
  strategy: { type: mongoose.Schema.Types.Mixed, required: true, immutable: true },
  versions: { type: mongoose.Schema.Types.Mixed, required: true, immutable: true },
  status: { type: String, enum: LEDGER_STATUSES, required: true, index: true },
  realized_outcome: { type: mongoose.Schema.Types.Mixed, default: null },
  settled_at: { type: Date, default: null },
  created_at: { type: Date, required: true, immutable: true },
}, {
  timestamps: false,
  strict: 'throw',
});

// One forecast per assessment horizon: a second insert collides here and the
// service resolves the winner idempotently (identical spec) or rejects the
// rewrite (differing spec) instead of writing a second document.
forecastLedgerEntrySchema.index({ assessment_id: 1, horizon_months: 1 }, { unique: true });
forecastLedgerEntrySchema.index({ owner_id_internal: 1, instrument_id: 1, status: 1 });

module.exports = mongoose.models.ForecastLedgerEntry
  || mongoose.model('ForecastLedgerEntry', forecastLedgerEntrySchema);
module.exports.FORECAST_DIRECTIONS = FORECAST_DIRECTIONS;
module.exports.STRATEGY_KINDS = STRATEGY_KINDS;
module.exports.LEDGER_STATUSES = LEDGER_STATUSES;
module.exports.HORIZON_MONTHS = HORIZON_MONTHS;
