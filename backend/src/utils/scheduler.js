const cron = require('node-cron');
const BriefingConfig = require('../features/briefing/briefing_config.model');
const briefingService = require('../features/briefing/briefing.service');

const STAGGER_MINUTES = 15;

/**
 * Fetches all users with a briefing config and triggers the n8n workflow
 * for each one, staggered by STAGGER_MINUTES to avoid overloading the server.
 */
async function triggerAllUsers() {
  const configs = await BriefingConfig.find({}).select('user').lean();

  if (configs.length === 0) {
    console.log('Scheduler: No users with briefing configs found.');
    return;
  }

  console.log(`Scheduler: Triggering briefing for ${configs.length} user(s), staggered ${STAGGER_MINUTES}min apart.`);

  configs.forEach((config, index) => {
    const delayMs = index * STAGGER_MINUTES * 60 * 1000;
    setTimeout(() => {
      console.log(`Scheduler: Triggering briefing for user ${config.user} (slot ${index + 1}/${configs.length})`);
      briefingService.triggerWorkflow(config.user.toString(), 'scheduled_daily');
    }, delayMs);
  });
}

function startScheduler() {
  // Run at 6:00 AM every day
  cron.schedule('0 6 * * *', () => {
    console.log('Scheduler: Daily briefing cron fired.');
    triggerAllUsers().catch(err => {
      console.error('Scheduler: Error triggering users:', err.message);
    });
  });

  console.log('✅ Briefing scheduler started (daily at 06:00).');
}

module.exports = { startScheduler };
