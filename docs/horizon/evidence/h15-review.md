# H15 — Combined independent specification and quality review

Reviewer: `reviewer/deepseek-v4-pro` (vendor-disjoint from author `worker/zai`).
Reviewed package: H15 Application integration and legacy/mobile/Wear compatibility —
BOTH halves (frozen backend `t_a8e17276` + Flutter continuation `t_1812d30d`).
Source-only scope; every Dart/Flutter runtime criterion is DEFERRED_TO_DEV_PC.
Date: 2026-11-01.

## Verdicts

- **SPEC verdict: `SPEC_PASS_SOURCE_ONLY`**
- **QUALITY verdict: `QUALITY_PASS_SOURCE_ONLY`**

Both verdicts are source-only. They release source-development dependencies only,
never runtime acceptance or release readiness. Every unexecuted PC/runtime
criterion is listed explicitly in §6.

## Independent verification (real commands and outputs)

All commands run from the repository root on the live dirty `main` baseline. No
source file was modified by the reviewer; no commit/push; no cleanup.

| Check | Command | Result |
|---|---|---|
| SHA-256 — 4 backend + 10 Flutter files | `sha256sum …` | **14/14 match author evidence §1/§2.2 byte-for-byte** |
| Node runtime | `node --version` | v22.22.2 (matches SPEC §7) |
| Dart/Flutter toolchain | `which dart flutter` | absent — DEFERRED_TO_DEV_PC honest |
| Whitespace | `git diff --check` | exit 0 |
| Named compatibility suite | `node --test backend/test/research-compatibility.test.cjs` | **15/15 pass, exit 0** |
| Full aggregate | `node --test backend/test/*.test.cjs` | **249/249 pass, 0 fail, exit 0** |

Hash table (computed this run, all identical to author evidence):

```text
538bea5e… backend/test/research-compatibility.test.cjs
5f35d2ed… backend/src/app.js
9716e015… backend/src/server.js
49535190… backend/src/features/briefing/briefing.service.js
664aee0d… frontend/test/research_compatibility_test.dart
681dd152… frontend/lib/src/features/stock/stock_detail_screen.dart
42231476… frontend/lib/src/features/stock/stock_repository.dart
0cb3629c… frontend/lib/src/features/briefing/briefing_config_repository.dart
2fe70934… frontend/lib/src/features/nexus/management/manage_watchlist_screen.dart
9471d2e5… frontend/lib/src/wear/wear_watchlist_screen.dart
32a84e31… frontend/lib/src/wear/wear_opportunities_screen.dart
2c3711e4… frontend/lib/main.dart                        (unchanged)
1df333ae… frontend/lib/src/features/briefing/briefing_repository.dart (unchanged)
420c557b… frontend/lib/src/features/dashboard/watchlist_provider.dart (unchanged)
```

## Acceptance criteria — one by one

1. **"Current topics/news/opportunity consumers and Wear compile/parse correctly
   without a large chart on watch."** MET at source scope. `stock_repository.dart`
   still emits `StockData` for briefing categories and watchlist tickers; the Wear
   screens (`wear_watchlist_screen.dart`, `wear_opportunities_screen.dart`) consume
   `StockData` via `required List<StockData> stocks` and import NO chart widget
   (grep: no `fl_chart`/`LineChart`/`BarChart` in either file). The C1/C3 test
   scenarios assert `find.byType(LineChart/BarChart/PieChart/ScatterChart) →
   findsNothing`. Dart compilation itself is DEFERRED_TO_DEV_PC (§6).

