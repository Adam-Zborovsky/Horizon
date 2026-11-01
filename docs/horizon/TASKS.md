# Horizon orchestrator work packages

Applied board state: [review consolidation audit](evidence/replan/trim-report.md), 2026-10-31 — 13 additional duplicate reviews archived, 62→49 non-archived cards, six capacity-only edges removed. Early integration/follow-up packages below remain planned until their live card mapping is verified; the review trim alone does not establish full board synchronization.

Current execution baseline: [AMENDMENT-2026-10-30.md](AMENDMENT-2026-10-30.md). Original full scope and pre-replan files remain in evidence/replan/. This package is authorized source work on the existing board, not deployment authority.

## Dispatch, review and ownership
One bounded author unit → one combined independent review (separate SPEC/QUALITY verdicts); only H03/H04/H07/H18 retain focused extra reviews. TDD steps remain inside each unit. Future authors deliver artifacts then needs_input block `review-required: author delivery ready`; controller verifies delivery before closing author and releasing reviewer. Never request-review, nested delegation, self-approval or sdlc-review. Different author/reviewer model/profile; same OpenAI vendor disclosed.

Cap 2 global workers via scheduled holds/managed ready queue, no capacity dependency edges. H15A→H15B→H15 owns shared application glue sequentially; H11 owns new Flutter domain/generator inputs. No hand-authored generated outputs; generation is on PC. File-disjoint modules may progress independently. All cards read SPEC.md and CONTRACTS.md, preserve dirty main baseline, use fixtures/mocks only, and obey the common invariants below.

Server backend command policy: from repository root `node --test backend/test/<named-file>.test.cjs`, eventually `node --test backend/test/*.test.cjs`, `git diff --check`. Tests are only claimed after real output. `backend/scripts/test-research-workflow.cjs` is live and must NOT be run here. Flutter source/test authoring here; all analyze/generation/test/device/web/mobile/Wear/APK execution DEFERRED_TO_DEV_PC. H17 writes DEV_PC_HANDOFF.md; DEVPC stays held before H18. Root/H19 remain operator-only. No renderer replacement.

## Five milestones
- M1 Safe truthful foundation: H00, H01, H03, H05, H15A. Status: H01_source_accepted_foundation_queued.
- M2 Research end to end: H04, H06, H07, H08, H09. Status: queued.
- M3 Usable interactive chart: H02, H11, H13. Status: source_queued_runtime_deferred_to_dev_pc.
- M4 Integrated application: H10, H12, H14, H15B, H15. Status: queued.
- M5 Reliability and release verification: H17, DEVPC, H18, H19. Status: external_and_operator_gates_held.

## Common invariants (repeat in every card)
- Secrets never in output, logs, fixtures, exported literal credentials, or card text; workers do not read .env or credential stores.
- No ports: in Docker compose; expose: only, route through existing Cloudflare Tunnels. No DNS/tunnel changes.
- No shell backgrounding (&, nohup, setsid); use tracked terminal background processes only when authorized.
- Preserve existing dirty/untracked baseline and user data; no git reset/clean, database or volume deletion, commit/push/history rewrite without explicit authorization.
- No live workflow publication, credential provisioning, live migration, paid service, license acceptance, or other-profile changes in worker cards; hand those to primary/admin.
- Observed market data and conditional scenarios remain separate. No invented prices, candles, history, source claims or verification output.
- Read SPEC.md and CONTRACTS.md; edit only assigned files. Shared files and generated outputs have one owner. Stop on contract drift.
- Write failing tests first, run them, implement, rerun; attach actual commands/output and remaining limitations. Do not claim an unavailable toolchain passed.
- After two failures on the same target, stop and escalate with exact errors and attempted fixes; no blind third retry.
- No confidential business data, secrets, profile/shared-skill/global-config changes, live operations, SDK/container installation, commits/pushes, or nested delegation.
- Author worker/gpt-5.6-terra; reviewer reviewer/gpt-6-luna; distinct profile/model, same OpenAI Codex vendor disclosed.
- Flutter runtime checks are DEFERRED_TO_DEV_PC, never PASS from source inspection. No renderer replacement.

## H00: Preflight and exact baseline

Role: integration-worker. Dependencies: none. Phase: core_source. Status: accepted_preflight_with_recorded_limits.

**Files — create:**
- docs/horizon/evidence/preflight.md

**Files — modify only within scope:**
- None.

**Named tests:**
- None.

**Execution steps:**
- Recheck repository root, branch, dirty/untracked paths and nested project rules.
- Record backend/deployment Node versions, actual Flutter lock resolution, SDK/build/device availability and existing test failures.
- Discover live workflow identity/version read-only with primary-controlled credential use where required.
- Define the shared-file lock/allowlists and record provider/license/live-operation gates.

**Acceptance:**
- Existing user changes are enumerated and protected; no secrets in baseline evidence.
- Flutter absence or baseline failures have exact evidence and a resolution gate, not an assumed pass.
- No live workflow or profile was changed.

**Review:** One independent combined specification and quality review with separate verdicts; targeted author repair then independent re-review. Focused extra review only H03/H04/H07/H18.
**Evidence:** docs/horizon/evidence/h00-author.md (authors); h00-review.md (combined reviewer); historic reports remain preserved.

## H01: Executable shared contracts and offline fixtures

Role: contract-worker. Dependencies: H00. Phase: core_source. Status: independently_accepted_source_only.

