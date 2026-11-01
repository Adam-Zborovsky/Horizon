# Horizon implementation contracts

Status: proposed implementation baseline. No endpoints or fields in this document are claimed to exist yet. Existing routes/models are identified in SPEC.md. Changes to this contract must update all dependent tasks and fixtures before implementation proceeds.

## 1. Core decisions

- Contract version: `1` for the new research/position API; independent of legacy briefing format.
- All identifiers are opaque strings. Instrument identity is not ticker alone: `{instrument_id, symbol, exchange, currency, provider_symbol}`. Resolve through a vetted provider adapter; reject invalid/ambiguous identities, do not repair malformed symbols or silently pick an exchange.
- Exchange sessions and UTC instants are separate concepts. ISO date-only values denote the instrument's exchange-local session date; ISO timestamps always contain timezone information and are serialized in UTC. Never derive session dates solely by truncating a UTC timestamp.
- Position prices/costs carry currency. Financial periods, publication times, retrieval times, and session dates are distinct fields.
- Decimal money and quantity inputs use bounded decimal strings; provider OHLC values and derived analytical metrics use finite JSON numbers with explicit basis. No NaN/Infinity, negative prices, fabricated defaults, or zero-as-missing.
- API request/response shapes are validated in backend code and mirrored by typed Flutter models. Unknown fields in write requests are rejected. Additive response fields remain forward-compatible.
- Authentication/authorization is part of every endpoint, not an optional later hardening task.

## 2. Position

`Position` fields:

| Field | Type / semantics |
|---|---|
| `id`, `instrument_id` | Opaque IDs; instrument resolves to one exchange/currency |
| `state` | `candidate`, `owned`, or `legacy_unclassified` |
| `average_cost` | null or `{amount: decimal_string, currency: ISO_currency}`; strictly positive amount |
| `quantity` | null or positive decimal string; fractional shares allowed |
| `opened_on` | null or date-only; actual user-entered opening date, not forecast date |
| `preferred_horizon_months` | 1, 2, or 3; default 3 when a new user has not chosen; every assessment still contains all three horizons |
| `original_thesis` | User text, bounded length, optional; not treated as verified evidence |
| `review_conditions` | Bounded list of user-authored conditions, optional |
| `risk_context` | Optional declared risk constraints and portfolio context with timestamps/source; absent means unknown, not a profile inferred by AI |
| `archived` | Boolean; removal from active coverage is reversible archival, not deletion of history |
| `revision` | Positive integer; optimistic concurrency |
| `created_at`, `updated_at` | UTC timestamps |

Owner ID is server-derived from JWT, not writable by the client. User-facing responses need not expose it. All reads/updates are scoped to authenticated owner.

Rules:
- Candidate records have no executed cost/quantity/open date. A desired entry condition belongs in review_conditions, not average_cost.
- Owned records may have unknown cost/quantity: ask in UI but do not invent values or prevent market-level research. Do not infer taxes, portfolio weight, or personal risk capacity.
- Candidate -> owned is an explicit user action. Require supplied values to validate; never auto-convert an analyst's hypothetical entry into a transaction.
- Owned -> candidate after closing must clear active cost/quantity with a user-confirmed transition; preserve a revision/audit record. Full lot/realized-tax accounting is out of scope.
- Currency mismatch disables comparable P/L until a sourced FX conversion policy is implemented. No silent current-FX approximation.
- Legacy ticker records import as legacy_unclassified with null economics; require user classification before a position-specific recommendation. Generic stock research continues. This avoids treating prior model assumptions as actual purchases.
- Average cost does not become market support or fair value. Initial market/business analysis does not see it; position-aware synthesis does.
- P/L is code-calculated. Percent P/L can be shown with valid cost/current price in matching basis/currency; absolute P/L additionally requires quantity. Label fees/dividends excluded in the initial implementation. Splits must be reconciled or comparable P/L is unavailable with explanation.

## 3. Observed market bars and chart history

`MarketBar`: `{time, session_date, open, high, low, close, volume, adjusted_close, is_final}`.

