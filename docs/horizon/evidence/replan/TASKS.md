# Horizon orchestrator work packages

These are bounded work packages, not claims of completed implementation. Each implementing card must be split into small red-test / run-failure / implement / run-pass / attach-evidence steps if it exceeds one worker session. Read SPEC.md and CONTRACTS.md first. New paths below are **proposed**; existing paths were inspected or must be revalidated at preflight. No guessed import/library API is approved.

## Dispatch and ownership

- H00 then H01 freeze the baseline/contracts. After that run independent lanes in parallel, initially capped at two until resource/API budgets are measured.
- H02 chart prototype is an early decision gate. Do not replace the renderer before evidence.
- H03 is mandatory before position economics flow to automation. H19 is primary/admin only, never an autonomous worker card.
- H15 is the sole shared-file integrator. Other workers deliver new modules/widgets against frozen contracts; they do not race on app.js, manifests, existing models/screens or generated files.
- H11 owns new Flutter domain/generated outputs; H15 owns regeneration involving existing models. Lock generator execution.
- H04/H05/H06/H07/H08/H09 own disjoint new modules. H10 alone patches preserved workflow/scheduler sources.
- Do not use clean-HEAD worktrees as a substitute for the dirty baseline. Use file-disjoint shared workspace with allowlists, or approved isolated copies including baseline. Git commits/branches/pushes are not implicitly authorized by this plan.
- Each card receives its own goal, dependencies, file allowlist, acceptance, invariant list and output-evidence path. Do not attach the entire chat as its only context.
- After each package, independent spec compliance then code/quality review. Choose different reviewer/model, different vendor where available; record same-vendor limitation explicitly rather than claiming independence.
- Source-only tests use injected fixtures/mocks. Workers do not read credentials, publish workflows, migrate live data, accept licenses or spend on new services.

## Verification commands

For backend tests named below, from repo root: `node --test backend/test/<named-file>.test.cjs`; full planned suite: `node --test backend/test/*.test.cjs`. These files are to be created, not existing passing tests.

For Flutter tests, from `frontend`: `flutter test test/<named-file>.dart`; full suite `flutter test`; `flutter analyze`; generator `dart run build_runner build --delete-conflicting-outputs` only under generated-file ownership approval. Toolchain availability must be verified. Integration tests/build flags require actual target configuration/device discovery; use standard runner on the inspected project, not assumed flavors.

Expected red phase: the new assertion fails for the specific unimplemented capability; capture actual error. Expected green phase: all named assertions pass with real tool output. No invented expected numeric fixture results. Independently compute fixture expected values before using them as tests.

## Common invariant block (paste onto every worker/reviewer card)

- Secrets never in output, logs, fixtures, exported literal credentials, or card text; workers do not read .env or credential stores.
- No ports: in Docker compose; expose: only, route through existing Cloudflare Tunnels. No DNS/tunnel changes.
- No shell backgrounding (&, nohup, setsid); use tracked terminal background processes only when authorized.
- Preserve existing dirty/untracked baseline and user data; no git reset/clean, database or volume deletion, commit/push/history rewrite without explicit authorization.
- No live workflow publication, credential provisioning, live migration, paid service, license acceptance, or other-profile changes in worker cards; hand those to primary/admin.
- Observed market data and conditional scenarios remain separate. No invented prices, candles, history, source claims or verification output.
- Read SPEC.md and CONTRACTS.md; edit only assigned files. Shared files and generated outputs have one owner. Stop on contract drift.
- Write failing tests first, run them, implement, rerun; attach actual commands/output and remaining limitations. Do not claim an unavailable toolchain passed.
- After two failures on the same target, stop and escalate with exact errors and attempted fixes; no blind third retry.

## H00: Preflight and exact baseline

**Role:** integration-worker. **Dependencies:** none. **Kind:** source_work.

**Files — create:**
- `docs/horizon/evidence/preflight.md`

