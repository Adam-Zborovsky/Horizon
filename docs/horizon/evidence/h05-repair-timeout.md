# H05 Repair Evidence — Bounded Provider Response-Body Timeout

Scope: H05 repair work package. Repaired the independently reproduced unbounded provider response-body timeout defect in `backend/src/features/market/providers/yahoo.js` and expanded hermetic regression tests in `backend/test/market-history.test.cjs`.

## Changed Files (Write Allowlist Compliant)

- `backend/src/features/market/providers/yahoo.js`
  - Extends provider abort timeout lifetime to span the full lifecycle of the request: network header fetch, response body streaming, and JSON parsing.
  - Races both `fetch()` and `response.json()` against `timeoutPromise` so a hung body stream cannot bypass timeout bounds.
  - Aborts request via `AbortController` and classifies timeout or `AbortError` as `PROVIDER_TIMEOUT`.
  - Retains distinct classifications for network errors (`PROVIDER_UNAVAILABLE`) and body parse errors (`PROVIDER_INVALID_RESPONSE`).
  - Cleans up timers unconditionally via `finally { clearTimeout(timeout); }` on success, error, or timeout.
- `backend/test/market-history.test.cjs`
  - Added hermetic regression: body promise that ignores abort signal is bounded and classified as `PROVIDER_TIMEOUT` (reproducing the reported defect).
  - Added hermetic regression: stalled header fetch is bounded and classified as `PROVIDER_TIMEOUT`.
  - Added delayed body parsing test: verifies successful body completion within timeout bounds clears timer handle without triggering abort.
  - Added timer cleanup verification on network failure and body parse rejection.
- `docs/horizon/evidence/h05-repair-timeout.md`
  - Durable repair evidence, reproduction log, verification output, and sibling inspection.
- `docs/horizon/evidence/h05/`
  - Sanitized execution logs: `named-suite.log`, `aggregate-suite.log`, `regression-reproduce.log`, and `sha256sums.txt`.

## Defect Reproduction and Root Cause

The initial H05 implementation cleared its abort timer in a `finally` block immediately after `fetch()` resolved HTTP headers, before `response.json()` was called. If an external provider stalls or slowly drips bytes during body streaming, `response.json()` could hang indefinitely while the abort timer was already cleared.

### Independent Reproduction (Red Probe)
Simulating the unpatched logic with a 25 ms timeout and a stalled body read (`json: () => new Promise(() => {})`) when raced against a 75 ms safety probe:
```text
[Probe 1] Testing unpatched pattern (timeout cleared before body consumption)...
Unpatched result: {"settled":false,"elapsed":75}
```
The request stalled for 75+ ms with no rejection.

### Repaired Behavior (Green Probe)
Under the repaired implementation:
```text
[Probe 2] Testing repaired YahooMarketProvider with stalled body...
Repaired result code: PROVIDER_TIMEOUT in 26 ms; aborted: true
```
The stalled body was bounded by the 25 ms timeout, rejected with `PROVIDER_TIMEOUT`, and triggered `controller.abort()`.

## Verification Commands and Actual Output