- `time`: UTC start timestamp of intraday bucket; daily bars additionally use session_date as identity. Daily OHLC timestamps are not synthesized as midnight market trades.
- OHLC are observed finite positive numbers satisfying `low <= min(open,close) <= max(open,close) <= high`. Volume is a nonnegative integer or null with an availability reason; adjusted_close is finite positive or null.
- Bars are ascending, unique by instrument/resolution/session bucket, and accompanied by source, currency, price adjustment basis, exchange timezone, and fetch/publication metadata. Duplicate/out-of-order invalid bars are explicitly handled and tested.
- Never manufacture candles from a close array. Never fill missing sessions with fake OHLC or forward-filled volume. A missing bar is a gap/unavailable result.
- Raw tradable OHLC, split-adjusted prices, dividend-adjusted total returns, and cost basis must not be mixed. Provider adapter documents each basis and supplies corporate-action metadata. Transform entire OHLC consistently when using adjusted candles; adjusting only close is invalid.

`HistoryResponse`:
`{contract_version, instrument, snapshot_id, range, requested_resolution, actual_resolution, exchange_timezone, session_mode, adjustment_basis, as_of, fetched_at, data_status, delay_status, is_stale, available_ranges, bars, warnings, next_cursor}`.

`data_status`: `available`, `partial`, or `unavailable`. `delay_status`: `realtime`, `delayed`, or `unknown`; never claim real-time by default. Unavailable responses have an empty bar array and machine-readable reason. Stale cached results remain explicitly stale. `session_mode` defaults to regular hours and is labeled; extended-hours support is not silently inferred.

Initial ranges/resolutions:

| UI range | Semantics | Preferred resolution |
|---|---|---|
| 1D | Current regular trading session, or most recent completed session when closed | 5m |
| 1W | Most recent five exchange trading sessions, including current session if open | 30m |
| 1M | Last calendar month ending at cutoff | 1d |
| 3M | Last three calendar months ending at cutoff | 1d |
| 6M | Last six calendar months ending at cutoff | 1d |
| 1Y | Last calendar year ending at cutoff | 1d |

Provider adapters map these semantic ranges to supported fetch parameters. If intraday retention is insufficient, expose a supported resolution and reason; do not silently relabel daily bars as 30m. The UI labels actual resolution. Holidays/early closes/DST are exchange-aware. Calendar-month subtraction clamps month ends; result windows are inclusive of session endpoints as documented by adapter tests.

Chart display history can refresh independently of research runs. Viewing an assessment snapshot pins historical bars, as-of, metrics, and overlays to that immutable evidence snapshot. Default market view can show later bars, but must not present stale projection overlays as freshly issued.

## 4. Evidence and calculations

`EvidenceItem`:
`{id, instrument_id, kind, title, source_url, source_name, published_at, retrieved_at, available_at, reporting_period, excerpt, source_locator, facts, coverage_status}`.

- kind: `filing`, `earnings_release`, `transcript`, `company_ir`, `news`, `market_data`, `corporate_action`, `event_calendar`.
- available_at is the point-in-time availability cutoff used by research; later retrieval does not make a later amendment valid earlier evidence. Preserve original and amended/revised facts separately.
- reporting_period is not publication time; values include unit/currency and GAAP/non-GAAP basis where relevant.
- source_locator contains filing accession/page/section or transcript timestamp where available. URLs are vetted source links, never arbitrary model-generated destinations.
- Store only permitted retrieved content/excerpts. News headlines alone remain explicitly headline-only, not a read article or proof of a cause.
- External text, user thesis, and source pages are untrusted data and cannot alter tool permissions or instructions.

`Metric`:
`{id, instrument_id, value, unit, currency, as_of, basis, method, method_version, input_evidence_ids, input_snapshot_ids}`.

All returns, rolling indicators, drawdown, volatility, relative returns, valuation arithmetic, and P/L are computed in tested code. No model-derived authoritative figures. The numeric renderer resolves model references to supplied metric IDs; unregistered numerical claims are rejected or sent to bounded repair. Dates/horizon labels are not incorrectly treated as prices by simplistic regex checks.