**Execution steps:**
1. Recheck repository root, branch, dirty/untracked paths and nested project rules.
2. Record backend/deployment Node versions, actual Flutter lock resolution, SDK/build/device availability and existing test failures.
3. Discover live workflow identity/version read-only with primary-controlled credential use where required.
4. Define the shared-file lock/allowlists and record provider/license/live-operation gates.

**Acceptance:**
- Existing user changes are enumerated and protected; no secrets in baseline evidence.
- Flutter absence or baseline failures have exact evidence and a resolution gate, not an assumed pass.
- No live workflow or profile was changed.

**Handoff:** exact diff/file list, test commands and actual results, fixture/source IDs, screenshots where applicable, known limits, next dependency; independent spec then quality review. Evidence belongs in `docs/horizon/evidence/` without secrets.

## H01: Executable shared contracts and offline fixtures

**Role:** contract-worker. **Dependencies:** H00. **Kind:** source_work.

**Files — create:**
- `backend/src/features/research/contracts.js`
- `backend/test/research-contracts.test.cjs`
- `backend/test/fixtures/research/observed-bars.json`
- `backend/test/fixtures/research/contract-cases.json`

**Execution steps:**
1. Write failing schema tests for position, bars, claims, assessment, projections and run lifecycle.
2. Implement Zod/JSON schemas matching CONTRACTS.md, including strict write fields and bounded values.
3. Capture a source-dated sanitized observed-bar fixture and separately labeled engineered negative fixtures; no real personal costs.
4. Publish canonical schema/fixtures and sample serialized outputs to all dependent lanes.

**Acceptance:**
- Invalid OHLC, numeric strings where forbidden, candidate economics, duplicate/missing horizon, stale/cross-currency cases fail.
- Fixtures explicitly distinguish observed recordings from test-only engineered cases.
- Consumer schemas have one version and no incompatible local variants.

**Named tests:** `backend/test/research-contracts.test.cjs`.

**Handoff:** exact diff/file list, test commands and actual results, fixture/source IDs, screenshots where applicable, known limits, next dependency; independent spec then quality review. Evidence belongs in `docs/horizon/evidence/` without secrets.

## H02: Existing-library chart capability prototype

**Role:** chart-worker. **Dependencies:** H01. **Kind:** source_work.

**Files — create:**
- `frontend/test/support/chart_probe.dart`
- `frontend/test/chart_capability_test.dart`
- `docs/horizon/evidence/chart-decision.md`

**Execution steps:**
1. Read actual locked fl_chart APIs and versioned source, not redirected docs.
2. Build a test-only native probe with observed intraday/daily OHLCV, line/candles, exact selection readout and common-axis overlays.
3. Exercise pan/zoom/reset, range/style switches, volume context and phone/web touch semantics.
4. Record screenshots/interaction proof and keep/reject decision; stop after one focused prototype session if a hard requirement fails.

**Acceptance:**
- Exact O/H/L/C/V/time matches fixture in line/candle selection; style/range state is preserved.
- Actual and future endpoint ranges never overlap as observed bars; stale/null projections handled.
- Existing fl_chart retained if all required behaviors pass; new renderer needs explicit dependency/license approval.
- Compile-only or no-phone-toolchain evidence is not mobile acceptance.

**Named tests:** `frontend/test/chart_capability_test.dart`.

**Handoff:** exact diff/file list, test commands and actual results, fixture/source IDs, screenshots where applicable, known limits, next dependency; independent spec then quality review. Evidence belongs in `docs/horizon/evidence/` without secrets.

## H03: Scoped automation security and tenancy tests

**Role:** security-worker. **Dependencies:** H01. **Kind:** source_work.

**Files — create:**
- `backend/src/middleware/automation.middleware.js`
- `backend/test/research-auth.test.cjs`

**Files — modify only after reading and preserving baseline:**
- `backend/src/features/briefing/briefing.routes.js`
- `backend/src/features/briefing/briefing.controller.js`
- `backend/src/config/env.js`

