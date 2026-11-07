const crypto = require('node:crypto');
const cronLib = require('node-cron');
const BriefingConfig = require('../features/briefing/briefing_config.model');
const briefingService = require('../features/briefing/briefing.service');
const PositionModel = require('../features/positions/position.model');
const ResearchSchedulerLeaseModel = require('../features/research/research_scheduler_lease.model');
const { createResearchScheduler } = require('../features/research/run_worker');

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
  cronLib.schedule('10 16 * * 1-5', () => {
    console.log('Scheduler: Market-close briefing cron fired.');
    triggerAllUsers().catch(err => {
      console.error('Scheduler: Error triggering users:', err.message);
    });
  }, { timezone: 'America/New_York' });

  console.log('✅ Briefing scheduler started (Mon-Fri 16:10 America/New_York, DST-aware).');
}

function assertLeaseInput(key, ownerId, ttlMs) {
  if (typeof key !== 'string' || key.length === 0 || key.length > 160) {
    throw new TypeError('lease key must be a non-empty string');
  }
  if (typeof ownerId !== 'string' || ownerId.length === 0 || ownerId.length > 160) {
    throw new TypeError('lease owner must be a non-empty string');
  }
  if (!Number.isSafeInteger(ttlMs) || ttlMs <= 0) {
    throw new TypeError('lease ttl must be a positive integer of milliseconds');
  }
}

// Mongo compare-and-set leader lease. The filter allows only an expired lease
// or a renewal by its current owner. An upsert collision means a competing
// replica created/renewed a live record between our read and write, so this
// replica must behave as a follower. TTL cleanup is not part of correctness.
function createMongooseLeaderLease({
  model = ResearchSchedulerLeaseModel,
  now = () => new Date(),
} = {}) {
  if (!model || typeof model.findOneAndUpdate !== 'function' || typeof model.deleteOne !== 'function') {
    throw new TypeError('createMongooseLeaderLease requires a mongoose lease model');
  }

  return Object.freeze({
    async tryAcquire(key, ownerId, ttlMs) {
      assertLeaseInput(key, ownerId, ttlMs);
      const acquiredAt = now();
      const expiresAt = new Date(acquiredAt.getTime() + ttlMs);
      try {
        const record = await model.findOneAndUpdate(
          {
            _id: key,
            $or: [
              { expires_at: { $lte: acquiredAt } },
              { owner: ownerId },
            ],
          },
          { $set: { owner: ownerId, expires_at: expiresAt } },
          { new: true, upsert: true, setDefaultsOnInsert: true },
        ).lean();
        if (!record || record.owner !== ownerId) return null;
        return {
          key,
          owner: ownerId,
          expires_at: new Date(record.expires_at).toISOString(),
        };
      } catch (error) {
        // A concurrent upsert against the unique _id is expected leader
        // contention, not an application failure. Do not log database detail.
        if (error && error.code === 11000) return null;
        throw error;
      }
    },
    async release(lease) {
      if (!lease || typeof lease.key !== 'string' || typeof lease.owner !== 'string') return false;
      const result = await model.deleteOne({ _id: lease.key, owner: lease.owner });
      return (result.deletedCount ?? 0) === 1;
    },
  });
}

// Convert only the fields required by queueDailyUpdateRuns. Archived
// positions are intentionally excluded: no automatic work is queued for a
// user-hidden holding. This provider is server-side and never trusts n8n
// input or exposes position economics.
function createMongooseScheduledPositionsProvider({ model = PositionModel } = {}) {
  if (!model || typeof model.find !== 'function') {
    throw new TypeError('createMongooseScheduledPositionsProvider requires a position model');
  }
  return async function listScheduledPositions() {
    const positions = await model.find({ archived: false })
      .select('_id owner_id instrument revision')
      .lean();
    return positions.map((position) => ({
      position_id: String(position._id),
      owner_id: String(position.owner_id),
      revision: position.revision,
      instrument_id: position.instrument?.instrument_id,
    }));
  };
}

function safeSchedulerErrorCode(error, fallback = 'EXECUTION_START_FAILED') {
  if (error && typeof error.code === 'string' && /^[A-Z][A-Z0-9_]{1,79}$/.test(error.code)) {
    return error.code;
  }
  return fallback;
}

function summarizeErrorCodes(errors) {
  const counts = new Map();
  for (const error of errors) {
    const code = error && typeof error.error_code === 'string' ? error.error_code : 'UNKNOWN';
    counts.set(code, (counts.get(code) ?? 0) + 1);
  }
  return [...counts.entries()]
    .sort(([left], [right]) => left.localeCompare(right))
    .map(([code, count]) => `${code}:${count}`)
    .join(',');
}