**Files — create:**
- backend/src/features/research/contracts.js
- backend/test/research-contracts.test.cjs
- backend/test/fixtures/research/observed-bars.json
- backend/test/fixtures/research/contract-cases.json

**Files — modify only within scope:**
- None.

**Named tests:**
- backend/test/research-contracts.test.cjs

**Execution steps:**
- Write failing schema tests for position, bars, claims, assessment, projections and run lifecycle.
- Implement Zod/JSON schemas matching CONTRACTS.md, including strict write fields and bounded values.
- Capture a source-dated sanitized observed-bar fixture and separately labeled engineered negative fixtures; no real personal costs.
- Publish canonical schema/fixtures and sample serialized outputs to all dependent lanes.

**Acceptance:**
- Invalid OHLC, numeric strings where forbidden, candidate economics, duplicate/missing horizon, stale/cross-currency cases fail.
- Fixtures explicitly distinguish observed recordings from test-only engineered cases.
- Consumer schemas have one version and no incompatible local variants.

**Review:** One independent combined specification and quality review with separate verdicts; targeted author repair then independent re-review. Focused extra review only H03/H04/H07/H18.
**Evidence:** docs/horizon/evidence/h01-author.md (authors); h01-review.md (combined reviewer); historic reports remain preserved.

## H02: Existing-library chart capability prototype

Role: chart-worker. Dependencies: H01. Phase: core_source. Status: scheduled.

**Files — create:**
- frontend/test/support/chart_probe.dart
- frontend/test/chart_capability_test.dart
- docs/horizon/evidence/chart-decision.md

**Files — modify only within scope:**
- None.

**Named tests:**
- frontend/test/chart_capability_test.dart

**Execution steps:**
- Read actual locked fl_chart APIs and versioned source, not redirected docs.
- Build a test-only native probe with observed intraday/daily OHLCV, line/candles, exact selection readout and common-axis overlays.
- Exercise pan/zoom/reset, range/style switches, volume context and phone/web touch semantics.
- Record screenshots/interaction proof and keep/reject decision; stop after one focused prototype session if a hard requirement fails.

**Acceptance:**
- Exact O/H/L/C/V/time matches fixture in line/candle selection; style/range state is preserved.
- Actual and future endpoint ranges never overlap as observed bars; stale/null projections handled.
- Existing fl_chart retained if all required behaviors pass; new renderer needs explicit dependency/license approval.
- Compile-only or no-phone-toolchain evidence is not mobile acceptance.

**Review:** One independent combined specification and quality review with separate verdicts; targeted author repair then independent re-review. Focused extra review only H03/H04/H07/H18.
**Evidence:** docs/horizon/evidence/h02-author.md (authors); h02-review.md (combined reviewer); historic reports remain preserved.

## H03: Scoped automation security and tenancy tests

Role: security-worker. Dependencies: H01. Phase: core_source. Status: scheduled.

**Files — create:**
- backend/src/middleware/automation.middleware.js
- backend/test/research-auth.test.cjs

**Files — modify only within scope:**
- backend/src/features/briefing/briefing.routes.js
- backend/src/features/briefing/briefing.controller.js
- backend/src/config/env.js

**Named tests:**
- backend/test/research-auth.test.cjs

**Execution steps:**
- Write anonymous ingestion/config, invalid service token/scope and owner spoofing denial tests.
- Implement fail-closed automation authentication with injected test secrets, safe logging and bounded bodies.
- Protect legacy system/ingestion code in source; document coordinated n8n deployment, without applying it live.
- Define run-bound callback nonce/lease authorization helper for new routes.

**Acceptance:**
- Anonymous legacy sensitive routes fail in tests; wrong/expired scopes and replay conflicts fail.
- Client-supplied userId cannot authorize new position/research operations.
- No real credential read/generated/stored by worker; live credential setup remains release gate.

**Review:** One independent combined specification and quality review with separate verdicts; targeted author repair then independent re-review. Focused extra review only H03/H04/H07/H18.
**Evidence:** docs/horizon/evidence/h03-author.md (authors); h03-review.md (combined reviewer); historic reports remain preserved.

## H04: Position persistence, owner-scoped API and migration preview

Role: backend-worker. Dependencies: H03. Phase: core_source. Status: scheduled.

**Files — create:**
- backend/src/features/positions/position.model.js
- backend/src/features/positions/position.service.js
- backend/src/features/positions/position.routes.js
- backend/scripts/migrate-positions.cjs
- backend/test/positions.test.cjs

**Files — modify only within scope:**
- None.

**Named tests:**
- backend/test/positions.test.cjs

**Execution steps:**
- Write owner-isolation, transitions, decimal validation, duplicate identity and revision-conflict tests.
- Implement position model/service/router with server-derived owner and reversible archival.
- Write dry-run-first additive migration with exact counts, legacy_unclassified defaults and reversible change manifest.
- Test candidate-to-owned and stale legacy tickers update policy without touching live DB.

**Acceptance:**
- No cost/ownership facts inferred from old tickers or model prose.
- Unknown costs remain null; currency mismatch and split basis block misleading P/L.
- Migration only exercised on isolated test data; live execution is not authorized.

**Review:** One independent combined specification and quality review with separate verdicts; targeted author repair then independent re-review. Focused extra review only H03/H04/H07/H18.
**Evidence:** docs/horizon/evidence/h04-author.md (authors); h04-review.md (combined reviewer); historic reports remain preserved.

## H05: Observed OHLCV history, snapshots and chart API

