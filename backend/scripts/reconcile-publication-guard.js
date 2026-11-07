'use strict';

// Proof-gated, auditable recovery for a standalone-Mongo publication guard.
// Default is dry-run. --apply only releases a guard when its named immutable
// assessment already exists with the exact position/owner/revision binding.
// It deliberately refuses an absent assessment because an old worker could
// still be between guard acquisition and insert.

const mongoose = require('mongoose');
const PositionModel = require('../src/features/positions/position.model');
const ResearchAssessmentModel = require('../src/features/research/research_assessment.model');
const { createMongooseAssessmentRepository } = require('../src/features/research/research.service');

function valueAfter(argv, flag) {
  const index = argv.indexOf(flag);
  return index >= 0 ? argv[index + 1] : null;
}

async function main(argv = process.argv.slice(2), env = process.env) {
  const positionId = valueAfter(argv, '--position-id');
  const ownerId = valueAfter(argv, '--owner-id');
  const apply = argv.includes('--apply');
  if (!positionId || !ownerId) {
    throw new Error('Usage: node scripts/reconcile-publication-guard.js --position-id <id> --owner-id <id> [--apply]');
  }
  if (!env.MONGODB_URI) throw new Error('MONGODB_URI is required');

  await mongoose.connect(env.MONGODB_URI);
  try {
    const repository = createMongooseAssessmentRepository(ResearchAssessmentModel, { positionModel: PositionModel });
    const result = await repository.reconcileCompletedPublicationGuard({
      position_id: positionId,
      owner_id: ownerId,
      apply,
    });
    console.log(JSON.stringify({
      operation: 'reconcile-publication-guard', position_id: positionId,
      owner_id: ownerId, apply, ...result,
    }));
    // Blocked results are successful audits, not permission to force unlock.
    return result;
  } finally {
    await mongoose.disconnect();
  }
}

if (require.main === module) {
  main().catch((error) => {
    console.error(JSON.stringify({ operation: 'reconcile-publication-guard', error: error.message }));
    process.exitCode = 1;
  });
}

module.exports = { main, valueAfter };