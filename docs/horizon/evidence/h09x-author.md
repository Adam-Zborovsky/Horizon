# H09X author evidence

- Author package: H09X — Follow-up: generalized tools, stage replay and recovery.
  Resumed from controller-verified partial on-disk state after run 277 crashed
  infrastructure-side (gateway session loss, 11:52 UTC); the last in-flight edit to
  `automation.routes.js` was an INTERRUPTED edit and is completed here. No rewrite of
  coherent work — only broken paths were fixed and the missing half of the router was
  finished.
- Changed paths this run (author-owned only): `backend/src/features/research/tool_registry.js`,
  `backend/test/research-runtime.test.cjs`, `backend/src/features/research/automation.routes.js`,
  `backend/src/features/research/research.service.js`, `docs/horizon/evidence/h09x-author.md`,
  `docs/horizon/evidence/h09x/green-run.log`, `docs/horizon/evidence/h09x/aggregate-run.log`.
  `docs/horizon/evidence/h09x/red-run.log` (pre-existing) is preserved.
- Canonical new files (SHA-256, bytes):
  - `backend/src/features/research/tool_registry.js` —
    `122e8942bda86995648fbc06d4d0b1e3d1e994f7553a72ca6fa78ea7282e7f26`, 16507 bytes.
  - `backend/test/research-runtime.test.cjs` —
    `8d7ae5fed673d89e4a23ab006bc8bc349c3ece9c934196fd20a66770e31043fc`, 31468 bytes.
- Existing files modified within scope (SHA-256, bytes, dirty-main baseline, no commit):
  - `backend/src/features/research/automation.routes.js` —
    `364ddcd15946cd4ba47bdceab8ef3c91e3c685443fef4be3a72c32d64b98aabc`, 16482 bytes.
  - `backend/src/features/research/research.service.js` —
    `35a753d05269edc4406128dfee4761d1e3fc8f08b47a325ff08c445df6dc9bc7`, 48667 bytes.
- Existing file left untouched (hash recorded for the reviewer):
  - `backend/src/features/research/agent_runtime.js` —
    `3df087bbad44fd83ef3e05731f5e69e4ec1aba7ac5a661a9e9d129449ce6bc1a`, 13340 bytes.
    `git diff --stat` is empty for this path — byte-identical to the H09 baseline. It keeps
    the single bounded Node pipeline (one `modelClient.complete`, `modelCalls` counter, no
    reviewer stage), so the H09X "single execution owner / no automatic paid reviewer"
    requirement holds without touching it.

## Continuation delta (what was broken on disk and what this run fixed)

The partial state on disk was 24/37 green with 13 reds in three groups, all inspected
before editing (no blind rewrite):

1. `tool_registry.js` registry entries dropped their argument schema. The frozen `TOOLS`
   map carried `name`/`allowed_stages`/`synthesis_only`/`description` but not
   `arg_keys`/`ranges`/`resolutions`/`required`, so `validateToolArguments` threw
   `Cannot read properties of undefined (reading 'includes')`. Fixed by freezing the full
   argument schema into each registry entry (single hunk; validation now reads the same
   fields the private definitions declare).
2. Two test-side defects in the not-yet-green test file: `allowed_stages.sort()` mutated a
   frozen array (now `[...allowed_stages].sort()`); and the "unregistered resolver" test
   invoked `validate_research_result` in the `analyst` stage (not allowed) so it hit
   `TOOL_NOT_ALLOWED_IN_STAGE` before the resolver lookup. Corrected to the `reviewer`
   stage, where the tool is allowed and the missing resolver is the only rejection.
3. `automation.routes.js` was the interrupted edit: it had the `crypto`/`validateToolRequest`
   imports, the H09X `ERROR_STATUS`/`TOOL_ISSUE_STATUS` tables, `constantTimeEquals`, and the
   `toolExecutor`/`resolveToolContext` factory params, but no `/stages/:stage` or `/tools`
   handlers (the router returned with no such routes → 404 for ten tests). Added the two
   handlers plus a `authorizeRunLease` helper (lease nonce + expiry, constant-time) that both
   endpoints share. No existing route was changed.

## Contract mappings

- **Typed tool registry (SPEC §4 H09X table; CONTRACTS §9 L196):** `tool_registry.js`
  registers exactly the ten typed tools from the SPEC table with per-stage allowlists
  (`get_market_history` evidence/analyst, `get_market_metrics` analyst, `get_financial_facts`
  evidence/analyst, `get_filing_excerpt` analyst, `get_earnings_context` analyst,
  `get_material_news` evidence/analyst, `get_confirmed_events` analyst, `get_prior_thesis`
  analyst/synthesis, `get_position_context` synthesis-only, `validate_research_result`
  reviewer/delivery). Tool requests accept only `tool_name`/`arguments`/`stage`/`request_id`;
  any other key — and any `owner_id`/`url`/`command`/`code`/`sql`/credential-key argument —
  is rejected (`UNEXPECTED_FIELD`/`FORBIDDEN_ARGUMENT`). `get_position_context` is
  `synthesis_only` and cannot be invoked from analyst/reviewer (`SYNTHESIS_ONLY_STAGE`).
