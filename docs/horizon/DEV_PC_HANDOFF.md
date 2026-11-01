# DEV-PC handoff — H17 (source snapshot → Dev-PC build/device gate)

This document is the safe-transfer contract for running the H17 Flutter
verification on the development PC. The authoring server has **no Dart/Flutter
SDK** and therefore could only author source and run hermetic backend Node
tests. **The server cannot pass the PC gate** — everything in §3–§5 below is
DEFERRED_TO_DEV_PC and is executed by the Dev-PC operator, never claimed here.

Repository: `/home/ubuntu/apps/Horizon` (dirty main baseline preserved; no
branch change, no commit/push). Package: `horizon` (pubspec `name: horizon`,
SDK `^3.11.0`, Android applicationId/namespace `com.example.horizon`, Wear
minSdk 30).

## 1. Source snapshot hashes (transfer verification)

SHA-256 of the files the Dev-PC must receive byte-identical. Re-verify with
`sha256sum <path>` after transfer; any mismatch means the transfer is
incomplete and MUST be re-done before building.

```text
# This card's new files
9f8e9ae253875e3be14ff853600630290142ea208516ebb1e4b2ca6e1d18bbc8  backend/test/research-end-to-end.test.cjs
4987729534f3ee382acb5f3cf19be007f6b086f28be765e1adc5fdd612c8b9bc  frontend/integration_test/research_journey_test.dart

# Accepted upstream Flutter sources (frozen baseline, do not edit)
33fd7c1d8338c1a4c4dd85ecae58d88e5d3f533b195fb3d672eb9e6dd59e7227  frontend/pubspec.yaml
2c3711e4cec167e9bc2eada324d3c42dcecbb5a8f6096045562d67be725d8205  frontend/lib/main.dart
e929cddd2b81f47c795ce74aa2ff22cf366e1444c32daf92fee2de071c74484e  frontend/lib/main_wear.dart
abccadd079672cdb6f030a6039d39bf3356e5b2a1f46ec887e1b68896b6e80e3  frontend/lib/src/features/research/research_models.dart
2d1717e1d023f04e908bec4c99ec00bec0c298872c380621333413326866c52b  frontend/lib/src/features/research/research_repository.dart
e1bcc2e8ba97ca4d1ec713109d330e0bc84ed9a1612751c515bbd6b923a3963a  frontend/lib/src/features/research/widgets/research_panel.dart
70b3932d338ebc168ba95f79aaf2591b9672c768490084dbb79ca94ab2d80ba7  frontend/lib/src/features/research/widgets/outlook_panel.dart
b9c6fdfbf74aa25e95e46730f1e986babcf7da13df8db7a6feee380acafe85d5  frontend/lib/src/features/research/widgets/evidence_sheet.dart
eb96e00d14d48e85ca37817ea819f9c1c4ca519b683064099dad1f6eb37e2f4f  frontend/lib/src/features/positions/position_models.dart
bad936a37951ad1bb5dcd570241378a6d2b7e9b0312a9dd3b4d1ad5b4976c67a  frontend/lib/src/features/positions/position_repository.dart
681dd152887e8f5a838cfc67c37808a54c3a03817d21dd58a794709b902b972b  frontend/lib/src/features/stock/stock_detail_screen.dart
42231476ff810cd2ff55fe897d0c91869dcd7af439363c1b5a89d6adfcc228ec  frontend/lib/src/features/stock/stock_repository.dart

# Accepted upstream Flutter tests (do not edit)
6b0d0bd6a36d84d18b02915001ef15f953da819f5b5c9cba9afba14989882f07  frontend/test/research_panel_integration_test.dart
824b4890f33cdbd09a418e7e4319bb9800ee0f45ace0b1f5334802a5f83a7b8a  frontend/test/research_compatibility_test.dart
```

## 2. Generator order (MANDATORY — do not skip or reorder)

The H11 position/research **generated parts are absent** on disk
(`position_models.freezed.dart`, `position_repository.g.dart`,
`research_models.freezed.dart`, `research_repository.g.dart` do not exist).
Freezed shapes changed in H11/H15B, so regeneration is a hard precondition —
no Flutter command succeeds before it.

Run from `frontend/`, in this exact order:

```text
# 1. Resolve dependencies (and add the integration_test SDK package — §4)
flutter pub get

# 2. Regenerate freezed/riverpod/json parts (MANDATORY)
dart run build_runner build --delete-conflicting-outputs

# 3. Static gate
flutter analyze
```

