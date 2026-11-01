# H09 — Bounded grounded research pipeline and validation — Combined Independent Review

- Review task: t_e95e1d9a (combined SPEC + QUALITY)
- Author delivery: t_c5e7237e (docs/horizon/evidence/h09-author.md)
- Reviewer: reviewer (independent; author worker/gpt-5.6-terra — distinct profile/model, same-vendor disclosure retained)
- Date: 2026-10-31 22:39 UTC
- Workspace: /home/ubuntu/apps/Horizon (existing dirty main baseline; no branch change, no commit/push, no source repair)
- Scope: core_source, source-only. This review never implies runtime or release acceptance (see Deferred).

## Verdict

| Verdict | Result |
|---|---|
| SPEC | **SPEC_PASS_SOURCE_ONLY** |
| QUALITY | **QUALITY_PASS_SOURCE_ONLY** |

Both verdicts pass. Independent review is not author test self-report: every file below was read in full, hashes were independently recomputed, and the relevant tests were independently re-run on this host.

## 1. Independent verification performed

- **5/5 SHA-256 hashes** recomputed and matched the author's table exactly (prompts.js, agent_runtime.js, result_validator.js, research-agent.test.cjs, research-validation.test.cjs).
- **`node --test backend/test/research-validation.test.cjs` → exit 0, 24/24 pass** (independently run).
- **`node --test backend/test/research-agent.test.cjs` → exit 0, 20/20 pass** (independently run).
- **`node --test backend/test/*.test.cjs` → exit 0, 197/197 pass** (ten suites; no regression against the pre-existing 153).
- **`git diff --check` → clean, exit 0.**
- **Secret scan** across all five delivered files: no credential/token literals; the only `grep` hits are the words "token"/"credentials" inside regex identifiers (`HORIZON_TOKEN_RE`, `NUMERIC_TOKEN_RE`) and negative statements ("never credentials surface", "no credentials"). No `process.env`, no `dotenv`, no `readFileSync` on credential stores.
- **No live calls**: the three source files contain no `fetch`/`http.request`/`axios`; model clients are injected and mocked.
- **Red-first TDD** reproduced from the author's `docs/horizon/evidence/h09/red-run.log`: both suites failed at module-load (`Cannot find module '../src/features/research/prompts'` / `result_validator`) before implementation, exit 1 — genuine red, not a fabricated trace.
- **Baseline integrity**: H09's deliverable is five new untracked files plus evidence. No tracked file was modified by this package (`git status` shows only `??` additions under `backend/src/features/research/`, the two test files, and `docs/`). The pre-existing dirty files (`app.js`, `env.js`, `briefing.*`, `scheduler.js`) belong to other lanes (SPEC §2 + H15A/H03/H04) and are untouched here.

## 2. SPEC assessment (acceptance criteria → evidence)

1. **Fabricated metrics/sources, post-cutoff facts and state-incompatible actions fail closed** — PASS.
   `result_validator.checkClaims` resolves every `evidence_id`/`metric_id` against the frozen context index (`FABRICATED_SOURCE`, `FABRICATED_METRIC`); `buildMarketSynthesisContext` drops post-cutoff items and the validator independently re-checks referenced availability (`POST_CUTOFF_REFERENCE`, defense in depth); `STATE_ACTIONS` mirrors CONTRACTS §5 and the canonical `researchAssessmentSchema` superRefine re-checks the same table. All defect codes are in the frozen `PLANTED_DEFECT_CODES` and asserted by tests.

2. **Exactly one/two/three-month outlooks, source-backed conclusion/countercase, explicit missing data and prior-report/checkpoint continuity** — PASS.
   Horizon-set gate (`'1,2,3'` only), server-computed calendar/evaluation dates (`INVENTED_HORIZON_DATE`), distinct-content check (`IDENTICAL_HORIZON_COPY`), non-empty `counterevidence`/`countercase` (`MISSING_COUNTERCASE`), `observed` claims must cite ≥1 reference (`UNSUPPORTED_CLAIM`), partial coverage requires `missing_data` (`LIMITED_WITHOUT_MISSING_DATA`), and `changes_since_previous` must bind the exact prior assessment/session/checkpoint ids (`CONTINUITY_MISMATCH`, `FABRICATED_CHECKPOINT_REFERENCE`).

3. **Personal economics stays out of market synthesis/shared caches; server joins exact revision and deterministic P/L** — PASS.
   `positionSlice` carries only `{position_id, state, preferred_horizon_months}`; cost/quantity/opened_on are dropped before context build (test asserts the serialized model request contains no `average_cost`/`quantity`/cost value). Revision mismatch throws `REVISION_CONFLICT` before any model call; `composeEconomics` → H07 `profitAndLoss` is deterministic and server-only; "changing cost alone cannot change the market thesis" is directly tested.

