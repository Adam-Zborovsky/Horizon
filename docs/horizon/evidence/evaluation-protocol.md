# H16 — Forward outcome ledger and quality scorecard — Frozen evaluation protocol

Status: held follow-up (delivery_phase `follow_up`), source-only backend. This
document is the frozen evaluation protocol for the H16 forward outcome ledger
and quality scorecard. It is a definition, not a runtime claim: nothing here
was exercised against live market data, a live model provider, or a live
MongoDB, and no forecasting edge is claimed.

Normative references: `docs/horizon/CONTRACTS.md` §10 (forward outcome ledger),
`docs/horizon/SPEC.md` §6 (definition of done — research quality),
`docs/horizon/evidence/evaluation-protocol.md` (this file).

## 1. Purpose

Horizon records predictions **before** outcomes are known, then appends the
realized outcome later, so that research quality and forecasting accuracy can
be measured without retrospective rewriting. The ledger answers two distinct
questions that must never be conflated:

1. **Forecasting** — was the forecast direction realized by the benchmark
   (direction hit rate)?
2. **Quality** — was the assessment well-grounded, honest and internally
   consistent (the frozen quality set)?

These are separate metrics (CONTRACTS §10: "separate quality from forecasting
metrics"). A grounded-but-wrong forecast and a right-for-the-wrong-reasons
forecast are both recorded; neither score is presented as a probability of
profit.

## 2. Forward outcome ledger

One append-only record per `(assessment_id, horizon_months)`. The forecast half
is immutable at write time; the outcome half is appended exactly once.

| Field | Semantics |
|---|---|
| `ledger_id` | Opaque unique id (service-assigned) |
| `owner_id_internal` | Owner-scoped (server-derived, never writable) |
| `assessment_id` | The immutable assessment this forecast came from |
| `instrument_id` | Instrument identity |
| `horizon_months` | 1, 2, or 3 |
| `direction` | `positive` / `negative` / `mixed` / `insufficient_evidence` — the frozen forecast |
| `issue_session_date` | The assessment's `session_as_of` — when the forecast was issued |
| `evaluation_session_date` | The exact calendar evaluation session (CONTRACTS §5) |
| `benchmark` | Frozen `{benchmark_id, method, method_version, definition, tolerance}` |
| `strategy` | Frozen `{strategy_id, kind}` — the forecasting strategy (analyst or baseline) |
| `versions` | Frozen model/prompt/method/snapshot version record |
| `status` | `pending` → `settled` (single permitted transition) |
| `realized_outcome` | `null` → `{realized_direction, benchmark_return, observed_session_date, source}` |
| `settled_at` | UTC timestamp of the single append |

### 2.1 Point-in-time validity and idempotency

- **Exact calendar evaluation dates.** The `evaluation_session_date` must equal
  the contract-computed evaluation session for `issue_session_date` +
  `horizon_months` (`contracts.calendarTargetDate` + `contracts.evaluationSessionDate`
  with the instrument's exchange-session predicate). A settlement must be
  observed at exactly `evaluation_session_date`; any other observation date is
  `INVALID_OUTCOME_DATE`.
- **No settlement before availability.** An outcome is knowable only after the
  evaluation session has passed; the service refuses settlement when the
  injected clock is not strictly later than `evaluation_session_date`
  (`OUTCOME_NOT_AVAILABLE`).
- **Idempotent settlement.** Replaying an identical realized outcome returns the
  existing settled record without a second write (`settled_at` unchanged). A
  conflicting second settlement is `OUTCOME_CONFLICT` — append-only, never a
  rewrite.
- **No original assessment rewrites.** Re-registering an identical forecast is
  idempotent; a differing re-registration for the same `(assessment_id,
  horizon_months)` is `FORECAST_CONFLICT`. The original assessment is never
  rewritten to create retrospective consistency (CONTRACTS §6).

### 2.2 Benchmark-defined realization

A direction forecast is realized by the sign of the instrument's horizon
return from the issue-session close to the evaluation-session close, against
the frozen benchmark `benchmark-total-return-sign` (method
`horizon_total_return_sign`, `method_version: 1`):

- return `> +tolerance` → `positive`
- return `< -tolerance` → `negative`
- within `±tolerance` → `mixed`

`tolerance` is part of the frozen benchmark and is recorded on each ledger
entry. The service computes the realized direction from the supplied
`benchmark_return` in code; a caller-supplied `realized_direction` that
contradicts the recorded return is `INVALID_REALIZED_DIRECTION`. The ledger
never trusts a self-asserted direction.

## 3. Baselines

Three strategy kinds are frozen (`outcome.service` `STRATEGY_KINDS`):

| Kind | Meaning |
|---|---|
| `strategy_appropriate` | The analyst's assessment — the primary subject |
| `no_change` | Predicts `mixed` every horizon (flat / no-change reference) |
| `no_llm` | A deterministic no-LLM rule (method + version declared per entry) |

Baselines are recorded through the same ledger and settlement path, so their
hit rates are comparable on an equal-input basis (SPEC §6). Any additional
baseline must declare a `benchmark` method + version; no baseline is inferred
implicitly. Baseline selection must be appropriate to the strategy's stated
horizon/mechanism.

## 4. Frozen quality set

Six deterministic per-assessment quality dimensions, each mapped to the H09
planted-defect code that governs it. Quality is scored from validator output,
fully separate from forecasting metrics.

| Dimension | Label | Governing defect code |
|---|---|---|
| `grounding` | Observed claims cite supporting evidence/metrics | `UNSUPPORTED_CLAIM` |
| `countercase` | Strongest countercase present and non-trivial | `MISSING_COUNTERCASE` |
| `coverage` | Missing data explicit; limited status carries missing_data | `LIMITED_WITHOUT_MISSING_DATA` |
| `continuity` | `changes_since_previous` references the exact prior assessment | `CONTINUITY_MISMATCH` |
| `horizon_integrity` | Three distinct horizons, no identical copy | `IDENTICAL_HORIZON_COPY` |
| `numeric_integrity` | No unregistered numerals or fabricated metric references | `UNREGISTERED_NUMBER` |

No dimension is a probability of profit. Quality observations carry per-dimension
`pass` / `fail` / `unknown`; `unknown` is excluded from the aggregate total.

## 5. Forecasting metrics and the edge prohibition

- **Direction hit rate** = `hits / scored` per strategy, where `scored` counts
  forecasts with `direction != insufficient_evidence`, and a hit is
  `forecast.direction === realized.direction`. `insufficient_evidence`
  forecasts are settled but never scored.
- **Maturity gate.** A hit rate is published only when the strategy has at
  least `MIN_MATURE_OBSERVATIONS = 10` scored observations. Below that the
  scorecard reports `insufficient_observations` and `hit_rate: null`.
- **No edge claim.** `edge_claim` is always `null`. A descriptive
  `baseline_comparison` (analyst vs baselines) is emitted only when both the
  primary strategy and a baseline are mature, and is explicitly labeled
  `descriptive_only: true` — never a superiority claim.
- **Probabilistic metrics only when valid/calibrated.** A direction hit rate is
  an empirical proportion (`is_calibrated_probability: false`), not a
  calibrated predictive probability. `calibrated_probability_metrics` is
  `null` unless per-forecast calibrated probabilities and calibration evidence
  are recorded — the ledger stores categorical directions only, so it never
  fabricates a calibrated probability. This is not a launch claim (SPEC §6:
  "do not declare a forecasting edge at release").

## 6. Insufficient mature observations

When fewer than `MIN_MATURE_OBSERVATIONS` scored observations exist for the
primary strategy, the scorecard records `insufficient_observations` with the
observed sample size and the threshold, and publishes no hit rate. This is an
honest "not enough data yet" state, never advertised as a forecasting edge and
never upgraded into a confidence number.

## 7. Limitations (deferred, not passed)

- **Live measurement.** Cost, latency, live provider/model behavior and the
  analyst-vs-analyst+reviewer comparison require live runs and are out of
  scope here (H10 integration lane / DEFERRED_TO_DEV_PC). No comparison or
  superiority claim is made.
- **Calibration.** Calibrated forecasting (Brier/reliability, coverage
  intervals) requires per-forecast probability output, which H07A holds; the
  scorecard never synthesizes it.
- **Storage-layer behavior.** The Mongoose model and repository are
  implemented and the model is probed with `validateSync`; unique-index and
  CAS behavior against a live MongoDB are deferred to the integration lane
  (H15/H17), per the hermetic-tests-only scope.
- **Wiring.** `OutcomeService` is a standalone module; no route mounts it. Route
  wiring is the single-owner integration change (H15), not H16.
