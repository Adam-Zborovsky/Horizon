const mongoose = require('mongoose');

const ASSESSMENT_STATUSES = Object.freeze(['complete', 'limited']);

// Contract: docs/horizon/CONTRACTS.md §5 ResearchAssessment, persisted here in
// its durable-boundary role: one immutable published assessment per run
// (unique run_id), bound to the exact position revision and evidence snapshot
// it was generated against. Published assessments are judgments about prior
// evidence, not evidence themselves (§6): artifact_kind marks that explicitly
// and is immutable. Unavailable/error outcomes belong to the run record
// (§8) — a document with status 'complete' or 'limited' is the only thing
// this collection ever stores.
const researchAssessmentSchema = new mongoose.Schema({
  _id: { type: String, required: true },
  run_id: { type: String, required: true, immutable: true, index: true },
  position_id: { type: String, required: true, immutable: true, index: true },
  owner_id_internal: { type: String, required: true, immutable: true, index: true },
  position_revision: { type: Number, required: true, min: 1, immutable: true },
  instrument_id: { type: String, required: true, immutable: true },
  evidence_snapshot_id: { type: String, required: true, immutable: true },
  generated_at: { type: Date, required: true, immutable: true },
  session_as_of: { type: String, required: true, immutable: true },
  status: { type: String, enum: ASSESSMENT_STATUSES, required: true, immutable: true },
  artifact_kind: { type: String, enum: ['judgment'], required: true, immutable: true },
  assessment: { type: mongoose.Schema.Types.Mixed, required: true, immutable: true },
}, {
  timestamps: { createdAt: 'created_at', updatedAt: false },
  strict: 'throw',
});

// Concurrent callbacks for the same run cannot create duplicate assessments:
// the second insert collides here, and the service resolves the winner
// idempotently instead of writing a second document.
researchAssessmentSchema.index({ run_id: 1 }, { unique: true });
researchAssessmentSchema.index({ owner_id_internal: 1, position_id: 1, generated_at: -1 });

module.exports = mongoose.models.ResearchAssessment
  || mongoose.model('ResearchAssessment', researchAssessmentSchema);
module.exports.ASSESSMENT_STATUSES = ASSESSMENT_STATUSES;
