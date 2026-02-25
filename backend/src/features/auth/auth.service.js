const jwt = require('jsonwebtoken');
const User = require('./user.model');
const env = require('../../config/env');

class AuthService {
  /**
   * Register a new user
   * @param {string} username 
   * @param {string} password 
   */
  async register(username, password) {
    const existingUser = await User.findOne({ username: username.toLowerCase() });
    if (existingUser) {
      const error = new Error('Username already exists');
      error.status = 400;
      throw error;
    }

    const user = new User({ username, password });
    await user.save();
    
    return this.generateTokenResponse(user);
  }

  /**
   * Login user
   * @param {string} username 
   * @param {string} password 
   */
  async login(username, password) {
    const user = await User.findOne({ username: username.toLowerCase() });
    if (!user) {
      const error = new Error('Invalid credentials');
      error.status = 401;
      throw error;
    }

    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      const error = new Error('Invalid credentials');
      error.status = 401;
      throw error;
    }

    return this.generateTokenResponse(user);
  }

  /**
   * Generate JWT token for user
   * @param {Object} user 
   */
  generateTokenResponse(user) {
    const token = jwt.sign(
      { id: user._id, username: user.username },
      env.JWT_SECRET,
      { expiresIn: env.JWT_EXPIRES_IN }
    );

    return {
      token,
      user: {
        id: user._id,
        username: user.username,
      }
    };
  }

  /**
   * Verify token and return user
   * @param {string} token 
   */
  async verifyToken(token) {
    try {
      const decoded = jwt.verify(token, env.JWT_SECRET);
      return await User.findById(decoded.id).select('-password');
    } catch (err) {
      return null;
    }
  }
}

module.exports = new AuthService();
