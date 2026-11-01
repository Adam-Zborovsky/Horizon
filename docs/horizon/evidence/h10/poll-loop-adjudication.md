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

## H10X follow-up (2026-11-01): poll counter re-keyed (H10 review F1)

The H10 combined review (F1, non-blocking) found that the `poll_count` budget was
**structurally present but operationally inert**: `Classify Poll Result` derived
`poll_count` from `$('Normalize Execute Response').item.json`, a node that runs once
at workflow start and never changes, so `poll_count` was recomputed as `0 + 1 = 1` on
every iteration — the `Poll Budget Remaining?` gate (`poll_count < 60`) could never
trip and `Mark Poll Timeout` was unreachable.

H10X re-keyed the counter to the loop item. The running count is now carried on the
item that flows through `Wait Between Polls` (the wait node passes its input through,
and the `Poll Run Status` HTTP response never carries `poll_count` back); on the very
first poll the count seeds from `Normalize Execute Response` (`poll_count: 0`). The
counter now increments `1, 2, …` per poll, so the `poll_count < 60` budget is
operational and `Mark Poll Timeout` is reachable.

Accurate bound (layered, not a single mechanism):

1. `Poll Budget Remaining?` — the `poll_count < 60` budget, now functional after the
   H10X re-key (no unbounded poll spin).
2. Node-side deadline → stall (H10 `run_worker` / H08 `recoverAbandonedRuns`) — a run
   past its `deadline_at` is stalled or superseded, never polled forever.
3. `Wait Between Polls` — a 30 s floor between polls.

The earlier wording in this file ("bounded counter") is superseded by this note: before
H10X the counter was inert and termination relied on (2) + (3) alone; after H10X the
counter (1) is also enforced. The `n8n-workflow.json` graph (14 nodes / 16 edges, no
self-loop, feeder sets unchanged) is preserved; only `Classify Poll Result`'s `jsCode`
changed. Live publication remains operator-only.
