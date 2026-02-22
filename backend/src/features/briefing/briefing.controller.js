const briefingService = require('./briefing.service');

class BriefingController {
  /**
   * GET /api/v1/briefing
   * Returns the latest available briefing for the app
   */
  async getLatest(req, res, next) {
    try {
      const briefing = await briefingService.getLatest();
      
      if (!briefing) {
        return res.status(200).json({
          success: true,
          data: {},
          message: 'No briefing available yet.',
        });
      }

      res.status(200).json({
        success: true,
        data: briefing.data,
        metadata: {
          id: briefing._id,
          createdAt: briefing.createdAt,
        },
      });
    } catch (err) {
      next(err);
    }
  }

  /**
   * POST /api/v1/briefing
   * Receives new data from n8n and updates the latest state
   */
  async save(req, res, next) {
    try {
      const briefing = await briefingService.save(req.body);
      
      res.status(201).json({
        success: true,
        data: briefing.data,
        message: 'Briefing saved successfully.',
      });
    } catch (err) {
      next(err);
    }
  }

  /**
   * PUT /api/v1/briefing/config/topic/:topicName
   * Toggles the enabled status of a specific topic
   */
  async toggleTopic(req, res, next) {
    try {
      const { topicName } = req.params;
      const { enabled } = req.body;

      if (typeof enabled === 'undefined') {
        return res.status(400).json({
          success: false,
          message: 'The "enabled" status is required in the request body.',
        });
      }

      const config = await briefingService.toggleTopic(topicName, enabled);
      
      res.status(200).json({
        success: true,
        data: config,
        message: `Topic "${topicName}" enabled status updated to ${enabled}.`,
      });
    } catch (err) {
      next(err);
    }
  }

  /**
   * POST /webhook/update-briefing-config
   * Receives updated topics/tickers from the frontend
   */
  async updateConfig(req, res, next) {

    try {
      const config = await briefingService.updateConfig(req.body);
      
      res.status(200).json({
        success: true,
        data: config,
        message: 'Briefing configuration updated successfully.',
      });
    } catch (err) {
      next(err);
    }
  }

  /**
   * POST /api/v1/briefing/trigger
   * Manually triggers the briefing generation workflow
   */
  async triggerManual(req, res, next) {
    try {
      await briefingService.triggerWorkflow('manual_trigger');
      
      res.status(200).json({
        success: true,
        message: 'Briefing generation triggered successfully.',
      });
    } catch (err) {
      next(err);
    }
  }

  /**
   * GET /api/v1/briefing/config
   * Returns the current topics and tickers configuration
   */
  async getConfig(req, res, next) {
    try {
      const config = await briefingService.getConfig();
      
      res.status(200).json({
        success: true,
        data: config || { topics: [], tickers: [] },
      });
    } catch (err) {
      next(err);
    }
  }

  /**
   * GET /api/v1/briefing/history
   * List historical briefings with pagination
   */
  async getHistory(req, res, next) {
    try {
      const page = parseInt(req.query.page) || 1;
      const limit = parseInt(req.query.limit) || 20;
      
      const { briefings, total } = await briefingService.getHistory(page, limit);
      
      res.status(200).json({
        success: true,
        data: briefings,
        pagination: {
          page,
          limit,
          total,
          totalPages: Math.ceil(total / limit),
        },
      });
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new BriefingController();
