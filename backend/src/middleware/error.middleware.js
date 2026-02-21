const env = require('../config/env');

const errorHandler = (err, req, res, next) => {
  const statusCode = res.statusCode === 200 ? 500 : res.statusCode;
  
  res.status(statusCode).json({
    success: false,
    error: {
      message: err.message,
      code: err.code || 'INTERNAL_SERVER_ERROR',
    },
    stack: env.NODE_ENV === 'production' ? null : err.stack,
  });
};

module.exports = errorHandler;
