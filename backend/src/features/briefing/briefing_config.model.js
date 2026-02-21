const mongoose = require('mongoose');

const briefingConfigSchema = new mongoose.Schema({
  topics: [
    { name: 'Geopolitical Defense & AI Strategy', enabled: true },
    { name: 'Market Trends & Analysis', enabled: true },
    { name: 'Tech Innovation & Disruptions', enabled: true },
    { name: 'Economic Indicators', enabled: true },
    { name: 'Company News', enabled: true },
  ],
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
