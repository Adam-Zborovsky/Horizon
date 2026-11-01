# H01 independent quality assessment

Review date: 2026-10-30 (UTC)

## Verdict

QUALITY_FAIL_SOURCE. The named offline suite passes, but independent pure-schema probes reproduce three substantive contract violations and one unresolved response-shape concern. These defects mean the H01 validators are not safe to release as canonical contract enforcement. No source repair was made.

Author/reviewer disclosure: H01 author worker/gpt-5.6-terra and reviewer/gpt-6-luna are different models, but both run through OpenAI Codex. This is model separation, not vendor independence.

## Scope and baseline

Read the historical failure evidence `docs/horizon/evidence/h01-spec.md`, the prior combined review `docs/horizon/evidence/h01-review.md`, `docs/horizon/CONTRACTS.md` v1, author handoff, canonical validator, contract tests, both fixture files, and the sanitized provenance artifact. The six H01 implementation/evidence artifacts inspected were `backend/src/features/research/contracts.js`, `backend/test/research-contracts.test.cjs`, `backend/test/fixtures/research/observed-bars.json`, `backend/test/fixtures/research/contract-cases.json`, `docs/horizon/evidence/h01/observed-bars-provenance.json`, and `docs/horizon/evidence/h01-author.md`. The task's seven historical findings are individually dispositioned below.

`git rev-parse HEAD` returned `9fbb26b5519889e0816720530dd60c204dda2bf2`. `git status --short --branch` showed `main...origin/main`, modified `backend/src/utils/scheduler.js`, and pre-existing untracked work including the H01 files. These unrelated changes were preserved; this assessment is the only path written by this review. The historical `h01-spec.md` was read only and preserved.

## Findings and dispositions

1. **Calendar date/time validation — PARTIALLY FIXED; BLOCKING boundary defect.** `contracts.js:33-48,82-89` now validates actual date parts, leap days, and UTC clock ranges; the existing regression test rejects `2024-02-30` and hour `24`. However, `calendarTargetDate` at `contracts.js:50-60` fails to enforce its own supported 0001–9999 year range after month rollover. The independent probe returned `"10000-01-31"` for `calendarTargetDate('9999-12-31', 1)`. The helper must not produce a non-contract date.

2. **Bounded decimal inputs — FIXED for the inspected position-write path.** `contracts.js:91-101` enforces length, integer and fractional digit limits and positivity without coercing to `Number`. The 13-test suite exercises the maximum accepted decimal, a 400-digit rejection, and zero rejection. The author handoff and code document limits as constants. This resolves the historical overflow reproduction for the inspected schema.

3. **Run lifecycle combinations — IMPROVED; NOT EXHAUSTIVELY ESTABLISHED.** `contracts.js:445-511` enforces key queued/running/terminal timestamps, result/error fields, chronology, and deadline conditions. Tests cover accepted queued, running/resumed, succeeded, limited (fixture), failed, stalled, and superseded states plus selected invalid combinations. The named suite passes. It does not constitute exhaustive state-transition proof; the contract does not fully specify all transition legality. No standalone illegal transition matrix or transition validator exists. This is a coverage gap, but the independently tested cases did not reproduce a concrete additional lifecycle defect. Keep lifecycle transition acceptance distinct from these snapshot-shape validations.

4. **Structured payloads and cross-object invariants — PARTIALLY FIXED; BLOCKING defects.** Nested structures and assessment identities are substantially more constrained than in the original submission. However, `assessmentPositionContext` at `contracts.js:309-317` does not apply the candidate economics prohibition from `CONTRACTS.md §2`, while `positionWrite` does. A valid assessment changed to `state: 'candidate'` with `average_cost` and `quantity` parses successfully. `checkpoint` at `contracts.js:319-341` requires a metric for rolling checkpoints and a fixed level for fixed-level checkpoints, but does not forbid the incompatible representation: both `rolling_indicator` with a non-null `fixed_level` and `fixed_observed_level` with a non-null `metric_id` parse successfully, contrary to §6. In addition, nested claim objects use `.passthrough()` (`contracts.js:216-227`); a claim with an arbitrary `extra_payload` parses successfully. Contract §1 allows additive response fields, but does not clearly authorize arbitrary unknown nested claim payloads. The additive boundary needs to be explicit and canonical nested payloads must remain enforceable. The first two violations are independently reproduced blockers; the passthrough behavior remains a material contract/maintainability concern.

