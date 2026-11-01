const Briefing = require('./briefing.model');
const BriefingConfig = require('./briefing_config.model');
const marketUtil = require('../../utils/market');
const { reconcileLegacyTickerUpdate } = require('../positions/position.service');

// Default active-position source for legacy-ticker derivation (CONTRACTS
// §10): non-archived positions of the owner, projected to the narrow shape
// the compatibility helpers consume ({id, archived, instrument}).
async function defaultListActivePositions(userId) {
  const Position = require('../positions/position.model');
  const docs = await Position.find({ owner_id: String(userId), archived: false })
    .select('instrument archived')
    .lean();
  return docs.map((doc) => ({
    id: String(doc._id),
    archived: Boolean(doc.archived),
    instrument: doc.instrument,
  }));
}

class BriefingService {
  constructor({
    briefingModel = Briefing,
    configModel = BriefingConfig,
    marketDataProvider = marketUtil.fetchStockData,
    listActivePositions = defaultListActivePositions,
    userModel = null,
    workflowFetch = globalThis.fetch,
  } = {}) {
    this.briefingModel = briefingModel;
    this.configModel = configModel;
    this.marketDataProvider = marketDataProvider;
    this.listActivePositions = listActivePositions;
    this.userModel = userModel;
    this.workflowFetch = workflowFetch;
  }

  /**
   * Derive the effective legacy ticker set for a user: the stored config
   * tickers plus the tickers of active (non-archived) positions —
   * provider_symbol when resolved, else the instrument symbol. Uppercased,
   * deduplicated, config order preserved first. Legacy flows (n8n briefing,
   * hallucination guard) consume this set so position instruments stay
   * covered without being re-entered as bare tickers (CONTRACTS §10).
   */
  async getEffectiveTickers(userId) {
    const config = await this.getConfig(userId);
    const effective = [];
    const seen = new Set();
    const push = (ticker) => {
      if (typeof ticker !== 'string') return;
      const normalized = ticker.trim().toUpperCase();
      if (!normalized || seen.has(normalized)) return;
      seen.add(normalized);
      effective.push(normalized);
    };
    (Array.isArray(config.tickers) ? config.tickers : []).forEach(push);
    try {
      const positions = this.listActivePositions
        ? await this.listActivePositions(userId)
        : [];
      for (const position of positions || []) {
        if (!position || position.archived || !position.instrument) continue;
        const instrument = position.instrument;
        push(instrument.provider_symbol || instrument.symbol);
      }
    } catch (err) {
      // Derivation is additive; on lookup failure the stored config set is
      // preserved (never weakened) and the failure is reported.
      console.warn(`BriefingService: active-position ticker derivation failed: ${err.message}`);
    }
    return effective;
  }

