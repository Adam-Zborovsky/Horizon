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

        const filterNested = (obj) => {
          const filtered = {};
          Object.keys(obj).forEach(key => {
            // If the key is a disabled topic, skip it
            if (disabledTopicNames.includes(key)) return;

            // If the value is an object and not an array, recurse one level deep 
            // This handles news, market, news_intel etc.
            if (typeof obj[key] === 'object' && obj[key] !== null && !Array.isArray(obj[key])) {
              const nestedResult = filterNested(obj[key]);
              if (Object.keys(nestedResult).length > 0) {
                filtered[key] = nestedResult;
              }
            } else {
              // It's a direct category or other data point (like list in market_analyst), keep it if not disabled
              filtered[key] = obj[key];
            }
          });
          return filtered;
        };

        briefingData = filterNested(briefingData);
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
    let parsedData = cleanData;
    
    // Validate and parse JSON if it's a string
    if (typeof cleanData === 'string' && (cleanData.trim().startsWith('{') || cleanData.trim().startsWith('['))) {
      try {
        parsedData = JSON.parse(cleanData);
      } catch (e) {
        console.warn('⚠️ BriefingService: Incoming briefing is INVALID JSON.');
      }
    }

    // Enrich data with sparkline history for all tickers
    const enrichWithHistory = (obj) => {
      if (!obj || typeof obj !== 'object') return;
      
      if (Array.isArray(obj)) {
        obj.forEach(item => enrichWithHistory(item));
      } else {
        if (obj.ticker && (obj.price || obj.sentiment_score || obj.sentiment)) {
          const price = parseFloat(String(obj.price || '0').replace(/[^\d.]/g, '')) || 100.0;
          const change = parseFloat(String(obj.change || '0').replace(/[^\d.+-]/g, '')) || 0.0;
          const sentiment = parseFloat(obj.sentiment_score || obj.sentiment || 0);
          
          if (!obj.history) {
            obj.history = this.generateHistory(price, change, sentiment);
          }
        }
        Object.values(obj).forEach(val => {
          if (typeof val === 'object') enrichWithHistory(val);
        });
      }
    };

    enrichWithHistory(parsedData);

    // VALIDATION: Check if the data is connected to our configuration
    const config = await this.getConfig();
    if (config && config.tickers && config.tickers.length > 0 && typeof parsedData === 'object' && parsedData !== null) {
      const requestedTickers = config.tickers.map(t => t.toUpperCase());
      
      // Extract all tickers mentioned in the briefing
      const foundTickers = new Set();
      
      const findTickers = (obj) => {
        if (!obj || typeof obj !== 'object') return;
        
        if (Array.isArray(obj)) {
          obj.forEach(item => findTickers(item));
        } else {
          if (obj.ticker && typeof obj.ticker === 'string') {
            foundTickers.add(obj.ticker.toUpperCase());
          }
          Object.values(obj).forEach(val => {
            if (typeof val === 'object') findTickers(val);
          });
        }
      };
      
      findTickers(parsedData);
      
      // Check if there is any overlap
      const hasOverlap = requestedTickers.some(t => foundTickers.has(t));
      
      if (!hasOverlap && foundTickers.size > 0) {
        console.warn('⚠️ BriefingService: HALLUCINATION DETECTED.');
        console.warn(`Requested: [${requestedTickers.join(', ')}]`);
        console.warn(`Received: [${Array.from(foundTickers).join(', ')}]`);
        console.warn('Rejecting save and triggering retry...');
        
        this.triggerWorkflow('hallucination_detected_retry');
        
        const error = new Error('Briefing data mismatch: Requested tickers not found in response.');
        error.status = 422;
        throw error;
      }

      if (foundTickers.size === 0 && requestedTickers.length > 0) {
        console.warn('⚠️ BriefingService: No tickers found in briefing data. Checking if this is expected...');
        // If we expect tickers but found none, it might be a partial failure or very broad news
        // We'll allow it but log it, unless it's completely empty
      }
    }

    const briefing = new Briefing({
      data: parsedData, // Use the enriched parsedData
      source: 'n8n',
    });

    return await briefing.save();
  }

  /**
   * Generates a 15-point synthetic history for a ticker
   */
  generateHistory(currentPrice, changePercent, sentiment) {
    if (!currentPrice || currentPrice <= 0) return Array.from({ length: 15 }, () => 10.0);
    
    const points = [];
    let lastVal = parseFloat(currentPrice);
    const change = parseFloat(changePercent) || 0;
    const sent = parseFloat(sentiment) || 0;
    
    points.push(lastVal);
    
    const effectiveChange = change === 0 ? (Math.random() - 0.5) * 0.5 : change;

    for (let i = 0; i < 14; i++) {
      const volatility = lastVal * 0.012;
      const bias = (effectiveChange / 100) * (lastVal / 10);
      const noise = (Math.random() - 0.5) * volatility;
      const sentimentInfluence = sent * (lastVal * 0.002);
      
      lastVal = lastVal - bias + noise - sentimentInfluence;
      if (lastVal < currentPrice * 0.7) lastVal = currentPrice * 0.7 + (Math.random() * 5);
      
      points.unshift(lastVal);
    }
    return points;
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
      const savedConfig = await config.save();
      return savedConfig;
    } catch (saveErr) {
      console.error('⚠️ BriefingService: Save failed. Forcing reset and retry.');
      await BriefingConfig.collection.deleteMany({});
      const freshConfig = new BriefingConfig({ 
        tickers: tickers || [],
        topics: (newTopics || []).map(t => ({ name: t.name, enabled: t.enabled }))
      });
      const savedConfig = await freshConfig.save();
      return savedConfig;
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
      const savedConfig = await config.save();
      return savedConfig;
    } catch (saveErr) {
      console.error('⚠️ BriefingService: Toggle save failed. Resetting.');
      await BriefingConfig.collection.deleteMany({});
      const fresh = new BriefingConfig();
      fresh.topics.push({ name: topicName, enabled: enabled });
      const savedConfig = await fresh.save();
      return savedConfig;
    }
  }

  /**
   * Completely remove a topic from the configuration.
   * @param {string} topicName - The name of the topic to remove.
   */
  async removeTopic(topicName) {
    let config;
    try {
      config = await BriefingConfig.findOne();
      if (!config || !config.topics) return null;
      
      const originalLength = config.topics.length;
      config.topics = config.topics.filter(t => t.name !== topicName);
      
      if (config.topics.length === originalLength) return config; // No change

      return await config.save();
    } catch (err) {
      console.error('BriefingService: Error in removeTopic:', err);
      throw err;
    }
  }

  /**
   * Get recommended topics based on categories found in the latest briefing 
   * that the user isn't already following.
   */
  async getRecommendedTopics() {
    try {
      const briefing = await Briefing.findOne().sort({ createdAt: -1 });
      const config = await BriefingConfig.findOne();
      
      const followedTopics = config ? config.topics.map(t => t.name) : [];
      const recommendedSet = new Set(['Geopolitical Defense & AI Strategy', 'Market Trends & Analysis', 'Tech Innovation & Disruptions', 'Economic Indicators', 'Company News']);

      if (briefing && briefing.data) {
        let briefingData = briefing.data;
        if (typeof briefingData === 'string') {
          try {
            briefingData = JSON.parse(briefingData);
          } catch (e) {
            console.warn('BriefingService: Failed to parse briefing data for recommendations');
          }
        }

        if (typeof briefingData === 'object' && !Array.isArray(briefingData)) {
          const extractTopics = (obj) => {
            Object.keys(obj).forEach(key => {
              if (['news', 'market', 'news_intel', 'market_analyst', 'opportunities', 'opportunity_scout'].includes(key)) {
                if (typeof obj[key] === 'object' && obj[key] !== null && !Array.isArray(obj[key])) {
                  extractTopics(obj[key]);
                }
              } else {
                recommendedSet.add(key);
              }
            });
          };
          extractTopics(briefingData);
        }
      }

      // Filter out already followed topics
      return Array.from(recommendedSet).filter(topic => !followedTopics.includes(topic));
    } catch (err) {
      console.error('BriefingService: Error in getRecommendedTopics:', err);
      return [];
    }
  }

  /**
   * Trigger the external n8n workflow
   * @param {string} reason 
   */
  async triggerWorkflow(reason) {
    const env = require('../../config/env');
    if (!env.N8N_WEBHOOK_URL) {
      console.log(`BriefingService: N8N_WEBHOOK_URL not set. Skipping workflow trigger for "${reason}".`);
      return;
    }

    try {
      console.log(`BriefingService: Triggering n8n workflow via ${env.N8N_WEBHOOK_URL} (Reason: ${reason})...`);
      const response = await fetch(env.N8N_WEBHOOK_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          event: 'config_change',
          reason: reason,
          timestamp: new Date().toISOString()
        })
      });
      
      if (response.ok) {
        console.log('BriefingService: n8n workflow triggered successfully.');
      } else {
        console.warn(`BriefingService: n8n trigger failed with status ${response.status}.`);
      }
    } catch (err) {
      console.error('BriefingService: Failed to trigger n8n workflow:', err.message);
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
