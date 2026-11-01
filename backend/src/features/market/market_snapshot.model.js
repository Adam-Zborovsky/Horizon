const mongoose = require('mongoose');

const marketSnapshotSchema = new mongoose.Schema({
  snapshot_id: { type: String, required: true, unique: true, immutable: true, index: true },
  cache_key: { type: String, required: true, index: true, immutable: true },
  instrument_id: { type: String, required: true, index: true, immutable: true },
  range: { type: String, required: true, immutable: true },
  requested_resolution: { type: String, required: true, immutable: true },
  fetched_at: { type: Date, required: true, immutable: true },
  expires_at: { type: Date, required: true, index: true, immutable: true },
  response: { type: mongoose.Schema.Types.Mixed, required: true, immutable: true },
}, {
  timestamps: { createdAt: 'created_at', updatedAt: false },
  strict: 'throw',
});

marketSnapshotSchema.index({ cache_key: 1, fetched_at: -1 });

module.exports = mongoose.models.MarketSnapshot
  || mongoose.model('MarketSnapshot', marketSnapshotSchema);