  /**
   * Get the most recent briefing for a specific user
   */
  async getLatest(userId) {
    try {
      const briefing = await this.briefingModel.findOne({ user: userId }).sort({ createdAt: -1 });

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
        // AI models sometimes produce trailing commas — strip them and retry
        try {
          const sanitized = cleanData.replace(/,(\s*[}\]])/g, '$1');
          parsedData = JSON.parse(sanitized);
          console.warn('⚠️ BriefingService: Briefing had trailing commas — sanitized and parsed successfully.');
        } catch (e2) {
          console.warn('⚠️ BriefingService: Incoming briefing is INVALID JSON, storing as raw string.');
        }
      }
    }

    // H15B: the legacy synthetic history enrichment was removed. Briefing
    // items carry only what the model reported; observed price history comes
    // exclusively from the market history slice (/api/v1/market), never from
    // Math.random fabrication.

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
    if (typeof parsedData === 'object' && parsedData !== null) {
      // CONTRACTS §10: the hallucination guard compares against the EFFECTIVE
      // ticker set (stored config + active-position derived tickers), so a
      // briefing that covers position instruments is never falsely rejected.
      const effectiveTickers = await this.getEffectiveTickers(userId);
      const requestedTickers = effectiveTickers;
      const hasOverlap = requestedTickers.some(t => foundTickers.has(t));

      if (!hasOverlap && foundTickers.size > 0 && requestedTickers.length > 0) {
        console.warn('⚠️ BriefingService: HALLUCINATION DETECTED.');
        this.triggerWorkflow(userId, 'hallucination_detected_retry');
        
        const error = new Error('Briefing data mismatch: Requested tickers not found in response.');
        error.status = 422;
        throw error;
      }
    }

    try {
      const factualMarketData = await this.marketDataProvider(Array.from(foundTickers));
      const validFactualData = factualMarketData.filter(d => d !== null);

      const updateWithFactualData = (obj) => {
        if (!obj || typeof obj !== 'object') return;
        if (Array.isArray(obj)) {
          obj.forEach(item => updateWithFactualData(item));
        } else {
          if (obj.ticker && typeof obj.ticker === 'string') {
            // Rich currency-denominated price objects (typed data shape,
            // CONTRACTS §1) are authoritative — the legacy tickers-only
            // enrichment must never clobber them with a bare number.
            const hasRichPrice = obj.price !== null && typeof obj.price === 'object';
            if (!hasRichPrice) {
              const factual = validFactualData.find(d => d.ticker.toUpperCase() === obj.ticker.toUpperCase());
              if (factual) {
                obj.price = factual.price;
                obj.change = factual.change;
                if (!obj.name) obj.name = factual.name;
                obj.is_invalid = false;
              } else {
                // Mark as invalid if not found in real market data
                obj.is_invalid = true;
              }
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

    // H15B: no synthetic history enrichment here either — factual compilation
    // only. Items without a model-reported history carry none.

    const briefing = new this.briefingModel({
      user: userId,
      data: parsedData,
      source: data.source || 'n8n',
    });
    return await briefing.save();
  }

  /**
   * Update the briefing configuration for a specific user
   */
  async updateConfig(userId, data) {
    const cleanData = data.data || data;
    const { topics: newTopics, tickers } = cleanData;

    // getConfig() upserts atomically, so the doc always exists before we mutate it.
    let config = await this.getConfig(userId);

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
      if (!Array.isArray(tickers) || tickers.some(t => typeof t !== 'string')) {
        const error = new Error('tickers must be an array of strings.');
        error.status = 400;
        throw error;
      }

      // CONTRACTS §10 / SPEC §5: an old client's stale tickers-only PUT must
      // not wipe tickers that back active positions. The accepted H04
      // reconcile helper classifies removals; conflicting updates are
      // refused explicitly (409 with the blocked removals) instead of a
      // destructive replacement.
      const activePositions = this.listActivePositions
        ? await this.listActivePositions(userId)
        : [];
      const reconciliation = reconcileLegacyTickerUpdate({
        activePositions,
        previousTickers: config.tickers,
        incomingTickers: tickers,
      });
      if (reconciliation.status === 'conflict') {
        const error = new Error(reconciliation.message);
        error.status = 409;
        error.code = 'POSITION_TICKER_CONFLICT';
        error.details = reconciliation.blocked_removals;
        throw error;
      }
      config.tickers = tickers;
    }

    const saved = await config.save();
    
    // Workflow trigger removed from here to follow daily schedule only.
    
    return saved;
  }

  /**
   * Toggle the enabled status of a specific topic for a user.
   */
  async toggleTopic(userId, topicName, enabled) {
    // getConfig() upserts atomically, so the doc always exists before we mutate it.
    const config = await this.getConfig(userId);
    const topic = config.topics.find(t => t.name === topicName);
    if (topic) {
      topic.enabled = enabled;
    } else {
      config.topics.push({ name: topicName, enabled: enabled });
    }

    const saved = await config.save();
    // Workflow trigger removed from here to follow daily schedule only.
    return saved;
  }

  /**
   * Completely remove a topic from the configuration for a user.
   */
  async removeTopic(userId, topicName) {
    const config = await this.configModel.findOne({ user: userId });
    if (!config || !config.topics) return null;
    
    config.topics = config.topics.filter(t => t.name !== topicName);
    const saved = await config.save();
    // Workflow trigger removed from here to follow daily schedule only.
    return saved;
  }

  /**
   * Get recommended topics for a user
   */
  async getRecommendedTopics(userId) {
    try {
      const briefing = await this.briefingModel.findOne({ user: userId }).sort({ createdAt: -1 });
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
      const User = this.userModel || require('../auth/user.model');
      const user = await User.findById(userId);
      if (!user) return;

      // Get user's configuration
      const config = await this.getConfig(userId);

      // CONTRACTS §10: the legacy payload carries the effective ticker set —
      // stored config tickers plus active-position derived tickers — so the
      // legacy workflow keeps covering position instruments.
      const effectiveTickers = await this.getEffectiveTickers(userId);

      console.log(`BriefingService: Triggering n8n workflow for user ${user.username} (Reason: ${reason})...`);

      const response = await this.workflowFetch(env.N8N_WEBHOOK_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          event: 'config_change',
          reason: reason,
          userId: userId,
          username: user.username,
          config: {
            topics: config.topics,
            tickers: effectiveTickers.length > 0 ? effectiveTickers : (config.tickers || []),
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
    // Atomic upsert: two concurrent requests on a fresh account both used to
    // findOne -> miss -> insert, and the loser hit E11000 (user_1 unique index).
    let config = await this.configModel.findOneAndUpdate(
      { user: userId },
      { $setOnInsert: { user: userId } },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );
    return config;
  }

  /**
   * Search for tickers using Yahoo Finance autocomplete
   */
  async searchTickers(query) {
    if (!query || query.length < 1) return [];

    try {
      const url = `https://query1.finance.yahoo.com/v1/finance/search?q=${encodeURIComponent(query)}&quotesCount=10&newsCount=0`;
      const response = await this.workflowFetch(url, {
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

    const briefings = await this.briefingModel.find({
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
   * Get the timestamp of the latest briefing for a user (lightweight check)
   */
  async getLatestTimestamp(userId) {
    const briefing = await this.briefingModel.findOne({ user: userId })
      .sort({ createdAt: -1 })
      .select('createdAt')
      .lean();
    return briefing ? briefing.createdAt : null;
  }

  /**
   * Get historical briefings for a user
   */
  async getHistory(userId, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    
    const [briefings, total] = await Promise.all([
      this.briefingModel.find({ user: userId }).sort({ createdAt: -1 }).skip(skip).limit(limit),
      this.briefingModel.countDocuments({ user: userId }),
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
module.exports.BriefingService = BriefingService;