2. **"No $100/random fallback or silent latest-price/old-analysis overwrite persists
   in new research flow."** MET. Independent source read confirms:
   - `stock_repository.dart` deleted `_extractPrice`/`_extractChange` prose scrapers,
     the `dart:math Random` synthetic-history generator, and the `100.0`/`$100`
     fallbacks. Price/change come only from `item.price`/`item.change` (structured
     fields) and `item.history` (model-reported); otherwise 0.0/empty = "unavailable".
   - `briefing.service.js` deleted `generateHistory` (Math.random) and the
     `enrichWithHistory` call sites; rich `{amount, currency}` price objects are
     guarded by `hasRichPrice` and never clobbered by the numeric legacy enrichment.
   - Grep across touched flows confirms no `Math.random`/`Random()`/`_generateHistory`
     remains; `dart:math` in `stock_detail_screen.dart` is used only for
     `Random.secure()` (idempotency key — stdlib, not synthetic data).
   - `num.clamp()` sites: none in any H15-touched file. The only `.clamp(` hits are
     in non-allowlist files (`price_chart.dart` H13, `dashboard_screen.dart`,
     `wear_rotary_scroll.dart`, `wear_refresh_bottom.dart`, `test/support/chart_probe.dart`)
     — all pre-existing/other-lane, none introduced by H15.

3. **"Only integrator edits shared files; updates to scheduler/export preserve prior
   dirty changes."** MET. H15's modified/created set is exactly the allowlist
   (backend `app.js`/`server.js`/`briefing.service.js`/new test; Flutter
   `stock_repository`/`stock_detail_screen`/`briefing_config_repository`/
   `manage_watchlist_screen`/both Wear screens/new test). `briefing.controller.js`,
   `briefing.routes.js`, `env.js` carry Oct-31 mtimes (prior lanes); `scheduler.js`
   Sep-07 (baseline) — none touched this run. `git status` shows the pre-existing
   dirty baseline preserved; no commit, no reset, no clean.

## Backend source inspection (H10 O3 wiring + CONTRACTS §10 legacy compatibility)

- **`app.js`** — `createApp({...})` factory mounts `/market` (H15A slice preserved,
  1 MiB `jsonLimit`), and mounts `/positions`/`/research` only when a service/router
  is injected, and `/automation/research` only when a composed `automationRouter` is
  injected. Default factory → all three conditional paths 404 (tests A1–A3 assert).
  Error-status forwarding adapter + `errorHandler` preserved.
- **`server.js`** — `buildProductionServices` returns ONE shared `runRepository`
  (H10 review O3: user service + automation identity + bounded worker all share the
  same store — no parallel queue). `composeAutomationSurface` fails closed on any
  missing dependency (model client, input provider, run repository, scoped identity)
  — asserted by tests B2–B4. `require.main === module` guard added so requiring
  `server.js` in tests never boots the server. Automation stays UNMOUNTED in
  production until the operator provisions the model-client identity (CONTRACTS §9).
- **`briefing.service.js`** — DI constructor with injectable seams
  (`briefingModel`/`configModel`/`marketDataProvider`/`listActivePositions`/
  `workflowFetch`). `getEffectiveTickers` = stored config ∪ active-position tickers
  (provider_symbol then symbol, uppercased, deduped). `updateConfig` refuses a stale
  tickers-only PUT that would remove position-backed tickers with `409
  POSITION_TICKER_CONFLICT` + `blocked_removals` (via `reconcileLegacyTickerUpdate`,
  read and confirmed bounded/non-destructive). Hallucination guard now compares
  against the effective set; rich price objects never clobbered; no history
  fabrication. Legacy `getLatest`/`triggerWorkflow` regression-guarded (C6/C7).
- **Wire fidelity (independently traced)** — `error.middleware.js` serializes only
  `{success, error: {message, code}}`; `error.details` is NOT on the wire today. The
  frontend `_throwForResponse` therefore surfaces the typed exception with the
  server `message` verbatim (guaranteed) and parses `error.details.blocked_removals`
  through only when present (forward-compatible). No client-side fabrication.

## Flutter source inspection

- **`briefing_config_repository.dart`** — hand-written (non-generated)
  `PositionTickerConflictException` + `BriefingConfigApiException`; injectable
  `createClient()` transport seam (production returns `http.Client()`; tests subclass
  and inject `MockClient`); all four methods use the seam; `_throwForResponse` maps
  409 `POSITION_TICKER_CONFLICT` → typed exception (message verbatim, blockedRemovals
  parsed when present), everything else → generic API failure with status preserved.
  No silent retry.
