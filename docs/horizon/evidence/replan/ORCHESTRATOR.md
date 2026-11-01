# Orchestrator execution brief: Horizon research and charts

## Goal and authoritative package

Implement `/home/ubuntu/apps/Horizon/docs/horizon/SPEC.md` using `CONTRACTS.md`, `TASKS.md` and `task-graph.json` in the same directory. This prompt becomes execution authority when Adam explicitly gives it to you to implement; its creation in another session did not itself launch work.

Read all four files before decomposing. The package is self-contained; do not assume access to the earlier chat, a scratch attachment or a subagent report. `SOURCES.md` records research limitations. No implementation is complete yet.

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

There are 20 packages H00–H19, with exact file allowlists, dependencies, acceptance and invariant blocks. Convert each source package into small red-test/run-failure/implement/run-pass/evidence subcards where needed. Every card carries its own goal, workspace, accepted contract version, predecessor artifacts, exact files, named tests, relevant skills and all invariant strings. Do not pass only a package ID or the whole chat.

H00 protects current dirty/untracked work and verifies toolchain. H01 freezes executable contracts/fixtures. H02 proves existing fl_chart interactions before a new renderer is adopted. H03 security precedes private automation. H11 and H15 serialize generated Flutter outputs; H15 alone changes shared integration files. H17 is full QA, H18 independent readiness review. H19 is NOT an autonomous worker card.

For backend model calls, use the injected provider client in `agent_runtime`; n8n invokes bounded ready-stage endpoints and persistence/delivery, rather than implementing a second independent analyst loop. All private synthesis context is bound server-side. No credential copying by workers.

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

After each completed unit: independent specification review, then code/quality review. The reviewer does not fix their own findings; return defects to author. Do not close a dependency based only on author's “done.” Check the exact diff, actual test output and resulting artifact. Maintain durable status and handoff evidence under `docs/horizon/evidence/` with no secrets, exact commands, blockers and next-ready tasks. Do not rely on scratch files surviving sessions.

No speculative framework installation, full trading-agent stack, new queue service or chart rewrite. Only introduce a dependency after the failing capability/requirement is documented and Adam approves the supply-chain/license/cost implications.

## Completion and stop line

Source completion requires all engineering/research/chart/accessibility criteria and actual backend/Flutter builds/tests in SPEC.md. No forecasting-performance claim from a handful of examples. Show candidate and owned report examples and chart interaction evidence.

Before H19, present one concrete live-release change set, recoverable workflow/app baseline, database backup/restore proof, dry-run migration counts, credential/provider/license/budget gates and rollback. Temporary Horizon downtime is acceptable; shared n8n disruption is not. Do not build staging infrastructure for its own sake.

Only primary/admin performs approved external writes, credential setup, migration and publication, and then verifies exact targets by readback. After actual live acceptance, synthesize final evidence, archive the engagement with the supported procedure and record any factory-created resources. Do not archive or report success while required criteria remain unverified.