4. **Bounded retrieval/repair/deadlines and real failure status; no generalized runtime or paid model comparison prerequisite** — PASS.
   Frozen `CONTEXT_BUDGETS`/`PIPELINE_BUDGETS` (`MAX_SYNTHESIS_ATTEMPTS=2`, `MAX_REPAIR_ATTEMPTS=1`, `MAX_CONTEXT_EVIDENCE_ITEMS=20`); one fixed sequence (freeze → ≤2 attempts → server composition → schema gate), no tool registry/stage endpoints (the historical `tool_registry.js` is correctly absent from this scope); injected deadlines checked at start and per attempt (`DEADLINE_EXCEEDED`), coverage `unavailable` → `INSUFFICIENT_EVIDENCE` before any call, two failures → `SYNTHESIS_VALIDATION_FAILED`. Mocks only; no superiority/quality-comparison claim made or testable.

## 3. QUALITY assessment

- **Security/privacy** — PASS. No secrets, no env/credential access, no live network, personal economics excluded from the model context (tested), server-derived owner/revision binding, `context_digest` stamps the frozen context before invocation.
- **Contract fidelity** — PASS. Additive `economics` field is a legal passthrough (`researchAssessment` is `.passthrough()`, CONTRACTS §1); `validateAssessmentDelivery` binds run/snapshot/instrument/revision/session exactly; the local `STATE_ACTIONS` mirror agrees with the canonical `stateActions` backstop.
- **Maintainability** — PASS with two non-blocking notes (below). Clean three-module separation, named frozen budgets, no generalized dispatch, defensive server-side normalization before validation.
- **Test fidelity** — PASS. 44 new tests, frozen planted-defect protocol, synthetic fixtures explicitly labeled "NOT observed market data", red-first trace genuine.
- **Baseline preservation** — PASS. No tracked-file edits, `git diff --check` clean.

## 4. Findings (non-blocking)

- **N1 (quality, non-blocking)** — `agent_runtime.js:80` `composePositionContext(position, economics)` accepts `economics` but never reads it; `economics_status` (line 94) is derived solely from `hasCost && hasQuantity`. In the currency/basis-mismatch case the authoritative `economics.status` correctly reports `unavailable`/`currency_mismatch` while `position_context.economics_status` still reads `available`. Independent probe reproduced this exact pair. The H01 contract fixture (`contract-cases.json`, `research-contracts.test.cjs`) defines `economics_status` as "economics inputs present", so `available` here is defensible — but the field naming collides with `economics.status` and the dead parameter shows the wiring was left incomplete. **Recommendation (not required for this gate):** either drop the unused parameter, or derive `economics_status` from the composed `economics.status` so the two cannot disagree. **Downstream H15B/H14 renderer must not present `economics_status: 'available'` as "comparable P/L available" when `economics.status` is `unavailable`.**

- **N2 (evidence doc only, non-blocking)** — `h09-author.md` line 27 cites `node --test backend/test/` as the aggregate command, but that exact invocation fails with `Cannot find module .../backend/test` (Node `--test` with a trailing-slash directory argument does not glob). The command that actually produces 197/197 — and matches SPEC §7 — is `node --test backend/test/*.test.cjs`. The author's own `verification.log` records per-file runs, so the test results themselves are genuine; only the cited command string in the summary is inaccurate.

## 5. Deferred criteria (explicit — never passed from source inspection)

- Live model/provider calls and real reasoning quality → H10 integration lane.
- n8n trigger/poll/deliver, leases, stalls, replay → H10.
- Flutter analysis/generation/tests/device/web/mobile/Wear/APK and chart interaction/accessibility → **DEFERRED_TO_DEV_PC**.
- `numeric_projection` → H07A held; server composes `null` and rejects any model-emitted projection (`NUMERIC_PROJECTION_HELD`).
- Model quality comparison / superiority claims → no claim made; frozen evaluation protocol only.

Source-only acceptance releases source-development dependencies only; it does not establish runtime or release readiness (H18/H19 remain).

---

# H09-N1 — `economics_status` repair — Combined Independent Review (append)

- Review task: t_77356be1 (combined SPEC + QUALITY)
- Author delivery: t_d218b310 (`docs/horizon/evidence/h09-repair-economics.md`)
- Reviewer: reviewer (deepseek / deepseek-v4-pro — vendor-disjoint from zai / glm-5.3-flash author)
- Date: 2026-11-01 07:55 UTC
- Workspace: /home/ubuntu/apps/Horizon (dirty main baseline; no branch change, no commit/push; source-only; runtime DEFERRED_TO_DEV_PC)
- Scope: source-only. This review never implies runtime or release acceptance.

## Verdict

