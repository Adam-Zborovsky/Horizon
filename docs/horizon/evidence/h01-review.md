# H01 combined independent specification and quality re-review

Review date: 2026-10-30 (UTC)
Author/reviewer separation: author worker/gpt-5.6-terra and reviewer gpt-6-luna differ; both use openai-codex, so vendor independence is not claimed.

## Verdicts

- SPEC: SPEC_FAIL_SOURCE — several original defects are repaired, but canonical validators still accept contract-invalid position economics and checkpoint combinations, permit arbitrary payload extensions in contract objects, and generate a date outside the supported ISO year range at the upper calendar boundary.
- QUALITY: QUALITY_FAIL_SOURCE — the offline suite passes, but the independently reproduced correctness gaps below prevent source-level acceptance. This does not assess runtime/deployment compatibility or Flutter/mobile acceptance.

## Artifact and scope inspected

Read `docs/horizon/SPEC.md`, `CONTRACTS.md` v1, `ORCHESTRATOR.md`, the prior `h01-spec.md`, `h01-author.md`, `contracts.js`, `research-contracts.test.cjs`, both research fixture files, and the source-provenance artifact. Confirmed repository HEAD remains `9fbb26b5519889e0816720530dd60c204dda2bf2`. Existing dirty/untracked work was preserved; this review wrote only this report. No source repair was made.

## Original seven findings — dispositions

