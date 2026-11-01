#!/usr/bin/env node
// H04 — Legacy ticker -> legacy_unclassified position migration (PREVIEW ONLY).
//
// Dry-run-first, additive, reversible at the document level. The planner is a
// pure function tested against isolated fixture data; this CLI is the only
// execution path and it is NOT authorized against the live database in this
// engagement. Live execution is an operator decision outside worker scope.
//
// Usage:
//   node scripts/migrate-positions.cjs --uri mongodb://127.0.0.1:27017/target --manifest-out /tmp/manifest.json
//   node scripts/migrate-positions.cjs --uri <uri> --apply   (additionally requires
//     HORIZON_MIGRATION_ACKNOWLEDGE=I-AUTHORIZE-LIVE-MIGRATION and a loopback target)
//
// Without --uri the script prints usage and exits 2. Default mode is dry-run
// and writes nothing.

const path = require('node:path');

const {
  planLegacyMigration,
} = require('../src/features/positions/position.service');

const ACKNOWLEDGEMENT = 'I-AUTHORIZE-LIVE-MIGRATION';

function parseArgs(argv) {
  const args = { apply: false, uri: null, manifestOut: null };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === '--apply') args.apply = true;
    else if (arg === '--uri') args.uri = argv[++i] ?? null;
    else if (arg === '--manifest-out') args.manifestOut = argv[++i] ?? null;
    else {
      process.stderr.write(`Unknown argument: ${arg}\n`);
      args.unknown = true;
    }
  }
  return args;
}

function usage() {
  process.stdout.write(`H04 position migration (dry-run first, additive, reversible)\n
Usage:
  node scripts/migrate-positions.cjs --uri mongodb://127.0.0.1:27017/<db> [--manifest-out <path>]
  node scripts/migrate-positions.cjs --uri <uri> --apply

Default is a dry run: reads BriefingConfig tickers and existing positions,
prints a reversible change manifest, and writes nothing.

--apply guardrails (live execution is operator-authorized only):
  1. Requires HORIZON_MIGRATION_ACKNOWLEDGE=${ACKNOWLEDGEMENT}
  2. Requires a loopback (127.0.0.1/localhost) target unless
     HORIZON_MIGRATION_ALLOW_REMOTE=1 is also set explicitly
  3. Creates legacy_unclassified positions only; never modifies existing
     documents, users, briefings or briefing configs\n`);
}

function isLoopbackTarget(uri) {
  try {
    const { hostname } = new URL(uri);
    return hostname === '127.0.0.1' || hostname === 'localhost' || hostname === '::1';
  } catch {
    return false;
  }
}

async function loadSourceDocuments(uri) {
  const mongoose = require('mongoose');
  await mongoose.connect(uri, { serverSelectionTimeoutMS: 10000 });
  const BriefingConfig = require('../src/features/briefing/briefing_config.model');
  const Position = require('../src/features/positions/position.model');
  const configs = await BriefingConfig.find({}).lean();
  const existing = await Position.find({}).lean();
  return {
    mongoose,
    configs: configs.map((c) => ({
      owner_id: String(c.user),
      tickers: Array.isArray(c.tickers) ? c.tickers : [],
    })),
    existingPositions: existing.map((p) => ({
      id: String(p._id),
      owner_id: p.owner_id,
      archived: !!p.archived,
      instrument: p.instrument,
      state: p.state,
    })),
  };
}

// The exact document shape the apply loop persists: the planner's document
// with the deterministic manifest id as _id. Hermetic tests construct a
// Mongoose model instance from this to prove the legacy-mig-* id survives
// schema casting without any DB connection.
function buildAppliedDocument(change) {
  return { ...change.document, _id: change.position_id };
}

async function run(args) {
  const { uri, apply, manifestOut } = args;
  if (!uri) {
    usage();
    return 2;
  }
  if (apply) {
    if (process.env.HORIZON_MIGRATION_ACKNOWLEDGE !== ACKNOWLEDGEMENT) {
      process.stderr.write(`Refusing --apply: live migration requires HORIZON_MIGRATION_ACKNOWLEDGE=${ACKNOWLEDGEMENT}. Live execution is operator-authorized only.\n`);
      return 3;
    }
    if (!isLoopbackTarget(uri) && process.env.HORIZON_MIGRATION_ALLOW_REMOTE !== '1') {
      process.stderr.write('Refusing --apply: target is not loopback. Set HORIZON_MIGRATION_ALLOW_REMOTE=1 only after operator authorization.\n');
      return 3;
    }
  }

  const { mongoose, configs, existingPositions } = await loadSourceDocuments(uri);
  const manifest = planLegacyMigration({ configs, existingPositions, now: new Date() });

  if (apply) {
    const Position = require('../src/features/positions/position.model');
    const createdIds = [];
    for (const change of manifest.changes) {
      // insertOnly: pre-existing active duplicate would have been skipped by the planner.
      // _id must be the manifest's deterministic legacy-mig-* id so that
      // applied.position_ids match stored documents and the
      // delete_position_by_id rollback steps find them.
      await Position.create(buildAppliedDocument(change));
      createdIds.push(change.position_id);
    }
    manifest.dry_run = false;
    manifest.applied = { positions_created: createdIds.length, position_ids: createdIds };
  }

  process.stdout.write(`${JSON.stringify(manifest, null, 2)}\n`);
  if (manifestOut) {
    const fs = require('node:fs');
    fs.mkdirSync(path.dirname(path.resolve(manifestOut)), { recursive: true });
    fs.writeFileSync(path.resolve(manifestOut), `${JSON.stringify(manifest, null, 2)}\n`);
    process.stdout.write(`Manifest written to ${path.resolve(manifestOut)}\n`);
  }

  await mongoose.disconnect();
  return 0;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.unknown) return 2;
  try {
    return await run(args);
  } catch (error) {
    process.stderr.write(`Migration failed: ${error.message}\n`);
    return 1;
  }
}

if (require.main === module) {
  main().then((code) => process.exit(code));
}

module.exports = { run, parseArgs, usage, isLoopbackTarget, buildAppliedDocument, ACKNOWLEDGEMENT };