- **`manage_watchlist_screen.dart` + `stock_detail_screen.dart`** — removal/star
  paths catch `PositionTickerConflictException` BEFORE the generic catch and surface
  `conflict.message` (with blocked tickers when available); nothing swallowed into
  "Could not update watchlist". `watchlist_provider.dart` `_updateBackend` does NOT
  catch — the typed exception propagates unchanged to the caller (verified: no
  try/catch in `_updateBackend`).
- **`stock_detail_screen.dart` heading** — renders `$price` only when
  `currentPrice > 0`; otherwise `—` + `PRICE UNAVAILABLE` and hides the change badge.
  Change badge also gated on `currentPrice > 0`. No currency symbol invented for
  unavailable values.
- **Wear screens** — `$0.00` replaced by `—` when `currentPrice <= 0`; change badge
  renders only with a price; no chart widget imported anywhere.
- **`frontend/test/research_compatibility_test.dart`** — 15 authored scenarios
  (A1–A5, B1–B5, C1–C5) mirroring the frozen backend suite. Harnesses subclass the
  PUBLIC notifier classes (`BriefingRepository`/`BriefingConfigRepository`/
  `StockRepository`) and override only inputs/build/`createClient`; the real mapping
  and provider chain run. `package:http/testing` `MockClient` (existing dep); no new
  dependency (`pubspec.yaml`/`pubspec.lock` byte-identical — `git diff` empty); no
  hand-authored generated file. Fixtures are hermetic hand-built model objects and
  wire-shape JSON; the only token is the static `'test-token'` fixture.

## Non-blocking findings (correctly flagged by author, NOT in H15 allowlist)

1. **Cross-lane drift — H15B test file won't compile as authored.**
   `frontend/test/research_panel_integration_test.dart:296` declares
   `class _FixtureStockRepository extends _$StockRepository`. `_$StockRepository` is
   the library-private generated part class of `stock_repository.dart` and cannot be
   referenced from `test/`. Independently confirmed real. The file is H15B-owned and
   outside H15's allowlist; the author correctly REPORTED rather than repaired it
   (H15's own test uses the public `StockRepository`). A scoped repair card for the
   H15B lane is warranted; it does not block H15.
2. **`dashboard_screen.dart` (not in allowlist)** may still render `$0.00` for
   unavailable watchlist tickers — carried open from H15B evidence; owner-lane pass
   pending.
3. **H13 `PriceChart`** remains unwired into the detail chart slot (needs an
   instrument-resolved market-history loader) — unchanged, out of H15 scope.
4. **`/automation/research` production activation** remains operator-provisioning
   territory (frozen backend §3.2), per CONTRACTS §9 fail-closed posture.

## Secret / invariant scan

- No secrets, literal credentials, or credential-store reads in any reviewed file
  (grep over all 14 files + the two sanitized rerun logs: clean). The only tokens are
  synthetic fixtures (`test-token`, `Bearer token-owner-a/b` in the backend test).
  `.env` is not read by any H15 deliverable.
- No `ports:`/`expose:` introduced (docker-compose untouched this run); no DNS/tunnel
  changes; no shell backgrounding; no git mutations; no DB/volume deletion; no live
  ops; no new dependency; no renderer replacement (fl_chart retained).

## Deferred criteria (DEFERRED_TO_DEV_PC — never PASS from source inspection)

- Flutter/Dart compile, `flutter analyze`, `flutter test`, `build_runner` codegen,
  widget/parser tests, accessibility, device/web/mobile/Wear execution, APK build —
  all DEFERRED_TO_DEV_PC (toolchain absent on this host). Dev-PC prerequisite:
  `dart run build_runner build --delete-conflicting-outputs` then
  `flutter test test/research_compatibility_test.dart`.
- Runtime/deployment: live MongoDB connection, scheduler execution, live provider
  calls, automation provisioning, DNS/tunnel/Cloudflare changes — not exercised.

## Conclusion

Both halves of H15 are correct, fail-closed, hermetic, and truthful at source scope.
The 15/15 named suite and 249/249 aggregate were independently re-executed with exit 0;
14/14 SHA-256 hashes match author evidence byte-for-byte; the three acceptance
criteria are met by independent source inspection and re-execution. No blocking
defect found. Approve at source-only scope.
