# Horizon Research and Interactive Charts Implementation Plan

> **For Hermes:** Use the subagent-driven-development skill for implementation units and the dedicated orchestrator's current swarm/routing rules for durable execution. This package is a planning deliverable, not authorization to launch a board or modify live systems in this session.

**Goal:** Deliver a position-aware, source-backed research workflow with direct recommendations, persistent reasoning, one/two/three-month outlooks, and an interactive observed-data chart while preserving Horizon's visual design.

**Architecture:** Keep Flutter/Riverpod/Freezed, Node/Express/Mongoose/MongoDB and n8n. The backend owns validated positions, observed market/evidence snapshots, deterministic calculations, run state, thesis history, numerical validation and outcomes. n8n orchestrates bounded analyst/reviewer calls and delivery; Flutter renders typed research and chart data from explicit APIs.

**Tech stack:** Existing CommonJS backend with Zod and Mongoose; existing Flutter chart dependency `fl_chart` first; provider adapters and schema-constrained model calls. No required new microservice, broker integration, vector database, paid feed, or model framework installation.

---

## 1. Scope and authority

Adam accepted the research redesign direction and specifically added interactive charts to the first-release scope. The requested deliverable here is a fully workable handoff for the orchestrator, not implementation or deployment in this chat.

Required:
- Considering entry versus owned; optional average purchase cost, quantity, original thesis, desired horizon and explicit context limits.
- Actual multi-timeframe market data, source-linked company evidence and tools; deterministic calculations.
- Independent market/business assessment followed by position-aware synthesis.
- Direct evidence-based recommendations, counterevidence and invalidation criteria, not vague generic summaries.
- One-, two-, three-calendar-month outlooks with assumptions, events, and quantified scenarios only where supported.
- Cross-day thesis/checkpoint continuity; honest missing-run and freshness reporting.
- Schema-constrained generation, numerical/source validation, bounded repair and visible failure/stall states.
- Immutable report/evidence/version and forward-outcome ledger.
- Interactive chart: line/candles, 1D/1W/1M/3M/6M/1Y, real timestamps, readable axes, OHLCV inspection, pan/zoom, reset, volume context and optional analyst scenario endpoint/range overlays.
- Retain current dark/obsidian/gold/glass visual identity and readable mobile/Wear compatibility.

Not included without another explicit decision:
- Broker trades, order execution, exact portfolio allocation optimization, tax-lot ledger, broker synchronization.
- A promise of predictive edge, uncalibrated probability fans, invented price targets, future candles or synthetic historical bars.
- Full TradingView terminal, arbitrary indicators/drawings, Pine Script, streamed exchange-grade ticks, expanded non-US coverage where reliable data is unavailable.
- Installing entire TradingAgents/FinRobot/FinAgent stacks. Borrow scoped tool/prompt/state techniques, not their infrastructure by default.
- Paid vendor/subscription commitments, unapproved license acceptance, changes to other Hermes profiles, DNS/tunnel changes, database/volume recreation.

Before future execution, obtain source-work authorization by sending ORCHESTRATOR.md to the orchestrator. Deployment, live data migration, credential provisioning, new paid services and publishing remain primary-agent/Adam gates. Do not infer them from feature enthusiasm.

## 2. Confirmed starting point and preservation

Repository: `/home/ubuntu/apps/Horizon`, branch `main` at inspection. Recheck both before work.

Pre-existing changes that must be preserved:
- Modified `backend/src/utils/scheduler.js`.
- Untracked `N8N_REBUILD_PROMPT.md`, `RESEARCH_RELEASE.md`, `backend/scripts/test-research-workflow.cjs`, `n8n-workflow.json`.

Do not git-reset, clean, overwrite, commit or push these without explicit scope. An isolated worktree made from HEAD alone omits this dirty baseline; do not treat it as the real project.

