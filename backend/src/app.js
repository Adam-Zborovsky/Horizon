const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const env = require('./config/env');
const briefingRoutes = require('./features/briefing/briefing.routes');
const errorHandler = require('./middleware/error.middleware');

const app = express();

// Standard middleware
app.use(helmet());
app.use(cors());
app.use(morgan('dev'));
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Health Check
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy', version: '1.0.0' });
});

// API Routes
app.use(`${env.API_PREFIX}/briefing`, briefingRoutes);

// Error Handling
app.use(errorHandler);

module.exports = app;
