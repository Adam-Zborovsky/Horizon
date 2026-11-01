# H17 test report — hermetic end-to-end integration and failure injection

Status: **AUTHOR DELIVERY — backend suite green; Flutter execution
DEFERRED_TO_DEV_PC.** This report records the observable backend result (real
`node --test` output) and the authored-but-unexecuted Flutter integration
source. No Flutter runtime check is claimed as PASS from source inspection.

Workspace: `/home/ubuntu/apps/Horizon` (dirty main baseline preserved). Node
runtime: `v22.22.2`. Host has **no** Dart/Flutter SDK (`dart --version` /
`flutter --version` → command not found).

## 1. Backend suite — `backend/test/research-end-to-end.test.cjs`

Hermetic: in-memory repositories + scripted model clients, no MongoDB, no
network, no scheduler, no live model calls, no secrets. Fixtures are synthetic
(`2030-01-*` clock, `instrument-h17-main` / `instrument-h17-second`); no
observed market data is invented or claimed.

Command (exact, from repository root):

```text
MONGODB_URI='mongodb://placeholder-url-shaped.invalid/db' \
JWT_SECRET='placeholder-jwt-secret-for-zod-module-load-only' \
node --test backend/test/research-end-to-end.test.cjs
```

Result: **exit 0 — 15/15 pass, 0 fail, 0 skipped.**

```text
# tests 15
# pass 15
# fail 0
# cancelled 0
# skipped 0
# todo 0
```

> CLI note (card-required): use the glob form
> `node --test backend/test/research-end-to-end.test.cjs` (explicit file). The
> trailing-slash directory form (`node --test backend/test/`) fails with
> MODULE_NOT_FOUND on this Node version.

File identity:

```text
9f8e9ae253875e3be14ff853600630290142ea208516ebb1e4b2ca6e1d18bbc8  backend/test/research-end-to-end.test.cjs
```

(72,918 bytes, 1,635 lines.)

### Test inventory (all PASS)

| # | Test | Covers |
|---|------|--------|
| 1 | A1 candidate add produces the full contract wire and rejects duplicates/unknown fields | H01 contract wire; strict parse; duplicate/unknown-field refusal |
| 2 | A2 run queueing honors persisted idempotency and single-active-run semantics | H03/H08 idempotency key; single active run |
| 3 | A3 candidate research journey — automation surface, input binding, publish, honest status | H10 automation surface; input binding; publish; honest run/assessment status |
| 4 | A4 owned transition → economics computed; cost edit → thesis unchanged, P/L recomputed | H07 frozen metrics; H09 economics.status authoritative; thesis continuity across cost edit |
| 5 | B1 chart ranges resolve with truthful resolutions, provenance and OHLC integrity | H13/H05 chart resolutions; provenance; OHLC integrity |
| 6 | B2 unsupported resolutions and unknown instruments degrade truthfully | chart/truthful degradation (no invented candles) |
| 7 | C1 provider failure injection fails the run honestly; last success stays separate | H05/H08 provider failure; last-success vs latest-attempt separation |
| 8 | C2 schema failure injection is bounded at two synthesis attempts | synthesis retry bound (two attempts) |
| 9 | C3 unavailable evidence coverage fails the run before any model call | evidence starvation → fail before model call |
| 10 | C4 partial coverage publishes an explicitly limited assessment with visible gaps | limited assessment; visible coverage gaps |
| 11 | C5 deadline timeout injection stalls a running run and supersedes an expired queue entry | H05 deadline stall; expired queue supersession |
| 12 | C6 restart recovery over the shared persisted store stalls orphans without duplicates | H08 restart recovery; no orphan duplication |
| 13 | C7 concurrent position edit during generation supersedes the in-flight run | H08 concurrent-edit supersession |
| 14 | C8 callback authorization — replay idempotency, source injection and lease binding | H03/H06 callback replay, source (evidence snapshot) injection, lease nonce |
| 15 | D1 every configured instrument gets its own bound run/assessment; coverage gaps visible | multi-instrument ticker coverage (never only one instrument) |

### Aggregate suite

The new suite is additional to the pre-existing 249-test aggregate. Full
aggregate including the new file:

```text
MONGODB_URI='mongodb://placeholder-url-shaped.invalid/db' \
JWT_SECRET='placeholder-jwt-secret-for-zod-module-load-only' \
node --test backend/test/*.test.cjs
→ exit 0 — 264 tests, 264 pass, 0 fail
```

(`249/249` is the PRE-H17 aggregate that excludes this new suite; the
post-H17 aggregate is `264/264`. The live script
`backend/scripts/test-research-workflow.cjs` was NOT run — it is not a
`backend/test/*.test.cjs` file and is outside this card.)

## 2. Flutter integration source (authored, not executed)

`frontend/integration_test/research_journey_test.dart` — device-level
integration test (`integration_test` package) driving the accepted H15B stock
detail flow through the full journey (candidate → queue run → owned → cost
edit → limited → failed/stalled → no-position truth) against a hermetic
scripted MockClient transport. Mirrors the backend A3/A4/C4/C6/C7/D1 stages
at the UI layer; wire fixtures are hand-built from the traced canonical wire
and parsed through the strict H11 models.

Execution is DEFERRED_TO_DEV_PC. Prerequisites on the development PC (full
list in `docs/horizon/DEV_PC_HANDOFF.md`):

```text
dart run build_runner build --delete-conflicting-outputs   # MANDATORY — see §3
flutter test integration_test/research_journey_test.dart
```

## 3. Mandatory generator prerequisite (blocker if skipped)

The H11 position/research generated parts **do not exist on disk** — there is
no `position_models.freezed.dart`, `position_repository.g.dart`,
`research_models.freezed.dart` or `research_repository.g.dart`. The model and
repository files carry `part` directives to them, so **no Flutter analyze,
test, build or APK can succeed until `dart run build_runner build
--delete-conflicting-outputs` is run** (freezed shapes changed in H11/H15B).
Any "Flutter check failed" that occurs before that regeneration is not a
source defect — it is the missing-generator precondition.

## 4. Deferred / not claimed

- All Flutter runtime verification (compile, `flutter analyze`, `flutter
  test`, a11y, device runs, web/mobile/Wear build, APK) is DEFERRED_TO_DEV_PC.
- The `integration_test` package is not yet listed in `pubspec.yaml`
  (out of this card's write allowlist); the Dev-PC handoff lists the one-line
  `integration_test: {sdk: flutter}` dev-dependency addition required before
  the integration test runs.
- No live MongoDB, model, provider or credential was contacted; no secret or
  confidential business data appears in fixtures, logs, or this report.
