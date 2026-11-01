# H15B author evidence — Early position and research panel integration

Scope: continuation delivery (task t_e4e9a1c3) of the H15B Flutter half plus
this evidence file, on top of the controller-verified frozen backend half from
run 251 (parent t_fc55c3a0). Backend files were NOT modified in this run.

## 1. Backend half (frozen, controller-verified — recorded for completeness)

Files (unchanged this run; hashes recomputed from disk):

```text
10438e6f63ae51f2bdc899fa043aec6a75cc90ee08a561ea4d1f70a089b11085  backend/test/research-panel-integration.test.cjs
210364607a977d454ed1a4376ed86395fe7701ab2e6325960c97d8ca4dc0d38b  backend/src/app.js
8a89b59258538def645a6a74a826ed3c6ac3996256e679f6bbfa812c158fe522  backend/src/features/briefing/briefing.service.js
```

Independently rerun this run (not merely quoted):

```text
node --test backend/test/research-panel-integration.test.cjs   → exit 0 (11/11 pass)
node --test backend/test/*.test.cjs                            → exit 0 (234 tests, 234 pass, 0 fail)
```

Raw outputs stored as sanitized logs:
- `docs/horizon/evidence/h15b/named-suite-rerun-cont.log`
- `docs/horizon/evidence/h15b/aggregate-suite-rerun-cont.log`

(Superseded run-251 logs remain alongside: `red-failure.log`,
`named-suite.log`, `aggregate-suite.log`.)

The backend half removes the legacy `Math.random` synthetic history
enrichment from `briefing.service.js` and mounts owner-scoped
`/api/v1/positions` and `/api/v1/research` routes in the accepted H15A
`createApp` pattern, preserving the market history slice, 1 MiB parser and
route-free `/webhook`.

## 2. Flutter half (authored this run; execution DEFERRED_TO_DEV_PC)

### Toolchain status (honest record)

```text
dart --version   → /usr/bin/bash: dart: command not found
flutter --version→ /usr/bin/bash: flutter: command not found
```

No Dart/Flutter SDK on this host (per AMENDMENT-2026-10-30). Therefore:
- The integration test is AUTHORED, not executed. Red/green execution is
  DEFERRED_TO_DEV_PC. No Flutter runtime check is claimed as PASS from
  source inspection.
- `git diff --check` → exit 0 (whitespace-clean, the only check runnable here
  for Dart files).

### Changed/created files

1. **`frontend/test/research_panel_integration_test.dart` (created)** — the
   canonical Flutter integration test (11 testWidgets scenarios). SHA-256:
   `66c6cb5a14d6238f9c7ca365784c9db3c5cbca47973978ba61e13b14b9022dab`

   Contract mapping (scenarios → contract requirements):
   - Integrated journey renders position state, honest economics and the
     grounded panel with the chart slot preserved as truthfully unavailable —
     panels never wait for chart completion (H15B step 2).
   - Candidate economics: candidate badge + "no executed purchase" copy;
     candidate-compatible recommendation actions only (CONTRACTS §2/§5).
   - Owned unknown economics: null cost/quantity render explicit "unknown"
     copy — never zero, never invented (CONTRACTS §2).
   - Editor save wires the REAL `PositionRepository.patchPosition`: PATCH
     body asserted as `{expected_revision: 7, changes: {...}}` containing the
     nested `instrument` object (position.routes.js:60 envelope).
   - Revision conflict: 409 REVISION_CONFLICT surfaces the editor's conflict
     copy; exactly one PATCH (no silent retry).
   - Prior-report changes: `_ContinuityCard` renders from
     `changes_since_previous` (CONTRACTS §6).
   - Limited assessment renders the honest "Limited report" marker (§5).
   - No-result state: `latest_assessment: null`, empty run state →
     "No research report yet" plus explicit "no successful runs"/"no
     attempts" rows; nothing invented (§8).
   - Latest-attempt vs latest-success: prior success still grounds the panel
     while a later failed attempt is reported separately with its error_code
     (§8; never rewrite a success into failure).
   - Queue run: POST carries a non-empty `Idempotency-Key` header; queued run
     is surfaced honestly, no assessment fabricated while pending (§8).
   - Immutable research prices: loading an assessment never overwrites the
     briefing-derived observed price header; the chart slot stays
     "OBSERVED PRICE HISTORY UNAVAILABLE" (no synthetic candles).

   Fixtures are hand-built wire-shape JSON parsed through the strict H11
   models. The mock transport (package:http/testing MockClient, already a
   dependency) records every request; no new dependency; no generated files
   hand-authored. Prerequisite on the dev PC:
   `dart run build_runner build --delete-conflicting-outputs` (H11
   position/research generated providers do not exist before generation),
   then `flutter test test/research_panel_integration_test.dart`.

