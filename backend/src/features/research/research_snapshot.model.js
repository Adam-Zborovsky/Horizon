const mongoose = require('mongoose');

// Contract: docs/horizon/CONTRACTS.md §8 immutable input references. A
// ResearchSnapshot pins exactly what a run was asked to do at queue time:
// the canonical request payload, its SHA-256 digest, the position revision
// and the instrument binding. It is written once at queueRun and never
// mutated — restart recovery and callback validation compare against this
// record instead of trusting later claims. Personal position context lives
// here (owner-scoped collection), so it must never enter shared caches.
const researchSnapshotSchema = new mongoose.Schema({
  snapshot_id: { type: String, required: true, unique: true, immutable: true, index: true },
  run_id: { type: String, required: true, immutable: true, index: true },
  owner_id_internal: { type: String, required: true, immutable: true, index: true },
  position_id: { type: String, required: true, immutable: true },
  position_revision: { type: Number, required: true, min: 1, immutable: true },
  instrument_id: { type: String, required: true, immutable: true },
  payload_digest: { type: String, required: true, minlength: 64, maxlength: 64, immutable: true },
  request_payload: { type: mongoose.Schema.Types.Mixed, required: true, immutable: true },
  created_at: { type: Date, required: true, immutable: true },
}, {
  timestamps: { createdAt: 'created_at', updatedAt: false },
  strict: 'throw',
});

researchSnapshotSchema.index({ run_id: 1 }, { unique: true });

module.exports = mongoose.models.ResearchSnapshot
  || mongoose.model('ResearchSnapshot', researchSnapshotSchema);