Confirmed existing code:
- Position configuration currently only topics/tickers: `backend/src/features/briefing/briefing_config.model.js:8–31` and `frontend/lib/src/features/briefing/briefing_config_model.dart:6–23`.
- Current watchlist editor: `frontend/lib/src/features/nexus/management/manage_watchlist_screen.dart`; provider `frontend/lib/src/features/dashboard/watchlist_provider.dart`.
- `frontend/pubspec.yaml:43`: fl_chart constraint `^1.1.1`; read actual lock resolution during preflight. Versioned official 1.1.1 source contains CandlestickChart/CandlestickSpot OHLC and transformation configuration. Its candle data has no volume field; render volume from the shared domain bars in separate UI/panel.
- Detail chart: `frontend/lib/src/features/stock/stock_detail_screen.dart:335–402`; hides axes, uses array-index X values, curved close-only line and a price-only touch tooltip. The user's practical interaction complaint is valid, but touch is not literally absent from the code.
- `frontend/lib/src/features/stock/stock_repository.dart:127–128,162–200` fabricates fallback history and missing-watchlist prices. Backend also fabricates history in `briefing.service.js:187–213`. These are not observed data and must not survive as real-looking prices/charts.
- Current source ingestion route POST /briefing and GET /briefing/config/system precede JWT middleware: `backend/src/features/briefing/briefing.routes.js:8–23`. Controller accepts arbitrary userId: `briefing.controller.js:24–37,52–69`. This is a release blocker before extending position economics to automation; no external exploit was attempted during planning.
- Empty `backend/src/features/briefing/webhook.routes.js` does not protect ingestion.
- `briefing.service.js:145–172` re-fetches prices at save time without recomputing research. New assessments must preserve their snapshot rather than mixing newer price with older reasoning.
- Current n8n prompt is daily-focused and next-few-days oriented; history fetches a year but passes summaries and ten recent bars. Local workflow export is not proof of the live version.
- Backend test script currently intentionally fails; existing `backend/scripts/test-research-workflow.cjs` tests live inputs and shape, not reasoning. Flutter currently has a smoke widget test.
- Local shell Node at inspection: v22.22.2. Flutter executable was not available on PATH. This plan does not claim Flutter tests/builds ran; a functioning Flutter toolchain is a preflight requirement for implementation acceptance.

README includes historical/stale descriptions; source and actual command output outrank it.

## 3. Chart decision and acceptance gate

### Recommended sequence

1. Use a bounded prototype with existing fl_chart before adding a dependency. It already has candles; do not spend a week implementing a custom financial plotting engine around it.
2. Keep it if the prototype proves common X-axis mapping, exact OHLCV inspection, pan/zoom, simple volume context and scenario endpoint alignment in both line and candle modes.
3. If a required capability cannot be achieved cleanly within one focused prototype session, stop and present the specific failing criterion, not a sunk-cost rewrite. Recommend self-hosted TradingView Lightweight Charts with a Flutter WebView bridge as the open-source fallback. Approval is required before new dependency adoption.
4. Syncfusion Flutter Charts is another native option with strong documented finance interactions, but it introduces license eligibility/acceptance and dependency gates. Do not assume Community License eligibility or buy a license.

### Products that must not be confused

| Product | Own Horizon data | Horizon overlays | Decision |
|---|---|---|---|
| Existing fl_chart | Yes | Custom shared-axis rendering needed | First prototype; zero new renderer dependency |
| Syncfusion Flutter Charts | Yes | Mixed series/annotations | Optional after license/dependency decision |
| TradingView hosted widget | Uses hosted TradingView feed/settings | Not the custom datafeed/overlay API required here | Not primary chart; optional external-link reference only |
| TradingView Lightweight Charts | Yes, application supplies bars | Separate series/primitives; own tooltip/bridge | Open-source fallback; retain attribution |
| TradingView Advanced Charts | Yes, custom datafeed required | Rich libraries with access/licensing conditions | Excess scope; not default for this project |

A chart library does not supply the application's historical feed. Hosted widget convenience does not solve evidence/price consistency.

### Mobile UX contract

