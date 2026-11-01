# Orchestrator execution brief: Horizon research and charts

> **Engagement override:** AMENDMENT-2026-10-30.md governs the existing `horizon-research-2026-10` board. Do not create a replacement board. Combined independent review replaces blanket separate reviews; capacity is a managed scheduled queue, never false artifact edges. The 2026-10-31 applied review consolidation is recorded in `evidence/replan/trim-report.md`. Product requirements and independent acceptance remain mandatory; historical prose below is superseded where the amendment explicitly differs.

## Goal and authoritative package

Implement `/home/ubuntu/apps/Horizon/docs/horizon/SPEC.md` using `CONTRACTS.md`, `TASKS.md` and `task-graph.json` in the same directory. This prompt becomes execution authority when Adam explicitly gives it to you to implement; its creation in another session did not itself launch work.

Read all four files before decomposing. The package is self-contained; do not assume access to the earlier chat, a scratch attachment or a subagent report. `SOURCES.md` records research limitations. H00 preflight and H01 contracts have independent source acceptance with recorded limits; remaining implementation and PC/runtime acceptance are outstanding.

## Product outcomes

1. Candidate versus owned positions; average cost/quantity are optional owner-provided facts, not technical support levels.
2. Multi-timeframe observed data, primary-source evidence, deterministic math and a typed read-only analyst tool registry.
3. Persisted investment thesis/checkpoints and explicit explanation of what changed since prior assessments, including missing report days.
4. Direct evidence-driven candidate and owned recommendations; holding and adding are separate decisions. No mandatory bullish bias or invented allocation.
5. Distinct one/two/three-calendar-month scenarios and source-linked catalysts/invalidators. Numeric projections only with reproducible assumptions/methods; no guaranteed targets.
6. Interactive native-looking chart with line/candles, six historical ranges, OHLCV/time inspection, readable axes, pan/zoom/reset, volume context and optional clearly conditional future endpoint overlays.
7. Remove synthetic production market data and preserve truthful unavailable/stale states, legacy topics/opportunities and mobile/Wear parsing.

## Operating mode

Load current `hermes-agent`, `swarm-factory`, `model-routing-doctrine`, `horizon-research-workflow` and `subagent-driven-development` skills. For Flutter UI/chart authors also load `ui-design` and its relevant routing targets; use `ui-review` for visual/accessibility review. Skills in your profile may differ: attach per-card where supported rather than modifying another profile's tree.

You are the dedicated planner/orchestrator. Decompose, route, synthesize, report; do not implement source work yourself or assign it to the default chat profile. Resolve live model/profile/provider availability and reasoning bands, reuse existing profiles and attach skills per card. Do not change other profiles or create/reconfigure a profile without authorization. Same-model review does not qualify as independent; different vendor where available, with limitations declared.

Create a fresh engagement board only after explicit execution authorization. Put the roster specification, repository path, exact baseline and scope on the root record. Measure CPU/memory/API budgets; start with at most two concurrent source lanes unless measurement supports more. Discover current CLI/tool syntax from authoritative documentation/skills; this document deliberately does not invent Kanban flags.

`task-graph.json` is a dependency graph, not a claim that it maps automatically to one-parent CLI fields. Materialize multi-parent joins explicitly using supported dependency mechanisms or ready-state gating; do not dispatch an integration task after just one of its prerequisites.

## Work decomposition

The canonical task graph defines bounded packages, early integration slices and explicitly held follow-ups. Keep red-test/run-failure/implement/run-pass/evidence steps inside each coherent implementation card, not separate subcards. Every card carries its own goal, workspace, accepted contract version, predecessor artifacts, exact files, named tests, relevant skills and invariant strings. Do not pass only a package ID or the whole chat.

H00 protects current dirty/untracked work and verifies toolchain. H01 freezes executable contracts/fixtures. H02 proves existing fl_chart interactions before a new renderer is adopted. H03 security precedes private automation. H11 and H15 serialize generated Flutter outputs; H15 alone changes shared integration files. H17 is full QA, H18 independent readiness review. H19 is NOT an autonomous worker card.

For backend model calls, use the injected provider client in the fixed bounded Node pipeline in `agent_runtime`; n8n triggers `/execute`, polls persisted status and delivers validated results. Generalized stage/tool endpoints remain held H09X follow-up, not a core prerequisite. All private synthesis context is bound server-side. No credential copying by workers.