- **Named budget constants + in-code enforcement (SPEC §4 L136; CONTRACTS §9 L196):**
  `TOOL_BUDGETS.ANALYST_MAX_READ_CALLS=8`, `ANALYST_MAX_RETRIEVAL_PASSES=1`,
  `SYNTHESIS_MAX_POSITION_READS=1`, `REVIEWER_MAX_WEB_TOOLS=0`, `MAX_TOOL_RESULT_BYTES=64 KiB`.
  `createToolExecutor` enforces the per-run/stage call budget (429 `CALL_BUDGET_EXHAUSTED`,
  remaining counter reported) and the per-result response-size cap (413 `RESPONSE_TOO_LARGE`),
  and records exhaustion — budgets are code, not prompts.
- **Scoped stage/tools endpoints (CONTRACTS §9 L188–189):** `automation.routes.js` mounts
  `POST /runs/:runId/stages/:stage` under `research:stages` and `POST /runs/:runId/tools`
  under `research:tools`, both `requireOwner`. Both are lease-bound by `authorizeRunLease`
  (constant-time `x-horizon-run-nonce` vs the persisted `lease_nonce`, exact
  `x-horizon-run-id`, expired lease → 409); cross-owner/missing run → indistinguishable 404.
  The `stage` is an enum validated by the registry (`validateStage`), never arbitrary code
  or a model name.
- **Persisted stage replay, no re-charge (CONTRACTS §8 L168, §9 L198):**
  `research.service.js` `advanceStage` persists a stage artifact under
  `run_result_ref.stage_artifacts`, advances monotonically (`STAGE_OUT_OF_ORDER` on a
  backward transition), is idempotent for an identical artifact (`replayed:true`, no
  re-execution) and conflicts on a different one (`STAGE_REPLAY_CONFLICT`). `replayStage`
  reads back the persisted artifact without re-execution. The tool executor additionally
  serves an identical `run_id:request_id` from an in-memory retry cache without re-charging
  the call budget.
- **Generalized recovery preserves immutable references + deadlines (CONTRACTS §8 L168):**
  `recoverIncompleteRun` returns a `resumable:true` view exposing `input_snapshot_id`,
  `run_input_ref`, `deadline_at`, `position_revision`, `created_at` byte-identical, without
  mutating them; a running run past its deadline is handed to the existing
  `recoverAbandonedRuns` sweep and reported non-resumable (stalled/superseded), never
  silently resumed.
- **No additional model reviewer stage / no automatic paid call (SPEC §4 L111; CONTRACTS §8
  L166; TASKS H09X step 2):** the reviewer stage is deterministic-only
  (`validate_research_result`, `REVIEWER_MAX_WEB_TOOLS=0`, no model resolver). No model
  reviewer stage is introduced and no quality/cost/latency benefit is asserted anywhere in
  these files; `agent_runtime.js` (the single model pipeline) is untouched.

## Commands and exit codes (node v22.22.2; logs under `docs/horizon/evidence/h09x/`)

- Red phase (pre-existing, preserved): `node --test backend/test/research-runtime.test.cjs`
  → exit 1, `MODULE_NOT_FOUND` for `../src/features/research/tool_registry` — the test file
  was authored before the registry module existed. See `red-run.log`.
- `node --test backend/test/research-runtime.test.cjs` → exit 0, **37/37 pass**. See
  `green-run.log`.
- `node --test backend/test/*.test.cjs` → exit 0, **357/357 pass** across all suites. See
  `aggregate-run.log`.
- `git diff --check` → exit 0 (clean).

## Acceptance checklist

- No unrestricted tool URLs/commands/owner IDs; response size/call/stage budgets enforced in
  code: registry whitelist + `FORBIDDEN_ARGUMENT_KEYS` + `REQUEST_KEYS` (tests 7–13); per-stage
  call budget 429 and response-size 413 in the executor (tests 16–17); endpoint-level
  rejection of unknown tool (400), synthesis-only from analyst (403), owner_id in arguments
  (400), budget exhaustion (429), expired lease (409), and fail-closed 503 when no tool
  runtime is configured (tests 31–37).
- Replay/recovery preserves immutable references and deadlines; extra stage benefits not
  asserted without evidence: idempotent stage replay and replay-conflict (tests 20–21),
  backward-transition rejection (test 22), deadline fail-closed (test 24),
  `recoverIncompleteRun` byte-identical immutable references and stalled-not-resumed
  expiry (tests 25–26); no model reviewer stage added, no superiority claim made.

## Limitations

- All verification is hermetic/source-level. No live model/provider call, no MongoDB, no
  live n8n publication, and no production call was available or attempted; runtime/live-model
  acceptance remains an operator release gate. Fixtures are synthetic (`makeRun`,
  in-memory repositories, injected resolvers) — not observed market data.
- The stage/tools handlers live in the isolated `automation.routes.js` router; that router is
  not mounted into `app.js` (H15 integration-lane wiring, cf. H10 finding O3). The endpoints
  therefore do not exist live until the integration lane mounts the router.
- The tool executor's idempotent retry cache and the stage-artifact store are in-memory in
  these tests; durable persisted stage-artifact storage is exercised against the run
  repository abstraction but not against a live Mongo-backed store.
- Flutter/runtime/release acceptance out of scope for H09X (DEFERRED_TO_DEV_PC); none attempted.
- `tool_registry.js` and `research-runtime.test.cjs` are new (untracked) files; the two
  modified existing files are uncommitted changes on the dirty-main baseline per the
  execution contract (no commit/push performed).