Role: market-data-worker. Dependencies: H01. Phase: core_source. Status: scheduled.

**Files — create:**
- backend/src/features/market/market.service.js
- backend/src/features/market/market.routes.js
- backend/src/features/market/market_snapshot.model.js
- backend/src/features/market/providers/yahoo.js
- backend/test/market-history.test.cjs

**Files — modify only within scope:**
- None.

**Named tests:**
- backend/test/market-history.test.cjs

**Execution steps:**
- Write range/resolution, ordering, invalid bars, stale cache, provider timeout and DST/holiday/early-close tests.
- Implement vetted instrument mapping, provider adapter, source metadata and immutable chart snapshots.
- Expose owner-authenticated history with truthful actual resolution and partial/unavailable status.
- Add request limits/cache keys and forbid fabricated OHLC or fallback quotes.

**Acceptance:**
- All six ranges follow CONTRACTS.md; unsupported intervals are labeled, not silently relabeled.
- Real timestamps/currency/adjustment/delay status survive serialization.
- Provider failures yield explicit gaps or stale cache, not synthetic points.

**Review:** One independent combined specification and quality review with separate verdicts; targeted author repair then independent re-review. Focused extra review only H03/H04/H07/H18.
**Evidence:** docs/horizon/evidence/h05-author.md (authors); h05-review.md (combined reviewer); historic reports remain preserved.

## H06: Primary evidence adapters and registry

Role: research-data-worker. Dependencies: H01. Phase: core_source. Status: scheduled.

**Files — create:**
- backend/src/features/research/evidence.model.js
- backend/src/features/research/evidence.service.js
- backend/src/features/research/providers/sec.js
- backend/src/features/research/providers/company_news.js
- backend/test/research-evidence.test.cjs

**Files — modify only within scope:**
- None.

**Named tests:**
- backend/test/research-evidence.test.cjs

**Execution steps:**
- Write cutoff, filing-period/unit, amendment, URL allowlist, duplicate-news and unavailable-coverage tests.
- Implement SEC/company IR/accessible news evidence adapters with bounded retrieval and fair-access behavior.
- Persist source locators, publication/availability/retrieval times and headline-only flags.
- Create normalized fact/excerpt outputs for analyst tools; do not invent transcripts/consensus.

**Acceptance:**
- Later filings or amended facts cannot enter earlier-cutoff evidence.
- Untrusted content cannot request tools, secrets, arbitrary HTTP or policy changes.
- Lean-source gaps are explicit and do not produce generic business claims.

**Review:** One independent combined specification and quality review with separate verdicts; targeted author repair then independent re-review. Focused extra review only H03/H04/H07/H18.
**Evidence:** docs/horizon/evidence/h06-author.md (authors); h06-review.md (combined reviewer); historic reports remain preserved.

## H07: Core deterministic metrics, economics and calendar horizons

Role: quant-worker. Dependencies: H05, H06. Phase: core_source. Status: scheduled.

**Files — create:**
- backend/src/features/research/metrics.js
- backend/test/research-metrics.test.cjs

**Files — modify only within scope:**
- None.

**Named tests:**
- backend/test/research-metrics.test.cjs

**Execution steps:**
- Write independently checked fixtures for returns/averages/volatility/drawdown/relative returns/P&L and calendar horizon mapping.
- Implement registry with method/input/source IDs and finite-value/basis guards.
- Keep numeric_projection null with explicit limitation until H07A is independently accepted. No scenario engine prerequisite.

**Acceptance:**
- Money/quantity handling is deterministic; same-cost/split/currency assumptions tested.
- Calendar target/evaluation sessions correct at month ends, holidays and leap years.
- Metric references remain reproducible and code-calculated; no fabricated projection.

**Review:** One independent combined specification and quality review with separate verdicts; targeted author repair then independent re-review. Focused extra review only H03/H04/H07/H18.
**Evidence:** docs/horizon/evidence/h07-author.md (authors); h07-review.md (combined reviewer); historic reports remain preserved.

## H08: Durable run state, evidence snapshots and thesis memory

Role: backend-worker. Dependencies: H04, H07. Phase: core_source. Status: scheduled.

**Files — create:**
- backend/src/features/research/research_run.model.js
- backend/src/features/research/research_assessment.model.js
- backend/src/features/research/research_snapshot.model.js
- backend/src/features/research/thesis_state.model.js
- backend/src/features/research/research.service.js
- backend/src/features/research/research.routes.js
- backend/test/research-state.test.cjs

**Files — modify only within scope:**
- None.

**Named tests:**
- backend/test/research-state.test.cjs

**Execution steps:**
- Write persisted idempotency, duplicate claim, owner isolation, revision superseding and checkpoint change tests.
- Implement immutable assessment/snapshot references, exact position revisions and separate last-success/latest-attempt state.
- Persist atomic claims/idempotency, immutable run input/result references, heartbeat/deadline/stalled states; safe restart terminates or explicitly supersedes an incomplete run. Generalized stage replay/recovery is H09X, not core prerequisite.
- Expose research read/run endpoints as isolated router; integration lane mounts it later.

**Acceptance:**
- Concurrent callbacks cannot create duplicate assessments or cross-owner writes.
- Prior judgments are identified as judgments; triggered/retired/replaced checkpoints retain history.
- A crashed/expired run becomes stalled or recoverable, not forever running.