**Execution steps:**
1. Write anonymous ingestion/config, invalid service token/scope and owner spoofing denial tests.
2. Implement fail-closed automation authentication with injected test secrets, safe logging and bounded bodies.
3. Protect legacy system/ingestion code in source; document coordinated n8n deployment, without applying it live.
4. Define run-bound callback nonce/lease authorization helper for new routes.

**Acceptance:**
- Anonymous legacy sensitive routes fail in tests; wrong/expired scopes and replay conflicts fail.
- Client-supplied userId cannot authorize new position/research operations.
- No real credential read/generated/stored by worker; live credential setup remains release gate.

**Named tests:** `backend/test/research-auth.test.cjs`.

**Handoff:** exact diff/file list, test commands and actual results, fixture/source IDs, screenshots where applicable, known limits, next dependency; independent spec then quality review. Evidence belongs in `docs/horizon/evidence/` without secrets.

## H04: Position persistence, owner-scoped API and migration preview

**Role:** backend-worker. **Dependencies:** H03. **Kind:** source_work.

**Files — create:**
- `backend/src/features/positions/position.model.js`
- `backend/src/features/positions/position.service.js`
- `backend/src/features/positions/position.routes.js`
- `backend/scripts/migrate-positions.cjs`
- `backend/test/positions.test.cjs`

**Execution steps:**
1. Write owner-isolation, transitions, decimal validation, duplicate identity and revision-conflict tests.
2. Implement position model/service/router with server-derived owner and reversible archival.
3. Write dry-run-first additive migration with exact counts, legacy_unclassified defaults and reversible change manifest.
4. Test candidate-to-owned and stale legacy tickers update policy without touching live DB.

**Acceptance:**
- No cost/ownership facts inferred from old tickers or model prose.
- Unknown costs remain null; currency mismatch and split basis block misleading P/L.
- Migration only exercised on isolated test data; live execution is not authorized.

**Named tests:** `backend/test/positions.test.cjs`.

**Handoff:** exact diff/file list, test commands and actual results, fixture/source IDs, screenshots where applicable, known limits, next dependency; independent spec then quality review. Evidence belongs in `docs/horizon/evidence/` without secrets.

## H05: Observed OHLCV history, snapshots and chart API

**Role:** market-data-worker. **Dependencies:** H01. **Kind:** source_work.

**Files — create:**
- `backend/src/features/market/market.service.js`
- `backend/src/features/market/market.routes.js`
- `backend/src/features/market/market_snapshot.model.js`
- `backend/src/features/market/providers/yahoo.js`
- `backend/test/market-history.test.cjs`

**Execution steps:**
1. Write range/resolution, ordering, invalid bars, stale cache, provider timeout and DST/holiday/early-close tests.
2. Implement vetted instrument mapping, provider adapter, source metadata and immutable chart snapshots.
3. Expose owner-authenticated history with truthful actual resolution and partial/unavailable status.
4. Add request limits/cache keys and forbid fabricated OHLC or fallback quotes.

**Acceptance:**
- All six ranges follow CONTRACTS.md; unsupported intervals are labeled, not silently relabeled.
- Real timestamps/currency/adjustment/delay status survive serialization.
- Provider failures yield explicit gaps or stale cache, not synthetic points.

**Named tests:** `backend/test/market-history.test.cjs`.

**Handoff:** exact diff/file list, test commands and actual results, fixture/source IDs, screenshots where applicable, known limits, next dependency; independent spec then quality review. Evidence belongs in `docs/horizon/evidence/` without secrets.

## H06: Primary evidence adapters and registry

**Role:** research-data-worker. **Dependencies:** H01. **Kind:** source_work.

**Files — create:**
- `backend/src/features/research/evidence.model.js`
- `backend/src/features/research/evidence.service.js`
- `backend/src/features/research/providers/sec.js`
- `backend/src/features/research/providers/company_news.js`
- `backend/test/research-evidence.test.cjs`

