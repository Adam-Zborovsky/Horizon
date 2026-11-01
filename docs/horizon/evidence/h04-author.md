# H04 — Position persistence, owner-scoped API and migration preview — Author Delivery

- Task: t_8cd5755e (H04), delivery_phase: core_source, scope: source-only
- Author: worker/zai/glm-5.3-flash (run 186, 2026-10-31)
- Status: AUTHOR DELIVERY — not independent acceptance. Controller verifies delivery; independent reviewer inspects artifacts.
- Baseline preserved: existing dirty/untracked main baseline untouched; no commit/push, no branch change, no cleanup; no live database, container, credential or .env access at any point.

## 1. Delivered files (all new, exactly the canonical package list)

| Path | Lines | SHA-256 |
|---|---|---|
| backend/src/features/positions/position.model.js | 135 | 935224ecf27652e3198d9b64347c365f6db4a7acbf8d012cff021c0686695a0d |
| backend/src/features/positions/position.service.js | 727 | ad5b3ae9f52b75ba0870caaec062aae7b3b1295610fe8c264f52fc51403e8544 |
| backend/src/features/positions/position.routes.js | 83 | ea1e4204e71ac521f91d3fc3908bc161174f9ba9731d4cd4f873b8a46e7e0bad |
| backend/scripts/migrate-positions.cjs | 148 | 245b2797aad9d98cc1098360ff15e1beaceb43be827e9fae8bb2c5e00d07ae6d |
| backend/test/positions.test.cjs | 741 | 30b8b018743f3f4c4f95e45ed152dcbed1b1c7d1f9853ffb06e648e684a621d2 |

`existing_files` in the canonical package is empty; nothing outside the package was created or modified. Evidence artifacts under docs/horizon/evidence/h04/: named-suite.log (full 36-test output), verification.log (regression battery + secret scan + hashes + scope check), cli-guards.log (migration CLI guard behavior).

## 2. Commands and results (host node v22.22.2, all foreground, hermetic — fixtures/in-memory fakes only)

TDD ordering: tests written first and executed RED (exit 1, module-not-found for all three src modules), then implemented, then GREEN.

```
node --test backend/test/positions.test.cjs
  RED first run: exit 1 (Cannot find module '../src/features/positions/position.model')
  GREEN final:   exit 0; tests 36, pass 36, fail 0

Regression battery (no predecessor-suite regressions):
node --test backend/test/research-evidence.test.cjs   -> exit 0; 19/19
node --test backend/test/research-contracts.test.cjs  -> exit 0; 14/14
node --test backend/test/market-history.test.cjs      -> exit 0; 12/12
node --test backend/test/research-auth.test.cjs       -> exit 0; 6/6
node --test backend/test/research-history-integration.test.cjs -> exit 0; 11/11

Migration CLI guards (executed; no database connection ever made):
node scripts/migrate-positions.cjs                                  -> exit 2 (usage; no --uri)
node scripts/migrate-positions.cjs --apply --uri mongodb://127.0.0.1:27017/x
                                                                    -> exit 3 (acknowledgement refused)
HORIZON_MIGRATION_ACKNOWLEDGE=I-AUTHORIZE-LIVE-MIGRATION node scripts/migrate-positions.cjs --apply --uri mongodb://10.0.0.5:27017/x
                                                                    -> exit 3 (non-loopback target refused)
node -e "require('./scripts/migrate-positions.cjs'); ..."           -> require is inert (no side effects; guard via require.main)

sha256sum <five delivered files>  -> digests in section 1
grep -rniE "(api[_-]?key|secret|password|token)\s*[:=]\s*['\"][A-Za-z0-9+/]{16,}" \
  backend/src/features/positions/ backend/scripts/migrate-positions.cjs backend/test/positions.test.cjs
  -> no matches: no embedded credential literals
git status --short -> no pre-existing modified/untracked entries changed by this run
```

Total: 98/98 tests passing across the six backend suites (36 new + 62 predecessor).

## 3. Canonical-step mapping

