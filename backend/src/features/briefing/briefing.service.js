const Briefing = require('./briefing.model');
const BriefingConfig = require('./briefing_config.model');
const marketUtil = require('../../utils/market');

class BriefingService {
  /**
   * Get the most recent briefing for a specific user
   */
  async getLatest(userId) {
    try {
      const briefing = await Briefing.findOne({ user: userId }).sort({ createdAt: -1 });
      
      let config = await this.getConfig(userId);

      if (!briefing) {
        console.log(`BriefingService: No latest briefing found for user ${userId}.`);
        return null;
      }

      let briefingData = briefing.data;

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
            if (disabledTopicNames.includes(key)) return;

            if (typeof obj[key] === 'object' && obj[key] !== null && !Array.isArray(obj[key])) {
              const nestedResult = filterNested(obj[key]);
              if (Object.keys(nestedResult).length > 0) {
                filtered[key] = nestedResult;
              }
            } else {
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
   * Save a new briefing for a specific user
   */
  async save(userId, data) {
    const cleanData = data.data || data;
    let parsedData = cleanData;
    
    if (typeof cleanData === 'string' && (cleanData.trim().startsWith('{') || cleanData.trim().startsWith('['))) {
      try {
        parsedData = JSON.parse(cleanData);
      } catch (e) {
        console.warn('⚠️ BriefingService: Incoming briefing is INVALID JSON.');
      }
    }

    const enrichWithHistory = (obj) => {
      if (!obj || typeof obj !== 'object') return;
      if (Array.isArray(obj)) {
        obj.forEach(item => enrichWithHistory(item));
      } else {
        if (obj.ticker && (obj.price || obj.sentiment_score || obj.sentiment)) {
          const rawPrice = String(obj.price || '0').replace(/[^\d.]/g, '');
          const price = parseFloat(rawPrice) || 0;
          const change = parseFloat(String(obj.change || '0').replace(/[^\d.+-]/g, '')) || 0.0;
          const sentiment = parseFloat(obj.sentiment_score || obj.sentiment || 0);
          
          if (!obj.history && price > 0) {
            obj.history = this.generateHistory(price, change, sentiment);
          }
        }
        Object.values(obj).forEach(val => {
          if (typeof val === 'object') enrichWithHistory(val);
        });
      }
    };

    enrichWithHistory(parsedData);

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

    const config = await this.getConfig(userId);
    if (config && config.tickers && config.tickers.length > 0 && typeof parsedData === 'object' && parsedData !== null) {
      const requestedTickers = config.tickers.map(t => t.toUpperCase());
      const hasOverlap = requestedTickers.some(t => foundTickers.has(t));
      
      if (!hasOverlap && foundTickers.size > 0) {
        console.warn('⚠️ BriefingService: HALLUCINATION DETECTED.');
        this.triggerWorkflow(userId, 'hallucination_detected_retry');
        
        const error = new Error('Briefing data mismatch: Requested tickers not found in response.');
        error.status = 422;
        throw error;
      }
    }

    try {
      const factualMarketData = await marketUtil.fetchStockData(Array.from(foundTickers));
      const validFactualData = factualMarketData.filter(d => d !== null);

      const updateWithFactualData = (obj) => {
        if (!obj || typeof obj !== 'object') return;
        if (Array.isArray(obj)) {
          obj.forEach(item => updateWithFactualData(item));
        } else {
          if (obj.ticker && typeof obj.ticker === 'string') {
            const factual = validFactualData.find(d => d.ticker.toUpperCase() === obj.ticker.toUpperCase());
            if (factual) {
              obj.price = factual.price;
              obj.change = factual.change;
              if (!obj.name) obj.name = factual.name;
            }
          }
          Object.values(obj).forEach(val => {
            if (typeof val === 'object') updateWithFactualData(val);
          });
        }
      };

      updateWithFactualData(parsedData);
    } catch (err) {
      console.error('BriefingService: Failed to compile market data:', err.message); 
    }

    enrichWithHistory(parsedData);

    const briefing = new Briefing({
      user: userId,
      data: parsedData,
      source: data.source || 'n8n',
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
   * Update the briefing configuration for a specific user
   */
  async updateConfig(userId, data) {
    const cleanData = data.data || data;
    const { topics: newTopics, tickers } = cleanData;

    let config = await BriefingConfig.findOne({ user: userId });

    if (!config) {
      config = new BriefingConfig({ user: userId });
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

    const saved = await config.save();
    
    // Trigger workflow because config changed
    this.triggerWorkflow(userId, 'config_update');
    
    return saved;
  }

  /**
   * Toggle the enabled status of a specific topic for a user.
   */
  async toggleTopic(userId, topicName, enabled) {
    let config = await BriefingConfig.findOne({ user: userId });

    if (!config) {
      config = new BriefingConfig({ user: userId });
      config.topics.push({ name: topicName, enabled: enabled });
    } else {
      const topic = config.topics.find(t => t.name === topicName);
      if (topic) {
        topic.enabled = enabled;
      } else {
        config.topics.push({ name: topicName, enabled: enabled });
      }
    }
    
    const saved = await config.save();
    this.triggerWorkflow(userId, 'topic_toggle');
    return saved;
  }

  /**
   * Completely remove a topic from the configuration for a user.
   */
  async removeTopic(userId, topicName) {
    const config = await BriefingConfig.findOne({ user: userId });
    if (!config || !config.topics) return null;
    
    config.topics = config.topics.filter(t => t.name !== topicName);
    const saved = await config.save();
    this.triggerWorkflow(userId, 'topic_remove');
    return saved;
  }

  /**
   * Get recommended topics for a user
   */
  async getRecommendedTopics(userId) {
    try {
      const briefing = await Briefing.findOne({ user: userId }).sort({ createdAt: -1 });
      const config = await this.getConfig(userId);
      
      const followedTopics = config ? config.topics.map(t => t.name) : [];
      const recommendedSet = new Set(['Geopolitical Defense & AI Strategy', 'Market Trends & Analysis', 'Tech Innovation & Disruptions', 'Economic Indicators', 'Company News']);

      if (briefing && briefing.data) {
        let briefingData = briefing.data;
        if (typeof briefingData === 'string') {
          try {
            briefingData = JSON.parse(briefingData);
          } catch (e) {}
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

      return Array.from(recommendedSet).filter(topic => !followedTopics.includes(topic));
    } catch (err) {
      console.error('BriefingService: Error in getRecommendedTopics:', err);
      return [];
    }
  }

  /**
   * Trigger the external n8n workflow for a specific user
   */
  async triggerWorkflow(userId, reason) {
    const env = require('../../config/env');
    if (!env.N8N_WEBHOOK_URL) {
      console.log(`BriefingService: N8N_WEBHOOK_URL not set. Skipping workflow trigger.`);
      return;
    }

    try {
      // Find user to get username
      const User = require('../auth/user.model');
      const user = await User.findById(userId);
      if (!user) return;

      // Get user's configuration
      const config = await this.getConfig(userId);

      console.log(`BriefingService: Triggering n8n workflow for user ${user.username} (Reason: ${reason})...`);
      
      const response = await fetch(env.N8N_WEBHOOK_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          event: 'config_change',
          reason: reason,
          userId: userId,
          username: user.username,
          config: {
            topics: config.topics,
            tickers: config.tickers
          },
          timestamp: new Date().toISOString()
        })
      });
      
      if (response.ok) {
        console.log('BriefingService: n8n workflow triggered successfully.');
      }
    } catch (err) {
      console.error('BriefingService: Failed to trigger n8n workflow:', err.message);
    }
  }

  /**
   * Get the briefing configuration for a user
   */
  async getConfig(userId) {
    let config = await BriefingConfig.findOne({ user: userId });
    if (!config) {
      config = new BriefingConfig({ user: userId });
      await config.save();
    }
    return config;
  }

  /**
   * Search for tickers using Yahoo Finance autocomplete
   */
  async searchTickers(query) {
    if (!query || query.length < 1) return [];

    try {
      const url = `https://query1.finance.yahoo.com/v1/finance/search?q=${encodeURIComponent(query)}&quotesCount=10&newsCount=0`;
      const response = await fetch(url, {
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36'
        }
      });

      if (!response.ok) {
        throw new Error(`Yahoo Finance search returned ${response.status}`);
      }

      const data = await response.json();
      return (data.quotes || []).map(q => ({
        symbol: q.symbol,
        name: q.shortname || q.longname || q.symbol,
        exch: q.exchDisp || q.exchange,
        type: q.quoteType
      }));
    } catch (err) {
      console.error('BriefingService: Error searching tickers:', err.message);
      return [];
    }
  }

  /**
   * Get Opportunity Scout appearance stats for a specific ticker
   * Returns how many times the ticker appeared in the last 30 days
   * and the current consecutive trading-day streak.
   */
  async getOpportunityStats(userId, ticker) {
    const upperTicker = ticker.toUpperCase();
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const briefings = await Briefing.find({
      user: userId,
      createdAt: { $gte: thirtyDaysAgo },
    }).sort({ createdAt: -1 });

    // Helper: check if a briefing's data contains ticker in opportunities
    const tickerInOpportunities = (data) => {
      if (!data || typeof data !== 'object') return false;
      const opportunityKeys = ['opportunities', 'opportunity_scout'];
      for (const key of opportunityKeys) {
        const section = data[key];
        if (Array.isArray(section)) {
          if (section.some(item => item && typeof item.ticker === 'string' && item.ticker.toUpperCase() === upperTicker)) {
            return true;
          }
        }
      }
      return false;
    };

    // Trading days: Mon–Fri (simple check, no holiday calendar)
    const isTradingDay = (date) => {
      const day = date.getDay();
      return day !== 0 && day !== 6;
    };

    let totalLast30Days = 0;
    let consecutiveTradingDays = 0;
    let lastSeen = null;

    // Collect all dates where ticker appeared (most recent first)
    const appearanceDates = [];
    for (const briefing of briefings) {
      let data = briefing.data;
      if (typeof data === 'string') {
        try { data = JSON.parse(data); } catch (e) { continue; }
      }
      if (tickerInOpportunities(data)) {
        totalLast30Days++;
        appearanceDates.push(new Date(briefing.createdAt));
      }
    }

    if (appearanceDates.length > 0) {
      lastSeen = appearanceDates[0];

      // Calculate consecutive trading-day streak from today backwards
      // Walk backward through trading days and check if ticker appeared on each
      const appearanceDateStrings = new Set(
        appearanceDates.map(d => d.toISOString().split('T')[0])
      );

      let cursor = new Date();
      cursor.setHours(0, 0, 0, 0);

      // If today is not a trading day, start from last trading day
      while (!isTradingDay(cursor)) {
        cursor.setDate(cursor.getDate() - 1);
      }

      // Walk back counting consecutive trading days with appearances
      let checking = new Date(cursor);
      while (true) {
        if (!isTradingDay(checking)) {
          checking.setDate(checking.getDate() - 1);
          continue;
        }
        const dateStr = checking.toISOString().split('T')[0];
        if (appearanceDateStrings.has(dateStr)) {
          consecutiveTradingDays++;
          checking.setDate(checking.getDate() - 1);
        } else {
          break;
        }
      }
    }

    return { totalLast30Days, consecutiveTradingDays, lastSeen };
  }

  /**
   * Get historical briefings for a user
   */
  async getHistory(userId, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    
    const [briefings, total] = await Promise.all([
      Briefing.find({ user: userId }).sort({ createdAt: -1 }).skip(skip).limit(limit),
      Briefing.countDocuments({ user: userId }),
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