5. **Outlook target/session semantics — PARTIALLY FIXED.** `researchAssessment` enforces month-end-clamped target dates and evaluation dates no later than target (`contracts.js:411-418`); the tests cover leap/month-end cases and bad target/evaluation values. `evaluationSessionDate` delegates exchange-session resolution to a caller-supplied predicate (`contracts.js:70-80`), and the schema cannot verify actual holidays or exchange sessions. This dependency is explicitly disclosed in the author handoff. The year rollover defect in finding 1 also affects the calendar helper.

6. **Negative fixture/test coverage — IMPROVED, STILL INSUFFICIENT FOR ACCEPTANCE.** The fixture matrix contains positive and at least one negative sample for each of the nine exported canonical schemas, and the suite exercises date/decimal bounds, lifecycle states, assessment nesting, history order, and fixture integrity. However, key contract negatives are absent: candidate economics inside assessment context, mutually exclusive checkpoint forms, upper-year rollover, and arbitrary nested payload. All four were independently probed; the first three reproduce accepted invalid values, while passthrough accepts undocumented payload fields. One generic negative per schema is not a meaningful substitute for these cross-field invariants.

7. **Observed fixture provenance — FIXED WITH STATED LIMITATION.** `observed-bars.json` points to a source-specific public Yahoo chart URL and records a SHA-256 for the sanitized provenance artifact. The test hashes that artifact; independent `sha256sum` returned `dcf75e1922753be1fc0ced05f47892c6dfbc48b4c52fe5bd2c2e0d9e83923caf`, matching the fixture digest. The provenance artifact explicitly says it does not preserve or digest the provider's raw response bytes. This limitation is accurately disclosed; no upstream byte-for-byte reproducibility is claimed.

## Commands and actual results

- `node --version` — `v22.22.2`.
- `node --test backend/test/research-contracts.test.cjs` — exit 0; TAP reported 13 tests, 13 passed, 0 failed, 0 skipped.
- `git diff --check` — exit 0.
- A read-only `node` probe using the canonical schemas and fixtures printed:
  - `candidate_assessment_economics_accepted: true`
  - `rolling_checkpoint_with_fixed_level_accepted: true`
  - `fixed_checkpoint_with_metric_accepted: true`
  - `arbitrary_claim_payload_accepted: true`
  - `max_year_rollover: "10000-01-31"`
  - `superseded_without_start_accepted: false` (no defect reproduced by this last exploratory case).
  Probe process exit 0; the `true` results above are reproduced acceptance of values that should be rejected, not passing assertions.
- `git rev-parse HEAD` — `9fbb26b5519889e0816720530dd60c204dda2bf2`.
- `git status --short --branch` — `## main...origin/main`; modified scheduler and untracked pre-existing work were visible; none were edited by this review.
- `sha256sum docs/horizon/evidence/h01/observed-bars-provenance.json` — digest matches `observed-bars.json` and the provenance test.

All exercised tests and probes were offline, local, read-only, and used synthetic fixtures. No live service, database, credential store, or production data was accessed.

## Limits and required follow-up

The available executable verification was Node 22 against the offline H01 schema suite and targeted probes. No deployment-runtime compatibility was established. Flutter/Dart analysis, generation, device validation, and APK/build checks remain `DEFERRED_TO_DEV_PC`; they are not passes or part of this source-quality verdict. The reported npm audit findings were not re-audited. Source acceptance would not imply runtime, Flutter, integration, or release acceptance.

Required before QUALITY_PASS_SOURCE: reject candidate economics in assessment position context; enforce the checkpoint kind/value exclusivity required by contract §6; reject unsupported-year month rollovers; and add regression tests for each. Clarify and test the permissible additive-response-field boundary so arbitrary nested contract payloads are not silently accepted. Then repeat independent review. Until then, keep dependent H01 consumer work gated.
