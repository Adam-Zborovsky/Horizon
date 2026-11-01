# H15B — Combined independent specification and quality review

Reviewer: reviewer / deepseek-v4-pro (vendor-disjoint from author worker/gemini-3.8-flash / zai).
Reviewed package: H15B Early position and research panel integration (both halves — frozen
backend + Flutter continuation t_e4e9a1c3). Source-only scope; runtime criteria
DEFERRED_TO_DEV_PC.

## Verdicts

- **SPEC_PASS_SOURCE_ONLY**
- **QUALITY_PASS_SOURCE_ONLY**

Both halves independently verified. No blocking defects found.

## Independent verification performed (this review run)

### 1. SHA-256 hashes — 7/7 match author-recorded values exactly

```text
10438e6f63ae51f2bdc899fa043aec6a75cc90ee08a561ea4d1f70a089b11085  backend/test/research-panel-integration.test.cjs
210364607a977d454ed1a4376ed86395fe7701ab2e6325960c97d8ca4dc0d38b  backend/src/app.js
8a89b59258538def645a6a74a826ed3c6ac3996256e679f6bbfa812c158fe522  backend/src/features/briefing/briefing.service.js
66c6cb5a14d6238f9c7ca365784c9db3c5cbca47973978ba61e13b14b9022dab  frontend/test/research_panel_integration_test.dart
d571d4c3eb2b3fcde63be4cf70c8124d193b25dc1f2811897177283c084cb768  frontend/lib/src/features/stock/stock_detail_screen.dart
b5ebe28fc7fff9054fc983e16f29d388d8ea689eb5f17c8e8bb35ea65c0aaee3  frontend/lib/src/features/stock/stock_repository.dart
b1323fb57fe67dbeffde7068d2c937982c1b7c9fcf34c0243aee5e4c82c7a5c1  docs/horizon/evidence/h15b-author.md
```

### 2. Backend tests — independently rerun (not quoted)

```text
node --test backend/test/research-panel-integration.test.cjs  -> 11/11 pass, exit 0
node --test backend/test/*.test.cjs                            -> 234/234 pass, 0 fail, exit 0
git diff --check                                               -> clean, exit 0
```

Node v22.22.2 (matches SPEC §7 supported runtime).

### 3. Backend source — route mounting and synthetic-history removal

- `backend/src/app.js` refactored to a `createApp({...})` factory. Positions and
  research routers are mounted only when a `positionService`/`researchService`
  (or a router) is injected; the default factory leaves `/api/v1/positions` and
  `/api/v1/research` unmounted (404), preserving the H15A contract. The market
  route (H15A protected observed-history slice), the 1 MiB transport parser
  (`jsonLimit = '1mb'`), route-free `/webhook`, and `/health` are all preserved.
  `createApp` is exported both as a property and top-level, so `server.js`'s
  `require('./app')` still works unchanged. Production service injection into
  `server.js` is H15's scope (server.js is in H15's existing_files, not H15B's).
- `backend/src/features/briefing/briefing.service.js` — the `Math.random`
  synthetic history enrichment (`enrichWithHistory` + `generateHistory`) is
  fully removed from both `compileMarketData` and the save path. Only
  model-reported history is carried. No synthetic fallback remains.
- `backend/src/features/positions/position.routes.js` and
  `backend/src/features/research/research.routes.js` — read and confirmed
  owner-scoped; owner derived server-side from JWT, never client-supplied.

### 4. Wire reconciliation — traced against source (not assumed)

- `toPublicRunView` (research.routes.js) deletes only `lease_nonce`; it
  **retains** `owner_id_internal`. The H11 `ResearchRun.fromJson` requires
  `owner_id_internal` (research_models.dart:1311), so `ResearchRun.fromJson(
  decoded['run'])` reconciles with the real run wire. Confirmed the backend
  `queueRun` response and the integration test both assert
  `owner_id_internal` present and `lease_nonce` absent.
- `getPositionResearchState` (research.service.js:803-833) returns
  `{position_id, latest_assessment, run_state:{last_success, latest_attempt}}`
  where `last_success`/`latest_attempt` are narrow owner-safe projections, not
  full run objects. `toPublicAssessmentView` strips `owner_id_internal` from the
  assessment. The Flutter `ResearchWire.latestState` unwraps exactly this shape,
  and `_runStateRows` renders last-success and latest-attempt as separate
  truthful rows (CONTRACTS §8) — an existing success is never rewritten by a
  later failure.
- Backend test asserts all of the above against real HTTP responses: run wire
  retains owner_id_internal + no lease_nonce; assessment view strips
  owner_id_internal; latest-attempt-vs-last-success separation; limited counts
  as last_success; queued 202 + idempotent replay + 409 on conflicting payload
  + 400 MISSING_IDEMPOTENCY_KEY; revision conflict 409 REVISION_CONFLICT leaves
  state unchanged; prior-report changes supersede stale runs without mutating
  prior assessments; owner B gets indistinguishable denial (404 patch, empty
  list, all-null research state); market/research snapshot stores isolated.

### 5. Flutter source — wiring, adapter, fallback removal