**Review:** One independent combined specification and quality review with separate verdicts; targeted author repair then independent re-review. Focused extra review only H03/H04/H07/H18.
**Evidence:** docs/horizon/evidence/h08-author.md (authors); h08-review.md (combined reviewer); historic reports remain preserved.

## H09: Bounded grounded research pipeline and validation

Role: research-engine-worker. Dependencies: H07, H08. Phase: core_source. Status: scheduled.

**Files — create:**
- backend/src/features/research/prompts.js
- backend/src/features/research/agent_runtime.js
- backend/src/features/research/result_validator.js
- backend/test/research-agent.test.cjs
- backend/test/research-validation.test.cjs

**Files — modify only within scope:**
- None.

**Named tests:**
- backend/test/research-agent.test.cjs
- backend/test/research-validation.test.cjs

**Execution steps:**
- Test exact owner/revision/snapshot binding, direct state-aware actions, three distinct horizons, prior-assessment/checkpoint continuity and invalid evidence/number/cutoff cases.
- Use existing H05/H06/H07/H08 modules and injected clients in one fixed bounded Node pipeline, not a generalized tool/stage runtime. Freeze bounded source context before model invocation.
- Generate one grounded cost-free market synthesis (position state/horizon allowed, purchase cost/quantity excluded); deterministic server composition adds exact owner-bound economics and validates state-compatible stance. Changing cost alone cannot change the market thesis.
- Allow at most two synthesis/repair attempts total, explicit deadlines, missing coverage and failed/limited status. No model reviewer stage by default; preserve quality comparison requirement before adding one.
- Test with mocks, planted factual/temporal/unsupported-claim fixtures and a frozen evaluation protocol; no paid/live model calls or superiority claims.

**Acceptance:**
- Fabricated metrics/sources, post-cutoff facts and state-incompatible actions fail closed.
- Exactly one/two/three-month outlooks, direct source-backed conclusion/countercase, explicit missing data and prior-report/checkpoint changes.
- Personal economics stays out of market synthesis/shared caches; server joins exact revision and deterministic P/L.
- Bounded retrieval/repair/deadlines and real failure status; no generalized runtime or paid model comparison prerequisite.

**Review:** One independent combined specification and quality review with separate verdicts; targeted author repair then independent re-review. Focused extra review only H03/H04/H07/H18.
**Evidence:** docs/horizon/evidence/h09-author.md (authors); h09-review.md (combined reviewer); historic reports remain preserved.

## H10: Thin n8n trigger/poll/delivery and bounded run worker

Role: workflow-worker. Dependencies: H03, H09. Phase: core_source. Status: scheduled.

**Files — create:**
- backend/src/features/research/automation.routes.js
- backend/src/features/research/run_worker.js
- backend/test/research-workflow.test.cjs

**Files — modify only within scope:**
- n8n-workflow.json
- backend/src/utils/scheduler.js
- backend/scripts/test-research-workflow.cjs

**Named tests:**
- backend/test/research-workflow.test.cjs

**Execution steps:**
- Preserve source baseline; live workflow comparison is an operator release gate, not permission to access production here.
- Write hermetic trigger/execute/poll/result replay, deadline/stall, authorization and restart tests with injected clients.
- Node owns fixed pipeline execution; n8n only triggers, polls persisted status and delivers validated bound results, without an analyst loop.
- Implement minimal atomic persisted claims/leases, duplicate suppression, deadlines/stalls and bounded delivery; advanced scheduler/leader redesign is H10X. Preserve existing scheduler behavior outside this scope.
- Compile source Code nodes safely and separate live smoke; no workflow publication or production calls.

**Acceptance:**
- Duplicate schedules/restarts do not duplicate research; status exposes failures/stalls and last success honestly.
- No arbitrary callback userId, unbounded 422 loop or literal exported credential.
- Unrelated n8n workflows remain untouched; source/export changes are not called a live deployment.

**Review:** One independent combined specification and quality review with separate verdicts; targeted author repair then independent re-review. Focused extra review only H03/H04/H07/H18.
**Evidence:** docs/horizon/evidence/h10-author.md (authors); h10-review.md (combined reviewer); historic reports remain preserved.

## H11: Flutter typed domain and authenticated repositories

Role: flutter-domain-worker. Dependencies: H01. Phase: core_source. Status: scheduled.

**Files — create:**
- frontend/lib/src/features/positions/position_models.dart
- frontend/lib/src/features/positions/position_repository.dart
- frontend/lib/src/features/market/market_models.dart
- frontend/lib/src/features/market/market_repository.dart
- frontend/lib/src/features/research/research_models.dart
- frontend/lib/src/features/research/research_repository.dart
- frontend/test/research_models_test.dart

**Files — modify only within scope:**
- None.

**Named tests:**
- frontend/test/research_models_test.dart

**Execution steps:**
- Trace existing auth token/client conventions before importing anything; do not invent an api_client.dart.
- Write parser/serialization/error-state tests from canonical fixtures.
- Implement typed nullable economics, observed bars, claims/outlooks/overlays/run states and authenticated requests.
- Regenerate only owned Freezed/JSON/Riverpod outputs under a generation lock; publish stable interfaces to UI lanes.

**Acceptance:**
- Strict semantics preserve unavailable versus zero, currency/time/basis and legacy classification states.
- Auth/error and cancellation behavior tested; no credential persisted into fixtures or JS bridge.
- Generated files are not hand edited.

**Review:** One independent combined specification and quality review with separate verdicts; targeted author repair then independent re-review. Focused extra review only H03/H04/H07/H18.
**Evidence:** docs/horizon/evidence/h11-author.md (authors); h11-review.md (combined reviewer); historic reports remain preserved.

