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
  // Fire Mon-Fri at 16:10 America/New_York — 10 minutes after US market close
  // (16:00 ET). Wall-clock cron in NY timezone means the UTC fire time shifts
  // automatically with summer/winter clocks (20:10 UTC in EDT, 21:10 UTC in EST).
  // Weekends excluded: markets closed, no fresh market data to analyze.
  cron.schedule('10 16 * * 1-5', () => {
    console.log('Scheduler: Market-close briefing cron fired.');
    triggerAllUsers().catch(err => {
      console.error('Scheduler: Error triggering users:', err.message);
    });
  }, { timezone: 'America/New_York' });

  console.log('✅ Briefing scheduler started (Mon-Fri 16:10 America/New_York, DST-aware).');
}

module.exports = { startScheduler };
