const jwt = require('jsonwebtoken');
const env = require('../config/env');
const User = require('../features/auth/user.model');

/**
 * Middleware to protect routes and inject authenticated user into request.
 */
module.exports = async (req, res, next) => {
  try {
    let token;

    if (
      req.headers.authorization &&
      req.headers.authorization.startsWith('Bearer')
    ) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (!token) {
      return res.status(401).json({ message: 'Not authorized, no token provided' });
    }

    try {
      const decoded = jwt.verify(token, env.JWT_SECRET);
      req.user = await User.findById(decoded.id).select('-password');
      
      if (!req.user) {
        return res.status(401).json({ message: 'User no longer exists' });
      }

      next();
    } catch (err) {
      console.error('AuthMiddleware: Token verification failed:', err.message);
      return res.status(401).json({ message: 'Not authorized, token failed' });
    }
  } catch (err) {
    next(err);
  }
};
