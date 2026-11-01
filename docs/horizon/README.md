# Horizon redesign: orchestrator handoff

**Status: planning complete; implementation not started.** No production app, database, service or published workflow was changed by preparing this package.

## The product decision

Keep Horizon's dark/gold design. Add an interactive chart using the existing native Flutter renderer first, and replace only the renderer if a bounded capability prototype fails. Build position-aware research with persistent thesis memory, direct conclusions and evidence-backed one/two/three-month outlooks. Do not confuse a conditional outlook with a reliably predicted future price.

## Read in this order

1. **ORCHESTRATOR.md** — executable handoff prompt and authority boundary.
2. **SPEC.md** — scope, architecture, chart decision, tool registry and definition of done.
3. **CONTRACTS.md** — shared data/API/time/security contract.
4. **TASKS.md** — file ownership, dependencies, test steps and package acceptance.
5. **task-graph.json** — machine-readable work packages; not live Kanban IDs.
6. **SOURCES.md** — primary-source findings and limitations.
7. **validation.md** — checks performed on this planning package; not implementation test results.

## Dispatch summary

20 work packages H00–H19. H00/H01 establish baseline/contracts; chart prototype, security, data and Flutter domain work can then proceed independently. H15 integrates shared files. H17 tests the complete experience, H18 independently reviews it. H19 is a primary/admin release gate, not a worker assignment.

The work packages are too large to treat as one-shot prompts. The orchestrator must make small test-first subcards under each, preserve the package acceptance criteria and checkpoint actual evidence after each session. No model/provider IDs are pinned in this package. Resolve the live roster; use a dedicated orchestrator, not the default chat profile.

## Chart scope

- Line/candle modes; 1D/1W/1M/3M/6M/1Y.
- Readable date/price axes, real timestamps, OHLCV inspection, pan/zoom and reset.
- Volume context, optional labeled user-cost line, distinct future scenario endpoint ranges when quantitative evidence exists.
- Keep the design. Existing fl_chart first; Lightweight Charts WebView is the proposed fallback. Hosted TradingView widgets do not satisfy custom Horizon data/overlay requirements.

## Important blockers already identified

- Existing automation ingestion/config routes need authenticated rollout before private position data is connected.
- Existing fake/random price/history fallback paths must become honest unavailable-data UI.
- Existing saved reports cannot be assumed to contain observed chart history.
- Flutter SDK was absent from PATH at planning inspection; actual mobile/web builds and interaction evidence remain mandatory.
- Service/provider credential provisioning, live migration and workflow publication require primary/admin coordination and approval. No new paid dependency is preapproved.

## Give this to the orchestrator

Read `/home/ubuntu/apps/Horizon/docs/horizon/ORCHESTRATOR.md` and the files it references. Implement the approved source scope using durable dependency-linked worker/reviewer cards. Start with H00/H01, preserve the dirty baseline, prove the existing-library chart prototype before changing renderers, and stop at the H19 live-release gate for approval.