### 1. Named Market History Suite
Command:
```bash
node --test backend/test/market-history.test.cjs
```
Result: Exit 0 (12 passed, 0 failed, duration: ~775 ms)
```text
TAP version 13
# Subtest: maps every contract range to its truthful preferred resolution
ok 1 - maps every contract range to its truthful preferred resolution
# Subtest: labels an unsupported requested resolution instead of silently relabeling it
ok 2 - labels an unsupported requested resolution instead of silently relabeling it
# Subtest: removes invalid and duplicate provider bars, keeps ascending observed bars, and reports partial data
ok 3 - removes invalid and duplicate provider bars, keeps ascending observed bars, and reports partial data
# Subtest: uses an expired immutable snapshot after a provider timeout and marks it stale
ok 4 - uses an expired immutable snapshot after a provider timeout and marks it stale
# Subtest: returns an explicit unavailable result when the provider fails without cached observations
ok 5 - returns an explicit unavailable result when the provider fails without cached observations
# Subtest: treats early closes and DST-bearing UTC timestamps as observed provider timestamps
ok 6 - treats early closes and DST-bearing UTC timestamps as observed provider timestamps
# Subtest: parses Yahoo chart rows without manufacturing OHLC values and exposes delayed metadata
ok 7 - parses Yahoo chart rows without manufacturing OHLC values and exposes delayed metadata
# Subtest: bounds a response body that ignores abort and classifies it as a provider timeout
ok 8 - bounds a response body that ignores abort and classifies it as a provider timeout
# Subtest: bounds stalled header fetch and classifies it as a provider timeout
ok 9 - bounds stalled header fetch and classifies it as a provider timeout
# Subtest: keeps the timeout through delayed body parsing and clears it after success
ok 10 - keeps the timeout through delayed body parsing and clears it after success
# Subtest: classifies network failure as unavailable and body parse rejection as invalid response
ok 11 - classifies network failure as unavailable and body parse rejection as invalid response
# Subtest: route factory applies injected authentication and only passes server-derived user context
ok 12 - route factory applies injected authentication and only passes server-derived user context
1..12
# tests 12
# suites 0
# pass 12
# fail 0
```

### 2. Aggregate Hermetic Suite and Concurrent H03 Status
Command:
```bash
node --test backend/test/*.test.cjs
```
Result: Exit 0 (32 passed, 0 failed, duration: ~1774 ms)
- 12/12 `market-history.test.cjs` tests passed.
- 6/6 `research-auth.test.cjs` tests passed.
- 14/14 `research-contracts.test.cjs` tests passed.

Note on cross-lane status: The previously reported aggregate failure at `research-auth.test.cjs:232` was resolved upstream by concurrent lane H03 (`t_5a12fcdc`). No files belonging to H03 were modified or weakened.

### 3. Syntax and Hygiene Checks
Commands:
```bash
node --check backend/src/features/market/providers/yahoo.js
node --check backend/test/market-history.test.cjs
git diff --check
```
All exit 0 with clean output.

## Sibling Timeout Path Inspection

As required by the card instructions, timeout handling was inspected across the codebase for sibling flaws:
1. `backend/src/utils/market.js` (`fetchStockData`): lines 11–23 call `fetch(tickerUrl, ...)` and `res.json()` with no timeout signal or bounding timer.
2. `backend/src/features/briefing/briefing.service.js`: lines 342–356 (`n8n` webhook trigger) and lines 387–398 (`searchTickers` Yahoo autocomplete) invoke `fetch()` and `response.json()` without timeout bounds.
3. `backend/scripts/test-research-workflow.cjs`: uses `AbortSignal.timeout()` for the initial request, but does not race `r.json()` against the timeout.

Per write allowlist rules, these files belong to other lanes and were not modified. These findings are recorded here for the orchestrator and respective module owners.

## Source Artifact SHA-256 Hashes

```text
72ce394994bc953e54ed0f1e5e31a4dc9639bd151da444ab3bf0dce19040f81d  backend/src/features/market/providers/yahoo.js
8a0aa1fb56ee308e8d53d062ac01b5265893276f5a557096f00776ac1dab7979  backend/test/market-history.test.cjs
9085369b48ef881490b1707fc2f5ee7710b2b3beeafba9334fc8d960423256ce  docs/horizon/evidence/h05/named-suite.log
dee93067a0af17d49d40b5aab4bd90b3942a58c771601c10b95d9d77e592ac4c  docs/horizon/evidence/h05/aggregate-suite.log
15f8238a9a2fcca24925a7b4aeecca36f951b05df41ddf37c94b638688bfddcb  docs/horizon/evidence/h05/regression-reproduce.log
```

## Limitations and Boundaries

- Offline hermetic tests only; no live Yahoo Finance network requests were made.
- Snapshot persistence was exercised through in-memory mock repository; no database was connected or altered.
- Route mounting in `backend/src/app.js` remains deferred to H15A.
- No Flutter UI, device verification, or production operations performed.
- Existing untracked and dirty work on the main baseline was preserved intact.

Author delivery ready for independent re-review by `t_0571f119`.
