# H10 continuation — poll-loop test adjudication (2026-11-01)

## Baseline (controller-verified, reproduced this run)

- `node --test test/research-workflow.test.cjs`: 24/25 pass.
- Sole failure: `workflow poll loop is bounded and honest (Wait node + counter, no self-loop)` at
  `backend/test/research-workflow.test.cjs:1025` with
  `unexpected poll feeders: Polling Required?, Wait Between Polls` (`false !== true`).

## Adjudication: the test's expected feeder name was wrong; the workflow JSON is correct

Actual edge list of `n8n-workflow.json` (14 nodes, 16 edges):

```
Normalize Execute Response -> Polling Required?
Polling Required?[true]    -> Poll Run Status          (single, gated entry: $json.phase === 'poll')
Polling Required?[false]   -> Assemble & Deliver Bound Result
Poll Run Status            -> Classify Poll Result
Classify Poll Result       -> Deliver Now?
Deliver Now?[true]         -> Assemble & Deliver Bound Result
Deliver Now?[false]        -> Poll Budget Remaining?
Poll Budget Remaining?[true]  -> Wait Between Polls    (bounded counter: poll_count < 60)
Poll Budget Remaining?[false] -> Mark Poll Timeout
Wait Between Polls         -> Poll Run Status          (every repetition, after the 30 s wait)
```

- `Poll Run Status` does not feed itself — no self-loop.
- Every repetition passes through `Poll Budget Remaining?` (the `poll_count < 60` bounded
  counter) and the `Wait Between Polls` (30 s) node.
- The first poll enters legitimately from `Polling Required?`, gated on `phase === 'poll'`.

The failing assertion required every feeder of `Poll Run Status` to be a node named
`Poll Budget Gate`. **No node named `Poll Budget Gate` exists in the export** — it is a
draft-era name that never landed. Under the assertion as written, the honest design would
also be un-passable without restructuring: forbidding the `Polling Required?` -> first-poll
edge would force the trigger path to poll unconditionally. The workflow side is the correct
side; the test encoded a nonexistent node and over-forbade a legitimate edge.

## Fix (test side only; workflow JSON untouched)

`backend/test/research-workflow.test.cjs:1033-1055` now asserts the real invariants:

1. No self-loop: `Poll Run Status` is never its own feeder (kept from the original test).
2. The exact feeder set of `Poll Run Status` is `['Polling Required?', 'Wait Between Polls']`.
3. New: the exact feeder set of `Wait Between Polls` is `['Poll Budget Remaining?']`, so no
   repetition can bypass the bounded counter or the wait.

## Result

- research-workflow suite: 25/25 pass, exit 0 (`docs/horizon/evidence/h10/verification.log`).
- Complete backend aggregate: 223/223 pass, exit 0.
- `n8n-workflow.json` was not modified (SHA-256
  `58a837417801db663febc390406d110eadd8ea42033c40bc7817dcf2f3e77967`).