- Keep existing visual tokens; simplify inner plot rather than restyling the whole app.
- Default line chart with readable price/time labels; straight segments, not spline smoothing that invents extremes.
- Clear Line / Candles toggle; timeframe controls independently labeled from forecast horizon tabs.
- Tap/drag or long-press inspection shows date/time with exchange zone, price and OHLCV where available. Support simple tap/step controls, not only precision gestures. Touch targets >=48 logical pixels, keyboard/semantic alternatives on web, scalable text and non-color-only up/down/actual/scenario distinction.
- Pinch/pan and visible reset/fit control; switching style preserves range and selection where still valid. Request cancellation/generation guards prevent stale responses overwriting a newly selected instrument/range.
- Visible current quote time, delay/freshness and observed data provenance. Loading, no data, partial/stale cache, provider error and retry are distinct.
- Volume context has a synchronized time axis or a clearly scoped inspected-bar readout; the prototype must demonstrate final planned presentation rather than promising a future panel.
- Average-cost line is optional and labeled user cost, not support. Require matching currency/price basis.
- Scenario overlay defaults off and uses future endpoint/range markers with issue/target dates; no fabricated daily path or future candles. Discrete scenarios are not calibrated probabilities. Stale overlays are hidden in live market view with an assessment-snapshot action.
- Preserve lightweight dashboard/Nexus/Wear sparklines from real closes; do not embed a full WebView chart on Wear.

Prototype proof: fixture assertions and screenshots/screen recording on a phone-size target plus Flutter web; interactions tested against known observed bars. Compile-only evidence is insufficient. If Android tooling/emulator/device access is unavailable, record the blocker and do not approve mobile acceptance from a desktop screenshot.

## 4. Research pipeline and tools

The backend is the system of record. Introduce logical modules under `backend/src/features/positions/`, `market/`, and `research/` (proposed directories). Keep their routes/models/services separate from legacy Mixed briefing parsing.

Pipeline:
1. Atomically create/claim a durable run for a position revision and idempotency key.
2. Resolve instrument, session cutoff and prior assessment; record versions and request scope.
3. Fetch/cache observed price series and primary evidence. Dates, source permissions, availability and corporate actions are explicit.
4. Compute metric registry in backend code. Freeze evidence snapshot and derived metrics.
5. Market analyst sees actual sequences, computed metrics, filing/news excerpts, prior market thesis and checkpoint state; it does not see purchase cost.
6. One bounded reviewer identifies unsupported claims, contradictory evidence, date/number problems, missing data and strongest thesis-breakers.
7. Position-aware synthesis receives the reviewed assessment, exact position revision and deterministic economics. It emits direct action plus three distinct horizon outlooks and changes since prior report.
8. Enforce schema, action/state constraints, source/metric support, cutoffs and numeric projection provenance. At most two generation/repair attempts per stage, then explicit failed/limited status according to CONTRACTS.md. No unbounded debate or 422 retry storm.
9. Backend atomically persists immutable assessment and state-change records; idempotent n8n callback cannot attach a result to another user/run/revision.
10. Render mobile/Wear compatibility projections without fabricating missing market facts; append forward outcomes after evaluation sessions.

### Typed tool registry (borrowed techniques, implemented locally)

| Tool | Allowed stage | Function |
|---|---|---|
| `get_market_history` | Evidence / analyst | Vetted instrument/range, observed OHLCV and provenance |
| `get_market_metrics` | Analyst | Code-computed indicators, drawdown and relative performance |
| `get_financial_facts` | Evidence / analyst | Filing-linked values with period/unit/basis |
| `get_filing_excerpt` | Analyst | Known filing/evidence ID and bounded section, no arbitrary URL |
| `get_earnings_context` | Analyst | Verified earnings release/guidance/call excerpts or explicit unavailable |
| `get_material_news` | Evidence / analyst | Dated material passages/headlines with exact coverage status |
| `get_confirmed_events` | Analyst | Source-backed event dates, not guessed earnings calendars |
| `get_prior_thesis` | Analyst / synthesis | Earlier judgments/checkpoints labeled as prior decisions, not facts |
| `get_position_context` | Synthesis only | Owner-bound revision, cost and deterministic P/L, never shared cache |
| `validate_research_result` | Reviewer / delivery | Deterministic schema/numeric/cutoff/authorization checks plus semantic-review findings |