1. Calendar date/time validity — PARTIALLY FIXED, with remaining boundary defect. `contracts.js` now checks real dates, leap days, and UTC clock ranges; direct tests reject 2024-02-30 and 24:00. But `calendarTargetDate('9999-12-31', 1)` returns `10000-01-31`, although contract dates are four-digit years 0001–9999 and the helper promises a valid calendar target. Must reject unsupported rollover (or otherwise enforce the contract's supported range) and test the maximum-year boundary.
2. Bounded decimal inputs — FIXED for inspected schema path. `positiveDecimal` limits length, integer digits, and fractional digits and checks positivity without `Number()` coercion. The suite accepts a max-bound amount and rejects a 400-digit amount and zero quantity. No lossless numeric conversion is used for these inputs.
3. Run lifecycle invariants — SUBSTANTIALLY FIXED. The validator now constrains queued/running/terminal combinations, chronology, result/error requirements and deadline behavior; tests cover queued, running/resumed, successful, failed, stalled, superseded, and rejected combinations. Existing 13-test suite passes.
4. Structured payloads and cross-object invariants — PARTIALLY FIXED; BLOCKING gaps remain. Thesis, risk context, versions, recommendation, outlook, checkpoint and projection shapes are now structured, and assessment checks key projection/checkpoint identities. However, an assessment whose position state is `candidate` with non-null cost and quantity passes; CONTRACTS.md §2 forbids candidate economics. Checkpoint kind/value relationships are incomplete: a `rolling_indicator` with both `metric_id` and `fixed_level` passes, as does `fixed_observed_level` with a metric reference. Contract §6 distinguishes rolling metrics from fixed levels. Also `claim`, `evidenceItem`, `numericProjection`, `researchAssessment`, and related nested response objects use `.passthrough()`; that allows arbitrary non-contract payload fields, including an arbitrary nested field on a claim. The contract permits additive response fields generally, but does not make required contract objects arbitrary; define the intended forward-compatible boundary without weakening canonical payload structure and add negatives for these cases.
5. Outlook date/horizon/session semantics — PARTIALLY FIXED. Assessment enforces month-end-clamped target dates and evaluation date <= target; tests include month-end/leap-year and a wrong target/late evaluation. Calendar session resolution is deliberately delegated to an exchange-calendar predicate and remains a downstream integration dependency. Upper supported year overflow is the separate boundary defect under finding 1. Do not claim exchange-holiday validation from this schema alone.
6. Negative coverage — IMPROVED, NOT COMPLETE. Positive and negative fixture entries now exist for each of the nine canonical exported schemas, and the named tests cover invalid dates, overflow, nested thesis, assessment/projection identity and lifecycle/history cases. But the invalid fixture matrix still has only one negative for evidence, claim, projection, assessment and run; it misses key high-risk rules identified above (candidate assessment economics, checkpoint kind/value exclusivity, date-year overflow and arbitrary payload acceptance). Add regression cases for the unresolved defects before acceptance.
7. Observed fixture provenance — FIXED WITH EXPLICIT LIMITATION. The generic Alpha Vantage documentation locator is replaced by a source-specific public Yahoo chart URL and a sanitized, selected-record provenance artifact. The test verifies the SHA-256 of that artifact. Provenance explicitly does not claim to retain or hash the provider's raw response bytes; the observed values therefore have a reproducible locator and internal sanitized-artifact integrity, not a byte-for-byte upstream capture. This limitation is disclosed rather than misrepresented.

## Reproduced commands and results

- `node --version` — `v22.22.2`.
- `node --test backend/test/research-contracts.test.cjs` — exit 0; 13 tests passed, 0 failed.
- `git diff --check` — exit 0.
- A read-only Node probe using the canonical schemas confirmed: (a) candidate assessment with average cost and quantity is accepted; (b) rolling checkpoint with a fixed level is accepted; (c) fixed-level checkpoint with a metric reference is accepted; (d) claim with arbitrary extra payload is accepted; (e) `calendarTargetDate('9999-12-31', 1)` returns `10000-01-31`. These are failures, not passes.
- The fixture provenance test passed, including the SHA-256 comparison between the observed fixture and sanitized provenance artifact.
- `git status --short --branch` showed branch `main` at the baseline commit and the pre-existing modified `backend/src/utils/scheduler.js` plus untracked work; no such files were modified by this review.

## Limits and remaining gates

No live provider, database, application service, deployment runtime, credentials, or production service was accessed. The host Node 22 test result does not establish the deployment Node runtime. Flutter/Dart analysis, tests, generation, device interaction, and APK/build evidence are DEFERRED_TO_DEV_PC; those were not run and are not passed by this source review. Source-only acceptance would not approve runtime, release, renderer changes, or deployment. Reported npm audit findings were not re-audited or remediated in this review.

## 2026-10-31 semantic-repair re-review (UTC)

### Verdicts

- SPEC: SPEC_PASS_SOURCE_ONLY. The semantic repair closes the previously blocking candidate-economics, checkpoint-exclusivity, calendar-overflow, and response/write-boundary findings. The repaired `opened_on` field is validated and candidate contexts reject it as an executed fact. No remaining source-contract defect was reproduced in the reviewed H01 scope.
- QUALITY: QUALITY_PASS_SOURCE_ONLY. The named offline suite passes independently, the new regressions exercise the repaired boundaries, and the evidence/fixtures are internally consistent. This is not deployment-runtime, Flutter, integration, or release acceptance.

### Seven historical findings — final disposition

1. Calendar date/time validity: FIXED for the reviewed schema and helper paths. Real date/time validation rejects impossible dates and clock values; targeted fixture tests cover leap day and invalid date/time. Calendar targets clamp month ends, preserve years 0001 and 0099, accept a target through 9999-12-31, and throw `RangeError` rather than overflow beyond year 9999. Assessment validation checks exact horizon target and requires evaluation dates to fall between `session_as_of` and the calendar target. The exchange-session predicate remains adapter-owned; this review does not claim holiday/calendar integration.
2. Bounded decimal inputs: FIXED. `positiveDecimal` enforces 40-character, 24-integer-digit and 12-fractional-digit bounds and checks positivity without `Number()` conversion. Tests accept the maximum configured amount and reject a 400-digit amount and zero quantity.
3. Run lifecycle invariants: FIXED for the v1 run record. Tests exercise queued, running, resumed, succeeded, failed, stalled, superseded and rejected combinations. The validator checks timestamp ordering, required terminal timestamps, success result/snapshot presence, failure error/no-assessment requirements, deadline constraints and queued/running exclusivity.
4. Structured payloads and cross-object invariants: FIXED for required known structure and the semantic gaps previously reproduced. The assessment validates required nested thesis/recommendation/outlook structures, candidate `average_cost`/`quantity`/`opened_on` restrictions, checkpoint-kind exclusivity, recommendation/state compatibility, identity/revision consistency, and projection/checkpoint references. CONTRACTS §1 explicitly permits additive response extensions; `.passthrough()` is retained for response objects, while required known fields are schema-validated and `positionWrite` remains strict. Tests accept additive response keys, reject malformed required payloads and unknown write keys.
5. Outlook date/horizon/session semantics: FIXED for source-level date ordering and horizon semantics. Tests verify month-end clamping, exact target dates and reject evaluation before the assessment session or after the target. Actual exchange-session membership is not inferable from these schemas and remains an adapter/integration check, not a claimed pass.
6. Negative coverage: IMPROVED AND SUFFICIENT FOR THIS SOURCE REVIEW. The canonical schemas each have named valid/invalid fixture cases; added focused regressions cover the repaired semantic findings and response/write policy. The single named test suite is not a substitute for downstream endpoint, persistence, exchange-calendar, or live integration tests.
7. Observed fixture provenance: FIXED WITH DISCLOSED LIMITATION. The fixture points to a source-specific public Yahoo chart URL and the test verifies the SHA-256 of the sanitized provenance artifact against the fixture digest. The provenance file states it does not retain/hash raw upstream response bytes; upstream byte-for-byte reproducibility is not claimed.

### Independently rerun checks and results

- `node --version` — `v22.22.2`.
- `node --test backend/test/research-contracts.test.cjs` — exit 0; 14 tests passed, 0 failed, 0 skipped.
- `git diff --check` — exit 0. Note: H01 source/artifacts are untracked in this baseline, so Git's ordinary diff check does not inspect those untracked files; the test suite reads and exercises the relevant implementation and fixtures.
- Read-only boundary probe: `0100-02-29` rejected; `0004-02-29` accepted. The helper's max-year rollover is directly asserted to throw in the named suite.
- Provenance artifact digest independently checked with `sha256sum`: `dcf75e1922753be1fc0ced05f47892c6dfbc48b4c52fe5bd2c2e0d9e83923caf`; it matches the `content_sha256` in `observed-bars.json`.
- HEAD remains `9fbb26b5519889e0816720530dd60c204dda2bf2`. Pre-existing modified scheduler and untracked repository work were preserved; this re-review changed only `docs/horizon/evidence/h01-review.md` and made no source repairs.

### Limits

Only offline Node schema tests and read-only probes ran. No live provider/database/service, deployment runtime, credentials, Flutter SDK/device, or release path was accessed. Node 22 host results do not establish deployed Node compatibility. Flutter analysis/tests/generation/device interactions/APK remain DEFERRED_TO_DEV_PC. No release/runtime claim follows from these source-only verdicts.
