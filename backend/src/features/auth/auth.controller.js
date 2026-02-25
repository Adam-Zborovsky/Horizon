const authService = require('./auth.service');

class AuthController {
  /**
   * Register user
   * @route POST /api/v1/auth/register
   */
  async register(req, res, next) {
    try {
      const { username, password } = req.body;
      
      if (!username || !password) {
        return res.status(400).json({ message: 'Username and password are required' });
      }

      const response = await authService.register(username, password);
      res.status(201).json(response);
    } catch (err) {
      next(err);
    }
  }

  /**
   * Login user
   * @route POST /api/v1/auth/login
   */
  async login(req, res, next) {
    try {
      const { username, password } = req.body;

      if (!username || !password) {
        return res.status(400).json({ message: 'Username and password are required' });
      }

      const response = await authService.login(username, password);
      res.status(200).json(response);
    } catch (err) {
      next(err);
    }
  }

  /**
   * Get current user
   * @route GET /api/v1/auth/me
   */
  async getMe(req, res, next) {
    try {
      if (!req.user) {
        return res.status(401).json({ message: 'Not authenticated' });
      }
      res.status(200).json({ user: req.user });
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new AuthController();