Tool parameters are schema-validated and server-bound to run/instrument/cutoff. Per-stage allowlists, read limits, provider timeouts and call budgets are enforced by code, not merely prompts. Reviewer receives frozen evidence/result and cannot browse arbitrarily or mutate state. No eval/LLM-generated code, filesystem access, unrestricted HTTP, SQL, broker tools or credential tools.

Default initial tool budget: analyst up to eight read calls per instrument and one bounded follow-up retrieval pass when coverage is insufficient; reviewer uses supplied evidence with no independent web tool; synthesis reads one exact position revision. Make budgets named code constants and record exhaustion as missing coverage. Deep evidence gathering can run before analyst without pretending the LLM fetched it itself.

n8n may call the scoped automation tool endpoint defined in CONTRACTS.md; tool requests never accept an authoritative ownerId from the model. Model calls use provider-supported strict response schemas; fallback model changes are recorded and tested. Borrow prompt structure from primary research, not verbatim broad “comprehensive report” instructions.

### Evidence-source default

Use existing market feed through a replaceable, validated adapter plus SEC/company IR sources and relevant accessible news/call passages. Check feed usage/redistribution suitability before public rollout. SEC facts require period/unit/availability normalization. Consensus estimates, complete transcripts and global data may be unavailable on the lean path; label those gaps rather than claiming coverage.

No paid data is required for development acceptance. If the lean sources cannot support a required company's business thesis, produce an honest limited result and present a concrete provider choice/cost gate. Do not ship generic pretend-fundamental conclusions to fill the gap.

### Refresh policy

Deep research on initial classification/coverage, material filings/results/events and a periodic review. Daily update compares new evidence/price structure with the persisted thesis. Position edits supersede personal synthesis, not shared company evidence. Shared snapshots contain no position data. Model context must distinguish no material change from missing data.

## 5. Integration, migration and operations

- CONTRACTS.md is the single cross-lane behavior baseline. First contract task creates executable Zod/JSON schemas and sanitized fixtures before production module implementation proceeds.
- New modules mount only in the integration lane; module authors do not race on app.js or package manifests.
- One Flutter model/generation owner; never hand-edit Freezed/generated serializers. UI work uses stable domain interfaces. One integrator owns stock_detail_screen.dart and app routing, avoiding simultaneous chart/report/position edits to the same file.
- Migration is additive, dry-run-first and reversible at the document level. Preserve users/briefings and existing tickers. Legacy ticker -> legacy_unclassified/null economics. Dual-read compatibility must not let an old tickers-only PUT wipe richer positions. Live migration execution requires approval, not just reviewer acceptance of its script.
- Authentication changes and n8n callbacks deploy together under a short documented maintenance window; fail closed, never leave a temporary public bypass. Horizon service credential and n8n-management API key are different identities.
- Persist runs/heartbeats/stage artifacts and recoverable deadlines. Replace reliance on in-process setTimeout chains with atomically claimed persisted work; no new queue service is required initially. One scheduler leader/lease prevents replica duplicates. Avoid N×15-minute uncontrolled delay.
- Last successful assessment and last attempted run are separate. User sees queued/running/failed/stalled/superseded status and stale-data warning. A heartbeat monitor must detect absent/stalled scheduled output, not only explicit errors.
- No credential/position economics in logs, test fixtures, exports or card bodies. All sensitive provisioning/live writes stay with primary/admin, not autonomous worker cards.
- Preserve topic/news/opportunity behavior while removing synthetic price/history fallback across all real-market render paths. Existing historical reports remain untouched; unknown legacy provenance is not relabeled observed.
- Keep notification style and unrelated app design intact. No new unsolicited notification stream or dashboard infrastructure.

## 6. Measurable definition of done

