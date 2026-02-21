const mongoose = require('mongoose');

const briefingSchema = new mongoose.Schema({
  data: {
    type: mongoose.Schema.Types.Mixed,
    required: true,
  },
  source: {
    type: String,
    enum: ['n8n', 'manual', 'agent'],
    default: 'n8n',
  },
  createdAt: {
    type: Date,
    default: Date.now,
    index: true,
  }
}, {
  timestamps: true,
});

// Always retrieve the latest briefing by default when queried
briefingSchema.index({ createdAt: -1 });

module.exports = mongoose.model('Briefing', briefingSchema);
