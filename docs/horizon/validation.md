# Planning-package validation

## Scope

Validated the proposed handoff, not an implemented application. Source implementation, migration, live workflow publication and new Flutter builds remain not started. No production changes were made while preparing this package. Existing dirty/untracked code/workflow files were preserved.

## Actual checks and results

Repository inspection returned branch `main` and the existing modified `backend/src/utils/scheduler.js`, untracked N8N_REBUILD_PROMPT.md, RESEARCH_RELEASE.md, backend/scripts/test-research-workflow.cjs and n8n-workflow.json, plus the new docs tree. This is not a clean-HEAD baseline and future workers must recheck it.

Official fl_chart version 1.1.1 archive was downloaded in memory through the pub.dev version API. It contains candle chart source and transformation configuration. Inspected candle data includes open/high/low/close, not volume or timestamp fields. No package was installed. This proves source capability, not finished chart interactions or the actual project lock resolution.

Python parsed task-graph.json and checked package IDs, all dependencies, acyclicity/topological layers, existing-file declarations, one owner per proposed/modified path, path safety and mandatory acceptance/steps/invariants. Actual output:

```
PACKAGES 20
DEPENDENCY_LAYERS [['H00'], ['H01'], ['H02', 'H03', 'H05', 'H06', 'H11'], ['H04', 'H07', 'H13'], ['H08', 'H12'], ['H09'], ['H10', 'H14', 'H16'], ['H15'], ['H17'], ['H18'], ['H19']]
MISSING_EXISTING_PATHS []
FILE_OWNERSHIP_COLLISIONS {}
UNSAFE_PATHS []
PASS: graph, file ownership, declared existing paths and card requirements
```

The package explicitly separates new/proposed files from existing files. H19 is a primary/admin gate, not an autonomous worker task. Every task embeds safety invariants and acceptance criteria. Production route names/models in CONTRACTS.md are proposed behavior, not claims of existing APIs.

## Review corrections incorporated

- Prefer bounded existing-fl_chart prototype rather than assuming candles require a new package.
- Distinguish hosted TradingView widgets, Lightweight Charts and Advanced Charts.
- Numeric projections remain optional, reproducible and distinct from observed history; no generated future candles/path.
- Specify one backend agent runtime with n8n stage orchestration, rather than two competing analyst implementations.
- Bind stage/tool/result operations to server-owned run/owner/revision/nonce; private cost is synthesis-only and not returned by generic input.
- Specify actual SDK/mobile evidence, fixture-based arithmetic, missing data and release-readback gates.
- Preserve existing user changes and serialize shared-file/generated-output ownership.

## Limitations

- No application tests were added or run by this planning deliverable. Proposed test files/commands are future acceptance work, not a fabricated pass count.
- Flutter executable was not on PATH during inspection; no mobile/web/Wear build or interaction evidence is claimed.
- Source/library documentation does not establish predictive performance or chart usability. Both require implementation-specific evaluation.
- No paid provider, license eligibility, new dependency, new credentials or model budget is approved by these files.
- Existing routes' authentication and synthetic fallback issues are source-inspection findings; no external exploitation was performed.
- Full source-level independent review belongs to H18 after implementation. Planning mechanical checks do not substitute for it.
- One convenience listing command initially mixed relative and absolute pathlib paths and failed; a corrected repository-relative validation completed successfully. It did not alter source files.
