const Briefing = require('./briefing.model');

class BriefingService {
  /**
   * Get the most recent briefing
   */
  async getLatest() {
    return await Briefing.findOne().sort({ createdAt: -1 });
  }

  /**
   * Save a new briefing
   * @param {Object} data - The briefing data received from agents/n8n
   */
  async save(data) {
    // If the data is wrapped in another object (common from n8n), extract it
    const cleanData = data.data || data;
    
    const briefing = new Briefing({
      data: cleanData,
      source: 'n8n',
    });

    return await briefing.save();
  }

  /**
   * Get historical briefings (paginated)
   * @param {number} page
   * @param {number} limit
   */
  async getHistory(page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    
    const [briefings, total] = await Promise.all([
      Briefing.find().sort({ createdAt: -1 }).skip(skip).limit(limit),
      Briefing.countDocuments(),
    ]);

    return {
      briefings,
      total,
      page,
      limit,
    };
  }
}

module.exports = new BriefingService();