- `frontend/lib/src/features/stock/stock_detail_screen.dart` adds:
  - `ResearchWire` adapter (latestState/queueRun) with correct envelope
    unwrapping (`decoded['latest_assessment']`, `decoded['run']`) and
    `Idempotency-Key` header emission; injectable http.Client + token provider.
  - Hand-written `researchWireProvider` (no codegen — this is a shared screen
    file, not a generated-part owner).
  - `_PositionResearchSection` inserted after `_OpportunityScoutStats`, keeping
    the existing theme. Position matched by `instrument.symbol` (non-archived).
    H12 `PositionEditor.edit` wired with `onSave: (write) =>
    repository.patchPosition(position.id, write)` — the REAL
    `PositionRepository` (editor builds `{expected_revision, changes}` itself
    and surfaces 409 internally, no silent retry). H14 `ResearchPanel` fed by
    the unwrapped latest state. `RUN RESEARCH` queues with a locally generated
    idempotency key (Random.secure, dart:math stdlib only).
  - Chart slot preserved with truthful "OBSERVED PRICE HISTORY UNAVAILABLE"
    when no bars; panels render independently of the chart. No-tracked-position
    state renders honest copy; no create-mode editor from a bare ticker (no
    vetted instrument resolver — correctly refusing to invent instrument_id).
  - **Zero `num.clamp()` sites** (grep confirmed) — standing Dart lesson honored.
- `frontend/lib/src/features/stock/stock_repository.dart` — synthetic history
  fallback (`_generateHistory`, `Random`, `isMarketClosed`) removed; watchlist
  tickers without briefing data carry price 0.0 / empty history meaning
  "unavailable", rendered truthfully downstream.
- No `Math.random`/`_generateHistory`/`Random()` remains in any touched flow
  (stock_repository, briefing_repository, briefing_config_repository,
  watchlist_provider, manage_watchlist_screen — grep confirmed).
- `frontend/test/research_panel_integration_test.dart` — 11 `testWidgets`
  scenarios mapping to the contract: integrated journey + truthful chart slot;
  candidate economics; owned-unknown economics (never zero, never invented);
  editor save emits `{expected_revision:7, changes:{instrument:...}}` via the
  real repository; revision conflict surfaces conflict copy with exactly one
  PATCH (no retry); limited marker; no-result honest empty panel; latest-attempt
  vs last-success separation; queue sends non-empty Idempotency-Key; immutable
  research prices never overwrite the observed price header. Fixtures are
  hand-built wire-shape JSON parsed through the strict H11 models; MockClient
  (package:http/testing, already a dependency) records every request. No new
  dependency; no generated files hand-authored.

### 6. Secret and invariant scan

No secrets, literal credentials, or credential-store reads in the reviewed
files (grep confirmed). `authorization: \`Bearer ${token}\`` in the backend
test is a template literal over fixture tokens — verified via `od -c` that the
`***` shown in tool display is a redaction artifact of the word "Bearer", not
corrupted source. No ports/DNS/tunnel changes, no shell backgrounding, no DB
deletion, no live ops. Fixtures use explicit synthetic values and never claim
to be observed data.

## Deferred / non-blocking items (all correctly marked, none claimed PASS)

1. **Flutter runtime** — compile, `flutter analyze`, `flutter test`, a11y, device,
   `flutter build web --release`, APK: DEFERRED_TO_DEV_PC. Toolchain absent on
   this host (`dart`/`flutter` → command not found). Author did not claim PASS
   from source inspection. Prerequisite on the PC:
   `dart run build_runner build --delete-conflicting-outputs` then
   `flutter test test/research_panel_integration_test.dart`.
2. **H13 PriceChart** not swapped into the chart slot this run — slot preserved
   truthful-unavailable; listed as exact remainder. (In H15 scope.)
3. **Cross-lane H11 drift** — `frontend/lib/src/features/research/
   research_repository.dart` `getLatest` expects `{assessment, run}` (real wire
   `{position_id, latest_assessment, run_state}`) and `getRun`/`queueRun` feed
   the whole envelope to `ResearchRun.fromJson` (real wire `{run: ...}`). I
   independently read that file and confirm both mismatches are real. The
   author correctly did NOT repair it (H11-owned, out of H15B allowlist) and
   avoided it via the `ResearchWire` adapter. A scoped H11 repair card
   (t_fa26099c) is already in flight per the controller note — not this lane's
   responsibility, and not a blocker for H15B since the adapter is internally
   correct.
4. Production `server.js` injection of real position/research services into
   `createApp` is H15's step, not H15B's.
5. `dashboard_screen.dart` price-0.0 ripple (outside H15B allowlist) — flagged,
   still open for the truthful-unavailable pass.

## Acceptance criteria vs evidence

| Criterion | Verdict |
|---|---|
| Integrated source journey connects positions + grounded research panels without waiting for chart completion | Met at source scope (chart slot independent; runtime DEFERRED_TO_DEV_PC) |
| Owner isolation, snapshot consistency, truthful unavailable states verified in executable backend integration tests | Met — 11/11 independently rerun, exercises real app.js routing |
| H15 receives shared-file diff/interface handoff; generated outputs PC-only | Met — durable evidence + hashes + DEFERRED_TO_DEV_PC discipline |