// Replay entries can still be durable queued work after a process restart: the
// queue operation is idempotent, but it does not mean the prior process ever
// reached the worker. Always hand every valid queued run to startRun. Its
// persisted compare-and-set claim makes this safe across scheduler replicas,
// manual triggers, and repeated ticks: only the winner runs the pipeline;
// losers return a replay receipt. This is deliberately in-process: an
// unavailable or 401 external poller must not strand source-scheduled work.
async function startQueuedRunExecutions({ queued, runWorker }) {
  if (!runWorker || typeof runWorker.startRun !== 'function') {
    return { started: 0, replayed: 0, errors: [] };
  }
  const outcome = { started: 0, replayed: 0, errors: [] };
  for (const entry of queued) {
    if (!entry || typeof entry.run_id !== 'string') continue;
    try {
      const receipt = await runWorker.startRun({ run_id: entry.run_id });
      if (receipt && receipt.replayed) outcome.replayed += 1;
      else outcome.started += 1;
    } catch (error) {
      outcome.errors.push({ run_id: entry.run_id, error_code: safeSchedulerErrorCode(error) });
    }
  }
  return outcome;
}

// Source scheduler recovers stale persisted work, queues idempotent daily
// runs, and starts fresh work through the same bounded local worker used by
// automation. It never accepts external run or owner input, so a 401 from an
// external poller cannot strand scheduled work or weaken owner binding.
function startResearchScheduler({
  researchService,
  runWorker = null,
  positions = createMongooseScheduledPositionsProvider(),
  leadership = createMongooseLeaderLease(),
  cron = cronLib,
  ownerId = `research-scheduler-${crypto.randomUUID()}`,
  logger = console,
  timezone = 'America/New_York',
  expression = '20 16 * * 1-5',
} = {}) {
  if (!cron || typeof cron.schedule !== 'function') {
    throw new TypeError('startResearchScheduler requires a cron scheduler');
  }
  if (runWorker !== null && typeof runWorker.startRun !== 'function') {
    throw new TypeError('startResearchScheduler runWorker must expose startRun when provided');
  }
  const scheduler = createResearchScheduler({
    researchService,
    positions,
    leadership,
    ownerId,
    logger,
  });
  const task = cron.schedule(expression, () => scheduler.runScheduledTick()
    .then(async (outcome) => {
      const execution = outcome.leader
        ? await startQueuedRunExecutions({ queued: outcome.queued, runWorker })
        : { started: 0, replayed: 0, errors: [] };
      // Operationally useful aggregate only: no position IDs, model output,
      // credentials, or error details enter logs.
      if (logger && typeof logger.info === 'function') {
        if (!outcome.leader) {
          logger.info('research scheduler tick skipped: another replica holds the leader lease');
          return { ...outcome, execution };
        }
        const recovered = (outcome.recovery?.stalled ?? 0) + (outcome.recovery?.superseded ?? 0);
        const replays = outcome.queued.filter((entry) => entry.idempotent_replay).length;
        const queueCodes = summarizeErrorCodes(outcome.errors);
        const executionCodes = summarizeErrorCodes(execution.errors);
        logger.info(`research scheduler tick completed: queued=${outcome.queued.length - replays} replayed=${replays} queue_errors=${outcome.errors.length}${queueCodes ? `(${queueCodes})` : ''} execution_started=${execution.started} execution_replayed=${execution.replayed} execution_errors=${execution.errors.length}${executionCodes ? `(${executionCodes})` : ''} recovered=${recovered}`);
      }
      return { ...outcome, execution };
    })
    .catch((error) => {
      // Source-only: avoid propagating unhandled rejections or logging data
      // from position/model payloads. The next bounded tick retries normally.
      if (logger && typeof logger.warn === 'function') logger.warn(`research scheduler scheduled tick failed: ${safeSchedulerErrorCode(error, 'TICK_FAILED')}`);
    }), { timezone });
  if (logger && typeof logger.info === 'function') {
    logger.info(`Research scheduler started (${expression} ${timezone}; queue/recovery/local execution).`);
  }
  return Object.freeze({ scheduler, task });
}

module.exports = {
  startScheduler,
  createMongooseLeaderLease,
  createMongooseScheduledPositionsProvider,
  startQueuedRunExecutions,
  startResearchScheduler,
};