## H12: Position editor and candidate/owned experience

Role: flutter-position-worker. Dependencies: H04, H11. Phase: core_source. Status: scheduled.

**Files — create:**
- frontend/lib/src/features/positions/widgets/position_editor.dart
- frontend/lib/src/features/positions/widgets/position_badge.dart
- frontend/test/position_editor_test.dart

**Files — modify only within scope:**
- None.

**Named tests:**
- frontend/test/position_editor_test.dart

**Execution steps:**
- Write widget tests for add candidate, classify legacy, edit owned cost/quantity/horizon, archive and revision conflict.
- Build reusable widgets in existing theme without editing shared stock screen/router.
- Make candidate/owned transitions explicit, unknown values honest and currency validation visible.
- Supply integration-ready widgets and exact usage contract to H15.

**Acceptance:**
- No hypothetical entry becomes a filled purchase; no fake portfolio sizing.
- Text scaling/semantics/touch targets and error/retry states are verified.

**Review:** One independent combined specification and quality review with separate verdicts; targeted author repair then independent re-review. Focused extra review only H03/H04/H07/H18.
**Evidence:** docs/horizon/evidence/h12-author.md (authors); h12-review.md (combined reviewer); historic reports remain preserved.

## H13: Interactive observed-data chart and projection display

Role: flutter-chart-worker. Dependencies: H02, H05, H11. Phase: core_source. Status: scheduled.

**Files — create:**
- frontend/lib/src/features/stock/widgets/price_chart.dart
- frontend/lib/src/features/stock/widgets/chart_controller.dart
- frontend/test/price_chart_test.dart

**Files — modify only within scope:**
- None.

**Named tests:**
- frontend/test/price_chart_test.dart

**Execution steps:**
- Write widget/controller tests for all six ranges, line/candles, stale response cancellation and observed/projection separation.
- Promote approved prototype behavior into reusable themed component with axes, OHLCV readout, volume context, pan/zoom/reset.
- Implement typed endpoint/range projection overlay and user-cost line with basis/freshness gates.
- Capture phone/web interaction evidence and deliver component interface; H15 alone edits stock_detail_screen.dart.

**Acceptance:**
- Exact fixture values/timestamps and selected range survive style changes; no manufactured candles or future daily trajectories.
- Null/stale forecasts produce clear state and snapshot action, not scraped prose targets.
- Unavailable feed and first-load data gaps never render synthetic prices.

**Review:** One independent combined specification and quality review with separate verdicts; targeted author repair then independent re-review. Focused extra review only H03/H04/H07/H18.
**Evidence:** docs/horizon/evidence/h13-author.md (authors); h13-review.md (combined reviewer); historic reports remain preserved.

## H14: Direct recommendation and multi-horizon research panels

Role: flutter-research-worker. Dependencies: H09, H11. Phase: core_source. Status: scheduled.

**Files — create:**
- frontend/lib/src/features/research/widgets/research_panel.dart
- frontend/lib/src/features/research/widgets/outlook_panel.dart
- frontend/lib/src/features/research/widgets/evidence_sheet.dart
- frontend/test/research_panel_test.dart

**Files — modify only within scope:**
- None.

**Named tests:**
- frontend/test/research_panel_test.dart

**Execution steps:**
- Write widgets tests for candidate versus owned actions, limited results, source links and independent 1/2/3-month tabs.
- Build decision-first panel: action/reason/countercase/what-changed/invalidators with business versus price distinction.
- Add source/freshness/run status and snapshot links; keep horizon selectors distinct from historical chart ranges.
- Deliver standalone widgets; do not independently modify shared detail screen or global theme.

**Acceptance:**
- No vague placeholder replaces an evidence-backed recommendation; insufficient evidence remains a valid explicit conclusion.
- All displayed numbers resolve to validated metrics; date/currency/uncertainty labels readable and accessible.

**Review:** One independent combined specification and quality review with separate verdicts; targeted author repair then independent re-review. Focused extra review only H03/H04/H07/H18.
**Evidence:** docs/horizon/evidence/h14-author.md (authors); h14-review.md (combined reviewer); historic reports remain preserved.

## H15: Application integration and legacy/mobile/Wear compatibility

Role: integration-worker. Dependencies: H15B, H10, H13. Phase: core_source. Status: scheduled.

**Files — create:**
- backend/test/research-compatibility.test.cjs
- frontend/test/research_compatibility_test.dart

**Files — modify only within scope:**
- backend/src/app.js
- backend/package.json
- backend/src/server.js
- backend/src/features/briefing/briefing.service.js
- frontend/lib/main.dart
- frontend/lib/src/features/stock/stock_detail_screen.dart
- frontend/lib/src/features/stock/stock_repository.dart
- frontend/lib/src/features/briefing/briefing_repository.dart
- frontend/lib/src/features/briefing/briefing_config_repository.dart
- frontend/lib/src/features/dashboard/watchlist_provider.dart
- frontend/lib/src/features/nexus/management/manage_watchlist_screen.dart
- frontend/lib/src/wear/wear_watchlist_screen.dart
- frontend/lib/src/wear/wear_opportunities_screen.dart
- frontend/pubspec.yaml
- frontend/pubspec.lock

**Named tests:**
- backend/test/research-compatibility.test.cjs
- frontend/test/research_compatibility_test.dart

