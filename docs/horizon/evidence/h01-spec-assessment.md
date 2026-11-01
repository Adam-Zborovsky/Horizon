# H01 independent specification assessment

Verdict: SPEC_FAIL_SOURCE

Reviewed the seven findings in the historical `docs/horizon/evidence/h01-spec.md` against `docs/horizon/SPEC.md`, `docs/horizon/CONTRACTS.md` v1, `docs/horizon/ORCHESTRATOR.md`, the current H01 implementation/tests/fixtures, and `docs/horizon/evidence/h01-author.md`. The similarly named files are under `docs/horizon/`; there is no root-level `SPEC.md` or `ORCHESTRATOR.md`. The historical failure report was read and left unchanged.

This is a source/specification assessment, not live, deployment-runtime, Flutter, or release acceptance. No source code, shared configuration, or historical evidence was modified. Author: worker/gpt-5.6-terra. Reviewer: reviewer/gpt-6-luna. These are different models/profiles but both OpenAI Codex; vendor overlap remains a limitation.

## Original findings and disposition

1. Calendar/date-time validation — PARTIALLY RESOLVED; BLOCKING EDGE REMAINS. Date parsing now rejects impossible month/day values and invalid UTC clock values; the test suite covers an impossible date, hour 24, and leap day. Safe boundary probe reproduced `calendarTargetDate('9999-12-31', 1) => '10000-01-31'`, which violates the four-digit year/date contract and emits an invalid session date. Month-end clamping otherwise reproduced correctly for `2024-01-31 + 1 => 2024-02-29` and `2023-01-31 + 1 => 2023-02-28`. The assessment validator also accepts an evaluation session before its `session_as_of` date (probe below), a horizon ordering inconsistency.

2. Bounded decimal strings — RESOLVED FOR TESTED BOUNDS. The current validator enforces length/integer/fraction bounds and checks positivity without converting to Number. The allowed maximum tested (`24` integer digits and `12` fractional digits) passes; 13 fractional digits and a 400-digit amount are rejected by the named suite. Zero is rejected. The decimal maximums are implementation constants (`DECIMAL_LIMITS`), not numerically specified by CONTRACTS.md; acceptability of those exact policy limits is not independently established by the text of the contract.

3. Research-run lifecycle invariants — SUBSTANTIALLY RESOLVED; FULL INVARIANT COVERAGE NOT ESTABLISHED. Validators now distinguish queued/running/terminal statuses and require terminal timestamps; succeeded/limited require snapshot and assessment, failed/stalled require an error and no assessment, and stalled completion is deadline-bound. The 13-test suite has positive status cases and several negative combinations. A failed run with a retained evidence snapshot but no assessment is accepted; CONTRACTS.md §8 does not forbid persisted stage artifacts, so this alone is not treated as a defect. The broad run-state protocol includes idempotency, atomic claiming, restart persistence, callbacks and deadline recovery that cannot be proven by these schema-only fixtures. These remain downstream implementation criteria, not passed by H01.

4. Nested structures, payload boundaries and cross-object invariants — UNRESOLVED; BLOCKING. Required market-thesis sections and several identity/date checks are now enforced, and malformed thesis/mismatched projection identity are negatively tested. However, `researchAssessment.position_context` permits candidate state with non-null `average_cost` and `quantity`, contrary to CONTRACTS.md §2's rule that candidate records have no executed economics. A corrected isolated probe with a compatible `buy` action returned `ACCEPT`. `claim` also accepts an arbitrary `arbitrary_payload` key (`.passthrough()` in `contracts.js`), although write requests must reject unknown fields and the contract permits forward-compatible additive response fields—not unrestricted extras on every payload. Checkpoint schema permits both a rolling-indicator metric reference and `fixed_level` simultaneously, and permits a fixed observed level with a metric reference; both combinations were independently accepted, contrary to §6's distinction. In addition, claim references are not checked against a containing assessment's evidence/metric registry. These are executable-contract gaps.

