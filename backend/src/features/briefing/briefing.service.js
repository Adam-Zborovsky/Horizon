const Briefing = require('./briefing.model');
const BriefingConfig = require('./briefing_config.model');

class BriefingService {
  /**
   * Get the most recent briefing
   */
  async getLatest() {
    const briefing = await Briefing.findOne().sort({ createdAt: -1 });
    const config = await BriefingConfig.findOne();

    if (!briefing) {
      return null;
    }

    let briefingData = briefing.data;

    // Filter briefing data based on enabled topics
    if (config && config.topics && Array.isArray(briefingData)) {
      briefingData = briefingData.filter(category => {
        const categoryName = Object.keys(category)[0];
        const enabledTopic = config.topics.find(t => t.name === categoryName);
        return enabledTopic ? enabledTopic.enabled : false;
      });
    }

    return {
      _id: briefing._id,
      data: briefingData,
      source: briefing.source,
      createdAt: briefing.createdAt,
      updatedAt: briefing.updatedAt,
    };
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
   * Update the global briefing configuration (topics/tickers)
   * @param {Object} data - { topics: Array, tickers: Array }
   */
  async updateConfig(data) {
    const cleanData = data.data || data;
    const { topics: newTopics, tickers } = cleanData;

    let config = await BriefingConfig.findOne();
    if (!config) {
      config = new BriefingConfig();
    }

    if (newTopics && Array.isArray(newTopics)) {
      const existingTopics = config.topics.map(t => t.name);
      const updatedTopics = [];

      for (const newTopic of newTopics) {
        const existingTopicIndex = config.topics.findIndex(t => t.name === newTopic.name);
        if (existingTopicIndex !== -1) {
          // Update existing topic's enabled status
          config.topics[existingTopicIndex].enabled = newTopic.enabled;
        } else {
          // Add new topic
          config.topics.push({ name: newTopic.name, enabled: newTopic.enabled });
        }
      }
      // Remove any topics from the config that are not in the newTopics array
      config.topics = config.topics.filter(existingTopic =>
        newTopics.some(newTopic => newTopic.name === existingTopic.name)
      );
    }
    
    if (tickers) {
      config.tickers = tickers;
    }

    return await config.save();
  }

  /**
   * Toggle the enabled status of a specific topic.
   * @param {string} topicName - The name of the topic to toggle.
   * @param {boolean} enabled - The desired enabled status.
   */
  async toggleTopic(topicName, enabled) {
    let config = await BriefingConfig.findOne();
    if (!config) {
      // If no config exists, create one with default topics and the specified topic toggled
      config = new BriefingConfig();
      const topicToToggle = config.topics.find(t => t.name === topicName);
      if (topicToToggle) {
        topicToToggle.enabled = enabled;
      } else {
        config.topics.push({ name: topicName, enabled: enabled });
      }
    } else {
      const topic = config.topics.find(t => t.name === topicName);
      if (topic) {
        topic.enabled = enabled;
      } else {
        // If topic doesn't exist, add it.
        config.topics.push({ name: topicName, enabled: enabled });
      }
    }
    return await config.save();
  }

  /**
   * Get the global briefing configuration
   */
  async getConfig() {
    return await BriefingConfig.findOne();
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