**Execution steps:**
- Write chart/automation/mobile/Wear integration tests, then compose chart into shared screens after the H15B shared-file handoff.
- Mount automation router and bounded run worker; retain H15A/H15B authenticated integration and accepted shared-file changes.
- Integrate typed data with legacy briefings/topics/opportunities; protect rich positions from old tickers-only writes.
- Remove random/fake price-history fallbacks and extraction of authoritative prices from prose; render unavailable states across all real-market surfaces.
- Update currency-aware summaries/Wear, stock screen heading and watchlist/star behavior; preserve design and inspect remaining synthetic call paths.
- Own all shared manifest/model/glue changes and serialized code generation needed for existing models.

**Acceptance:**
- Current topics/news/opportunity consumers and Wear compile/parse correctly without a large chart on watch.
- No $100/random fallback or silent latest-price/old-analysis overwrite persists in new research flow.
- Only integrator edits shared files; updates to scheduler/export preserve prior dirty changes.

**Review:** One independent combined specification and quality review with separate verdicts; targeted author repair then independent re-review. Focused extra review only H03/H04/H07/H18.
**Evidence:** docs/horizon/evidence/h15-author.md (authors); h15-review.md (combined reviewer); historic reports remain preserved.

## H16: Forward outcome ledger and quality scorecard

Role: evaluation-worker. Dependencies: H08, H09. Phase: follow_up. Status: deferred_held.

**Files — create:**
- backend/src/features/research/outcome.model.js
- backend/src/features/research/outcome.service.js
- backend/test/research-outcomes.test.cjs
- docs/horizon/evidence/evaluation-protocol.md

**Files — modify only within scope:**
- None.

**Named tests:**
- backend/test/research-outcomes.test.cjs

**Execution steps:**
- Write tests preventing settlement before availability, duplicate settlements and original assessment rewrites.
- Implement append-only realized horizon/benchmark outcomes using exact calendar evaluation dates and method versions.
- Define frozen quality set and simple no-change/no-LLM/strategy-appropriate baselines; separate quality from forecasting metrics.
- Record insufficient mature observations without advertising a forecasting edge.

**Acceptance:**
- Outcome timing is point-in-time valid and idempotent.
- No retrospective lessons enter earlier snapshots; probabilistic metrics only when probabilities are valid/calibrated.

**Review:** One independent combined specification and quality review with separate verdicts; targeted author repair then independent re-review. Focused extra review only H03/H04/H07/H18.
**Evidence:** docs/horizon/evidence/h16-author.md (authors); h16-review.md (combined reviewer); historic reports remain preserved.

## H17: Full integration, failure injection and build evidence

Role: qa-worker. Dependencies: H15. Phase: core_source. Status: scheduled.

**Files — create:**
- backend/test/research-end-to-end.test.cjs
- frontend/integration_test/research_journey_test.dart
- docs/horizon/evidence/test-report.md
- docs/horizon/DEV_PC_HANDOFF.md

**Files — modify only within scope:**
- None.

**Named tests:**
- backend/test/research-end-to-end.test.cjs
- frontend/integration_test/research_journey_test.dart

**Execution steps:**
- Run hermetic backend tests plus Flutter analyze/widget/parser tests on an actual supported toolchain.
- Exercise candidate add -> research -> owned transition -> cost edit -> chart range/style -> snapshot/source/forecast -> failed/stalled run journey.
- Inject provider/model/schema/timeouts/restart/concurrent edit/callback replay and source injection fixtures.
- Build Flutter web and supported mobile/Wear targets; capture actual interaction proof and baseline-versus-new report review.
- Keep live provider/generation/DB acceptance separate for primary coordinator; attach exact outputs and unresolved blockers.
- Produce DEV_PC_HANDOFF.md with exact source snapshot hashes, deferred criteria, safe transfer, generator order, actual discovered commands and APK artifact/hash requirements; server cannot pass PC gate.

**Acceptance:**
- No critical security/data correctness/continuity/chart regressions remain.
- Absent SDK/device/build access is explicitly blocked, never substituted with plausible output.
- All configured tickers are accounted for, not only AMD; coverage gaps are visible.

**Review:** One independent combined specification and quality review with separate verdicts; targeted author repair then independent re-review. Focused extra review only H03/H04/H07/H18.
**Evidence:** docs/horizon/evidence/h17-author.md (authors); h17-review.md (combined reviewer); historic reports remain preserved.

## H18: Independent release-readiness and financial-UX review

Role: independent-reviewer. Dependencies: H17, DEVPC, H07A, H09X, H10X, H16. Phase: full_release_gate. Status: scheduled_external_acceptance_wait.

**Files — create:**
- docs/horizon/evidence/release-review.md

**Files — modify only within scope:**
- None.

**Named tests:**
- None.

**Execution steps:**
- Read actual diffs, contracts and test evidence; reproduce critical tests independently.
- Check privacy/tenancy, idempotency, evidence/math, uncertainty, report continuity, chart semantics and mobile accessibility.
- Verify no hidden paid dependency, auth bypass, synthetic data path, unrelated refactor or unapproved profile/live change.
- Approve with explicit remaining gates or return concrete defects to owning lanes; reviewer does not implement fixes.

**Acceptance:**
- Separate spec compliance and code/quality conclusions; author self-report is not acceptance.
- All contractual requirements have traceable tests/evidence or explicit blocker.
- Unresolved follow-up requirements block full-release acceptance unless Adam explicitly changes scope. Source demo completion is not full scope completion.