5. Outlook target/evaluation semantics — PARTIALLY RESOLVED; BLOCKING EDGE REMAINS. The implementation recomputes the calendar target with month-end clamping, rejects evaluation dates after target, and exposes a session predicate helper. It cannot validate exchange holidays without a provider/calendar adapter, as the author correctly discloses. The safe probe also confirmed `researchAssessment` accepts evaluation dates before its assessment `session_as_of`; the evaluator's lower bound/session semantics are therefore incomplete. The year-9999 rollover in finding 1 affects outlook target generation too.

6. Canonical-schema and negative-test coverage — PARTIALLY RESOLVED. The test suite now asserts a positive and a negative fixture for each of nine registry schemas, with added lifecycle, date, decimal, history-ordering, nested-thesis, and identity checks. It is materially broader than the historical five grouped tests. However, the reported candidate-economics and checkpoint-combination defects have no negative regressions and are accepted by current implementation. The broad schema inventory does not establish semantic evidence entailment or runtime behavior.

7. Observed-fixture provenance — PARTIALLY RESOLVED / TRANSPARENT LIMITATION. The old generic documentation locator has been replaced with a source-specific public Yahoo chart URL, retrieval timestamp, sanitized selected records and an artifact SHA-256. The test recomputes and verifies the digest of the local sanitized provenance artifact against the fixture. This is not a digest of provider response bytes and the original response bytes are not retained; the artifact therefore does not independently make the source values byte-for-byte reproducible. The author explicitly states this limitation and does not mislabel the artifact digest as a provider-response digest. I did not access the live endpoint.

## Independent commands and actual results

All commands ran in `/home/ubuntu/apps/Horizon`; no live service, database, provider endpoint, secret store, or production data was accessed.

- `node --test backend/test/research-contracts.test.cjs` — exit 0; 13 tests, 13 passed, 0 failed, 0 skipped.
- `git diff --check` — exit 0, no whitespace errors reported.
- `git status --short` — showed modified `backend/src/utils/scheduler.js` and pre-existing/untracked work including the H01 tree/docs. These were not modified by this assessment.
- `git rev-parse HEAD` — `9fbb26b5519889e0816720530dd60c204dda2bf2`.
- Safe inline Node probes against `backend/src/features/research/contracts.js` and synthetic checked-in contract cases:
  - Month-end clamping: `2024-01-31 +1 -> 2024-02-29`; `2023-01-31 +1 -> 2023-02-28`.
  - Boundary year: `9999-12-31 +1 -> 10000-01-31` (invalid output; reproduced defect).
  - Decimal bound: 24 integer digits plus 12 fractional digits accepted; 13 fractional digits rejected. The named suite also rejects a 400-digit decimal and zero.
  - Candidate assessment carrying average cost and quantity with `action: buy` -> ACCEPT (reproduced defect).
  - Rolling checkpoint with both metric ID and fixed level -> ACCEPT; fixed-observed-level checkpoint with metric ID -> ACCEPT (both reproduced defects).
  - Claim with arbitrary extra payload key -> ACCEPT (reproduced defect).
  - Outlook evaluation date before assessment session date -> ACCEPT (reproduced defect).
  - Failed run carrying an evidence snapshot but no assessment -> ACCEPT; not independently classified as invalid by §8.
- Provenance digest verification ran as part of the 13-test suite: the local provenance artifact digest matched the fixture's `content_sha256`. This verifies artifact integrity only, not a digest of the original source response.

A first ad-hoc probe harness invocation exited 1 with `TypeError: Cannot read properties of undefined (reading 'safeParse')` because its label was mistakenly used as a schema key. I corrected the harness and reran the targeted probes; the corrected output above is from the successful run. No repository files were changed by either invocation.

## Limits and disposition

No Flutter/Dart SDK/device, deployment-runtime compatibility, exchange calendar adapter, live source retrieval, route integration, persistence/idempotency, or callback behavior was exercised. `backend/package.json` has no configured project test script; the exact Node test file was invoked directly. The review found sufficient independent reproductions to fail the specification verdict despite the green named suite. The author/reviewer model distinction is real, but both belong to OpenAI Codex.