**Execution steps:**
1. Write cutoff, filing-period/unit, amendment, URL allowlist, duplicate-news and unavailable-coverage tests.
2. Implement SEC/company IR/accessible news evidence adapters with bounded retrieval and fair-access behavior.
3. Persist source locators, publication/availability/retrieval times and headline-only flags.
4. Create normalized fact/excerpt outputs for analyst tools; do not invent transcripts/consensus.

**Acceptance:**
- Later filings or amended facts cannot enter earlier-cutoff evidence.
- Untrusted content cannot request tools, secrets, arbitrary HTTP or policy changes.
- Lean-source gaps are explicit and do not produce generic business claims.

**Named tests:** `backend/test/research-evidence.test.cjs`.

**Handoff:** exact diff/file list, test commands and actual results, fixture/source IDs, screenshots where applicable, known limits, next dependency; independent spec then quality review. Evidence belongs in `docs/horizon/evidence/` without secrets.

## H07: Deterministic metrics, economics and numerical scenarios

**Role:** quant-worker. **Dependencies:** H05, H06. **Kind:** source_work.

**Files — create:**
- `backend/src/features/research/metrics.js`
- `backend/src/features/research/scenarios.js`
- `backend/test/research-metrics.test.cjs`
- `backend/test/research-scenarios.test.cjs`

**Execution steps:**
1. Write independently checked fixtures for returns/averages/volatility/drawdown/relative returns/P&L and calendar horizon mapping.
2. Implement registry with method/input/source IDs and finite-value/basis guards.
3. Implement auditable conditional scenario/volatility reference calculations only when inputs justify them.
4. Return null plus a limitation when numeric projections lack sufficient inputs; no LLM arithmetic authority.

**Acceptance:**
- Money/quantity handling is deterministic; same-cost/split/currency assumptions tested.
- Calendar target/evaluation sessions correct at month ends, holidays and leap years.
- Volatility bands cannot be mislabeled expected direction or calibrated probability.

**Named tests:** `backend/test/research-metrics.test.cjs`, `backend/test/research-scenarios.test.cjs`.

**Handoff:** exact diff/file list, test commands and actual results, fixture/source IDs, screenshots where applicable, known limits, next dependency; independent spec then quality review. Evidence belongs in `docs/horizon/evidence/` without secrets.

## H08: Durable run state, evidence snapshots and thesis memory

**Role:** backend-worker. **Dependencies:** H04, H07. **Kind:** source_work.

**Files — create:**
- `backend/src/features/research/research_run.model.js`
- `backend/src/features/research/research_assessment.model.js`
- `backend/src/features/research/research_snapshot.model.js`
- `backend/src/features/research/thesis_state.model.js`
- `backend/src/features/research/research.service.js`
- `backend/src/features/research/research.routes.js`
- `backend/test/research-state.test.cjs`

**Execution steps:**
1. Write persisted idempotency, duplicate claim, owner isolation, revision superseding and checkpoint change tests.
2. Implement immutable assessment/snapshot references, exact position revisions and separate last-success/latest-attempt state.
3. Add atomic run claims/leases, stage artifacts, heartbeat/deadline state and restart recovery.
4. Expose research read/run endpoints as isolated router; integration lane mounts it later.

**Acceptance:**
- Concurrent callbacks cannot create duplicate assessments or cross-owner writes.
- Prior judgments are identified as judgments; triggered/retired/replaced checkpoints retain history.
- A crashed/expired run becomes stalled or recoverable, not forever running.

**Named tests:** `backend/test/research-state.test.cjs`.

**Handoff:** exact diff/file list, test commands and actual results, fixture/source IDs, screenshots where applicable, known limits, next dependency; independent spec then quality review. Evidence belongs in `docs/horizon/evidence/` without secrets.

## H09: Analyst tools, prompts, reviewer and validation

**Role:** research-engine-worker. **Dependencies:** H07, H08. **Kind:** source_work.

