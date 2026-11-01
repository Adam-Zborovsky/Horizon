const mongoose = require('mongoose');

const evidenceSnapshotSchema = new mongoose.Schema({
  snapshot_id: { type: String, required: true, unique: true, immutable: true, index: true },
  instrument_id: { type: String, required: true, index: true, immutable: true },
  cutoff_at: { type: Date, required: true, index: true, immutable: true },
  session_as_of: { type: String, required: true, immutable: true },
  market_snapshot_ids: { type: [String], default: [], immutable: true },
  evidence_ids: { type: [String], default: [], immutable: true },
  metric_ids: { type: [String], default: [], immutable: true },
  coverage: { type: mongoose.Schema.Types.Mixed, required: true, immutable: true },
  content_digest: { type: String, required: true, immutable: true },
  items: { type: mongoose.Schema.Types.Mixed, required: true, immutable: true },
}, {
  timestamps: { createdAt: 'created_at', updatedAt: false },
  strict: 'throw',
});

evidenceSnapshotSchema.index({ instrument_id: 1, cutoff_at: -1 });

module.exports = mongoose.models.EvidenceSnapshot
  || mongoose.model('EvidenceSnapshot', evidenceSnapshotSchema);
