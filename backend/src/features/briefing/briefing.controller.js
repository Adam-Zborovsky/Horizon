const briefingService = require('./briefing.service');

class BriefingController {
  /**
   * Get the most recent briefing for current user
   */
  async getLatest(req, res, next) {
    try {
      const briefing = await briefingService.getLatest(req.user._id);
      if (!briefing) {
        return res.status(200).json({ status: 'pending', message: 'No briefing found for this user.' });
      }
      res.status(200).json(briefing);
    } catch (err) {
      next(err);
    }
  }

  /**
   * Save a new briefing (from agents/n8n)
   * Note: This needs to know which user this briefing belongs to.
   * If n8n sends it, it should probably include the userId in the body.
   */
  async save(req, res, next) {
    try {
      const { userId, ...data } = req.body;
      
      if (!userId) {
        return res.status(400).json({ message: 'userId is required for saving briefings' });
      }

      const saved = await briefingService.save(userId, data);
      res.status(201).json(saved);
    } catch (err) {
      next(err);
    }
  }

  /**
   * Manually trigger the briefing generation workflow
   */
  async triggerManual(req, res, next) {
    try {
      await briefingService.triggerWorkflow(req.user._id, 'manual_trigger');
      res.status(202).json({ message: 'Briefing generation triggered.' });
    } catch (err) {
      next(err);
    }
  }

  /**
   * Get the current configuration for user
   */
  async getConfig(req, res, next) {
    try {
      const config = await briefingService.getConfig(req.user._id);
      res.status(200).json(config);
    } catch (err) {
      next(err);
    }
  }

  /**
   * List historical briefings for user
   */
  async getHistory(req, res, next) {
    try {
      const page = parseInt(req.query.page) || 1;
      const limit = parseInt(req.query.limit) || 20;
      const history = await briefingService.getHistory(req.user._id, page, limit);
      res.status(200).json(history);
    } catch (err) {
      next(err);
    }
  }

  /**
   * Toggle topic enabled status
   */
  async toggleTopic(req, res, next) {
    try {
      const { topicName } = req.params;
      const { enabled } = req.body;
      const updated = await briefingService.toggleTopic(req.user._id, topicName, enabled);
      res.status(200).json(updated);
    } catch (err) {
      next(err);
    }
  }

  /**
   * Remove a topic
   */
  async removeTopic(req, res, next) {
    try {
      const { topicName } = req.params;
      const updated = await briefingService.removeTopic(req.user._id, topicName);
      res.status(200).json(updated);
    } catch (err) {
      next(err);
    }
  }

  /**
   * Get recommended topics
   */
  async getRecommendedTopics(req, res, next) {
    try {
      const recommendations = await briefingService.getRecommendedTopics(req.user._id);
      res.status(200).json(recommendations);
    } catch (err) {
      next(err);
    }
  }

  /**
   * Update full configuration
   */
  async updateConfig(req, res, next) {
    try {
      const updated = await briefingService.updateConfig(req.user._id, req.body);
      res.status(200).json(updated);
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new BriefingController();
