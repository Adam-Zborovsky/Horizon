# H09 — Bounded grounded research pipeline and validation — Author Delivery

- Task: t_c5e7237e (H09), delivery_phase: core_source, scope: source-only backend
- Author: worker (dispatched profile; roster per release note 2026-10-31: worker/zai/glm-5.3-flash)
- Status: AUTHOR DELIVERY — not independent acceptance. Controller verifies delivery; independent reviewer inspects artifacts.
- Baseline preserved: existing dirty/untracked main baseline untouched; no commit/push, no branch change, no cleanup, no file outside the canonical package created or modified. `git status --porcelain` for the touched paths shows only untracked additions (`??`).

## 1. Delivered files (all new; exactly the canonical package)

| Path | Lines | SHA-256 |
|---|---|---|
| backend/src/features/research/prompts.js | 328 | 11a69aff4cafb22d8e02db4c042601eddb9e2f287144e3c054ef5e71e69bd2d3 |
| backend/src/features/research/agent_runtime.js | 337 | 4604249a72745f29580a7cab98b382e6c059edcaea93f89efa25d6f33d96d86f |
| backend/src/features/research/result_validator.js | 386 | d17e874f96d36221a2e8aebf14b08ab0d2d72679f7675f5b916ab950cba4b213 |
| backend/test/research-agent.test.cjs | 503 | 3b8ffeb29946d479d63730f96ee05b14b1fb804c59f4810560ca86232b70a4ba |
| backend/test/research-validation.test.cjs | 545 | 78da215858b55f583a20feebdb60ee146f3c84e6a86c592c14094395c41e6ae0 |

Evidence artifacts: `docs/horizon/evidence/h09/red-run.log` (real TDD red run, exit 1, both suites failing on `Cannot find module` before implementation), `docs/horizon/evidence/h09/verification.log` (green run + full regression battery + `git diff --check`), `docs/horizon/evidence/h09/integrity.log` (secret scan, status, hashes). `existing_files` in the canonical package is empty; `contracts.js`, H06 evidence service, H07 metrics, H08 research.service/routes, Flutter sources: untouched.

## 2. Commands and results (this run, host node v22.22.2, hermetic offline)

All commands foreground in /home/ubuntu/apps/Horizon. No live APIs, no model calls beyond scripted in-process mocks, no credentials, no DB connection, no installs, no shell backgrounding.

```
node --test backend/test/research-validation.test.cjs   -> exit 0; 24 pass, 0 fail (TDD green)
node --test backend/test/research-agent.test.cjs        -> exit 0; 20 pass, 0 fail (TDD green)
node --test backend/test/                               -> all ten suites:
  market-history 12/12, positions 41/41, research-agent 20/20, research-auth 6/6,
  research-contracts 14/14, research-evidence 19/19, research-history-integration 11/11,
  research-metrics 24/24, research-state 26/26, research-validation 24/24  (= 197/197)
git diff --check                                        -> clean, exit 0
secret scan (credential-literal pattern over delivered files) -> no matches
```

Predecessor suites (153 pre-existing tests) all green: no regression. Full output in `docs/horizon/evidence/h09/verification.log`.

## 3. TDD record

Red (captured live, full log at `docs/horizon/evidence/h09/red-run.log`):

```
node --test backend/test/research-agent.test.cjs backend/test/research-validation.test.cjs -> exit 1
# Error: Cannot find module '../src/features/research/prompts' (x2 suites fail)
```

Then implement -> green (197/197 aggregate). Iterations during the green phase were test/implementation co-fixes within the same unit (missing `await` on the async pipeline helper; regex suffix bug in `NUMERIC_TOKEN_RE`; fixture id/basis corrections; server-side normalization of `missing_data` and null-prior `changes_since_previous` before validation). Two failures on the same target never required escalation: each failure had a distinct, diagnosed cause and a single targeted fix.

## 4. Contract mapping (what each acceptance line is, and where it lives)

