const mongoose = require('mongoose');

const topicSchema = new mongoose.Schema({
  name: { type: String, required: true },
  enabled: { type: Boolean, default: true },
}, { _id: false }); // _id: false if you don't need an ID for subdocuments

const briefingConfigSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true,
  },
  topics: {
    type: [topicSchema],
    default: [
      { name: 'Geopolitical Defense & AI Strategy', enabled: true },
      { name: 'Market Trends & Analysis', enabled: true },
      { name: 'Tech Innovation & Disruptions', enabled: true },
      { name: 'Economic Indicators', enabled: true },
      { name: 'Company News', enabled: true },
    ],
  },
  tickers: {
    type: [String],
    default: [],
  },
}, {
  timestamps: true,
});

// Since we only have one configuration for now, we'll use a single document
// or just always retrieve the latest.
module.exports = mongoose.model('BriefingConfig', briefingConfigSchema);