**Files — create:**
- `backend/src/features/research/prompts.js`
- `backend/src/features/research/tool_registry.js`
- `backend/src/features/research/agent_runtime.js`
- `backend/src/features/research/result_validator.js`
- `backend/test/research-agent.test.cjs`
- `backend/test/research-validation.test.cjs`

**Execution steps:**
1. Write fixture-based tests for role/tool scopes, direct state-aware actions, exactly three outlooks and numeric/source/cutoff rejection.
2. Implement the SPEC.md typed tool registry and code-enforced per-stage/read budgets.
3. Implement market analyst without cost, bounded challenge reviewer and position-aware synthesis using provider-supported response schemas.
4. Add few-shot cases, counterevidence/continuity requirements, metric rendering and at-most-two stage repair attempts.
5. Run frozen equal-input baseline/single/reviewer quality comparison with mocks first; live paid calls require approved budget.

**Acceptance:**
- A fabricated average, invented source, quote from post-cutoff data or candidate-as-owned recommendation is rejected.
- Changing average cost alone does not change market thesis; position economics update correctly.
- Reviewer cannot access unrestricted tools or private economics; synthesis sees only owner-bound revision.
- No model superiority or profitable-forecast claim without measured evidence.

**Named tests:** `backend/test/research-agent.test.cjs`, `backend/test/research-validation.test.cjs`.

**Handoff:** exact diff/file list, test commands and actual results, fixture/source IDs, screenshots where applicable, known limits, next dependency; independent spec then quality review. Evidence belongs in `docs/horizon/evidence/` without secrets.

## H10: n8n orchestration, leases, bounded delivery and status

**Role:** workflow-worker. **Dependencies:** H03, H09. **Kind:** source_work.

**Files — create:**
- `backend/src/features/research/automation.routes.js`
- `backend/src/features/research/run_worker.js`
- `backend/test/research-workflow.test.cjs`

**Files — modify only after reading and preserving baseline:**
- `n8n-workflow.json`
- `backend/src/utils/scheduler.js`
- `backend/scripts/test-research-workflow.cjs`

**Execution steps:**
1. Read preserved local export and compare live workflow read-only before patching; save one recoverable baseline via primary coordinator.
2. Write mocked end-to-end n8n/tool/callback tests, replaying malformed catalysts and missing result cases.
3. Update workflow source to run-bound service auth, stage artifacts, per-model schema/fallback version logging and idempotent callback.
4. Replace fire-and-forget scheduler behavior with persisted/leased claims, authenticated bounded dispatch and visible timeout/stall status.
5. Compile Code nodes with AsyncFunction and separate live smoke from hermetic tests; do not publish workflow.

**Acceptance:**
- Duplicate schedules/restarts do not duplicate research; status exposes failures/stalls and last success honestly.
- No arbitrary callback userId, unbounded 422 loop or literal exported credential.
- Unrelated n8n workflows remain untouched; source/export changes are not called a live deployment.

**Named tests:** `backend/test/research-workflow.test.cjs`.

**Handoff:** exact diff/file list, test commands and actual results, fixture/source IDs, screenshots where applicable, known limits, next dependency; independent spec then quality review. Evidence belongs in `docs/horizon/evidence/` without secrets.

## H11: Flutter typed domain and authenticated repositories

**Role:** flutter-domain-worker. **Dependencies:** H01. **Kind:** source_work.

**Files — create:**
- `frontend/lib/src/features/positions/position_models.dart`
- `frontend/lib/src/features/positions/position_repository.dart`
- `frontend/lib/src/features/market/market_models.dart`
- `frontend/lib/src/features/market/market_repository.dart`
- `frontend/lib/src/features/research/research_models.dart`
- `frontend/lib/src/features/research/research_repository.dart`
- `frontend/test/research_models_test.dart`

**Execution steps:**
1. Trace existing auth token/client conventions before importing anything; do not invent an api_client.dart.
2. Write parser/serialization/error-state tests from canonical fixtures.
3. Implement typed nullable economics, observed bars, claims/outlooks/overlays/run states and authenticated requests.
4. Regenerate only owned Freezed/JSON/Riverpod outputs under a generation lock; publish stable interfaces to UI lanes.

