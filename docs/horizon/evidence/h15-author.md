# H15 author evidence — application integration and legacy/mobile/Wear
# compatibility (both halves)

Status: **AUTHOR DELIVERY ONLY — both halves delivered, neither independently
accepted.** The backend half was controller-verified and FROZEN on t_a8e17276
(09:25 UTC); this run (t_1812d30d) delivered the Flutter half on top of it
without touching any backend file. The combined specification/quality review
(t_40620e92, reviewer deepseek, vendor-disjoint from the zai author) gates on
this card. All Dart/Flutter execution is DEFERRED_TO_DEV_PC — authored source
and tests only, no Flutter-runtime claim anywhere in this file.

Workspace: `/home/ubuntu/apps/Horizon` (dirty main baseline preserved; no
branch change, no commit/push, no cleanup). Node runtime: v22.22.2.
Dart/Flutter SDK on this host: **absent** (`dart --version` / `flutter
--version` → command not found).

## 1. Backend half (FROZEN — recorded, unchanged this run)

Created:

```text
538bea5e63a61860472f45d34e8074d920aa1dc3ba6effa86b91f120650d3825  backend/test/research-compatibility.test.cjs
```

Modified (frozen deltas from t_a8e17276, byte-identical this run):

```text
5f35d2ed63c2e4b0a3fb4cb73ae7b1966ce080b2268aef3b312f70afb1e0f567  backend/src/app.js
9716e015122205c24f7afa9f5429c75d4c4e01dfd5b77f26b7d2f941f240711c  backend/src/server.js
49535190bc048b1958888d45df87cad4647aa1382cf0b2222d98b1c260495ae8  backend/src/features/briefing/briefing.service.js
```

Backend contract summary (full detail in the run-251 version of this file and
the frozen suite logs): automation surface mounted at
`${API_PREFIX}/automation/research` only when injected (default app keeps the
route unmounted, 404); fail-closed `composeAutomationSurface()` production
composition sharing ONE `runRepository` between the research service, the
scoped automation identity and the bounded run worker (H10 review O3); legacy
briefing compatibility per CONTRACTS §10 / SPEC §5 — DI constructor with
today's defaults, `getEffectiveTickers` (stored ∪ active-position tickers),
stale tickers-only PUT refused `409 POSITION_TICKER_CONFLICT` with
`blocked_removals` (bounded/explicit, never destructive replacement), save()
hallucination guard against the effective set, rich `{amount, currency}` price
objects never clobbered, no `history` fabrication, legacy `getLatest` parse
regression-guarded.

Backend re-verification THIS run (not merely quoted — both suites rerun from
the repo root):

```text
node --test backend/test/research-compatibility.test.cjs   → exit 0 (15/15 pass)
node --test backend/test/*.test.cjs                        → exit 0 (249/249 pass, 0 fail)
git diff --check                                           → exit 0 (whitespace clean)
```

Raw sanitized logs:

- `docs/horizon/evidence/h15/compatibility-suite-rerun-cont.log` (new)
- `docs/horizon/evidence/h15/aggregate-suite-rerun-cont.log` (new)
- frozen-run logs preserved alongside: `compatibility-suite.log`,
  `aggregate-suite.log`

## 2. Flutter half (delivered this run; execution DEFERRED_TO_DEV_PC)

### 2.1 Toolchain status (honest record)

```text
dart --version    → /usr/bin/bash: dart: command not found
flutter --version → /usr/bin/bash: flutter: command not found
```

No Dart/Flutter SDK on this host (per AMENDMENT-2026-10-30). Therefore the
compatibility test and the screen work below are AUTHORED, never executed: no
`flutter test`, no `flutter analyze`, no compile, no device run is claimed.
Static source checks performed here: balance check (braces/parens/brackets)
over all seven edited files, symbol-reference greps against the existing
generated `.g.dart` files, and `git diff --check` (exit 0).

### 2.2 Changed/created files (SHA-256 computed this run)

Created:

```text
664aee0d26fc9d1d4008fdff9e17f23739561757ff81aa20185d1a090da20c26  frontend/test/research_compatibility_test.dart
```

Modified (within the H15 Flutter allowlist):

```text
681dd152887e8f5a838cfc67c37808a54c3a03817d21dd58a794709b902b972b  frontend/lib/src/features/stock/stock_detail_screen.dart
42231476ff810cd2ff55fe897d0c91869dcd7af439363c1b5a89d6adfcc228ec  frontend/lib/src/features/stock/stock_repository.dart
0cb3629cb558941f5a07723d949623fbc6e48cc77ed0b5cf8eadf12cd11ec75d  frontend/lib/src/features/briefing/briefing_config_repository.dart
2fe70934f0b8818a3f6be9c3807e45869b71b60fda77012af30b831588ddfce6  frontend/lib/src/features/nexus/management/manage_watchlist_screen.dart
9471d2e5a4fa6a7e8581e67b9f08c6c24835eac909dc5b70497b89a708123677  frontend/lib/src/wear/wear_watchlist_screen.dart
32a84e314a3380032981e49487c644229ddbef48fcafcb19e9b942e811a9adba  frontend/lib/src/wear/wear_opportunities_screen.dart
```

