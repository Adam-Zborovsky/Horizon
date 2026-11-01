const mongoose = require('mongoose');

const CHECKPOINT_KINDS = Object.freeze(['rolling_indicator', 'fixed_observed_level', 'business_condition']);
const CHECKPOINT_STATUSES = Object.freeze(['active', 'triggered', 'retired']);
const CHANGE_EVENT_KINDS = Object.freeze(['triggered', 'retired', 'replaced']);

// Contract: docs/horizon/CONTRACTS.md §6 Checkpoint. Rolling indicators
// reference a metric and carry no fixed_level; fixed_observed_level carries
// fixed_level and no metric reference; business conditions carry a condition
// string and neither numeric representation. Every status change appends an
// immutable history entry (previous/current status, why it changed, supporting
// evidence and the assessment that recorded it): triggered/retired/replaced
// checkpoints retain their full history forever.
const changeEventSchema = new mongoose.Schema({
  at: { type: Date, required: true },
  event_kind: { type: String, enum: CHANGE_EVENT_KINDS, required: true },
  previous_status: { type: String, enum: CHECKPOINT_STATUSES, required: true },
  new_status: { type: String, enum: CHECKPOINT_STATUSES, required: true },
  reason: { type: String, required: true, minlength: 1, maxlength: 500 },
  evidence_ids: { type: [String], default: [] },
  source_assessment_id: { type: String, default: null },
  observed_value: { type: Number, default: null },
  replacement_checkpoint_id: { type: String, default: null },
}, { _id: false });

const thesisCheckpointSchema = new mongoose.Schema({
  _id: { type: String, required: true },
  checkpoint_id: { type: String, required: true, unique: true, immutable: true, index: true },
  owner_id_internal: { type: String, required: true, immutable: true, index: true },
  instrument_id: { type: String, required: true, immutable: true, index: true },
  kind: { type: String, enum: CHECKPOINT_KINDS, required: true, immutable: true },
  metric_id: {
    type: String,
    default: null,
    required: function requireMetricForRolling() {
      return this.kind === 'rolling_indicator';
    },
    validate: {
      validator: function validateMetricReference(value) {
        return value == null || this.kind === 'rolling_indicator';
      },
      message: 'metric_id is only permitted on rolling_indicator checkpoints',
    },
  },
  fixed_level: {
    type: Number,
    default: null,
    required: function requireFixedLevelForObserved() {
      return this.kind === 'fixed_observed_level';
    },
    validate: {
      validator: function validateFixedLevel(value) {
        return value == null || this.kind === 'fixed_observed_level';
      },
      message: 'fixed_level is only permitted on fixed_observed_level checkpoints',
    },
  },
  condition: {
    type: String,
    default: null,
    maxlength: 500,
    required: function requireConditionForBusiness() {
      return this.kind === 'business_condition';
    },
  },
  status: { type: String, enum: CHECKPOINT_STATUSES, required: true, index: true },
  reason: { type: String, default: null, maxlength: 500 },
  source_assessment_id: { type: String, default: null },
  predecessor_checkpoint_id: { type: String, default: null, immutable: true },
  replacement_checkpoint_id: { type: String, default: null },
  history: {
    type: [changeEventSchema],
    default: [],
    validate: {
      validator: (list) => list.length <= 500,
      message: 'checkpoint history is bounded at 500 change events',
    },
  },
}, {
  timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' },
  strict: 'throw',
});

// Kind invariants (no masquerading between the three representations) are
// enforced by the metric_id/fixed_level/condition path validators above:
// metric references only on rolling_indicator, fixed levels only on
// fixed_observed_level, required condition text on business_condition.

module.exports = mongoose.models.ThesisCheckpoint
  || mongoose.model('ThesisCheckpoint', thesisCheckpointSchema);
module.exports.CHECKPOINT_KINDS = CHECKPOINT_KINDS;
module.exports.CHECKPOINT_STATUSES = CHECKPOINT_STATUSES;
module.exports.CHANGE_EVENT_KINDS = CHANGE_EVENT_KINDS;
