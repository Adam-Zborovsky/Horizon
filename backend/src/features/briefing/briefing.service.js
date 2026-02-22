const Briefing = require('./briefing.model');
const BriefingConfig = require('./briefing_config.model');

class BriefingService {
  /**
   * Get the most recent briefing
   */
  async getLatest() {
    try {
      const briefing = await Briefing.findOne().sort({ createdAt: -1 });
      
      let config;
      try {
        config = await BriefingConfig.findOne();
      } catch (e) {
        console.warn('⚠️ BriefingService: Config corrupted in getLatest. Resetting DB config.');
        await BriefingConfig.collection.deleteMany({});
        config = null;
      }

      if (!briefing) {
        console.log('BriefingService: No latest briefing found in database.');
        return null;
      }

      let briefingData = briefing.data;

      // If data is a string (common from n8n), try to parse it
      if (typeof briefingData === 'string') {
        try {
          briefingData = JSON.parse(briefingData);
        } catch (e) {
          console.error('BriefingService: Failed to parse briefing data string:', e.message);
        }
      }

      // Filter briefing data based on enabled topics
      if (config && config.topics && typeof briefingData === 'object' && briefingData !== null && !Array.isArray(briefingData)) {
        const disabledTopicNames = config.topics
          .filter(t => t.enabled === false)
          .map(t => t.name);

        const allCategories = Object.keys(briefingData);
        const filteredData = {};
        
        allCategories.forEach(categoryName => {
          if (!disabledTopicNames.includes(categoryName)) {
            filteredData[categoryName] = briefingData[categoryName];
          }
        });
        briefingData = filteredData;
      }

      return {
        _id: briefing._id,
        data: briefingData,
        source: briefing.source,
        createdAt: briefing.createdAt,
        updatedAt: briefing.updatedAt,
      };
    } catch (err) {
      console.error('BriefingService: Error in getLatest:', err);
      return null;
    }
  }

  /**
   * Save a new briefing
   * @param {Object} data - The briefing data received from agents/n8n
   */
  async save(data) {
    const cleanData = data.data || data;
    
    // Validate JSON if it's a string
    if (typeof cleanData === 'string' && (cleanData.trim().startsWith('{') || cleanData.trim().startsWith('['))) {
      try {
        JSON.parse(cleanData);
      } catch (e) {
        console.warn('⚠️ BriefingService: Incoming briefing is INVALID JSON.');
      }
    }

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
    console.log('BriefingService: Updating config...');
    const cleanData = data.data || data;
    const { topics: newTopics, tickers } = cleanData;

    let config;
    try {
      config = await BriefingConfig.findOne();
      // Test if document is valid by accessing its properties
      if (config && (!config.topics || !Array.isArray(config.topics))) {
        throw new Error('Topics is not an array');
      }
    } catch (err) {
      console.warn('⚠️ BriefingService: Corruption detected in updateConfig. Wiping.');
      await BriefingConfig.collection.deleteMany({});
      config = new BriefingConfig();
    }

    if (!config) {
      config = new BriefingConfig();
    }

    if (newTopics && Array.isArray(newTopics)) {
      config.topics = [];
      for (const newTopic of newTopics) {
        if (newTopic && newTopic.name) {
          config.topics.push({ 
            name: newTopic.name, 
            enabled: typeof newTopic.enabled === 'boolean' ? newTopic.enabled : true 
          });
        }
      }
    }
    
    if (tickers) {
      config.tickers = tickers;
    }

    try {
      return await config.save();
    } catch (saveErr) {
      console.error('⚠️ BriefingService: Save failed. Forcing reset and retry.');
      await BriefingConfig.collection.deleteMany({});
      const freshConfig = new BriefingConfig({ 
        tickers: tickers || [],
        topics: (newTopics || []).map(t => ({ name: t.name, enabled: t.enabled }))
      });
      return await freshConfig.save();
    }
  }

  /**
   * Toggle the enabled status of a specific topic.
   * @param {string} topicName - The name of the topic to toggle.
   * @param {boolean} enabled - The desired enabled status.
   */
  async toggleTopic(topicName, enabled) {
    let config;
    try {
      config = await BriefingConfig.findOne();
      if (config && (!config.topics || !Array.isArray(config.topics))) {
        throw new Error('Topics is not an array');
      }
    } catch (err) {
      console.warn('⚠️ BriefingService: Corruption in toggleTopic. Resetting.');
      await BriefingConfig.collection.deleteMany({});
      config = new BriefingConfig();
    }

    if (!config) {
      config = new BriefingConfig();
      config.topics.push({ name: topicName, enabled: enabled });
    } else {
      const topic = config.topics.find(t => t.name === topicName);
      if (topic) {
        topic.enabled = enabled;
      } else {
        config.topics.push({ name: topicName, enabled: enabled });
      }
    }
    
    try {
      return await config.save();
    } catch (saveErr) {
      console.error('⚠️ BriefingService: Toggle save failed. Resetting.');
      await BriefingConfig.collection.deleteMany({});
      const fresh = new BriefingConfig();
      fresh.topics.push({ name: topicName, enabled: enabled });
      return await fresh.save();
    }
  }

  /**
   * Get the global briefing configuration
   */
  async getConfig() {
    try {
      const config = await BriefingConfig.findOne();
      if (config && (!config.topics || !Array.isArray(config.topics))) {
        throw new Error('Topics is not an array');
      }
      return config;
    } catch (err) {
      console.warn('⚠️ BriefingService: Corruption in getConfig. Resetting.');
      await BriefingConfig.collection.deleteMany({});
      return new BriefingConfig();
    }
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
