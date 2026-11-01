const mongoose = require('mongoose');

const RUN_KINDS = Object.freeze(['deep_research', 'daily_update', 'manual_refresh']);
const RUN_STATUSES = Object.freeze(['queued', 'running', 'succeeded', 'limited', 'failed', 'stalled', 'superseded']);
const TERMINAL_STATUSES = Object.freeze(['succeeded', 'limited', 'failed', 'stalled', 'superseded']);

// Contract: docs/horizon/CONTRACTS.md §8 ResearchRun. All identifiers are
// opaque strings (§1); _id must stay a String — service-assigned run-<uuid>
// ids are not ObjectIds. lease_nonce / lease_expires_at materialize the
// H03 createRunCallbackAuthorizer interface (docs/horizon/evidence/h03-quality.md
// observation 3): the helper reads them from the run record and fails closed
// when absent, so they are nullable here and set only on a successful claim.
const researchRunSchema = new mongoose.Schema({
  _id: { type: String, required: true },
  position_id: { type: String, required: true, immutable: true, index: true },
  owner_id_internal: { type: String, required: true, immutable: true, index: true },
  position_revision: { type: Number, required: true, min: 1, immutable: true },
  run_kind: { type: String, enum: RUN_KINDS, required: true, immutable: true },
  request_class: { type: String, enum: RUN_KINDS, required: true, immutable: true },
  idempotency_key: { type: String, required: true, minlength: 1, maxlength: 255, immutable: true },
  payload_digest: { type: String, required: true, minlength: 64, maxlength: 64, immutable: true },
  status: { type: String, enum: RUN_STATUSES, required: true, index: true },
  stage: { type: String, required: true, minlength: 1, maxlength: 80 },
  created_at: { type: Date, required: true, immutable: true },
  started_at: { type: Date, default: null },
  heartbeat_at: { type: Date, default: null },
  deadline_at: { type: Date, required: true, immutable: true },
  finished_at: { type: Date, default: null },
  evidence_snapshot_id: { type: String, default: null },
  assessment_id: { type: String, default: null },
  error_code: { type: String, default: null, maxlength: 120 },
  retry_count: { type: Number, min: 0, max: 2, default: 0 },
  lease_nonce: { type: String, default: null },
  lease_expires_at: { type: Date, default: null },
  input_snapshot_id: { type: String, required: true, immutable: true },
  run_input_ref: { type: mongoose.Schema.Types.Mixed, required: true, immutable: true },
  run_result_ref: { type: mongoose.Schema.Types.Mixed, default: null },
  versions: { type: mongoose.Schema.Types.Mixed, required: true },
}, {
  timestamps: false,
  strict: 'throw',
});

// Persisted idempotency: one run per owner + position + idempotency key,
// enforced at the storage layer so concurrent queue requests collide here.
researchRunSchema.index(
  { owner_id_internal: 1, position_id: 1, idempotency_key: 1 },
  { unique: true },
);

// At most one active run per position revision and request class. The partial
// filter keeps terminal history unlimited while making double-claims of the
// same request class impossible at the storage layer.
researchRunSchema.index(
  { position_id: 1, position_revision: 1, request_class: 1 },
  {
    unique: true,
    partialFilterExpression: { status: { $in: ['queued', 'running'] } },
  },
);

module.exports = mongoose.models.ResearchRun
  || mongoose.model('ResearchRun', researchRunSchema);
module.exports.RUN_KINDS = RUN_KINDS;
module.exports.RUN_STATUSES = RUN_STATUSES;
module.exports.TERMINAL_STATUSES = TERMINAL_STATUSES;