**Acceptance:**
- Strict semantics preserve unavailable versus zero, currency/time/basis and legacy classification states.
- Auth/error and cancellation behavior tested; no credential persisted into fixtures or JS bridge.
- Generated files are not hand edited.

**Named tests:** `frontend/test/research_models_test.dart`.

**Handoff:** exact diff/file list, test commands and actual results, fixture/source IDs, screenshots where applicable, known limits, next dependency; independent spec then quality review. Evidence belongs in `docs/horizon/evidence/` without secrets.

## H12: Position editor and candidate/owned experience

**Role:** flutter-position-worker. **Dependencies:** H04, H11. **Kind:** source_work.

**Files — create:**
- `frontend/lib/src/features/positions/widgets/position_editor.dart`
- `frontend/lib/src/features/positions/widgets/position_badge.dart`
- `frontend/test/position_editor_test.dart`

**Execution steps:**
1. Write widget tests for add candidate, classify legacy, edit owned cost/quantity/horizon, archive and revision conflict.
2. Build reusable widgets in existing theme without editing shared stock screen/router.
3. Make candidate/owned transitions explicit, unknown values honest and currency validation visible.
4. Supply integration-ready widgets and exact usage contract to H15.

**Acceptance:**
- No hypothetical entry becomes a filled purchase; no fake portfolio sizing.
- Text scaling/semantics/touch targets and error/retry states are verified.

**Named tests:** `frontend/test/position_editor_test.dart`.

**Handoff:** exact diff/file list, test commands and actual results, fixture/source IDs, screenshots where applicable, known limits, next dependency; independent spec then quality review. Evidence belongs in `docs/horizon/evidence/` without secrets.

## H13: Interactive observed-data chart and projection display

**Role:** flutter-chart-worker. **Dependencies:** H02, H05, H11. **Kind:** source_work.

**Files — create:**
- `frontend/lib/src/features/stock/widgets/price_chart.dart`
- `frontend/lib/src/features/stock/widgets/chart_controller.dart`
- `frontend/test/price_chart_test.dart`

**Execution steps:**
1. Write widget/controller tests for all six ranges, line/candles, stale response cancellation and observed/projection separation.
2. Promote approved prototype behavior into reusable themed component with axes, OHLCV readout, volume context, pan/zoom/reset.
3. Implement typed endpoint/range projection overlay and user-cost line with basis/freshness gates.
4. Capture phone/web interaction evidence and deliver component interface; H15 alone edits stock_detail_screen.dart.

**Acceptance:**
- Exact fixture values/timestamps and selected range survive style changes; no manufactured candles or future daily trajectories.
- Null/stale forecasts produce clear state and snapshot action, not scraped prose targets.
- Unavailable feed and first-load data gaps never render synthetic prices.

**Named tests:** `frontend/test/price_chart_test.dart`.

**Handoff:** exact diff/file list, test commands and actual results, fixture/source IDs, screenshots where applicable, known limits, next dependency; independent spec then quality review. Evidence belongs in `docs/horizon/evidence/` without secrets.

## H14: Direct recommendation and multi-horizon research panels

**Role:** flutter-research-worker. **Dependencies:** H09, H11. **Kind:** source_work.

**Files — create:**
- `frontend/lib/src/features/research/widgets/research_panel.dart`
- `frontend/lib/src/features/research/widgets/outlook_panel.dart`
- `frontend/lib/src/features/research/widgets/evidence_sheet.dart`
- `frontend/test/research_panel_test.dart`

**Execution steps:**
1. Write widgets tests for candidate versus owned actions, limited results, source links and independent 1/2/3-month tabs.
2. Build decision-first panel: action/reason/countercase/what-changed/invalidators with business versus price distinction.
3. Add source/freshness/run status and snapshot links; keep horizon selectors distinct from historical chart ranges.
4. Deliver standalone widgets; do not independently modify shared detail screen or global theme.

