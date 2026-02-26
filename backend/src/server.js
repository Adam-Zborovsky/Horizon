const app = require('./app');
const env = require('./config/env');
const connectDB = require('./config/db');
const { startScheduler } = require('./utils/scheduler');

const startServer = async () => {
  // Connect to the database
  await connectDB();

  // Start the daily briefing scheduler
  startScheduler();

  // Listen for requests
  app.listen(env.PORT, () => {
    console.log(`✅ Alpha-Horizon Backend is running on port: ${env.PORT}`);
    console.log(`🌍 Environment: ${env.NODE_ENV}`);
    console.log(`🔗 API Prefix: ${env.API_PREFIX}`);
  });
};

startServer().catch(err => {
  console.error('❌ Failed to start server:', err);
  process.exit(1);
});
