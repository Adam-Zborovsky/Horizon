# H11 — Author delivery evidence

Author: worker/gpt-5.6-terra. Date: 2026-10-31. Workspace: /home/ubuntu/apps/Horizon (dirty main baseline preserved; no branch change, no commit/push, no cleanup).

## What was delivered

Seven new files, exactly the H11 canonical package `new_files`; no other source file touched.

| File | Lines | SHA-256 |
|---|---|---|
| `frontend/lib/src/features/positions/position_models.dart` | 536 | `7fa8cde59fdaffc97ecf9bf4390e7cd8ab3e4b274910bad7795ed2d7543471f9` |
| `frontend/lib/src/features/positions/position_repository.dart` | 163 | `546bb5d8d2e6fdc3cf7d812e245acfbf916f8827cd4af55698dee727c56e8e8b` |
| `frontend/lib/src/features/market/market_models.dart` | 363 | `64f1d79466174a51779059b64c0afcb62e1f7b7ebaf222847c00ec559645602a` |
| `frontend/lib/src/features/market/market_repository.dart` | 92 | `63ada6860ca5ea94ba7ec7f1163b87b560a117f755eee44596e8712fceed2d56` |
| `frontend/lib/src/features/research/research_models.dart` | 1490 | `bd80c790d2131d627b3aa5702944d69dfa9d6606184fb98ad689db4ff9ce845e` |
| `frontend/lib/src/features/research/research_repository.dart` | 143 | `fb2e507bf6dfd79ce22d5be3b5cf01219c1aacdd4dd2fe61d8258c6a4786c93c` |
| `frontend/test/research_models_test.dart` | 1039 | `202caff4bdaebe2f2c78d72bc4510561dd74b120ac691132bd3393d5ce71dbbe` |

All work is uncommitted, consistent with the dirty-main baseline policy. Baseline HEAD remains `9fbb26b5519889e0816720530dd60c204dda2bf2`.

## Commands run (actual output)

- `git -C /home/ubuntu/apps/Horizon rev-parse HEAD` → `9fbb26b5519889e0816720530dd60c204dda2bf2` (unchanged).
- `flutter test test/research_models_test.dart` → `bash: flutter: command not found`, exit **127**.
- `dart analyze lib/src/features test/research_models_test.dart` → `bash: dart: command not found`, exit **127**.
- Structural sanity check (Python delimiter balance outside strings/comments, import-order check, trailing-whitespace scan) on all seven files → all balanced, no import-order violations, no trailing whitespace. This is a partial check, not a Dart analysis pass.
- `sha256sum` over all seven files → hashes above.
- `git status --short` → only the pre-existing dirty baseline plus the seven new untracked H11 paths (`frontend/lib/src/features/{positions,market,research}/`, `frontend/test/research_models_test.dart`).

**No Dart/Flutter execution claim is made.** Flutter analysis, generation, and test execution are DEFERRED_TO_DEV_PC per the authorized server/PC split. The tests were authored first (TDD red step) and are expected to run green on the PC after generation; that run has not happened and is not claimed.

## Conventions traced before implementation (per H11 step 1)

- Token storage/lookup: `AuthRepository` (SharedPreferences, `auth_token` key) — `frontend/lib/src/features/auth/auth_repository.dart`.
- Request style: per-repository `package:http` calls, `Authorization: Bearer <token>` attached only when a token exists — as in `briefing_config_repository.dart`.
- Provider wiring: plain repository class + `@riverpod` factory function with `Ref` — as in `auth_repository.dart`.
- Base URL: imported `ApiConfig.baseUrl` (shared `api_config.dart` is not edited by this lane).
- Error envelope: `{success, error: {message, code}}` — `backend/src/middleware/error.middleware.js`; market request errors carry machine-readable codes (`market.service.js` `requestError`).
- No new `api_client.dart` was invented; no new dependency was added.

## Contract mapping (source of truth: docs/horizon/CONTRACTS.md, backend/src/features/research/contracts.js)