Allowlisted, reviewed, unchanged (no change needed):

```text
2c3711e4cec167e9bc2eada324d3c42dcecbb5a8f6096045562d67be725d8205  frontend/lib/main.dart
1df333ae262d5a91790395d2cc53a2807af5a766636052acba8b04d2e26545c3  frontend/lib/src/features/briefing/briefing_repository.dart
420c557b722bc1dbbd50de17ff9fc2fb5a37dd1f9ef62b0eed4c58604223af0c  frontend/lib/src/features/dashboard/watchlist_provider.dart
```

main.dart: router/auth/provider composition is platform-agnostic (mobile/web
through one GoRouter; Wear through `lib/main_wear.dart` with its own entry) —
no edit required. briefing_repository.dart: coerces model-reported history
only, no fabrication (accepted H15B inspection stands). watchlist_provider.dart:
derives state from the config provider, propagates the typed conflict from the
config repository unchanged (the swallowing would have defeated the surface,
so none was added).

`pubspec.yaml`/`pubspec.lock`: untouched — no new dependency.

### 2.3 What was implemented (contract mapping)

#### `stock_repository.dart` — prose price extraction removed (H15 acceptance)

- Deleted `_extractPrice`/`_extractChange` regex scrapers and the fallback
  chains over `potentialPriceAction`/`explanation`/`takeaway`/`analysis`.
  Authoritative prices now come ONLY from structured model-reported fields:
  `item.price`, `item.change` (parsed string fields) and `item.history`
  (`history.last` as the last-resort model-reported price). Anything else is
  0.0 / empty = "unavailable", rendered truthfully downstream. This is the
  client-side twin of the frozen backend's synthetic-fallback removal.
- Sentiment string mapping (`"Bullish"` → 0.7) deliberately retained: it maps
  an opinion to an opinion scale; no market fact (price/history) is derived
  from prose (covered by A5).

#### `briefing_config_repository.dart` — typed bounded refusal (CONTRACTS §10)

- New hand-written (non-generated) `PositionTickerConflictException` and
  `BriefingConfigApiException`.
- Transport seam `createClient()` (accepted H15B `ResearchWire` pattern):
  production returns the default `http.Client()`; tests subclass and inject a
  MockClient. All four methods (`getConfig`, `updateConfig`, `toggleTopic`,
  `removeTopic`) now use the seam.
- Error mapping `_throwForResponse()`: 409 + `POSITION_TICKER_CONFLICT`
  surfaces the typed exception with the server message VERBATIM and
  `error.details.blocked_removals` parsed through when present; every other
  non-2xx becomes `BriefingConfigApiException(statusCode, message)`. Nothing
  is retried silently; malformed error bodies fall back to the generic
  message and never fabricate conflict details client-side.
- Wire fidelity note: the backend error middleware serializes only
  `{success, error: {message, code}}` — `error.details` is NOT on the wire
  today, so the exception's `blockedRemovals` is populated from `details` only
  if the backend later exposes it; the `message` is the guaranteed bounded
  copy. (Backend files are frozen; extending the wire is backend-owner
  territory and was not touched.)

#### `manage_watchlist_screen.dart` + `stock_detail_screen.dart` — watchlist/star behavior

- `manage_watchlist_screen`: removal goes through
  `_removeWithConflictHandling()` — `PositionTickerConflictException` shows
  the server's refusal copy (plus blocked tickers when available) in a
  SnackBar; other errors keep the existing generic copy. Design preserved.
- `stock_detail_screen` `_DetailHeader` star button: the typed conflict is
  caught BEFORE the generic catch and surfaces `conflict.message`
  (bounded/explicit, never swallowed into "Could not update watchlist").

#### `stock_detail_screen.dart` — truthful heading price (currency-aware summaries)

- The heading renders the structured price only when `currentPrice > 0`;
  otherwise it renders `—` with an explicit `PRICE UNAVAILABLE` caption and
  hides the change badge — the "$0.00 fabrication" for watchlist tickers
  without data is gone at the screen level. Currency truthfulness: no currency
  symbol is invented for unavailable values; the available path keeps the
  existing `$` formatting (the briefing item wire carries no currency field —
  adding one would require freezed codegen, which is dev-PC territory, see
  §2.5).

#### Wear screens — no chart on watch, truthful prices