| Acceptance / step | Implementation |
|---|---|
| Fabricated metrics/sources fail closed | `result_validator.checkClaims` — every `evidence_id`/`metric_id` must resolve in the frozen context index (`FABRICATED_SOURCE`, `FABRICATED_METRIC`); rolling-checkpoint `metric_id` must resolve (`FABRICATED_METRIC`) |
| Post-cutoff facts fail closed | `prompts.buildMarketSynthesisContext` drops items with `available_at`/`published_at` > `cutoff_at` and records gap `post_cutoff_evidence_excluded`; `result_validator` independently re-checks every referenced id against the cutoff (`POST_CUTOFF_REFERENCE`, defense in depth) |
| State-incompatible actions fail closed | `result_validator` `STATE_ACTIONS` mirror of CONTRACTS §5 (`STATE_INCOMPATIBLE_ACTION`); composed assessment re-validated by `researchAssessmentSchema` superRefine |
| Exactly one/two/three-month outlooks | `metrics.outlookHorizons` (H07) computes calendar/evaluation dates server-side; model-supplied dates must match (`INVENTED_HORIZON_DATE`); runtime stamps the contract dates; schema `.length(3)` + superRefine gate |
| Direct source-backed conclusion/countercase | thesis sections + non-empty rationale + non-empty counterevidence enforced (`MISSING_COUNTERCASE`, `MISSING_FIELD`); every `observed` claim must cite ≥1 evidence/metric id (`UNSUPPORTED_CLAIM`) |
| Unregistered numbers | `prompts.containsUnregisteredNumericClaim` strips ISO dates, `Q1–Q4` and 1–3-month horizon tokens (CONTRACTS §4: dates/horizon labels are not prices), then rejects remaining numerals in observed claims without a metric reference (`UNREGISTERED_NUMBER`); deterministic composition: `positionSlice` carries only `{position_id, state, preferred_horizon_months}` |
| Explicit missing data / failed/limited status | coverage `unavailable` → failed `INSUFFICIENT_EVIDENCE` before any model call; coverage `partial` → server merges coverage gaps into `missing_data` and emits `limited`; two failed attempts → failed `SYNTHESIS_VALIDATION_FAILED` with the issue list |
| Prior-report/checkpoint continuity | context carries prior assessment id/session/checkpoints labeled `is_prior_decision`; validator requires `changes_since_previous` to reference the exact prior (`CONTINUITY_MISMATCH`) and `checkpoint_change_ids ⊆ prior checkpoint ids` (`FABRICATED_CHECKPOINT_REFERENCE`); null prior is server-normalized |
| Bounded retrieval | `prompts.CONTEXT_BUDGETS` / `PIPELINE_BUDGETS` named frozen constants: `MAX_CONTEXT_EVIDENCE_ITEMS=20`, excerpt/summary caps; overflow → gap `evidence_context_truncated` (tested) |
| At most two synthesis/repair attempts | `PIPELINE_BUDGETS.MAX_SYNTHESIS_ATTEMPTS=2` enforced by loop; attempt 2 is the single repair pass carrying concrete issues (`MAX_REPAIR_ATTEMPTS=1`); tested: 1 call valid, 2 calls via repair, never a third |
| Explicit deadlines | injected `deadlineAt` + injected `now()`; checked at the top of every attempt; expired → failed `DEADLINE_EXCEEDED` with zero calls; crossed mid-pipeline → `DEADLINE_EXCEEDED`, no repair call |
| Freeze bounded source context before model invocation | `buildMarketSynthesisContext` deep-freezes the context and stamps a SHA-256 canonical-JSON `context_digest`; the digest and the frozen object are what the injected model client receives (tested with `Object.isFrozen`) |
| Personal economics stays out of synthesis/shared caches | `positionSlice` drops cost/quantity/opened_on before context build; test asserts the entire model request serialization contains no `average_cost`, no cost amount, no `quantity` |
| Server joins exact revision | `position.revision !== run.position_revision` → throws `REVISION_CONFLICT` before any model call (H08 lane consumes the superseded transition); `validateAssessmentDelivery` re-checks run/snapshot/revision/instrument/session binding |
| Deterministic P/L | `metrics.profitAndLoss` (H07) composed server-side onto the assessment root as additive `economics` (basis/currency mismatch → `unavailable` with reason, per CONTRACTS §2); never derived from the thesis |
| Changing cost alone cannot change the market thesis | tested: two runs differing only in `average_cost` produce deep-equal `market_thesis`/`recommendation` and different `economics` |
| No generalized runtime / no model reviewer stage | one fixed sequence: freeze → ≤2 attempts → deterministic composition → schema gate; no tool registry, no stage endpoints, no reviewer stage, no generalized dispatch |
| No paid/live model comparison prerequisite | mocked clients only; frozen evaluation protocol = `validator.PLANTED_DEFECT_CODES` (13 planted defect classes, frozen order) asserted in `research-validation.test.cjs`; no superiority claims made or testable here |

Injected client surface (H10/H08 wiring later): `createResearchAgentRuntime({ modelClient: {complete({system, user, context, context_digest, deadline_at, issues}) -> {output}}, now, idFactory, isExchangeSession })`; `runMarketSynthesis({ run, snapshot, metrics, instrument, position, prior, currentPrice, deadlineAt })` returns either `{status: 'complete'|'limited', result: {position_revision, evidence_snapshot_id, session_as_of, status, assessment}, context_digest, model_calls}` — shape-compatible with H08 `recordRunResult` — or `{status: 'failed', error_code, model_calls, validation_issues?}`.

## 5. Verification of assessment correctness

`runMarketSynthesis` passes every composed assessment through `researchAssessmentSchema.parse` (H01 canonical schema) plus `validateAssessmentDelivery` (exact run/snapshot binding) before returning. Fixture horizons re-verified against `metrics.outlookHorizons` (2026-10-30 session: 1m→2026-11-30, 2m→2026-12-30, 3m→2027-01-30 with exchange-session walk-back per the weekday predicate).

## 6. Limitations

- Source-only delivery: runtime/model integration, real provider calls and end-to-end n8n trigger/poll/deliver are H10/DEFERRED_TO_DEV_PC boundaries; nothing here proves live model behavior.
- `numeric_projection` is always `null` (H07A held); a model attempt to emit one is rejected (`NUMERIC_PROJECTION_HELD`).
- Deep delivery validation is exposed as `result_validator.validateAssessmentDelivery` for the pipeline boundary; H08 `recordRunResult` itself was not modified (existing_files: none) — wiring it into the route is the integration lane's single-owner change.
- `STATE_ACTIONS`/`DIRECTIONS` enums are mirrored locally because `contracts.js` does not export them and H09 must not modify existing files; schema re-validation is the backstop against drift.
- The unregistered-number detector is deliberately conservative (fail-closed to bounded repair); a claim like "top 3 competitors" without a metric reference is rejected by design.
- `positions.test.cjs` shows 41 tests (one more than the 40 cited in the H08 evidence) — a same-day change from another lane, not from this run; this run's two suites add 44 tests (24 + 20).