`Claim`: `{text, evidence_ids, metric_ids, claim_type}`. claim_type is `observed`, `interpretation`, or `assumption`. Source-ID existence alone is not support: source entailment and temporal relevance are reviewed. Unverifiable causes, buyer/seller inferences from total volume, and unsupported valuation assertions must be flagged. Semantic review is not a mathematical proof; retain coverage limitations.

`EvidenceSnapshot`: immutable `{id, instrument_id, cutoff_at, session_as_of, market_snapshot_ids, evidence_ids, metric_ids, coverage, content_digest, created_at}`. Public company evidence can be cached/shared; personal position data must never enter shared caches.

## 5. Assessment and recommendations

`ResearchAssessment`:
`{id, contract_version, position_id, position_revision, instrument_id, run_id, evidence_snapshot_id, generated_at, session_as_of, status, market_thesis, recommendation, position_context, changes_since_previous, checkpoints, outlooks, missing_data, next_review, versions}`.

- status: `complete` or `limited`; unavailable/error belongs to run status, never an invented complete assessment.
- market_thesis: structured business assessment, price/technical assessment, valuation assessment, source-backed rationale and counterevidence. It is produced before personal cost is injected.
- recommendation: `{action, horizon_months, headline, rationale, countercase, invalidation_conditions, evidence_quality, predictive_uncertainty}`.
- action: `buy`, `wait`, `avoid`, `hold`, `hold_no_add`, `add`, `reduce`, `exit`, `insufficient_evidence`.
- Candidate actions: buy/wait/avoid/insufficient_evidence. Owned actions: hold/hold_no_add/add/reduce/exit/insufficient_evidence. Legacy_unclassified: insufficient_evidence for position-specific action; generic market thesis remains available.
- These are direct research recommendations, not automatic orders. They must be evidence-driven and consistent with the stated horizon. No forced hold bias or forced confident prediction.
- A position-specific add/reduce quantity or percentage requires current portfolio exposure and user constraints. Without them give the research stance and state the sizing limit, not an invented allocation. Missing average cost limits economics, not a negative market thesis or exit rationale.
- evidence_quality describes coverage/reliability. predictive_uncertainty describes forecast uncertainty. Neither is an uncalibrated probability of profit.
- Position context is copied from an exact revision and code-calculated metrics; if edited during generation, publication fails as superseded or reruns against the new revision. Never attach old analysis to new economics silently.

`outlooks` contains exactly one entry for each `horizon_months` 1, 2, and 3:
`{horizon_months, calendar_target_date, evaluation_session_date, direction, base_case, upside_case, downside_case, catalysts, invalidators, numeric_projection, data_limitations}`.

- All horizons anchored to evidence session_as_of. Add calendar months with month-end clamping; evaluate at the last exchange session on or before the calendar target. Store actual target/evaluation dates; do not substitute a fixed session count without relabeling the contract.
- direction: positive/negative/mixed/insufficient_evidence.
- Case/catalyst/invalidator entries are Claims. No fixed equal probability assumption, invented event dates, or identical copy across horizons.
- numeric_projection: null, or an audited code-produced object described below. A qualitative outlook remains valid without a numeric projection.

## 6. Persistent thesis/checkpoint state

`Checkpoint`: `{id, instrument_id, kind, metric_id, fixed_level, condition, created_at, updated_at, status, reason, source_assessment_id}`.

kind: rolling_indicator/fixed_observed_level/business_condition. A rolling indicator references identity/method and current metric; fixed_level is not simultaneously presented as a rolling average. status: active/triggered/retired. A change event records previous/current value/status, supporting evidence and why it changed.

`changes_since_previous` identifies prior assessment ID/session, missing report sessions, conditions that occurred, strengthened/weakened/unchanged/untested thesis components, retired/replaced checkpoints, and corrections. Prior generated judgments are not source evidence. Never rewrite earlier assessment documents to create retrospective consistency.

## 7. Projection overlays

