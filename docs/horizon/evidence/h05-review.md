# H05 combined independent review

Review scope: source-only review of the H05 market history service, router, snapshot model, Yahoo adapter, tests and author evidence. No source files were changed. This is not runtime, deployment, Flutter, live-provider, database, or release acceptance.

## Verdicts

- SPEC: `SPEC_FAIL_SOURCE`. The implementation does not fulfill the bounded provider-timeout behavior: `backend/src/features/market/providers/yahoo.js:53-69` clears its abort timer immediately after `fetch()` resolves, before `response.json()` at lines 75-80. A stalled response body therefore bypasses the advertised timeout and can leave a history request pending indefinitely. Reproduced with a 10 ms timeout and a mocked `json()` promise that never settles; after 100 ms the fetchHistory call remained unsettled.
- QUALITY: `QUALITY_FAIL_SOURCE`. The timeout gap is both a correctness defect and a missing regression case. The H05 named suite passes, but the broader hermetic suite has an independently reproducible failing assertion in `backend/test/research-auth.test.cjs:232`; see regression evidence below. Do not treat the broader-suite failure as caused by H05.

## Independent checks

- `node --version`: `v22.22.2`.
- `node --test backend/test/market-history.test.cjs`: exit 0; 8 passed, 0 failed.
- `node --test backend/test/*.test.cjs`: exit 1; 27 passed, 1 failed. Failure: `run callback authorization requires a current nonce and rejects conflicting replay deliveries`, `backend/test/research-auth.test.cjs:232`, `AssertionError: Missing expected exception.` This is outside H05 ownership; report to the owning lane and preserve the current dirty baseline.
- Provider timeout-body probe: exit 0; output `{"settledAfter100ms":false,"expectedBoundMs":10}`. This confirms the mocked body read is not covered by the timeout.

## Criteria and scope notes

- All six requested range/resolution mappings are implemented and directly tested in `market-history.test.cjs:89-94`.
- The service validates bars, orders/deduplicates them, exposes invalid-row warnings and returns stale/unavailable rather than synthetic bars; relevant tests pass.
- Cache keys include contract version, instrument, range and resolution (`market.service.js:136-138`); snapshots are persisted with immutable schema fields. No live database was used.
- The route applies authentication middleware and forwards only server-derived user identity (`market.routes.js:8-18`). Application mounting and the vetted instrument resolver are explicitly deferred to H15A, consistent with the card boundary.
- Currency, adjustment basis, exchange timezone, fetch/as-of times, delay status, actual resolution and source are carried through the response/provider path. No live Yahoo request was made.
- Flutter analysis/generation/tests/device/APK checks remain `DEFERRED_TO_DEV_PC`; no Flutter or release verdict is implied.

## Required repair before re-review

1. Keep the provider timeout active until the full response has been consumed and parsed, including `response.json()`; ensure timeout aborts/rejects that phase as `PROVIDER_TIMEOUT` without leaking timer handles.
2. Add a hermetic regression where `fetch()` resolves but `response.json()` never settles, and verify the bounded timeout rejects. Re-run the H05 suite and broader hermetic suite; the unrelated research-auth failure must be routed to its owner, not hidden or weakened.

## Boundaries

No production/live-provider/database operations, Flutter toolchain checks, renderer/dependency changes, or source repairs were performed. Existing uncommitted and untracked files were preserved.

---

## Re-review — 2026-10-31 (timeout repair re-check)

The prior SPEC_FAIL_SOURCE / QUALITY_FAIL_SOURCE history above is retained for audit. This section records the independent re-review after the author's scoped timeout-body repair (t_d3f69735). No source was repaired by the reviewer; no new cards were created.

### Verdicts

- SPEC: `SPEC_PASS_SOURCE_ONLY`. All six ranges (1D/5m, 1W/30m, 1M/3M/6M/1Y at 1d) match CONTRACTS.md §3; unsupported requested resolutions are labeled `UNSUPPORTED_RESOLUTION` rather than silently relabeled; truthful `actual_resolution` with `RESOLUTION_FALLBACK` warning; provider failures yield explicit `unavailable` (machine-readable reason) or stale cache, never synthetic bars; timestamps/currency/adjustment/delay/source metadata survive serialization (schema is `passthrough`, verified).
- QUALITY: `QUALITY_PASS_SOURCE_ONLY`. The previously reproduced timeout defect is fixed correctly: `response.json()` is now raced against the same `timeoutPromise` as `fetch()` (yahoo.js:71-93), and the timer is cleared only in the outer `finally` (yahoo.js:94-96), so the abort/timeout spans the full request lifecycle including body streaming and parsing.

