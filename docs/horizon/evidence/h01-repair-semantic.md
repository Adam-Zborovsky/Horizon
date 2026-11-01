# H01 semantic validator repair evidence

## Scope

Changed only the H01 allowlisted contract, test, fixture, and this evidence artifact:

- `backend/src/features/research/contracts.js`
- `backend/test/research-contracts.test.cjs`
- `backend/test/fixtures/research/contract-cases.json`
- `docs/horizon/evidence/h01-repair-semantic.md`

No service, database, provider, credential, or network operation was run.

## Reproduced regression and repair

The historical independent review found four unresolved semantic boundaries. The current untracked H01 delivery already contained repairs for candidate cost/quantity, checkpoint representations, calendar overflow, outlook lower bound, and the additive-response boundary. This repair independently found and closed the remaining contract field omission: `assessmentPositionContext` treated `opened_on` as an unconstrained additive response key, so a candidate assessment carrying an executed opening date was accepted.

Red regression command from repository root:

```text
node --test backend/test/research-contracts.test.cjs
exit 1
# tests 14
# pass 13
# fail 1
failure: opened_on
true !== false
at backend/test/research-contracts.test.cjs:248
```

The regression makes candidate assessment context reject each executed fact independently: `average_cost`, `quantity`, and `opened_on`. It also proves owned context may retain unknown economics and all valid candidate actions (`buy`, `wait`, `avoid`, `insufficient_evidence`) still parse.

The implementation adds `opened_on` as an optional nullable, real ISO date field on `assessmentPositionContext` and applies the existing candidate-state prohibition to it. This retains response `.passthrough()` behavior for legitimate future additive response keys; it does not make the response strict or weaken write validation.

## Contract mapping and verified coverage

- **CONTRACTS §1 additive-response adjudication:** `positionWrite` remains strict and rejects an unknown write key. `researchAssessment` and nested `Claim` retain additive response extension acceptance; malformed required `market_thesis` is still rejected.
- **CONTRACTS §2/§5 candidate economics:** candidate assessment contexts reject `average_cost`, `quantity`, and `opened_on` independently. Owned assessment contexts may keep both economics values unknown.
- **CONTRACTS §6 checkpoint representations:** rolling indicators require `metric_id` and reject `fixed_level`; fixed observed levels require `fixed_level` and reject `metric_id`; business conditions reject both numerical forms. Valid variants parse.
- **CONTRACTS §1/§5 calendar/outlook semantics:** `calendarTargetDate` preserves `0001` and `0099` formatting, leap/month-end clamping, and the maximum valid boundary; it throws a `RangeError` rather than emitting year `10000`. Assessments reject evaluation dates before `session_as_of` or after the calendar target. Actual exchange-session membership remains adapter-owned and was not asserted by these schema tests.

## Verification

Green command from repository root:

```text
node --test backend/test/research-contracts.test.cjs
exit 0
# tests 14
# pass 14
# fail 0
# skipped 0
```

Hygiene command from repository root:

```text
git diff --check
exit 0
```

## Limits

This is offline Node schema validation using synthetic fixtures. It does not establish exchange-calendar adapter behavior, source-evidence entailment/registry resolution (H09), deployment Node compatibility, routes, persistence, live providers, Flutter, device behavior, or release readiness.
