# H15B — Scoped repair: test fixture extends library-private base class

Task t_f4b2b565 · 2026-11-01 · Source-only repair (all Dart execution DEFERRED_TO_DEV_PC).

## Defect

`frontend/test/research_panel_integration_test.dart:296` (as authored) declared:

```dart
class _FixtureStockRepository extends _$StockRepository {
```

`_$StockRepository` is a Riverpod code-generated class emitted into the part
file `frontend/lib/src/features/stock/stock_repository.g.dart` (line 84:
`abstract class _$StockRepository extends $AsyncNotifier<List<StockData>>`).
Because `stock_repository.dart` declares `part 'stock_repository.g.dart'`,
`_$StockRepository` is library-private to `stock_repository.dart` and is not
visible from the test library — the test file could not compile as authored.

## Fix (minimal, one line)

```dart
class _FixtureStockRepository extends StockRepository {
```

The fixture now extends the public `StockRepository`
(`frontend/lib/src/features/stock/stock_repository.dart:33`), mirroring the
accepted H15 pattern in `research_compatibility_test.dart` (subclassing public
notifier classes). The `build()` override is unchanged and still fully
replaces the real data path; both override sites
(`_FixtureStockRepository.new` at lines 395 and 648) are unaffected because the
public class takes no constructor arguments.

No other change was made to the file. All scenarios, wire assertions,
`_RecordingTransport`, and other fixtures are byte-identical to the accepted
H15B delivery apart from the single base-class line.

## Proof

- `grep -n '_\$' frontend/test/research_panel_integration_test.dart` → **0
  occurrences** (before: exactly 1, at line 296). No library-private generated
  (`_$`) references remain anywhere in the test file.
- `git diff --check` → exit 0 (no whitespace/conflict-marker errors).
- Baseline preserved: the pre-existing dirty/untracked main baseline is
  untouched (no `git reset`/`clean`/`commit`/`push`; no files outside the
  allowlist were edited).

### SHA-256 of the changed file

```
6b0d0bd6a36d84d18b02915001ef15f953da819f5b5c9cba9afba14989882f07  frontend/test/research_panel_integration_test.dart
```

## Limits — DEFERRED_TO_DEV_PC

Compile (`flutter analyze`), and test execution (`flutter test`) were **not
executed on this machine** — no Flutter toolchain here. All Dart execution is
deferred to the Dev-PC. Nothing in this file claims compilation or test
success; it documents a source-only repair verified by grep and hash.