| Contract element | Where implemented |
|---|---|
| §1 decimal-string money, ISO currency, opaque IDs, bounded text, UTC timestamps, session dates, contract version 1 | `position_models.dart` shared primitives (`MoneyAmount`, `require*`/`optional*` validators, `horizonContractVersion`); explicit calendar day-count validation mirroring backend `isValidDateParts` |
| §1 additive response-field forward compatibility; write/reply boundary | Parsers ignore unknown keys; `PositionWrite.toJson()` emits only known keys, no owner identity |
| §2 Position incl. candidate economics guard, legacy_unclassified null economics, horizon default 3, revision | `Position.fromJson` cross-field validation; `PositionWrite` |
| §3 MarketBar OHLC invariants, null-vs-zero volume, adjusted_close nullable | `MarketBar.fromJson` |
| §3 HistoryResponse: unavailable ⇒ empty bars + machine reason; stale cannot claim realtime; ascending/unique bars; range/resolution enums; max 5000 bars | `HistoryResponse.fromJson` |
| §4 EvidenceItem/EvidenceFact/ReportingPeriod, claim reference uniqueness | `research_models.dart` (`EvidenceItem`, `EvidenceFact`, `ReportingPeriod`, `Claim`) |
| §5 ResearchAssessment: outlook triple {1,2,3}, month-end clamping (`calendarTargetDate` mirror incl. year-10000 rejection), state/action compatibility, position-context identity, legacy revision requirement | `ResearchAssessment.fromJson`, `calendarTargetDate` |
| §5/§7 NumericProjection: bound ordering, ≥1 bound, conditional_scenario ⇒ assumptions, calibrated_forecast ⇒ calibration evidence, validity ≥ anchor | `NumericProjection.fromJson`, `CalibrationEvidence.fromJson` |
| §6 Checkpoint kind/exclusive-field rules, update ≥ creation | `Checkpoint.fromJson` |
| §8 ResearchRun status invariants (queued/running/terminal/succeeded-limited/failed-stalled/superseded), retry ≤ 2 | `ResearchRun.fromJson` |
| §9 endpoints: GET/POST/PATCH /positions, GET /market/instruments/:id/history, GET /research/positions/:id/latest, GET /research/positions/:id/assessments, POST /research/positions/:id/runs (+`Idempotency-Key`), GET /research/runs/:runId, GET /research/evidence/:id | `position_repository.dart`, `market_repository.dart`, `research_repository.dart` |

## Key authoring decisions

1. **Hand-written validating parsers, no json_serializable for domain models.** Freezed value classes + explicit `fromJson` factories that validate before construction. Rationale: strict unavailable-vs-zero, decimal-string, currency/time/basis and classification semantics require real validation logic that generated fromJson cannot express without heavy custom converters; hand-written parsers are directly reviewable. This also keeps generated outputs for this lane to Freezed model outputs + Riverpod provider outputs only. No generated file was hand edited and none was fabricated.
2. **Shared contract primitives live in `position_models.dart`** and are imported by the market/research model files; `ApiException`/`AuthTokenProvider` live in `position_repository.dart` and are imported by the other two repositories. No shared new file was created (the package forbids extra files).
3. **`{data: ...}` envelope tolerance** on position/resource responses mirrors the existing app convention in `briefing_config_repository.dart`; the market history endpoint parses the body directly (matches the H15A service which returns the response object itself).
4. **Cancellation** is via injectable `http.Client` and `close()`, matching http semantics: closing the client rejects in-flight requests with `ClientException`, which the repositories surface (never swallow). Repository tests use injected fakes only — no live API calls, no real network.
5. **Test fixtures are synthetic** contract-style values (ACME/IBM-style identifiers). Nothing is presented as observed market data; no credential, token, or password value appears in any fixture or test (the only token-like string is the explicit non-secret literal `fixture-token-not-a-secret` used to assert header construction).

## Pending generation steps (development PC — H11 owns these outputs)

From `frontend/`:
1. `flutter pub get` (lockfile already exists; no resolution fabrication).
2. `dart run build_runner build --delete-conflicting-outputs` — generates exactly: `position_models.freezed.dart`, `market_models.freezed.dart`, `research_models.freezed.dart`, `position_repository.g.dart`, `market_repository.g.dart`, `research_repository.g.dart`.
3. `flutter analyze`, then `flutter test test/research_models_test.dart`.
Generation lock: these seven sources + their generated outputs are single-owner H11; no other lane may run build_runner over them or hand-edit the outputs.

## Limitations (explicit, not waived)

- **DEFERRED_TO_DEV_PC:** analyzer pass, test execution (8 groups, 37 test cases), generation, runtime behavior. Nothing here constitutes runtime or release acceptance.
- Response envelope shapes for `/research/positions/:id/latest` and `/research/positions/:id/assessments` are per CONTRACTS §9 prose (`{assessment, run}`, `{assessments, next_cursor}`) because no backend research routes exist yet on main; `listAssessments` sends the cursor as `cursor`. These two wire details should be reconciled when the research backend lane lands; the parser tolerates additive fields but the two key names are the assumptions to re-check.
- `evidence_quality`/`predictive_uncertainty` and `MarketWarning` extras are carried as bounded text/raw maps per contract; no UI semantics are attached in this lane.
- `git diff --check` equivalent cleanliness was part of the structural scan (no trailing whitespace introduced).