`NumericProjection`:
`{id, assessment_id, instrument_id, evidence_snapshot_id, anchor_time, anchor_price_metric_id, target_session_date, kind, method, method_version, input_metric_ids, assumption_ids, lower, central, upper, currency, adjustment_basis, calibration, valid_until, limitations}`.

- kind: `conditional_scenario` or `volatility_reference` or `calibrated_forecast`.
- lower/central/upper are nullable finite positive numbers with explicit interpretation, ordered where present; never invent missing values. Bounds can exist without a central path.
- `conditional_scenario` numeric values require explicit assumptions and reproducible calculation. They are not probability intervals.
- `volatility_reference` is not a directional forecast. It cannot be labeled the analyst's expected path.
- `calibrated_forecast` requires model/version, held-out evaluation, coverage/calibration definition and observed validation evidence. No confidence fan is displayed based on verbal model confidence.
- Initial product supports conditional scenarios and reference ranges; calibrated forecasting is an extension gated by evaluation, not a launch claim.

Chart rules:
- Overlay toggle defaults off. Label future area “Conditional scenarios — not observed prices”; retain readable historical area when enabled.
- Observations use solid line/candles. Projections use dashed boundaries or discrete future endpoint/range markers, with issued date, target date, method, and assumptions accessible on tap.
- No future candles; no fabricated daily points between current price and monthly endpoints. Connecting segments, if ever provided, must be explicitly illustrative—not an inferred path. Initial default is endpoint ranges, not smooth predictive trajectories.
- No quantitative projection -> show “No quantified projection for this assessment,” never extract targets from prose or create a zero-width prediction.
- If displayed market data has advanced beyond assessment cutoff, default to hiding old overlays with an explicit stale notice and “View assessment snapshot” action. In snapshot mode overlay/history/metrics use the same snapshot and price basis.
- Show average-cost reference only for known matching currency and compatible corporate-action basis; label it user cost, not support. It is a separate overlay from projections.
- No gradient or styling that makes conditional scenarios look as certain as observed data.

## 8. Run lifecycle and idempotency

`ResearchRun`:
`{id, position_id, owner_id_internal, position_revision, run_kind, idempotency_key, status, stage, created_at, started_at, heartbeat_at, deadline_at, finished_at, evidence_snapshot_id, assessment_id, error_code, retry_count, versions}`.

run_kind: deep_research/daily_update/manual_refresh. status: queued/running/succeeded/limited/failed/stalled/superseded. A limited result may refer to a validated limited assessment; no result means failed/unavailable, not limited success.

- Same authenticated owner + position + idempotency key + same request returns same run/result. Same key with different payload returns 409. Persist idempotency state across process restarts.
- A worker claims runs atomically; at most one active run for the same position revision and request class. No unbounded callbacks/retrigger loops.
- Provider transport retries and schema repair are separate budgets. Initial policy: at most two generation/repair attempts for one stage and one bounded provider-fallback pass configured in code; preserve strict validation. Orchestrator records concrete stage/deadline budgets after live measurement; runs cannot remain running indefinitely.
- Heartbeat/deadline expiry produces stalled status; owner-visible last attempt/error and last successful report remain separate. Existing success timestamps are never updated to disguise failure.
- Resume from persisted stage artifacts when valid; otherwise explicit superseding run. Never inject future-known outcome lessons into an earlier cutoff.
- Callback authorization binds run, owner, position revision and snapshot. Server resolves ownership from run ID, never trusts arbitrary callback userId. Duplicate valid delivery is idempotent. Conflicting snapshot/revision returns 409.

## 9. Proposed API surface

All user routes use existing JWT middleware and server-derived owner filtering. Object IDs belonging to another user return indistinguishable 404 or consistent denial. No user-controlled arbitrary fetch URLs.