### Independent reproductions (reviewer-authored hermetic probe, not author self-report)

- Stalled body (`json()` never settles, ignores abort): bounded to `PROVIDER_TIMEOUT` at ~27 ms vs 25 ms timeout, `aborted=true`.
- Stalled header (`fetch()` never settles): `PROVIDER_TIMEOUT`, `aborted=true`.
- Timer cleanup on success (body resolves in 10 ms under a 40 ms timeout): returns bars; no late abort after a further 60 ms wait.
- Network failure → `PROVIDER_UNAVAILABLE`; body parse rejection → `PROVIDER_INVALID_RESPONSE`; non-OK status → `PROVIDER_UNAVAILABLE`.

### Test and hygiene evidence

- `node --test backend/test/market-history.test.cjs`: exit 0, 12/12 pass.
- `node --test backend/test/*.test.cjs`: exit 0, 32/32 pass (the prior `research-auth.test.cjs:232` failure is gone, resolved by concurrent lane H03; not weakened here).
- `node --check` on yahoo.js and the test file: clean. `git diff --check`: clean.
- On-disk SHA-256 for the five H05 files match: yahoo.js and the test file match the repair evidence; service/routes/model are unchanged from the original author delivery (repair scope respected).

### Re-check of all prior findings

- Six ranges and truthful resolutions: confirmed against `MARKET_RANGE_CONFIG`, `RANGE_PARAMETERS`, and CONTRACTS.md.
- Ordering, dedup, invalid-bar omission: `normalizeBars` sorts by `time`, dedups by `session_date|time`, reports `INVALID_BARS_OMITTED`; `historyResponse` schema independently enforces ascending/unique bars.
- Stale cache and unavailable states: expired snapshot + provider error → `is_stale`, `data_status=partial`, `STALE_CACHE` warning; no cache + provider error → `unavailable` with `PROVIDER_TIMEOUT`/etc reason.
- Metadata serialization: `exchange_timezone`, `adjustment_basis`, `delay_status`, `as_of`, `fetched_at`, `source`, `available_ranges` all pass through the `passthrough` schema.
- Route auth injection: `createMarketRouter` applies injected auth and passes only server-derived `ownerId`; confirmed by test and source.
- Timeout lifecycle: independently re-verified across success/error/timeout (see above).

### Sibling-inspection claims (repair evidence §"Sibling Timeout Path Inspection")

Verified accurate, none modified (out of H05 ownership): `backend/src/utils/market.js` (`fetchStockData`, fetch + `res.json()` unbounded), `backend/src/features/briefing/briefing.service.js` (n8n webhook ~L342 and Yahoo autocomplete ~L387 unbounded), `backend/scripts/test-research-workflow.cjs` (`AbortSignal.timeout()` does not race `r.json()`). These remain recorded for their lane owners on root; they do not gate H05.

### Non-blocking note (not a defect in scope)

`yahoo.js` labels `adjustment_basis: 'raw_ohlc_unadjusted'` while separately carrying Yahoo `adjclose` as `adjusted_close`. The adapter passes Yahoo's chart values through unchanged and keeps adjusted close distinct, so the "do not mix bases" contract holds; whether Yahoo's returned OHLC are themselves split-adjusted is not determinable offline (no live request) and is left for a live-provider verification lane, not this source-only gate.

### Explicit deferred criteria (not passed, not failed here)

- Flutter analysis/generation/tests/device/APK: `DEFERRED_TO_DEV_PC`.
- Router mounting and vetted-instrument resolver composition in `backend/src/app.js`: deferred to H15A.
- Live Yahoo provider behavior, database persistence, and runtime/release readiness: not exercised; source-only acceptance does not imply runtime or release approval.
