# H18 — Independent release-readiness review (combined SPEC + QUALITY)

**Reviewer:** reviewer / zai-glm-5.3-flash (vendor-disjoint from all authors)
**Date:** 2026-11-01
**Baseline:** main @ `a9d2600c789a6d7b564fc3f0068eac1f91924a94` (Dev-PC gate repairs), 27 dirty/untracked entries = accepted authorial baseline, preserved untouched. Reviewer wrote only `docs/horizon/evidence/h18-review.md` and `docs/horizon/evidence/h18/` logs.
**Scope:** system-level final readiness per the 2026-10-31 live-board contract and the orchestrator's H18 release comment. NOT a per-package re-review — those verdicts stand.

## Verdicts

| Verdict | Result |
|---|---|
| Specification | **SPEC_PASS_SOURCE_ONLY** |
| Quality | **QUALITY_PASS_SOURCE_ONLY** |

Both verdicts are **source-level**. They are not runtime, deployment, or full-release approval. Every unexecuted criterion is enumerated in "Remaining gates" below. H19 (live release) remains operator-only; this review informs Adam's decision, it does not make it.

---

## 1. Evidence chain completeness — VERIFIED

All 23 packages (H00–H17, H07A, H09X, H10X, H16) have author evidence plus an independent review document under `docs/horizon/evidence/`. Programmatic scan: 23/23 review docs present; author evidence present for 22/23, with h02's author delivery preserved as `h02-repair.md` — its chain is honest and complete in-file: original **SPEC_FAIL_SOURCE / QUALITY_FAIL_SOURCE** with three blocking findings, targeted repair, and a **targeted re-review PASS_SOURCE_ONLY appended in the same file with the failure history preserved** (h02-review.md L238–249). Focused extra reviews required by AMENDMENT-2026-10-30 (H03 auth/privacy, H04 ownership/migration, H07 financial math) exist (`h03-quality.md`, `h04-ownership-review.md`, `h07-financial-review.md`); H18 is this document.

The Dev-PC gate (`t_65f71c73`, operator-executed 2026-11-01) is closed: codegen 44 outputs, analyze 0 errors, 145/145 + 11/11 + 15/15 + 4/4 tests, web build, both release APKs with hashes; repairs pushed as `a9d2600` and controller-verified against the server tree after CRLF/LF normalization. No DEFERRED_TO_DEV_PC claim remains unexecuted.

## 2. Independent execution — VERIFIED

- **Aggregate backend suite rerun:** `node --test backend/test/*.test.cjs` from repo root, node v22.22.2 → **365/365 pass, exit 0** (`h18/reviewer-aggregate-rerun.log`). Matches the H10X reviewer count exactly; includes all four follow-up-lane test files (`research-scenarios`, `research-runtime`, `research-scheduler`, `research-outcomes`).
- **Secret scan:** 0 matches for credential patterns in `n8n-workflow.json`; no `credentials:` blocks in the export; test 364 ("workflow export contains no literal credentials and no client-supplied userId forwarding") passed in the rerun. No secrets in the release docs or evidence logs reviewed.
- **Scope audit:** reviewer writes limited to `docs/horizon/evidence/h18-review.md` + `h18/`; `git status` delta over the 27-entry baseline is exactly the new h18 evidence paths.

## 3. Cross-package coherence — VERIFIED

**(a) Lease chain composes.** `research.service.js:547–553` issues a 32-byte random lease nonce at atomic claim (`findOneAndUpdate` CAS on queued status, L142–150); the nonce is persisted on `research_run.model.js` (`lease_nonce`/`lease_expires_at`, L33–34); result delivery in `automation.routes.js:182` does a **constant-time** comparison of the presented nonce against the persisted one, bound to run ID; `run_worker.js` returns the nonce only on a fresh claim (L127, L253) and the status view never carries it (L35). Replay returns persisted status without re-execution. This satisfies CONTRACTS §8/§9 as one continuous chain — the H08 CAS, H10 automation surface, H09X replay and H10X leader-lease interfaces use the same shapes (`run_worker.js` L372–374 documents the store-agnostic `tryAcquire`/`release` contract the future Mongo CAS lease must implement).

**(b) One runs store, no second queue.** `server.js` composes position/research services and (when provisioned) the automation surface over the **same** `runRepository` instance (L72–88, L154–166 — the H10 review O3 wiring responsibility, closed). The automation surface is deliberately **unmounted** in `startServer` (L203–216) with an explicit log line until the operator provisions a model client + scoped automation identity — fail-closed per CONTRACTS §9, never a weakened partial mount.

**(c) Legacy ingestion authenticated at source.** The CONTRACTS §9 release blocker — unauthenticated `POST /briefing` and `GET /briefing/config/system` accepting arbitrary `userId` — is resolved at source: both routes now sit behind `automationMiddleware` (`briefing.routes.js:42–58`, scopes `briefing:write`/`briefing:read`, `requireOwner: true`) plus owner-spoofing rejection (L23–29, 403 on any `userId` ≠ automation owner). `automation.middleware.js` fails closed: 401 `automation_auth_unavailable` when no token is configured, constant-time token compare, expiry and scope enforcement (L65–90).

**(d) Wire shapes compose.** Spot-verified end-to-end: `GET /positions/:id/latest` returns `{position_id, latest_assessment, run_state: {last_success, latest_attempt}}` (`research.routes.js:61–79`), and the Flutter model parses exactly those keys with backend-line cross-references (`research_models.dart:1440–1507`), including the documented constraint that `ResearchRun.fromJson` cannot parse the attempt projection. Position instrument identity serializes the full `{instrument_id, symbol, exchange, currency, provider_symbol}` object (`position.service.js:177–197` unknown-field rejection) mirrored by Flutter `InstrumentIdentity{instrumentId, symbol, exchange?, currency?, providerSymbol?}`. `PATCH /positions/:id` `{expected_revision, changes}` matches on both sides. Automation endpoints (`GET /runs/queued`, `POST /runs/:runId/execute`, `POST /runs/:runId/result`) match the n8n poll/deliver loop the H10X workflow drives (F1 re-key verified by the H10X review).

