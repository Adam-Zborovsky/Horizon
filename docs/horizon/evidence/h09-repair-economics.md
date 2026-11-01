# H09-N1 Repair — `economics_status` / `economics.status` naming collision

- **Task:** t_d218b310 (H09-N1 scoped repair, author delivery only)
- **Provenance:** H09 combined review non-blocking finding N1 — `docs/horizon/evidence/h09-review.md` line 55 (`agent_runtime.js:80-96`). Adam flagged it for fixing. Not a new feature.
- **Scope honored:** only `backend/src/features/research/agent_runtime.js`, `backend/test/research-agent.test.cjs`, and this evidence file were written. No commit/push, no branch change, no ports, no backgrounding, fixtures/mocks only, hermetic `node --test` only.
- **Author:** worker / zai / glm-5.3-flash. Reviewer (released separately by controller): deepseek / deepseek-v4-pro.

## 1. Defect (as verified by controller)

`composePositionContext(position, economics)` accepted `economics` but never read it. `position_context.economics_status` was derived solely from `hasCost && hasQuantity`, so when `composeEconomics` returned `{ status: 'unavailable', reason: 'currency_mismatch' }` (or `state_without_executed_economics` / `economics_input_invalid`), `position_context.economics_status` still read `'available'`. The dead parameter showed the wiring was left incomplete; the field name collides with the authoritative `assessment.economics.status`.

## 2. Option chosen and why

**Chosen: drop the unused `economics` parameter and clarify the field's meaning (review recommendation, branch 2).**

Not chosen: deriving `economics_status` from the composed `economics.status`. That branch would silently change accepted H01 wire semantics:

- `contracts.js:320` pins `economics_status: z.enum(['available', 'partial', 'unavailable'])` — a three-value enum the runtime emitter would collapse to two (`'partial'` — owned with exactly one of cost/quantity — has no counterpart in `economics.status`, which reports `'unavailable'` there, e.g. `missing_average_cost`).
- The currency-mismatch case would flip `economics_status: 'available'` → `'unavailable'`, redefining a field the H01 contract fixture (`contract-cases.json`, `research-contracts.test.cjs`) already publishes as "economics inputs present".
- Both changes would require fixture and CONTRACTS.md edits that are outside this task's write allowlist, and would alter wire semantics the card explicitly says not to change silently.

Under the chosen option the two fields **cannot disagree in the defined meaning**: `economics_status` is *defined* as "economics inputs present on the position" (available = both cost and quantity present; partial = owned with exactly one; unavailable = not owned), derived purely from the position's own inputs. `assessment.economics.status` remains the sole authoritative P/L-availability signal. There is no reachable state where `economics_status` misreports *its own* meaning, and with the parameter removed there is no wiring path through which the two could ever couple.

## 3. Red-first regression (pre-fix, actual output)

New test in `backend/test/research-agent.test.cjs:291` — `position_context.economics_status keeps H01 inputs-present semantics with no dead economics parameter`. It reproduces the exact controller-verified divergence pair end-to-end (currency-mismatch current price → `economics.status: 'unavailable' / currency_mismatch` while `position_context.economics_status: 'available'`), asserts that pair matches the H01 semantics, and pins the repair itself: the composer must have single arity (no `economics` parameter).

Command (pre-fix source, post-test):

```
$ cd backend && node --test --test-name-pattern 'inputs-present semantics' test/research-agent.test.cjs
not ok 1 - position_context.economics_status keeps H01 inputs-present semantics with no dead economics parameter
  ---
  duration_ms: 26.348211
  type: 'test'
  location: '/home/ubuntu/apps/Horizon/backend/test/research-agent.test.cjs:291:1'
  failureType: 'testCodeFailure'
  error: |-
    H09-N1: composePositionContext must not accept an economics parameter

    undefined !== 1

  code: 'ERR_ASSERTION'
  name: 'AssertionError'
  stack: |-
    TestContext.<anonymous> (/home/ubuntu/apps/Horizon/backend/test/research-agent.test.cjs:318:10)
  ...
1..1
# tests 1
# pass 0
# fail 1
# cancelled 0
```

Exit code 1. Red is carried by the parameter pin (`composePositionContext?.length` was `undefined` pre-fix — the export did not exist and the two-arity function was not exported). The divergence-pair assertions earlier in the test **passed pre-fix**, documenting that the pair is the contract-defined semantics, not a data bug; the defect was the dead parameter and the ambiguous wiring, exactly as the review's N1 recommendation frames it.

