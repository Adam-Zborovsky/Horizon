# H04 — Author repair evidence (t_f3a6cd05)

- Author: worker/zai; repair of blocking findings from docs/horizon/evidence/h04-review.md (reviewer deepseek-v4-pro, t_26fb2a69)
- Date: 2026-10-31
- Scope: only the card's write allowlist — backend/src/features/positions/position.model.js, backend/scripts/migrate-positions.cjs, backend/test/positions.test.cjs, plus this evidence and logs under docs/horizon/evidence/h04/. position.service.js and position.routes.js untouched (verified below).
- No DB connection, no live migration, no container, no backgrounding. All commands foreground, host Node v22.22.2.

## Finding 1 (BLOCKING) — `_id` typed ObjectId violated the opaque-string contract

Disposition: FIXED as specified. `_id: { type: String }` declared in `positionSchema` (backend/src/features/positions/position.model.js), with a comment pinning CONTRACTS §1 and the legacy-mig-* dependency. ObjectId was NOT adopted.

Red first (both blocking tests added before any fix; run `node --test backend/test/positions.test.cjs` → 40 tests, 4 fail):

- Test 37 `model: _id is an opaque String schema path — pos-<uuid> ids validate (Finding 1)` failed with:
  `CONTRACTS §1: identifiers are opaque strings; Mongoose must not default _id to ObjectId + actual - expected` (schema `_id` instance was `ObjectId`).
- Test 38 `model: legacy-mig-* deterministic ids validate on the real schema (Finding 1 + 2)` failed with:
  `legacy-mig-* _id must cast cleanly, got: ValidationError: _id: Cast to ObjectId failed for value "legacy-mig-owner-1-MSFT" (type string) at path "_id" because of "BSONError"` — the same CastError the review reproduced.
- Full tail of the red run (subtests 39–40): docs/horizon/evidence/h04/repair-red-run.log (tail capture; the 37/38 errors above are quoted verbatim from the same run's output).

Tests exercise the REAL Mongoose model (offline `validateSync` + `Position.schema.path('_id').instance` assertion) with both a `pos-<uuid>` id and a `legacy-mig-*` id — no in-memory fake. Per Note D this also pins the id-type contract the review suggested.

Green after fix: test 37/38 pass; `doc._id` preserves the exact string through construction and validation.

## Finding 2 (BLOCKING) — migration `--apply` never persisted the deterministic ids

Disposition: FIXED as specified. backend/scripts/migrate-positions.cjs apply loop now runs `await Position.create(buildAppliedDocument(change))` where `buildAppliedDocument(change)` returns exactly `{ ...change.document, _id: change.position_id }` (helper exported for hermetic testing; the apply loop uses the same code path the test pins). `applied.position_ids` now reference real stored `_id`s and `delete_position_by_id` rollback steps are real. Dry-run default and all CLI guards untouched.

Red first: Test 39 `migration: apply-path document persists the deterministic legacy-mig-* _id (Finding 2)` failed with `buildAppliedDocument is not a function` (helper/fix absent). Hermetic: `planLegacyMigration` fixture → `buildAppliedDocument` → `new Position(applied).validateSync()` → asserts `_id === change.position_id`, clean validation, and rollback step id match. No DB connection.

Green after fix: test 39 passes; the applied document validates and carries `legacy-mig-owner-1-MSFT`.

## Note B (SHOULD-FIX) — model decimal validator alignment

Disposition: FIXED. `isPositiveDecimalString` in position.model.js now enforces the service's bound: <= 18 total digits, <= 12 fraction digits, strictly positive via BigInt (no `parseFloat`). Service remains authoritative.

Red first: Test 40 `model: decimal validator matches the service bound — <=18 total / <=12 fraction digits (Note B)` failed with `model must reject amount 0.0000000000001` (old validator accepted it). Green after fix: rejects 13-fraction-digit, 19-total-digit, and zero values; accepts exact-boundary values (18 total / 12 fraction digits).

## Verification (actual commands and results)

| Command | Result |
|---|---|
| `node --test backend/test/positions.test.cjs` (red, pre-fix) | exit 1 — 40 tests, 36 pass, 4 fail (the 4 new red tests) |
| `node --test backend/test/positions.test.cjs` (post-fix) | exit 0 — 40 tests, 40 pass, 0 fail (docs/horizon/evidence/h04/repair-green-run.log) |
| `node --test backend/test/*.test.cjs` | exit 1 — 103 tests, 102 pass, 1 fail: `backend/test/research-metrics.test.cjs` |
| `ls backend/test/*.test.cjs \| grep -v research-metrics \| xargs node --test` | exit 0 — 102 tests, 102 pass, 0 fail (docs/horizon/evidence/h04/repair-aggregate-minus-lane.log) |
| `git diff --check` | exit 0, clean (H04 files are untracked `new_files` in the existing dirty baseline, so git diff shows no tracked-file churn) |
| `cd backend && node scripts/migrate-positions.cjs` | exit 2 (usage, no `--uri`) |
| `cd backend && node scripts/migrate-positions.cjs --uri mongodb://127.0.0.1:27017/x --apply` | exit 3 (acknowledgement refused) |
| `HORIZON_MIGRATION_ACKNOWLEDGE=I-AUTHORIZE-LIVE-MIGRATION node scripts/migrate-positions.cjs --uri mongodb://10.0.0.5:27017/x --apply` | exit 3 (non-loopback target refused) — guard string only; no connection attempted |

Aggregate note: the single aggregate failure (`research-metrics.test.cjs`) is a pre-existing failure from a sibling lane — the file is untracked, requires a not-yet-existing module `../src/features/research/metrics` (`MODULE_NOT_FOUND`), is outside this card's write allowlist, and is unrelated to positions. It failed identically before this repair; excluded run shows 102/102.

## SHA-256 of every changed file

```
ee3f25aba0eee2d94d7f6a63295b8eb914e594cbc391be5b8c8d75ebc6250875  backend/src/features/positions/position.model.js
ad5b3ae9f52b75ba0870caaec062aae7b3b1295610fe8c264f52fc51403e8544  backend/src/features/positions/position.service.js
0c5408510317c8918c7aa8ec168d127792a46d16c60a381b5c8188026fbed4cb  backend/scripts/migrate-positions.cjs
ff2c48e7f631df219d18dc7a122de213a4368d12cdf39e747ddc6c929341d565  backend/test/positions.test.cjs
```

`position.service.js` was NOT modified in this repair (hash listed for continuity with the prior delivery's verification; compare against h04-author.md — if it matches, zero diff). `position.routes.js` untouched, not listed.

## Remaining limitations

- All verification is offline/hermetic: `validateSync`, schema-path assertions and planner fixtures. No live MongoDB was connected; Mongoose persistence (real insert/findById round-trip), the partial unique index, and the actual `--apply` write path remain runtime-deferred, consistent with the review's deferred list.
- The red run's captured log file (repair-red-run.log) is a tail capture (subtests 39–40); the exact red errors for subtests 37–38 are quoted verbatim above from the same run.
- Note A (CONTRACTS.md §2 `average_cost.basis` documentation amendment) and Note C (percent rounding asymmetry, cosmetic) were non-blocking and remain with their named owners; not addressed here per allowlist.