Engineering:
- Every contract endpoint has request validation, ownership/scoped-service tests, safe errors and idempotency/revision tests.
- Existing unauthenticated ingestion/config routes cannot expose positions or accept anonymous cross-user writes after coordinated release.
- All configured instruments yield validated complete/limited results or visible unavailable failure, never a plausible subset.
- No synthetic production prices, candles or history; no price extraction from recommendation text.
- Exact known fixtures verify rolling averages, returns, P/L, chart OHLCV, calendar horizons, split/currency handling, source cutoff and deterministic scenario math.
- Cross-day fixtures prove crossed/retained/replaced checkpoints and stance changes are explained; prior errors can be corrected without rewriting history.
- Candidate/owned/unknown states render correctly; missing economics never become invented facts; changing only cost does not change market thesis.
- One/two/three outlooks exist once each with explicit dates, distinct evidence/assumptions and a direct recommendation when justified.
- Malformed catalysts, invented metric values/source IDs, contradictory action/state, missing evidence, stale position revision and duplicate callbacks fail safely.
- Chart prototype and final UI demonstrate real interactions, all ranges, readable axes/labels, reset, exact timestamps and separate optional forecast endpoints.
- Mobile/web/Wear parsing, auth, topics, opportunities, watchlist editing and refresh are regression-tested.
- Durable run restart/duplicate/stall/timeout scenarios are exercised; last-success freshness remains honest.

Research quality:
- Candidate and owned samples show source-linked rationale, strongest countercase, what changed and invalidators without generic boilerplate.
- No claim that price alone establishes a changed business thesis; no causal claim from a headline alone or buyer absence from total volume.
- Reviewer identifies known planted factual/temporal problems; schema-only pass does not count as reasoning validation.
- A frozen evaluation set compares previous baseline, new single analyst, and analyst+reviewer on quality/cost/latency. Default existing provider is retained unless evidence justifies a change.
- Forward ledger records predictions before outcomes. Mature outcomes are append-only, idempotent and benchmark-defined; do not declare a forecasting edge at release.

Operational:
- Actual build/test outputs and target UI evidence are attached. Missing Flutter/device/tool credentials remain blockers, not simulated passes.
- One recoverable workflow/application baseline and actual database backup with tested restore/readback are available before migration/release. Never recreate database volume to rebuild the app.
- Primary release coordinator verifies published workflow version, stored assessment, owner authorization, public endpoint health and rollback behavior. No worker self-report substitutes for readback.

## 7. Test command policy

Baseline commands to discover/recheck:
- `git status --short` and `git branch --show-current` from repository root.
- `node --version`; inspect supported Node version in backend build image. Tests must run on the deployment runtime, not only the host.
- `node backend/scripts/test-research-workflow.cjs` exists but performs live calls; run only as a separately labeled live smoke, not an offline unit suite.
- `flutter --version`, `dart --version`, `flutter devices` where toolchain/device is available. No false SDK version assumption from README badges.

Planned verification after corresponding tasks create tests:
- From root: `node --test backend/test/*.test.cjs` (flat test directory; new files are named per TASKS.md).
- From frontend: `dart run build_runner build --delete-conflicting-outputs` after model owners approve generated-only conflicts, `flutter analyze`, `flutter test`.
- From frontend: `flutter build web --release`; verify a supported Android/mobile build using inspected flavor/build configuration, not a guessed flavor argument. Wear compile with `lib/main_wear.dart` and the project's actual target flags.
- Physical/emulated interaction capture and visual assertions are additional to automated tests.

If Flutter is absent, use the project's existing build tooling/container or obtain an approved toolchain. Do not silently install an arbitrary SDK or let compilation absence erase mobile acceptance criteria.

## 8. Handoff contents

- README.md: entry point and recommended dispatch sequence.
- CONTRACTS.md: cross-lane data, API, state, time, projection and security behavior.
- TASKS.md: independently assignable tasks with files, tests, dependencies and acceptance evidence.
- task-graph.json: machine-readable dependency graph; no live IDs or profile/model pins.
- ORCHESTRATOR.md: copy/paste execution prompt and authority boundary.
- SOURCES.md: inspected primary research/chart sources and findings.
- validation.md: plan-only validation output and limitations; implementation status remains not started.

Review the entire package before dispatch. Do not reuse unavailable prior-chat attachments or assume the orchestrator has this conversation.