## 4. The fix

`backend/src/features/research/agent_runtime.js`:

1. `composePositionContext(position, economics)` → `composePositionContext(position)` — dead parameter removed (was `agent_runtime.js:80`).
2. Sole call site (assessment composition, was line ~265): the second argument `economics` removed.
3. Docblock added on the composer stating the H01 semantics ("economics inputs present", NOT P/L computability), naming `assessment.economics.status` (from `composeEconomics`) as the authoritative P/L availability signal, and warning downstream H14/H15B renderers never to present `economics_status: 'available'` as comparable P/L when `economics.status` is `'unavailable'`. Inline comment added at the `economics_status` assignment.
4. `composePositionContext` added to `module.exports` (alongside the already-exported `composeEconomics`) so the regression test can pin the one-arity signature.

No wire object changed shape; no enum, fixture, or schema value changed.

## 5. Post-fix verification (actual outputs, exit codes)

```
$ cd backend && node --test --test-name-pattern 'inputs-present semantics' test/research-agent.test.cjs
# tests 1  # pass 1  # fail 0          → exit 0

$ cd backend && node --test test/research-agent.test.cjs
# pass 21  # fail 0                    → exit 0   (20 baseline + 1 new regression test)

$ cd backend && node --test test/research-validation.test.cjs
# pass 24  # fail 0                    → exit 0

$ cd backend && node --test test/research-contracts.test.cjs
# pass 14  # fail 0                    → exit 0   (H01 wire semantics unchanged)

$ node --test 'backend/test/*.test.cjs'     (from repo root; glob form)
# tests 198  # pass 198  # fail 0      → exit 0
```

Aggregate delta vs. the card's stated baseline: 197 → **198** solely because one regression test was added (research-agent 20 → 21). No pre-existing test changed status.

Environment note: run from the repo root so the integration lane's documented `.env` precondition is met (see `h04-review.md`/`h06-repair.md`: `research-history-integration.test.cjs` validates `MONGODB_URI`/`JWT_SECRET` at module load and aborts without them — a no-credentials condition, not a code defect). No secret values were read or printed.

## 6. Contract mapping (explicit CONTRACTS.md-style section)

| Field | Authoritative meaning | Producer | Notes |
| --- | --- | --- | --- |
| `position_context.economics_status` | **"Economics inputs present on the position"** — `available` = owned with both `average_cost` and `quantity` present; `partial` = owned with exactly one; `unavailable` = not owned | `composePositionContext(position)` from the position's own fields only | Unchanged from accepted H01 semantics (`contract-cases.json` line 110; `research-contracts.test.cjs` candidate/owned-with-unknown-economics cases). **No fixture update needed — semantics did not change.** |
| `assessment.economics.status` | **"Comparable P/L computable for this assessment"** — `available` with full P/L fields, or `unavailable` with `reason` (`currency_mismatch`, `adjustment_basis_mismatch`, `state_without_executed_economics`, `missing_average_cost`, `missing_current_price`, `economics_input_invalid`) | `composeEconomics(position, currentPrice)` | Unchanged. Sole authoritative P/L availability signal. |
| Relationship | The two fields are deliberately independent signals about different questions. After this repair there is no code path connecting them: the composer takes no economics argument, so they can never disagree *within their own defined meanings* and can never be silently coupled. | — | Downstream H14/H15B renderers must not present `economics_status: 'available'` as "comparable P/L available" when `economics.status` is `'unavailable'` (per h09-review.md N1). |

## 7. Changed files and SHA-256

| File | Status | SHA-256 |
| --- | --- | --- |
| `backend/src/features/research/agent_runtime.js` | modified | `3df087bbad44fd83ef3e05731f5e69e4ec1aba7ac5a661a9e9d129449ce6bc1a` |
| `backend/test/research-agent.test.cjs` | modified | `558177e6e109cc95a91ac01f808792191467fcfb8c50bca76f948d48fcd57d1f` |
| `docs/horizon/evidence/h09-repair-economics.md` | new (this file) | controller-verified on disk — self-hash omitted by construction |

Baseline condition: both modified files are untracked on the dirty main baseline (H09 author delivery was not committed per the standing no-commit invariant), so `git diff` shows no stat; disk state is pinned by the hashes above.

## 8. Author handoff

Author delivery only — controller verifies artifacts and closes delivery, then releases the child reviewer (`t_77356be1`). No self-completion, no request-review.