| Verdict | Result |
|---|---|
| SPEC | **SPEC_PASS_SOURCE_ONLY** |
| QUALITY | **QUALITY_PASS_SOURCE_ONLY** |

Both verdicts pass. Every criterion was verified from the artifacts (source, test file, evidence file, contract fixtures), never from the author summary. Both SHA-256 hashes independently recomputed; the three relevant suites independently rerun on this host.

## 1. Independent verification performed

- **SHA-256 recomputed on disk**: `agent_runtime.js` = `3df087bbad44fd83ef3e05731f5e69e4ec1aba7ac5a661a9e9d129449ce6bc1a`; `research-agent.test.cjs` = `558177e6e109cc95a91ac01f808792191467fcfb8c50bca76f948d48fcd57d1f`. Both match the author's table exactly.
- **`node --test backend/test/research-agent.test.cjs` → exit 0, 21/21 pass** (independently run).
- **`node --test backend/test/research-validation.test.cjs` → exit 0, 24/24 pass** (independently run).
- **`node --test backend/test/research-contracts.test.cjs` → exit 0, 14/14 pass** (independently run).
- **Aggregate exclusion honored**: `research-workflow.test.cjs` is the H10 lane's in-flight TDD red (mtime 07:50:47Z, advancing live; the N1 files are stable at 07:29/07:30Z). The full aggregate is not a clean signal; the card's `aggregate 197/197` criterion is satisfied by the three suites above plus this documented exclusion (same rule as the H14 review). I did not touch `research-workflow.test.cjs` or any H10 file.

## 2. SPEC assessment

1. **Exactly one reviewer-recommended option implemented** — PASS. Branch 2 chosen: the dead `economics` parameter removed (`composePositionContext(position, economics)` → `composePositionContext(position)`, `agent_runtime.js:92`); the sole call site updated to single-arity (`agent_runtime.js:265-267`); an H01-semantics docblock added (`agent_runtime.js:80-91`). Branch 1 (derive `economics_status` from `economics.status`) was correctly rejected — it would collapse the three-value enum (`partial` has no counterpart in `economics.status`; `contracts.js:320`) and flip the currency-mismatch case, a silent change to accepted H01 wire semantics requiring fixture/CONTRACTS.md edits outside the write allowlist.
2. **H01 contract fixture / CONTRACTS mapping explicit** — PASS. Evidence §6 maps `position_context.economics_status` = "economics inputs present" → `contract-cases.json:110` (`available` for owned-with-full-inputs) and `research-contracts.test.cjs:237/261` (`unavailable` for candidate / owned-with-unknown-economics); `assessment.economics.status` = "comparable P/L computable" → `composeEconomics`. CONTRACTS.md §5/§6 establish the same semantics (line 47 "Currency mismatch disables comparable P/L"; line 116 "position context is copied from an exact revision and code-calculated metrics"). No fixture update needed — semantics did not change, and the evidence file states this explicitly.
3. **No silent wire-semantics change** — PASS. The removed parameter was unused, so its removal is behavior-neutral; the docblock/export edits emit no bytes. `composePositionContext` output is identical pre/post fix, the three-value enum is preserved (`partial` still emitted for owned-with-exactly-one-input, `agent_runtime.js:108`).

## 3. QUALITY assessment

- **Red-first regression genuine** — PASS. `research-agent.test.cjs:291-333` reproduces the N1 divergence pair end-to-end (EUR current price → `economics.status: 'unavailable'/currency_mismatch` while `position_context.economics_status: 'available'`, lines 309-312) and pins single-arity (lines 318-322). The pre-fix red is the arity pin: in the original H09 delivery `composePositionContext` was not exported (hash `4604249a…`, 337 lines), so `composePositionContext?.length` was `undefined`, producing the documented `undefined !== 1` failure. Post-fix it passes. The evidence is transparent that the divergence-pair assertions document the pair as contract-defined semantics rather than a data bug, and the arity pin is the actual repair guard — a genuine red→green, not a fabricated trace.
- **Post-fix invariant holds** — PASS. Under the chosen meaning (`economics_status` = economics inputs present), no reachable state misreports its own meaning, and with the parameter removed there is no wiring path coupling it to `assessment.economics.status`. The two fields are deliberately independent signals; the evidence §6 documents the renderer caveat (H14/H15B must not present `economics_status: 'available'` as comparable P/L when `economics.status` is `'unavailable'`).
- **Scope honored** — PASS. Only the three allowlisted files changed (both source files untracked on the dirty baseline, pinned by hash). No commit/push, no ports, no backgrounding; hermetic `node --test` only. No secrets in any reviewed artifact or evidence file.

## 4. Deferred (unchanged)

Runtime, live model/provider calls, n8n integration, Flutter analysis/render → DEFERRED_TO_DEV_PC / H10. Source-only acceptance only.