2. **`frontend/lib/src/features/stock/stock_detail_screen.dart` (modified
   within allowlist)** — SHA-256:
   `d571d4c3eb2b3fcde63be4cf70c8124d193b25dc1f2811897177283c084cb768`

   - New `ResearchWire` adapter + hand-written (non-codegen)
     `researchWireProvider` with injectable `http.Client`/token provider.
   - New `_PositionResearchSection` (ConsumerStatefulWidget) inserted after
     `_OpportunityScoutStats`, keeping the existing theme (AppTheme
     goldAmber/obsidian palette, GlassCard, identical section typography).
   - Position matching by `instrument.symbol` (non-archived); H12
     `PositionStateBadge` + `PositionEconomicsLine`; `PositionEditor.edit`
     opened in a bottom sheet with `onSave` wired to the real
     `PositionRepository.patchPosition` (editor builds
     `{expected_revision, changes}` itself from `initial.revision` and
     surfaces 409 REVISION_CONFLICT internally — no silent retries).
   - H14 `ResearchPanel` (which embeds the H14 OutlookPanel) fed by the
     unwrapped latest state; queued/running run surfaced via the panel's
     honest no-assessment view.
   - Truthful run-state rows: "Last successful report: <status> · finished
     <ts>" and "Latest attempt: <status> · stage <stage>" + "Error: <code>"
     rendered separately (CONTRACTS §8 last-attempt vs last-success).
   - "RUN RESEARCH" queues a manual run with a locally generated idempotency
     key `manual-<utc-millis>-<8 random hex bytes>` (Random.secure, dart:math
     stdlib only — no new dependency, no secret material).
   - No-tracked-position state renders honest copy; NO create-mode editor is
     offered from a bare ticker because a PositionInstrument requires a
     vetted provider-resolved identity (CONTRACTS §1) and the accepted API
     surface exposes no instrument-resolution endpoint — inventing
     `instrument_id` from a ticker is contract drift.
   - `num.clamp()` is not used anywhere in this file (standing Dart lesson:
     clamp returns num, never passed to int/double params).

3. **`frontend/lib/src/features/stock/stock_repository.dart` (modified,
   carried from run 251, within allowlist)** — SHA-256:
   `b5ebe28fc7fff9054fc983e16f29d388d8ea689eb5f17c8e8bb35ea65c0aaee3`.
   Synthetic history fallback removed: only a model-reported history is
   carried; watchlist tickers without briefing data get price 0.0 / empty
   history meaning "unavailable", rendered truthfully downstream.

4. **Reviewed, no edit required (allowlisted, unchanged)**:
   `frontend/lib/src/features/briefing/briefing_repository.dart` (coerces
   model-reported history only, no fabrication),
   `briefing_config_repository.dart`, `dashboard/watchlist_provider.dart`
   (derives state from config; no synthetic fallback), and
   `nexus/management/manage_watchlist_screen.dart` (no price/history
   fabrication present). Verified by source inspection this run; no change
   needed, so none was made.

### Wire reconciliation (parent-card constraints, traced — never assumed)

- **Run wire retains `owner_id_internal`.** `toPublicRunView`
  (research.routes.js:35) deletes only `lease_nonce`; H11
  `ResearchRun.fromJson` REQUIRES `owner_id_internal`. The queue-run parse
  `ResearchRun.fromJson(decoded['run'])` therefore reconciles with the real
  wire. No backend change needed.
- **Latest wire nests the assessment object under `latest_assessment`**
  (research.routes.js:61-80: `{position_id, latest_assessment, run_state:
  {last_success, latest_attempt}}`; `toPublicAssessmentView` strips
  `owner_id_internal`). The unwrap happens in `ResearchWire.latestState` in
  MY file (stock_detail_screen.dart). Run state arrives as narrow owner-safe
  projections, NOT full run objects — they are rendered as dedicated truthful
  rows rather than reassembled into a `ResearchRun` that would invent fields.

### Cross-lane drift REPORTED (not repaired — read-only files, owner H11)

`frontend/lib/src/features/research/research_repository.dart` (H11, accepted,
read-only for this lane) does not match the real wire in two places:
- `getLatest` parses the body with H11 `ResearchLatest.fromJson`, which
  expects `{assessment, run}`; the real wire is `{position_id,
  latest_assessment, run_state}` — parsed it would silently yield
  `assessment: null, run: null`.
- `getRun`/`queueRun` pass the whole response envelope to
  `ResearchRun.fromJson` instead of the nested `run` member
  (research.routes.js answers `{run: ...}`), which would throw
  `ContractFormatException` on `requireOpaqueId(json, 'id')`.
Both are avoided by the `ResearchWire` adapter in my file; a scoped H11
repair card should reconcile the repository itself.

## 3. Commands and exits (this run)

```text
node --test backend/test/research-panel-integration.test.cjs  → exit 0, 11/11
node --test backend/test/*.test.cjs                           → exit 0, 234/234
git diff --check                                              → exit 0
dart --version                                                → command not found (recorded, not claimed)
sha256sum (7 files)                                           → recorded above
```

## 4. Limits and deferred items

- Flutter runtime verification (compile, `flutter test`, analyzer, a11y,
  device) is DEFERRED_TO_DEV_PC — the test file and wiring are authored,
  never executed here, and no PASS is claimed from source inspection.
- H13 `PriceChart`/`ChartController` is NOT swapped into the stock detail
  chart slot this run: the slot is preserved with the run-251 truthful
  unavailable state (and model-reported briefing history when present), and
  the panels explicitly do not wait for the chart. Wiring `PriceChart` needs
  an instrument-resolved market-history loader per position — remaining work,
  listed for the next slice rather than half-done.
- Evidence detail: `GET /research/evidence/:id` is not part of the mounted
  route surface (research.routes.js mounts latest/assessments/runs only), so
  `onOpenEvidence`/`onViewSnapshot` are left null — evidence chips render as
  plain text instead of dead affordances.
- Create-mode `PositionEditor.create` is intentionally not wired (no vetted
  instrument resolver in the accepted surface; see §2 file 2).
- `stock_repository` price-0.0 semantics ripple: `dashboard_screen.dart`
  (not in this allowlist) may render $0.00 for watchlist tickers without
  briefing prices until a truthful-unavailable pass reaches it (flagged by
  run 251, still open).
- Backend routes are exercised only by the hermetic backend suite; no live
  MongoDB, model or provider was contacted; no secrets read or emitted.
