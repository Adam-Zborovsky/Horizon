# H08 — Repair of review findings F1 (blocking) and O2 (same class)

- Repair task: t_66520884 (author lane). Review under t_a24089d1 (reviewer/deepseek-v4-pro), verdict `SPEC_PASS_SOURCE_ONLY` / `QUALITY_FAIL_SOURCE` (findings: docs/horizon/evidence/h08-review.md).
- Date: 2026-10-31. Workspace: /home/ubuntu/apps/Horizon (dirty main baseline preserved; nothing committed, reset, or cleaned).
- Files changed (within the card's write allowlist):
  - `backend/src/features/research/research.service.js` — SHA-256 `cffd2cafbfd9accb4ecd0338d2106d69960235fc1dcba0e310df1b3b4b6dc403`
  - `backend/test/research-state.test.cjs` — SHA-256 `029f9051222cc8c722124a5cd0bbed0abe4bb56e8b0123f18f24a74c544852a7`
- `backend/src/features/research/research.routes.js` was intentionally NOT modified: it forwards `instrument_id` to `queueRun`, which now enforces the non-empty-string requirement, so the route conforms through the service boundary without a duplicate check.
- Models untouched (`required: true` preserved on `research_snapshot.model.js` / `research_assessment.model.js`), per invariant: service conforms to the models, never the reverse.

## F1 (blocking) — instrument-less queueRun contradicted required instrument_id — FIXED

Per-finding disposition against the review's three cited defects:

1. **`queueRun` coerced an absent instrument to null** (`research.service.js:441-443` pre-repair). Replaced with `const instrumentId = assertOwnerScopedId(request.instrument_id, 'instrument_id')` (same validator already used for `owner_id`/`position_id`/`idempotency_key` and for `instrument_id` in `createCheckpoint`/`listCheckpoints`): a queue without a non-empty string `instrument_id` now throws `INVALID_INPUT` before any snapshot or run is persisted. Contract basis: snapshot/assessment models `instrument_id: { type: String, required: true, immutable: true }`, CONTRACTS §4/§5.
2. **Test 24 asserted 202 for the instrument-less POST.** Reworked: the happy-path POST bodies (queue + persisted replay) now carry `instrument_id`, and the test adds an instrument-less POST asserting rejection. It also asserts no run and no orphan snapshot are persisted on a rejected service-level queue (new dedicated test "queueRun rejects a run without a non-empty instrument_id as INVALID_INPUT (review F1)"). Red-first note is embedded as a comment at both sites stating the pre-repair behavior (202 for the instrument-less POST; silent null coercion) that the old assertions encoded.
3. **`recordRunResult` snapshot-binding check had a null-bypass** (`if (snapshot.instrument_id && boundInstrument && …)` pre-repair). Now strict: `if (snapshot.instrument_id !== boundInstrument)` — both sides are guaranteed non-null at creation (service requires it at queue; models require it at storage), so a null on either side is itself a mismatch. The test harness's `evidenceSnapshotLookup` now also resolves a snapshot bound to a *different* instrument, so the existing "snapshot must match the run instrument" case exercises the genuine instrument-mismatch branch instead of passing through the "not found" branch.

### Status-code note (card said 422)

The card body says "(422)". The router's existing `ERROR_STATUS` map (unchanged, pre-delivery) maps `INVALID_INPUT → 400`, and CONTRACTS line 192 defines `400 malformed request` vs `422 invalid researched result`. An instrument-less queue is a malformed request, not an invalid researched result, so the repair keeps the established `INVALID_INPUT → 400` mapping and the tests assert 400. Flagging the discrepancy rather than silently diverging from either the router convention or CONTRACTS.

## O2 (same silent-null class) — session_as_of coerced to null — FIXED

`recordRunResult` pre-repair stored `session_as_of: typeof result.session_as_of === 'string' ? … : null`, silently normalizing an absent/non-string value to null against the assessment model's `required: true` String. Post-repair the delivery is rejected: `if (typeof result.session_as_of !== 'string' || result.session_as_of.length === 0) throw INVALID_INPUT('result.session_as_of must be a non-empty string')`, placed after the binding/status checks and before any write, and the create now stores `session_as_of: result.session_as_of` directly. Deep format validation (date shape) remains H09's boundary, per the review's own scoping — only the silent null was removed. New test "recordRunResult rejects an absent or non-string session_as_of as INVALID_INPUT (review O2)" covers `undefined`, `null`, and non-string (`42`), and asserts no assessment is persisted and the run stays `running` after a rejected delivery.

O1/O3/O4/O5 remain with the integration lane as the review directed; no scope expansion.

## Red-first evidence (actual runs, Node v22.22.2, hermetic — no DB/network)

Tests were edited first and run against the unmodified service; all three new/updated assertions failed for the intended reasons:

```
$ node --test backend/test/research-state.test.cjs
not ok 4 - queueRun rejects a run without a non-empty instrument_id as INVALID_INPUT (review F1)
    error: 'Missing expected rejection: instrument_id undefined must be rejected as INVALID_INPUT'
not ok 13 - recordRunResult rejects an absent or non-string session_as_of as INVALID_INPUT (review O2)
    error: 'Missing expected rejection: session_as_of undefined must be rejected as INVALID_INPUT'
not ok 26 - research router exposes owner-scoped read/run endpoints as an isolated router
    error: |-
      a queue without a non-empty instrument_id must be rejected (review F1)
      202 !== 400
# pass 23 # fail 3
```

The route-level failure reproduces the review's core defect verbatim: the instrument-less POST returned `202` (the exact assertion the review flagged as encoding model-contradicting behavior).

## Green evidence

```
$ node --test backend/test/research-state.test.cjs
# tests 26 # pass 26 # fail 0        (exit 0)

$ node --test backend/test/*.test.cjs   # full backend aggregate
# tests 153 # pass 153 # fail 0       (exit 0)
```

State suite grew 24 → 26 (two new tests; test 24 reworked in place). Aggregate grew 150 → 153: +2 new H08 tests and +1 from the concurrent positions lane growth the review already recorded (positions 41st test; not H08-owned, H08 touches no positions file).

Two test-side iteration bugs were hit and fixed during bring-up (service untouched by them): duplicate idempotency keys across O2 loop iterations (`RUN_ALREADY_ACTIVE`), a missing revision match in the O2 deliveries (`REVISION_CONFLICT` instead of `INVALID_INPUT`), and the route test's replay body lacking `instrument_id`. Each was fixed in the test file only.

## Verification summary

- `git diff --check` → clean, exit 0.
- SHA-256 of changed files recorded above; evidence file itself is this document (docs/horizon/evidence/h08-repair.md).
- Only allowlisted files edited: `research.service.js`, `research-state.test.cjs`, this evidence file. `research.routes.js` unchanged (rationale above); models untouched.
- No secrets in code, tests, output, or this document; no `.env` or credential-store reads. No ports/DNS/tunnel changes, no backgrounding, no commits/pushes/history rewrites; dirty/untracked baseline preserved. No invented market data (H08 has no market-data surface).

## Limitations

- Live-Mongo required-field rejection and index behavior remain integration-lane territory (H15/H17), as in the original review; the in-memory repositories + schema probes are unchanged.
- Deep `session_as_of` format validation (date shape) and deep result validation remain H09's boundary.
- `assertOwnerScopedId` caps ids at 160 chars (O5 class, over-restriction only, unchanged — non-blocking observation left for the integration lane).