**(e) Chart semantics present in final source.** `price_chart.dart` implements the CONTRACTS §7 rules: overlay default-off (L249–250, "no scenario banner … even when a projection is present"), stale gate hides overlays with an explicit notice and a 48dp "View assessment snapshot" action (L262–293), "Conditional scenarios — not observed prices" labeling with snapshot-mode marking (L351–353), 48dp touch-target constraints (L199, L285, L1078). Runtime interaction proof is the Dev-PC gate's, executed — source shows the semantics the gate exercised.

## 4. Release documents vs the actual system

- **RESEARCH_RELEASE.md** — a **historical record of the legacy holding-focused release** (2026-09-30; published workflow `YrZSZFqopEgqTpfp`, version `254c7deb`, execution IDs, MongoDB readback). Its content is internally consistent and it honestly discloses its own limits (synthetic-history fallback paths for old briefings/opportunities/mobile remain unfixed; the mobile app was not visually exercised). It does **not** describe the new position-aware research system, and nothing presents it as doing so — but its root-level filename invites that misreading. **Non-blocking doc finding D1:** before any external consumption, mark RESEARCH_RELEASE.md as the legacy release record, superseded for the research feature by this review chain and the operator's H19.
- **N8N_REBUILD_PROMPT.md** — **stale contract section (non-blocking doc finding D2).** It states the legacy `GET /briefing/config/system` and `POST /briefing` are "no auth — public unversioned route" (L29, L31). The current source authenticates both routes (§3c above). A rebuild executed verbatim from this prompt will fail closed (401) against the current backend, and a workflow presenting no Horizon service credential breaks the live legacy loop at coordinated-rollout time. The prompt predates the H03/H05 auth rollout. **Action required before any legacy rebuild or live cutover (operator, H19):** update the prompt's contract section to include the scoped automation identity (`Authorization: Bearer <Horizon service credential>`, `userId` omitted or equal to the bound automation owner), or archive the prompt. Recorded as a release-gate item, not a source defect — the source is the more secure side of the discrepancy.

## 5. Disclosed limitations consolidated (nothing release-blocking hidden)

Wiring/deferred items, each disclosed in its own review and/or source comments — consolidated here so the full-release picture is in one place:

1. **H07A scenarios module unwired** — `scenarios.js` referenced only by `contracts.js`; no route/service import (reviewer scan confirms). Projections reach the chart only via the H13/`buildProjection` path already reviewed.
2. **H16 outcome ledger unwired** — `outcome.service.js` self-referenced; `registerForecast` lacks a hindsight-registration gate and owner-checked idempotency; both must be enforced at route wiring when activated (H16 review findings).
3. **H10X scheduler unwired from live cron** — `scheduler.js` has 0 references to `run_worker`/leader lease; the in-memory leader lease is a reference implementation; production requires the Mongo-backed CAS lease with a safe TTL or renewal (H10X Q1) and cron wiring. `retry_count` is schema-declared but un-incremented (stall-don't-retry preserved, disclosed).
4. **H09X tool runtime mounted only inside the (currently unmounted) automation surface**; `ANALYST_MAX_RETRIEVAL_PASSES` declared but unenforced; failed tool calls re-charge budget; retry-cache key lacks stage/tool scope (all H09X non-blocking findings).
5. **H17 handoff gaps** — `test_driver` harness absent for the `flutter drive` path, `flutter devices` discovery step unstated, release-signing limitation unstated (all noted in h17-review.md; none blocked the executed Dev-PC gate).
6. **Legacy synthetic-history fallback paths** for old briefings/opportunities/mobile missing data remain, as disclosed in RESEARCH_RELEASE.md itself.

## 6. Remaining gates before full release (explicit, operator-owned)

1. **Credential provisioning** — Horizon service credential + scoped automation identity (primary/admin; never in git/Flutter/cards).
2. **Automation surface activation** — mount `/automation/research` via `composeAutomationSurface` with the provisioned identities (one-step wiring documented at server.js:203–213).
3. **Live n8n publication** — publish the research workflow, update the legacy workflow/credentials per finding D2, coordinated rollout under a documented maintenance window.
4. **Mongo CAS leader lease + cron wiring for the H10X scheduler** (item 5.3), with H16 registration wiring (item 5.2) when outcomes activation is scoped.
5. **Live migration + database backup/restore readback**, primary release coordinator verification with readback (SPEC §6 operational items) — no worker self-report substitutes.
6. **Adam's explicit go/no-go** — H19. A mocked comparison is not live quality/cost evidence; the frozen evaluation-set comparison remains an open quality gate if claimed.

## 7. Verdict basis

SPEC_PASS_SOURCE_ONLY: every contract requirement is either implemented and traceable to tests/evidence (aggregate 365/365 independently rerun; per-package suites rerun by package reviewers with real logs), or is an explicit item in §6, or is a disclosed held limitation in §5. No silent waiver found. QUALITY_PASS_SOURCE_ONLY: the composition is coherent and fail-closed; the one defect class found is stale documentation (D1/D2), non-blocking, with concrete dispositions.

Source inspection did not execute Flutter tooling, live models, MongoDB, n8n or any production system in this review, consistent with the contract; the runtime proof on record is the operator-executed Dev-PC gate.

— reviewer, 2026-11-01