**Review:** One independent combined specification and quality review with separate verdicts; targeted author repair then independent re-review. Focused extra review only H03/H04/H07/H18.
**Evidence:** docs/horizon/evidence/h18-author.md (authors); h18-review.md (combined reviewer); historic reports remain preserved.

## H19: Primary-controlled migration, publication and readback

Role: primary-admin. Dependencies: H18. Phase: full_release_gate. Status: operator_only_held.

**Files — create:**
- docs/horizon/evidence/release-readback.md

**Files — modify only within scope:**
- None.

**Named tests:**
- None.

**Execution steps:**
- Present exact live change set, credential/license/provider/budget needs, backup/restore proof and rollback to Adam.
- After explicit approval, provision scoped service auth, dry-run and execute additive migration, then coordinate backend/client/workflow publication.
- Read back live workflow published version, owner-scoped records, chart bars, all configured instrument results, failure/status behavior and public HTTP health.
- Exercise rollback without deleting data/volumes; report actual verified end state and close/archive engagement only when gates pass.

**Acceptance:**
- No live actions before approval; no shared n8n restart or unrelated workflow changes.
- Backup restoration/readback is demonstrated and user data preserved.
- Publication is verified by exact target readback; tests plus source export alone are not a release.

**Review:** One independent combined specification and quality review with separate verdicts; targeted author repair then independent re-review. Focused extra review only H03/H04/H07/H18.
**Evidence:** docs/horizon/evidence/h19-author.md (authors); h19-review.md (combined reviewer); historic reports remain preserved.

## H15A: Early protected observed-history API slice

Role: integration-worker. Dependencies: H03, H05. Phase: core_source. Status: scheduled.

**Files — create:**
- backend/test/research-history-integration.test.cjs

**Files — modify only within scope:**
- backend/src/app.js

**Named tests:**
- backend/test/research-history-integration.test.cjs

**Execution steps:**
- Read accepted H03/H05 interfaces; isolate app import/test setup from live server/database/scheduler.
- Mount authenticated observed-history route in existing app glue; retain legacy behavior and truthful unavailable responses.
- Exercise anonymous denial, valid authenticated observed fixture, unavailable/stale responses and error shape using hermetic injected mocks.

**Acceptance:**
- Protected history route is reachable through actual application routing in isolated tests, not only a detached service.
- No live bootstrap, fabricated history or premature position/research/automation mount.
- Publish exact shared app.js handoff for H15B.

**Review:** One independent combined specification and quality review with separate verdicts; targeted author repair then independent re-review. Focused extra review only H03/H04/H07/H18.
**Evidence:** docs/horizon/evidence/h15a-author.md (authors); h15a-review.md (combined reviewer); historic reports remain preserved.

## H15B: Early position and research panel integration

Role: integration-worker. Dependencies: H04, H09, H12, H14, H15A. Phase: core_source. Status: scheduled.

**Files — create:**
- backend/test/research-panel-integration.test.cjs
- frontend/test/research_panel_integration_test.dart

**Files — modify only within scope:**
- backend/src/app.js
- backend/src/features/briefing/briefing.service.js
- frontend/lib/src/features/stock/stock_detail_screen.dart
- frontend/lib/src/features/stock/stock_repository.dart
- frontend/lib/src/features/briefing/briefing_repository.dart
- frontend/lib/src/features/briefing/briefing_config_repository.dart
- frontend/lib/src/features/dashboard/watchlist_provider.dart
- frontend/lib/src/features/nexus/management/manage_watchlist_screen.dart

**Named tests:**
- backend/test/research-panel-integration.test.cjs
- frontend/test/research_panel_integration_test.dart

**Execution steps:**
- After H15A accepted shared-file handoff mount owner-scoped positions/research routes; retain protected observed-history slice.
- Connect position editor and decision/outlook/evidence panels to existing stock/watchlist flows with existing theme; preserve chart slot without requiring H13 first.
- Test candidate/owned/unknown economics, revision conflicts, prior-report changes, limited/no-result and latest-attempt versus latest-success using isolated fixtures.
- Do not overwrite immutable research prices with newly fetched values; remove synthetic fallbacks in touched flow. Runtime Flutter evidence deferred to PC.

**Acceptance:**
- An integrated source journey connects positions and grounded research panels without waiting for chart completion.
- Owner isolation, snapshot consistency and truthful unavailable states verified in executable backend integration tests.
- H15 receives shared-file diff/interface handoff; generated outputs remain PC-only.

**Review:** One independent combined specification and quality review with separate verdicts; targeted author repair then independent re-review. Focused extra review only H03/H04/H07/H18.
**Evidence:** docs/horizon/evidence/h15b-author.md (authors); h15b-review.md (combined reviewer); historic reports remain preserved.

## H07A: Follow-up: auditable numerical scenarios and overlay production

Role: backend-worker. Dependencies: H07. Phase: follow_up. Status: deferred_held.

**Files — create:**
- backend/src/features/research/scenarios.js
- backend/test/research-scenarios.test.cjs

**Files — modify only within scope:**
- None.

**Named tests:**
- backend/test/research-scenarios.test.cjs

**Execution steps:**
- Retain original H07 conditional scenario/volatility reference requirements, methods, inputs and independently computed fixture arithmetic.
- Produce optional projection objects only with auditable assumptions and compatible basis; do not manufacture daily paths.

