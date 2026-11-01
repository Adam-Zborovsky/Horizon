# H10 author evidence

- Author package: H10 — Thin n8n trigger/poll/delivery and bounded run worker
  (continuation after iteration-budget give-up; resumed from controller-verified partial
  state, no rewrite).
- Changed paths this run: `backend/test/research-workflow.test.cjs` (one test repaired),
  `docs/horizon/evidence/h10-author.md`, `docs/horizon/evidence/h10/poll-loop-adjudication.md`,
  `docs/horizon/evidence/h10/verification.log`. Nothing else was written.
- Canonical new files delivered (SHA-256, bytes):
  - `backend/src/features/research/automation.routes.js` —
    `5621771f074148072de1ab0b473dea84dbd24f4fd90163bb231e4c9f7d81be7f`, 11438 bytes.
  - `backend/src/features/research/run_worker.js` —
    `65e41c557034664421b981fa337ccb3c4ecee0900b414a4907ba1bc65027c816`, 13780 bytes.
  - `backend/test/research-workflow.test.cjs` —
    `c23be1536ef57042484957800cb25b656c223f591c339afe55283fde79a2b67b`, 47841 bytes.
- Existing files left untouched (hashes recorded for the reviewer):
  - `n8n-workflow.json` —
    `58a837417801db663febc390406d110eadd8ea42033c40bc7817dcf2f3e77967`, 14389 bytes.
  - `backend/src/utils/scheduler.js` — dirty main baseline preserved; no edit this run.
  - `backend/scripts/test-research-workflow.cjs` — untouched.

## Continuation delta (what this run changed and why)

- Sole carried defect: the poll-loop test (`research-workflow.test.cjs:1025`) failed with
  `unexpected poll feeders: Polling Required?, Wait Between Polls`. Adjudicated as a
  false-red in the test: the workflow graph is bounded and honest (no self-loop; every
  repetition passes the `poll_count < 60` counter `Poll Budget Remaining?` and the 30 s
  `Wait Between Polls` node; the first poll enters gated on `phase === 'poll'`), while the
  test demanded feeders from a node named `Poll Budget Gate` that does not exist in the
  export. Full reasoning and edge list: `docs/horizon/evidence/h10/poll-loop-adjudication.md`.
- Fix was test-side only: the assertion now requires (1) no self-loop, (2) the exact feeder
  set of `Poll Run Status` to be `['Polling Required?', 'Wait Between Polls']`, and (3) the
  exact feeder set of `Wait Between Polls` to be `['Poll Budget Remaining?']` so no
  repetition bypasses the bounded counter or the wait. The workflow JSON was not modified.

## Contract mappings

- **Leases / duplicate suppression (via H08's `lease_nonce`/CAS):** `run_worker.js`
  claims a run with a fresh `lease_nonce` returned only on a fresh claim; an already-claimed
  or terminal run replays persisted status/result without duplicating work
  (`run_worker.js` claim path, comment "replay persisted status, never a [duplicate
  execution] whose lease is still valid"). `automation.routes.js` returns the persisted
  status on re-trigger (409 conflict semantics for already-claimed runs) and stamps the
  claim receipt with `lease_nonce`. The status view never carries the nonce (test
  `status view never carries the lease nonce or owner internals`).
- **Deadlines / stalls:** `run_worker.js` enforces `deadline_at`; an expired-deadline claim
  is refused up front, a synthesis completing after deadline expiry is recorded as a stall,
  never a fake success ("Deadline expiry cannot fake a completion"); `toStatusView` exposes
  `heartbeat_at` / `deadline_at` honestly. `createMongooseQueuedRunSource` filters claimable
  batches on `deadline_at > now`.
- **Bounded delivery:** the n8n export bounds polls at `poll_count < 60` with a 30 s
  `Wait Between Polls`, times out via `Mark Poll Timeout`, and delivers only validated bound
  results through `Assemble & Deliver Bound Result`. In `automation.routes.js` a result that
  fails validation is a deterministic 422 `INVALID_RESULT` with the client owning retry
  policy (bounded, no unbounded 422 loop).
- **Status truthfulness:** `toStatusView` (`run_worker.js:38`) strips `lease_nonce`,
  `owner_id_internal` and `run_input_ref.request_payload`; failures/stalls surface with
  honest `error_code`s (`SYNTHESIS_VALIDATION_FAILED` etc.); success is never synthesized
  after deadline expiry.
- **No arbitrary callback userId:** the workflow export test asserts no HTTP node forwards a
  client `userId` and that all HTTP nodes authenticate via `genericCredentialType` n8n
  credentials — no inline secrets (test at `research-workflow.test.cjs:1044`).
- **Thin n8n / fat node:** all legacy analyst nodes are asserted absent from the export;
  Code nodes compile as n8n async bodies; pipeline execution lives in the Node worker
  (`run_worker.js`), n8n only triggers, polls persisted status and delivers.

## Commands and exit codes (node v22.22.2; full sanitized output in
`docs/horizon/evidence/h10/verification.log`)

- `node --test test/research-workflow.test.cjs` (cwd `backend/`) → exit 0, 25/25 pass.
- `MONGODB_URI=<hermetic-placeholder> JWT_SECRET=<hermetic-placeholder> node --test
  'test/*.test.cjs'` (cwd `backend/`) → exit 0, 223/223 pass across all 11 suites.
- Per-suite (no placeholders): market-history 12/12, positions 41/41, research-agent 21/21,
  research-auth 6/6, research-contracts 14/14, research-evidence 19/19, research-metrics
  24/24, research-state 26/26, research-validation 24/24, research-workflow 25/25 — all
  exit 0.
- `research-history-integration.test.cjs` standalone without placeholder env → exit 1 at
  module load (zod env validation in `src/config/env.js` requires `MONGODB_URI`/`JWT_SECRET`).
  With throwaway placeholder values on the command line: exit 0, 11/11 pass. The suite is
  hermetic (`createApp` with injected fakes; no Mongo connection). No `.env` was read and no
  real credential was provisioned.

## Acceptance checklist

- Duplicate schedules/restarts do not duplicate research: covered by the claim/lease replay
  tests in `research-workflow.test.cjs` (green).
- Status exposes failures/stalls and last success honestly: `toStatusView` + deadline/stall
  tests (green); the nonce/internal-stripping test (green).
- No arbitrary callback userId, unbounded 422 loop or literal exported credential: export
  test asserts no `userId` forwarding, credential-type auth only, no 64-hex literal (green);
  422 path is deterministic and bounded (green).
- Unrelated n8n workflows untouched: only `n8n-workflow.json` is in scope and it was not
  modified this run (hash above).
- Source/export changes are not called a live deployment: no workflow publication, no
  production calls, no credentials, no live n8n instance was contacted.

## Limitations

- All verification is hermetic/source-level. No live n8n instance, no live workflow
  publication, no MongoDB, and no production calls were available or attempted; live
  workflow comparison and coordinated deployment remain operator release gates.
- `research-history-integration.test.cjs` requires the placeholder-env invocation documented
  above in sandboxes where `.env` is absent/empty; it is another card's file and was not
  modified.
- Flutter/runtime/release acceptance out of scope for H10 (none attempted).
- The previous run's partial implementation of `automation.routes.js` and `run_worker.js`
  was accepted as-is after inspection; this run changed only the test plus evidence files.