**Acceptance:**
- No vague placeholder replaces an evidence-backed recommendation; insufficient evidence remains a valid explicit conclusion.
- All displayed numbers resolve to validated metrics; date/currency/uncertainty labels readable and accessible.

**Named tests:** `frontend/test/research_panel_test.dart`.

**Handoff:** exact diff/file list, test commands and actual results, fixture/source IDs, screenshots where applicable, known limits, next dependency; independent spec then quality review. Evidence belongs in `docs/horizon/evidence/` without secrets.

## H15: Application integration and legacy/mobile/Wear compatibility

**Role:** integration-worker. **Dependencies:** H10, H12, H13, H14. **Kind:** source_work.

**Files — create:**
- `backend/test/research-compatibility.test.cjs`
- `frontend/test/research_compatibility_test.dart`

**Files — modify only after reading and preserving baseline:**
- `backend/src/app.js`
- `backend/package.json`
- `backend/src/server.js`
- `backend/src/features/briefing/briefing.service.js`
- `frontend/lib/main.dart`
- `frontend/lib/src/features/stock/stock_detail_screen.dart`
- `frontend/lib/src/features/stock/stock_repository.dart`
- `frontend/lib/src/features/briefing/briefing_repository.dart`
- `frontend/lib/src/features/briefing/briefing_config_repository.dart`
- `frontend/lib/src/features/dashboard/watchlist_provider.dart`
- `frontend/lib/src/features/nexus/management/manage_watchlist_screen.dart`
- `frontend/lib/src/wear/wear_watchlist_screen.dart`
- `frontend/lib/src/wear/wear_opportunities_screen.dart`
- `frontend/pubspec.yaml`
- `frontend/pubspec.lock`

**Execution steps:**
1. Write integration tests before mounting new routes and composing new widgets into the real detail/watchlist flow.
2. Mount authenticated position/market/research/automation routers and start recoverable run worker/leader without live publication.
3. Integrate typed data with legacy briefings/topics/opportunities; protect rich positions from old tickers-only writes.
4. Remove random/fake price-history fallbacks and extraction of authoritative prices from prose; render unavailable states across all real-market surfaces.
5. Update currency-aware summaries/Wear, stock screen heading and watchlist/star behavior; preserve design and inspect remaining synthetic call paths.
6. Own all shared manifest/model/glue changes and serialized code generation needed for existing models.

**Acceptance:**
- Current topics/news/opportunity consumers and Wear compile/parse correctly without a large chart on watch.
- No $100/random fallback or silent latest-price/old-analysis overwrite persists in new research flow.
- Only integrator edits shared files; updates to scheduler/export preserve prior dirty changes.

**Named tests:** `backend/test/research-compatibility.test.cjs`, `frontend/test/research_compatibility_test.dart`.

**Handoff:** exact diff/file list, test commands and actual results, fixture/source IDs, screenshots where applicable, known limits, next dependency; independent spec then quality review. Evidence belongs in `docs/horizon/evidence/` without secrets.

## H16: Forward outcome ledger and quality scorecard

**Role:** evaluation-worker. **Dependencies:** H08, H09. **Kind:** source_work.

**Files — create:**
- `backend/src/features/research/outcome.model.js`
- `backend/src/features/research/outcome.service.js`
- `backend/test/research-outcomes.test.cjs`
- `docs/horizon/evidence/evaluation-protocol.md`

**Execution steps:**
1. Write tests preventing settlement before availability, duplicate settlements and original assessment rewrites.
2. Implement append-only realized horizon/benchmark outcomes using exact calendar evaluation dates and method versions.
3. Define frozen quality set and simple no-change/no-LLM/strategy-appropriate baselines; separate quality from forecasting metrics.
4. Record insufficient mature observations without advertising a forecasting edge.

**Acceptance:**
- Outcome timing is point-in-time valid and idempotent.
- No retrospective lessons enter earlier snapshots; probabilistic metrics only when probabilities are valid/calibrated.