**Acceptance:**
- Conditional ranges are not calibrated probabilities or directional volatility forecasts.
- Null/insufficient inputs remain explicit; downstream optional renderer contract preserved.

**Review:** One independent combined specification and quality review with separate verdicts; targeted author repair then independent re-review. Focused extra review only H03/H04/H07/H18.
**Evidence:** docs/horizon/evidence/h07a-author.md (authors); h07a-review.md (combined reviewer); historic reports remain preserved.

## H09X: Follow-up: generalized tools, stage replay and recovery

Role: backend-worker. Dependencies: H09, H08, H03, H10. Phase: follow_up. Status: deferred_held.

**Files — create:**
- backend/src/features/research/tool_registry.js
- backend/test/research-runtime.test.cjs

**Files — modify only within scope:**
- backend/src/features/research/agent_runtime.js
- backend/src/features/research/automation.routes.js
- backend/src/features/research/research.service.js

**Named tests:**
- backend/test/research-runtime.test.cjs

**Execution steps:**
- Preserve original typed tool names, scoped stage/tools endpoints, persisted stage replay and generalized recovery requirements from preserved SPEC/CONTRACTS.
- Only introduce additional model reviewer stages after frozen quality/cost/latency evidence justifies them; no automatic paid calls.
- Keep single Node execution owner, exact owner/revision/cutoff bindings, private economics isolation and no replay re-charge.

**Acceptance:**
- No unrestricted tool URLs/commands/owner IDs; response size/call/stage budgets enforced in code.
- Replay/recovery preserves immutable references and deadlines; extra stage benefits not asserted without evidence.

**Review:** One independent combined specification and quality review with separate verdicts; targeted author repair then independent re-review. Focused extra review only H03/H04/H07/H18.
**Evidence:** docs/horizon/evidence/h09x-author.md (authors); h09x-review.md (combined reviewer); historic reports remain preserved.

## H10X: Follow-up: advanced scheduler recovery and leadership

Role: backend-worker. Dependencies: H10, H09X. Phase: follow_up. Status: deferred_held.

**Files — create:**
- backend/test/research-scheduler.test.cjs

**Files — modify only within scope:**
- backend/src/utils/scheduler.js
- backend/src/features/research/run_worker.js
- n8n-workflow.json

**Named tests:**
- backend/test/research-scheduler.test.cjs

**Execution steps:**
- Retain advanced persisted stage scheduling/recovery and replica leader policy from original H10; no competing research owner.
- Tests cover lease ownership, process restart and bounded retry with isolated inputs; no service lifecycle/publication.

**Acceptance:**
- No duplicate model execution or deliveries from competing leaders; no unbounded delay chain.
- Preserve original dirty scheduler/workflow baseline and core bounded timeout/stall semantics.

**Review:** One independent combined specification and quality review with separate verdicts; targeted author repair then independent re-review. Focused extra review only H03/H04/H07/H18.
**Evidence:** docs/horizon/evidence/h10x-author.md (authors); h10x-review.md (combined reviewer); historic reports remain preserved.

## DEVPC: Development-PC runtime validation gate

Role: controller. Dependencies: H17. Phase: external_acceptance. Status: controller_held.

**Files — create:**
- None.

**Files — modify only within scope:**
- None.

**Named tests:**
- None.

**Execution steps:**
- Receive real PC generation/analyze/tests/device interactions/web/mobile/Wear/APK results and source snapshot/artifact hashes.

**Acceptance:**
- Real independent verification, not source-only PASS; no auto-dispatch on server.

**Review:** Independent evidence review at H18
**Evidence:** docs/horizon/evidence/devpc-author.md (authors); devpc-review.md (combined reviewer); historic reports remain preserved.

## Live-board synchronization — 2026-11-01 07:30 UTC (controller)

Supersedes all status values in this document dated before 2026-11-01. Verified from the live board, run logs and on-disk evidence (not memory):

- **Independently accepted, source-only (14 packages):** H00 (preflight, recorded limits), H01, H02, H03 (+focused security), H04 (+focused ownership/migration), H05, H06, H07 (+focused financial), H08, H09, H11, H12, H13, H15A. Per-lane evidence: `evidence/hXX-review.md` (FAIL→repair→PASS history preserved). Backend aggregate at H09 acceptance: 197/197 across 10 suites.
- **Running author lanes (cap 2):** H14 `t_5f43465d` (released 07:20 UTC morning resume), H10 `t_5a93e235` (released 07:25 UTC this sync).
- **Scheduled/awaiting:** H15B `t_fc55c3a0` (last gate: H14), H15 `t_a8e17276`, H17 `t_90250e8b`, H18 reviews (Dev-PC gate `t_65f71c73` precedes H18).
- **Deferred/held:** H16, H07A, H09X, H10X. H19 operator-only.
- **New scoped repair (held for capacity):** H09-N1 economics_status/economics.status naming collision — repair `t_d218b310` + child reviewer `t_77356be1`, per h09-review.md N1 (non-blocking finding; Adam requested the collision be removed).
- **Roster:** worker zai/glm-5.3-flash, reviewer deepseek/deepseek-v4-pro (vendor-disjoint). Older OpenAI model names in historical card bodies are superseded.
- **Concurrency:** cap 2 worker lanes per the 2026-11-01 continuation handoff (supersedes the 2026-10-31 cap-3 override).
- Card-ID mapping: `/home/ubuntu/.hermes/profiles/orchestrator/horizon-orchestration.json`; graph statuses mirrored in `task-graph.json` (`live_board_sync` block).