> Do NOT hand-edit any `*.freezed.dart` / `*.g.dart` output; the generator is
> the single owner. `--delete-conflicting-outputs` is required because the
> `part` declarations changed shape across H11/H15B.

## 3. Deferred criteria (run on Dev-PC, in order)

```text
flutter analyze                                              # zero errors
flutter test                                                 # unit/widget suite (incl. H15/H15B/H17-compat)
flutter test test/research_panel_integration_test.dart       # H15B canonical integration (widget layer)
flutter test test/research_compatibility_test.dart           # H15 compatibility suite
flutter test integration_test/research_journey_test.dart     # H17 journey (device layer) — see §4
flutter build web                                            # web target
flutter build apk --release                                  # mobile APK
flutter build apk --release -t lib/main_wear.dart            # Wear APK (minSdk 30, Wear OS 3+)
```

Device-level (requires an attached device/emulator):

```text
flutter test integration_test/research_journey_test.dart -d <device-id>
# or, for on-device driver collection:
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/research_journey_test.dart -d <device-id>
```

## 4. `integration_test` package prerequisite

The H17 journey test imports `package:integration_test/integration_test.dart`,
which is **not yet in `pubspec.yaml`** (that file is outside this card's write
allowlist). The Dev-PC operator must add one line to `dev_dependencies` before
`flutter pub get`:

```yaml
dev_dependencies:
  integration_test:
    sdk: flutter
```

This is the only new dependency introduced by H17 and it is a first-party
Flutter SDK package (no third-party license or renderer change — the chart
dependency remains `fl_chart` only).

## 5. APK artifact / hash requirements

After a successful `flutter build apk --release`, record and hand back the
artifact identity so the release gate can verify it:

```text
# Mobile
frontend/build/app/outputs/flutter-apk/app-release.apk
# Wear (if built)
frontend/build/app/outputs/flutter-apk/app-release.apk   # -t lib/main_wear.dart variant
```

Required evidence per artifact (do NOT substitute plausible values):

- `sha256sum <apk>` — exact SHA-256.
- `ls -l` size in bytes and `stat -c '%y'` mtime.
- The exact `flutter --version` and `flutter doctor -v` snapshot that produced
  it (toolchain identity, not just "built successfully").
- The `flutter build apk --release` command's actual stdout tail (success line).

These values are the release-gate inputs; an APK without a recorded hash and
toolchain version is not verifiable and must be rebuilt/recorded.

## 6. Transfer safety

- Copy the whole `frontend/` tree and `backend/test/research-end-to-end.test.cjs`
  (plus the `docs/horizon/` evidence tree) verbatim. Do not cherry-pick files —
  the generated parts are absent by design and are produced only by §2.
- Do not run `git clean`/`git reset`/`git checkout` to "tidy" before transfer:
  the working tree's dirty baseline is intentional and must be preserved.
- After transfer, run the §1 hash verification first; only then start §2.


## 6. Dev-PC gate feedback — 2026-11-01 (first build_runner run)

Four compile defects found on the development PC and fixed server-side (this
commit), all in files the authoring server could never compile (no Dart SDK):

1. freezed ^3.2.5 emits `@JsonSerializable()` on the generated class whenever
   a hand-written `fromJson(Map<String, dynamic>)` factory exists, which then
   requires a `.g.dart` part these hand-parsed files deliberately omit. Fixed
   by annotating all 20 affected classes
   `@Freezed(fromJson: false, toJson: false)`
   (17 in research_models.dart, Position, MarketBar, HistoryResponse).
2. Unescaped literal `$` in single-quoted strings in
   research_compatibility_test.dart (7 sites) — Dart interpolation syntax
   errors. Escaped as `\$`.
3. chart_probe.dart:175 closed a list literal with `]);` instead of `];`.
4. `integration_test: {sdk: flutter}` added to pubspec.yaml dev_dependencies.

Updated transfer hashes (§1 for files listed there; the rest here):

```text
9f1ac0f79ef1414e12ca32cc9f6f872eadfb23bcd4b0426ea9ee31dcf76cc46b  frontend/test/support/chart_probe.dart
eb96e00d14d48e85ca37817ea819f9c1c4ca519b683064099dad1f6eb37e2f4f  frontend/lib/src/features/positions/position_models.dart
900e2183b79402df47db4f44ed286bb7d52b0f12db7c2c51f9c9bfa240eaffb6  frontend/lib/src/features/market/market_models.dart
```

The "frozen baseline" marking in §1 referred to transfer integrity, not
eternal immutability — these are gate-feedback repairs with this section as
the audit trail. Re-verify all §1 hashes after pulling this commit.