- `wear_watchlist_screen.dart` and `wear_opportunities_screen.dart`: the
  fabricated `$0.00` is replaced by an explicit `—` when the price is
  unavailable; the change badge renders only with a price. No chart widget is
  imported or composed on any Wear surface (SPEC: "do not embed a full WebView
  chart on Wear"); both keep the existing glass/rotary design.

#### `frontend/test/research_compatibility_test.dart` — the canonical test

15 authored scenarios in three groups mirroring the frozen backend suite:

- **A-series (repository mapping, real provider, substituted inputs):**
  A1 prose mentioning $100/+2.5% never becomes a rendered quote (regression
  on the eliminated defect class); A2 structured `price`/`change` parse as-is;
  A3 model-reported history carried, `history.last` as price fallback;
  A4 watchlist tickers without briefing data stay unavailable; A5 sentiment
  is opinion-scale only, structured score wins.
- **B-series (legacy tickers-only writes):** B1 409
  `POSITION_TICKER_CONFLICT` → typed exception, server message verbatim,
  `blocked_removals` parsed, exactly one PUT, no retry, state not overwritten;
  B2 200 update lands with the server config, exactly one PUT; B3 non-conflict
  failures keep status and stay a distinct type; B4 `watchlist.remove()`
  surfaces the refusal through the real provider chain, PUT carries the full
  structured array, in-memory state untouched; B5 `watchlist.add()` sends the
  complete uppercased array (old-client compatible shape).
- **C-series (Wear/detail rendering):** C1 Wear watchlist renders quotes with
  NO fl_chart widget anywhere in the tree; C2 unavailable quote renders `—`,
  never `$0.00`; C3 Wear opportunities parse direction badge/analysis, no
  chart; C4 detail heading renders the structured price when available;
  C5 detail heading renders `PRICE UNAVAILABLE`, never `$0.00`.

Test infrastructure honesty: the A/B harnesses subclass the PUBLIC notifier
classes (`BriefingRepository`, `BriefingConfigRepository`, `StockRepository`)
and override only inputs/build — the real mapping and provider chain run.
`package:http/testing` MockClient is an existing dependency; no new
dependency; no hand-authored generated file. AutoDispose keep-alive via
explicit `container.listen` in the harnesses.

Dev-PC execution prerequisite (unchanged from H15B):

```text
dart run build_runner build --delete-conflicting-outputs
flutter test test/research_compatibility_test.dart
```

### 2.4 Cross-lane drift REPORTED (not repaired — file owned by H15B delivery)

`frontend/test/research_panel_integration_test.dart` (accepted H15B delivery,
NOT in this card's allowlist) defines `_FixtureStockRepository extends
_$StockRepository` (line ~296). `_$StockRepository` is library-private
(generated part file of `stock_repository.dart`) and CANNOT be referenced from
`test/` — that file will not compile as authored. This run's test uses the
public classes instead. The fix is mechanical (extend `StockRepository`), but
the file is outside this card's allowlist, so it is reported, not touched.

### 2.5 Remaining limits (explicit, not claimed)

- **All Dart execution DEFERRED_TO_DEV_PC**: compile, `flutter test`, analyzer,
  a11y, device runs — none performed here, none claimed. The 15 scenarios are
  authored expectations, not observed passes.
- **No freezed model change**: adding a `currency` field to `BriefingItem`/
  `StockData` (for fully currency-aware formatting of available prices) would
  require codegen; out of scope here by the no-generated-files constraint. The
  delivered truthfulness boundary is: no currency symbol is rendered for
  unavailable values; available prices keep the existing `$` format until the
  briefing wire carries currency.
- **dashboard_screen.dart** (not in this allowlist) may still render `$0.00`
  for unavailable watchlist tickers — carried from the H15B evidence, still
  open, flagged for the owner lane.
- **H13 PriceChart into the detail chart slot** remains unwired (per H15B
  evidence: needs an instrument-resolved market-history loader) — unchanged.
- Backend `/automation/research` production activation remains
  operator-provisioning territory (frozen backend §3.2).

## 3. Commands and exits (this run)

```text
node --test backend/test/research-compatibility.test.cjs  → exit 0, 15/15 (frozen backend, rerun)
node --test backend/test/*.test.cjs                       → exit 0, 249/249 (frozen backend, rerun)
git diff --check                                          → exit 0
dart --version / flutter --version                        → command not found (recorded, not claimed)
sha256sum (13 files)                                      → recorded above
```

## 4. Contract adherence

- Secrets: none in output, logs, fixtures or this file; no `.env` or
  credential-store reads. The only token in tests is the static fixture
  string `'test-token'`; log sanitization verified (no `Bearer`/JWT material
  in either rerun log).
- Backend files: zero modifications this run (hashes byte-identical to the
  frozen values in §1).
- No ports/DNS/tunnel changes; no backgrounding; no git mutations; no
  production operations; no nested delegation; no worker-created cards; no
  new dependency; no hand-authored generated files; no `num.clamp()` usage
  introduced (standing Dart lesson).
