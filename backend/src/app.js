const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const env = require('./config/env');
const briefingRoutes = require('./features/briefing/briefing.routes');
const webhookRoutes = require('./features/briefing/webhook.routes');
const authRoutes = require('./features/auth/auth.routes');
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
app.use(`${env.API_PREFIX}/auth`, authRoutes);
app.use(`${env.API_PREFIX}/briefing`, briefingRoutes);

// Webhook Routes (unversioned as they match specific external endpoint requirements)
app.use('/webhook', webhookRoutes);

// Error Handling
app.use(errorHandler);

module.exports = app;