| Method/path under /api/v1 | Purpose | Success |
|---|---|---|
| GET /positions | Owner's tracked positions including classification-required state | 200 |
| POST /positions | Add validated instrument/state; duplicate active identity ->409 | 201 |
| PATCH /positions/:id | Explicit changed fields + expected_revision; conflict ->409 | 200 |
| GET /market/instruments/:id/history | Validated range/resolution/snapshot, authenticated | 200 including explicit unavailable data_status |
| GET /research/positions/:id/latest | Latest assessment + latest run state + freshness, separately | 200 with null assessment when none |
| GET /research/positions/:id/assessments | Cursor-paginated owner-scoped immutable history | 200 |
| POST /research/positions/:id/runs | Queue run; required Idempotency-Key header | 202 |
| GET /research/runs/:runId | Owner-scoped progress, freshness/error metadata | 200 |
| GET /research/evidence/:evidenceId | Authorized source-linked excerpt/metadata, no private cross-owner fields | 200 |
| GET /automation/research/runs/:runId/input | Scoped service identity, bound run input only | 200 |
| POST /automation/research/runs/:runId/stages/:stage | Scoped service identity + lease nonce; execute one allowed ready stage within its deadline, replay returns recorded artifact | 200 validated stage artifact/status |
| POST /automation/research/runs/:runId/tools | Scoped service identity; allowlisted tool_name + validated arguments; server binds run/instrument/cutoff/stage | 200 bounded read result |
| POST /automation/research/runs/:runId/result | Scoped service identity; backend validates/persists exact bound result | 201 first /200 identical duplicate |

Errors: 400 malformed request, 401 missing/invalid authentication, 403 insufficient automation scope, 404 not found/not owned, 409 revision/idempotency/snapshot conflict, 422 invalid researched result, 429 bounded/rate-limited trigger. Include safe code/message/request_id; never upstream tokens or sensitive raw payloads in logs.

Automation credentials are not user JWTs and not the n8n-management API key. Introduce/use a scoped Horizon service credential through the primary/admin release process. Never put it in Flutter, git, card bodies, workflow exported literal values, or URLs. Fail closed when unset. Authenticate the existing legacy POST /briefing and GET /briefing/config/system during coordinated rollout before exposing position economics. The empty legacy /webhook router is not proof of ingestion protection.

Tool requests contain only `tool_name`, `arguments`, `stage`, and `request_id`; validate them against a server-owned registry. Synthesis-only position tools cannot be invoked by the analyst or reviewer. Never accept arbitrary URLs, commands, code, owner IDs or raw database queries. Enforce the per-run/stage call budget, response size and cutoff server-side. Service callbacks additionally bind the current lease/run nonce and reject expired or replay-conflicting requests; idempotent retries do not count as new delivery. No new private economics is returned by the legacy public endpoint before authenticated rollout.

The initial implementation executes model/tool stages in the backend `agent_runtime` through an injected provider client. n8n invokes ready stage endpoints, observes recorded artifacts/status and requests validated delivery; it does not run a second competing analyst implementation. Private economics is injected server-side only for synthesis, not returned by a generic input endpoint. The stage parameter is an enum, never arbitrary code or a model name. Primary/admin must provision the backend provider identity using existing approved account access; workers use mocks and must not copy credentials out of n8n. If credential provisioning is unavailable, live model acceptance remains blocked rather than weakening authentication. HTTP and model deadlines are bounded and coordinated; stage replay must not re-charge a completed model call.

## 10. Legacy compatibility and forward outcome ledger

- Retain legacy briefing/topic/opportunity consumers during transition. Derive legacy tickers from active positions and keep old clients from wiping positions through a stale tickers-only PUT. Conflicting legacy updates are bounded/explicit, not destructive replacement.
- New research/chart APIs do not depend on `history: List<double>` in briefings. Compatibility sparklines use real closes from observed bars; unknown/legacy-provenance arrays are not relabeled observed. Remove random market prices/history from backend/mobile/wear paths or show explicitly unavailable UI.
- Existing stored briefings remain unchanged. No database wipe, volume recreation, or silent backfill of costs.
- Forward ledger stores immutable assessment ID, forecast/condition specification, issue/evaluation dates, benchmark definition, model/prompt/method/snapshot versions and later appended realized outcome. Outcome append is idempotent and cannot run before evaluation availability. Preserve adjustments and actual execution assumptions separately from simple research scoring.
- User facts/positions/reports remain owner scoped; instrument evidence/history may be shared only if no personal values enter it.
