# H01 independent specification review

Verdict: SPEC_FAIL

Reviewed the H01 author handoff and all four assigned artifacts against `docs/horizon/CONTRACTS.md` v1, `SPEC.md`, the H01 acceptance criteria, and the author run metadata. This is a specification verdict only; it is not the separate code/quality review.

## Findings

1. BLOCKING — date/time fields validate shape, not valid calendar values. In `backend/src/features/research/contracts.js:5-8,14-16`, `ISO_DATE_RE` and `UTC_TIMESTAMP_RE` are regex-only. Independently reproduced: a market bar with `session_date: "2024-99-99"` and `time: "2024-99-99T99:99:99Z"` parses successfully. This violates the contract's date-only and timezone-aware ISO instant semantics and can admit invalid session cutoffs, horizons, and timestamps. Add real calendar/time validation (including valid month/day and clock ranges) and negative tests.

2. BLOCKING — decimal input is not bounded and the positivity check overflows. `backend/src/features/research/contracts.js:7,17-20` has no maximum length/precision; `Number(value) > 0` accepts a 400-digit decimal because it converts to `Infinity`, despite the contract requiring bounded decimal strings. The same reproduced value passes `positionWrite`. Define explicit length/precision/range bounds without lossy conversion and test boundary/overflow inputs for both cost and quantity.

3. BLOCKING — the run lifecycle validator and tests do not cover the specified lifecycle invariants. `backend/src/features/research/contracts.js:239-268` checks only successful-run assessment presence, queued timestamps, and finished-without-started. It accepts inconsistent states such as `running` with `finished_at`, `failed` without a terminal timestamp, `queued` with an error/snapshot, and completed runs without `finished_at`. The fixture suite has one valid run and no invalid `researchRun` cases (`backend/test/fixtures/research/contract-cases.json:92-110,139-153`), despite the package explicitly requiring lifecycle schema tests. Implement and test the contract's status/timestamp/result invariants; include resumed/stalled/failed/superseded and success cases as applicable.

4. BLOCKING — important contract payloads are effectively unconstrained rather than executable contracts. `market_thesis` is an arbitrary passthrough object (`contracts.js:203`); `position_context`, evidence, claims, projections, outlooks, and assessment also permit arbitrary extra fields (`:34-40,88-116,118-159,161-184,205-208,215`). The specified market/business, price/technical, valuation, and rationale/counterevidence structure is not enforced; reference existence/consistency and projection-to-assessment/instrument/snapshot consistency are not checked. In addition, `risk_context` and `versions` are unbounded/unknown (`:22,51`). Define bounded structures for the contract's required fields and cross-object invariants, while allowing only the forward-compatible response additions the contract permits. Add tests proving malformed nested payloads fail.

5. BLOCKING — contract date semantics and lifecycle/cardinal constraints have holes beyond string syntax. Outlook `calendar_target_date` / `evaluation_session_date` only use the regex (`contracts.js:161-173`); there is no check that evaluation is on/before target or that horizon dates correspond to the assessment's `session_as_of` with month-end clamping. The H01 fixtures contain only arbitrary fixed dates, and no negative cases for horizon/date mismatch. Add deterministic cross-field validation/tests or clearly separate those calculations into a required tested contract helper; do not allow invalid values through the canonical registry.

6. GAP — test coverage is substantially narrower than the package's named test requirements. `backend/test/research-contracts.test.cjs:19-78` has five grouped tests, but no direct negative cases for `claim`, `evidenceItem`, `researchRun`, invalid history ordering/duplicate buckets, projection kind-specific constraints, or invalid date/boundary behavior. Fixture invalid entries cover marketBar, numericProjection, positionContext, and historyResponse only. Expand named cases so every canonical schema and high-risk cross-field rule has positive and negative evidence.

7. GAP — observed fixture source provenance is stated but not reproducible from the recorded locator. `observed-bars.json:13-18` points to generic Alpha Vantage documentation rather than a source-specific request/response or archived source record; it records retrieval time but not a source artifact digest. `h01-author.md:46-48` states the values were read from the public demo endpoint, but the fixture alone cannot substantiate that claim. Preserve an allowed, non-secret source-specific provenance reference or content digest and clearly state any non-reproducibility; do not add a query credential.

## Independently reproduced checks

- `node --test backend/test/research-contracts.test.cjs` — exit 0; 5 passed, 0 failed.
- `git diff --check` — exit 0.
- Targeted Node probes confirmed that the impossible date/time and 400-digit decimal described above are accepted.
- `git status --short` still shows the pre-existing modified scheduler and pre-existing untracked work; these were not changed. HEAD remains `9fbb26b5519889e0816720530dd60c204dda2bf2`.
- Backend manifest confirms Zod `^4.3.6`; no dependency change was needed.

## Limits

This review ran only the named offline contract test and targeted pure-schema probes. No live provider, database, application service, deployment/runtime, or secret store was accessed. Author-reported npm audit findings remain unremediated and outside this specification review. Author/reviewer models differ but share the same vendor, as disclosed in the task.