| Canonical step | Implementation | Test evidence |
|---|---|---|
| Owner-isolation tests | position.service.js `get`/`update` throw identical NOT_FOUND for missing and foreign-owned ids; owner server-derived in routes (`String(req.user?._id)`), `owner_id`/`user_id`/`owner`/`userId` rejected as OWNER_FIELD_NOT_WRITABLE; serialization strips owner_id | 'service: another owner gets an indistinguishable NOT_FOUND...'; 'service: owner fields are not writable...'; 'service: serialized positions never expose owner_id'; route-level 404 deep-equality of foreign vs missing |
| Transitions tests | ALLOWED_TRANSITIONS map (candidate→owned, owned→candidate, legacy_unclassified→candidate/owned); owned→candidate clears average_cost/quantity/opened_on; candidate→legacy and owned→legacy rejected | 'service: candidate -> owned is an explicit action...'; 'service: owned -> candidate clears active economics...'; 'service: invalid transitions are rejected' |
| Decimal validation | bounded decimal strings only: `/^[0-9]+(\.[0-9]+)?$/`, ≤18 total digits, ≤12 fraction digits, strictly positive; fixed-point BigInt arithmetic at scale 12 with half-up rounding | 'service: decimal validation matrix' (12 rejections + 4 acceptances); 'model: rejects non-ISO currency...' (7 subdoc rejections) |
| Duplicate identity | partial unique index (owner_id, instrument.instrument_id) WHERE archived=false in position.model.js; service pre-check findActive; archived identities are free; unarchive conflicts with a newer active position | 'service: duplicate active identity...409-class'; 'service: same instrument for different owners is allowed'; 'service: archived positions free the identity...' |
| Revision-conflict tests | update requires expected_revision (MISSING_EXPECTED_REVISION 400), mismatch → REVISION_CONFLICT 409, success bumps revision | 'service: missing or stale expected_revision...'; route-level stale 409 / valid 200 rev+1 |
| Model/service/router with server-derived owner and reversible archival | position.model.js (strict:'throw', state-economics validators, unique partial index); position.service.js (create/get/list/update/computeProfitLoss); position.routes.js (GET/POST/PATCH under /, auth mandatory, typed error→status map 400/404/409) | full route test 'routes: auth is enforced, owner is server-derived, full CRUD behaves per contract' |
| Dry-run-first additive migration with exact counts, legacy_unclassified defaults, reversible change manifest | scripts/migrate-positions.cjs: pure `planLegacyMigration` planner (also exported from position.service.js); CLI defaults to dry-run, writes nothing, requires explicit --uri; --apply additionally requires HORIZON_MIGRATION_ACKNOWLEDGE=I-AUTHORIZE-LIVE-MIGRATION + loopback target; manifest carries source_counts, planned counts, per-insert changes and matching delete_position_by_id rollback steps | 'migration: legacy tickers import as legacy_unclassified...exact counts'; 'migration: second run is idempotent...'; 'migration: manifest is reversible...' |
| Candidate-to-owned and stale legacy tickers update policy without touching live DB | `reconcileLegacyTickerUpdate` (CONTRACTS §10): tickers-only PUT removing a ticker that backs an active position returns bounded explicit conflict (blocked_removals with active_position_ids), never destructive replacement; archived positions do not block; additions/allowed removals pass through | 'ticker policy: tickers-only PUT that would orphan active positions is blocked...'; 'ticker policy: removals without active positions...'; 'ticker policy: case-insensitive ticker matching...' |

## 4. Acceptance-criteria mapping

1. "No cost/ownership facts inferred from old tickers or model prose" — migration documents carry instrument {exchange:null, currency:null, provider_symbol:null}, average_cost/quantity/opened_on null, state legacy_unclassified; asserted exactly ('no currency inferred from a bare ticker', 'no amounts anywhere in the migrated document'). Service test additionally proves original_thesis prose never yields economics ('legacy_unclassified positions carry null economics — no cost inferred from tickers or prose').
2. "Unknown costs remain null; currency mismatch and split basis block misleading P/L" — computeProfitLoss returns {status:'unavailable', reason:'unknown_cost'|'currency_mismatch'|'split_basis_unreconciled'} with no FX approximation; percent requires matching currency+basis, absolute additionally requires quantity; fees/dividends explicitly labeled excluded. average_cost.basis (optional, default 'raw_purchase') is the single documented schema extension beyond CONTRACTS §2 — it exists so splits can be reconciled explicitly rather than always blocking; flagged for reviewer attention.
3. "Migration only exercised on isolated test data; live execution is not authorized" — planner is a pure function tested against in-memory fixture objects; CLI guards verified (exit 2/3/3 above); no mongoose.connect call executed in this engagement; dry_run:true is hard-set by the planner.

## 5. Limitations and deferred checks

- Source-only delivery: no live database, MongoDB index behavior (including the partial unique index) is defined but unverified at runtime; persistence exercised through the repository abstraction + in-memory fakes and offline mongoose validateSync.
- Host Node v22.22.2 tests do not establish deployment-runtime compatibility.
- `reconcileLegacyTickerUpdate` and `planLegacyMigration` are pure policy functions; wiring the tickers-only PUT guard into briefing.service.js (legacy PUT path) is another lane's shared-file ownership and was intentionally not touched.
- HTTP router is not mounted in backend/src/app.js: app.js is shared glue owned by the H15A→H15B→H15 sequence; this package ships `createPositionRouter({ positionService, authenticate })` for the integrator to mount under `${API_PREFIX}/positions`.
- No Flutter/frontend checks in scope; all device/APK/analysis checks remain DEFERRED_TO_DEV_PC per amendment.
- average_cost.basis extension noted in §4.2 for reviewer scrutiny.

## 6. Handoff

Author delivery ready for controller verification and independent combined specification + quality review (focused extra review per H04). Per handoff override, this task is blocked as needs_input with reason "review-required: author delivery ready". Never self-completed; no review tools invoked.