**Named tests:** `backend/test/research-outcomes.test.cjs`.

**Handoff:** exact diff/file list, test commands and actual results, fixture/source IDs, screenshots where applicable, known limits, next dependency; independent spec then quality review. Evidence belongs in `docs/horizon/evidence/` without secrets.

## H17: Full integration, failure injection and build evidence

**Role:** qa-worker. **Dependencies:** H15, H16. **Kind:** source_work.

**Files — create:**
- `backend/test/research-end-to-end.test.cjs`
- `frontend/integration_test/research_journey_test.dart`
- `docs/horizon/evidence/test-report.md`

**Execution steps:**
1. Run hermetic backend tests plus Flutter analyze/widget/parser tests on an actual supported toolchain.
2. Exercise candidate add -> research -> owned transition -> cost edit -> chart range/style -> snapshot/source/forecast -> failed/stalled run journey.
3. Inject provider/model/schema/timeouts/restart/concurrent edit/callback replay and source injection fixtures.
4. Build Flutter web and supported mobile/Wear targets; capture actual interaction proof and baseline-versus-new report review.
5. Keep live provider/generation/DB acceptance separate for primary coordinator; attach exact outputs and unresolved blockers.

**Acceptance:**
- No critical security/data correctness/continuity/chart regressions remain.
- Absent SDK/device/build access is explicitly blocked, never substituted with plausible output.
- All configured tickers are accounted for, not only AMD; coverage gaps are visible.

**Named tests:** `backend/test/research-end-to-end.test.cjs`, `frontend/integration_test/research_journey_test.dart`.

**Handoff:** exact diff/file list, test commands and actual results, fixture/source IDs, screenshots where applicable, known limits, next dependency; independent spec then quality review. Evidence belongs in `docs/horizon/evidence/` without secrets.

## H18: Independent release-readiness and financial-UX review

**Role:** independent-reviewer. **Dependencies:** H17. **Kind:** source_work.

**Files — create:**
- `docs/horizon/evidence/release-review.md`

**Execution steps:**
1. Read actual diffs, contracts and test evidence; reproduce critical tests independently.
2. Check privacy/tenancy, idempotency, evidence/math, uncertainty, report continuity, chart semantics and mobile accessibility.
3. Verify no hidden paid dependency, auth bypass, synthetic data path, unrelated refactor or unapproved profile/live change.
4. Approve with explicit remaining gates or return concrete defects to owning lanes; reviewer does not implement fixes.

**Acceptance:**
- Separate spec compliance and code/quality conclusions; author self-report is not acceptance.
- All contractual requirements have traceable tests/evidence or explicit blocker.

**Handoff:** exact diff/file list, test commands and actual results, fixture/source IDs, screenshots where applicable, known limits, next dependency; independent spec then quality review. Evidence belongs in `docs/horizon/evidence/` without secrets.

## H19: Primary-controlled migration, publication and readback

**Role:** primary-admin. **Dependencies:** H18. **Kind:** primary_release_gate.

**Files — create:**
- `docs/horizon/evidence/release-readback.md`

**Execution steps:**
1. Present exact live change set, credential/license/provider/budget needs, backup/restore proof and rollback to Adam.
2. After explicit approval, provision scoped service auth, dry-run and execute additive migration, then coordinate backend/client/workflow publication.
3. Read back live workflow published version, owner-scoped records, chart bars, all configured instrument results, failure/status behavior and public HTTP health.
4. Exercise rollback without deleting data/volumes; report actual verified end state and close/archive engagement only when gates pass.

**Acceptance:**
- No live actions before approval; no shared n8n restart or unrelated workflow changes.
- Backup restoration/readback is demonstrated and user data preserved.
- Publication is verified by exact target readback; tests plus source export alone are not a release.

**Handoff:** exact diff/file list, test commands and actual results, fixture/source IDs, screenshots where applicable, known limits, next dependency; independent spec then quality review. Evidence belongs in `docs/horizon/evidence/` without secrets.

