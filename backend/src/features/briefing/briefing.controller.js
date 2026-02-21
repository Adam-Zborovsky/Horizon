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