## Hard invariants: paste onto every card

- Secrets never in output, logs, fixtures, exported literal credentials or card text. Workers do not read .env/credential stores.
- No `ports:` in Docker compose: `expose:` only, through existing Cloudflare Tunnels. No DNS/tunnel changes.
- No shell backgrounding (`&`, `nohup`, `setsid`); use tracked terminal background processes only when authorized.
- Preserve dirty/untracked baseline and stored data. No reset/clean, database/volume deletion, unapproved commit/push/history rewrite.
- No live workflow publication, paid service/license acceptance, credential provisioning, live migration or other-profile changes by worker cards. Primary/admin gate.
- Observed bars, user cost and future scenarios are distinct. No invented prices/candles/history/sources/results.
- Read contract before implementation; edit only assigned files. Shared files/generators have one owner. Stop on contract drift.
- Use real test/tool output. Missing SDK/device access is a blocker, not a pass. Two failures on same target -> reclaim/escalate with exact errors, not blind retry.

## Review and session continuity

After each completed unit: ONE independent combined specification and code-quality review with separate verdict sections. Only H03 authorization/privacy, H04 ownership/migration, H07 financial calculations and H18 final readiness retain additional focused review. Do not automatically decompose a failed combined review into separate assessments and synthesis; route one scoped author repair then targeted independent re-review. The reviewer does not fix findings. Author delivery alone does not satisfy acceptance. Inspect exact artifacts and actual command output; preserve evidence and failed reports under `docs/horizon/evidence/`.

No speculative framework installation, full trading-agent stack, new queue service or chart rewrite. Only introduce a dependency after the failing capability/requirement is documented and Adam approves the supply-chain/license/cost implications.

## Completion and stop line

Source completion requires all engineering/research/chart/accessibility criteria and actual backend/Flutter builds/tests in SPEC.md. No forecasting-performance claim from a handful of examples. Show candidate and owned report examples and chart interaction evidence.

Before H19, present one concrete live-release change set, recoverable workflow/app baseline, database backup/restore proof, dry-run migration counts, credential/provider/license/budget gates and rollback. Temporary Horizon downtime is acceptable; shared n8n disruption is not. Do not build staging infrastructure for its own sake.

Only primary/admin performs approved external writes, credential setup, migration and publication, and then verifies exact targets by readback. After actual live acceptance, synthesize final evidence, archive the engagement with the supported procedure and record any factory-created resources. Do not archive or report success while required criteria remain unverified.

## Live-board synchronization — 2026-11-01 07:30 UTC (controller)

Supersedes all status values in this document dated before 2026-11-01. Verified from the live board, run logs and on-disk evidence (not memory):

- **Independently accepted, source-only (14 packages):** H00 (preflight, recorded limits), H01, H02, H03 (+focused security), H04 (+focused ownership/migration), H05, H06, H07 (+focused financial), H08, H09, H11, H12, H13, H15A. Per-lane evidence: `evidence/hXX-review.md` (FAIL→repair→PASS history preserved). Backend aggregate at H09 acceptance: 197/197 across 10 suites.
- **Running author lanes (cap 2):** H14 `t_5f43465d` (released 07:20 UTC morning resume), H10 `t_5a93e235` (released 07:25 UTC this sync).
- **Scheduled/awaiting:** H15B `t_fc55c3a0` (last gate: H14), H15 `t_a8e17276`, H17 `t_90250e8b`, H18 reviews (Dev-PC gate `t_65f71c73` precedes H18).
- **Deferred/held:** H16, H07A, H09X, H10X. H19 operator-only.
- **New scoped repair (held for capacity):** H09-N1 economics_status/economics.status naming collision — repair `t_d218b310` + child reviewer `t_77356be1`, per h09-review.md N1 (non-blocking finding; Adam requested the collision be removed).
- **Roster:** worker zai/glm-5.3-flash, reviewer deepseek/deepseek-v4-pro (vendor-disjoint). Older OpenAI model names in historical card bodies are superseded.
- **Concurrency:** cap 2 worker lanes per the 2026-11-01 continuation handoff (supersedes the 2026-10-31 cap-3 override).
- Card-ID mapping: `/home/ubuntu/.hermes/profiles/orchestrator/horizon-orchestration.json`; graph statuses mirrored in `task-graph.json` (`live_board_sync` block).
