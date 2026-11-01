# H15B — Scoped re-review: fixture repair verification

Task t_030cb31e · 2026-11-01 · Reviewer: deepseek (vendor-disjoint from author glm-5.3-flash).
Scope: repair t_f4b2b565 ONLY. Original H15B review t_a1f4857f (PASS, source-only) is terminal and not reopened.

## Verdict

**SPEC_PASS_SOURCE_ONLY + QUALITY_PASS_SOURCE_ONLY**

## Independent verification log

All commands run by the reviewer (not copied from the author's evidence):

| # | Check | Command | Result |
|---|-------|---------|--------|
| 1 | Library-private refs | `grep -n '_$' frontend/test/research_panel_integration_test.dart` | exit 1 — **0 occurrences** |
| 2 | Fixture base class | read of file lines 292–309 | line 296: `class _FixtureStockRepository extends StockRepository {` — public class |
| 3 | Hash | `sha256sum` (recomputed) | `6b0d0bd6a36d84d18b02915001ef15f953da819f5b5c9cba9afba14989882f07` — matches author evidence and controller addendum |
| 4 | Whitespace hygiene | `git diff --check` | exit 0 |
| 5 | Override sites | `grep -n '_FixtureStockRepository'` | lines 296 (def), 395 and 648 (`stockRepositoryProvider.overrideWith(_FixtureStockRepository.new)`) — exactly the two documented sites, unchanged |

## SPEC findings

**S1 — Public base class, zero private refs: PASS.** The single `_$StockRepository`
reference at line 296 (as authored) is replaced by the public `StockRepository`
(declared `frontend/lib/src/features/stock/stock_repository.dart:33`), imported
in the test at line 45 (`package:horizon/src/features/stock/stock_repository.dart`).
Independent grep confirms zero `_$` occurrences anywhere in the test file.

**S2 — Minimal diff: PASS.** The file is UNTRACKED in the dirty baseline
(controller RELEASE ADDENDUM 10:12 UTC confirms `git diff` is empty by design —
not evidence of no change), so minimality was verified by structural reading
instead: the fixture block (lines 292–309) is coherent with the documented
one-line change and nothing else; the recomputed hash matches the author's
post-repair hash; mtime evidence shows the repair window touched only the test
file (`research_panel_integration_test.dart` 09:49:37) while the dirty-baseline
files predate it (`stock_repository.dart` 09:30:58) and the generated part file
is untouched (`stock_repository.g.dart` mtime 2026-05-22, not in `git status`
modified list). Scenarios, wire assertions, and `_RecordingTransport`
(lines 311+) are outside the fixture block and untouched by construction.

**S3 — Author evidence file complete: PASS.** `h15b-repair-fixture.md` contains
before/after snippets, the grep proof, the SHA-256, the `git diff --check`
result, and an explicit DEFERRED_TO_DEV_PC statement (its "Limits" section).

## QUALITY findings

**Q4 — build() bypass preserved: PASS.** The fixture's `build()` override
(lines 297–308) returns a fixed `StockData` list directly — no briefing/config
provider chain is triggered — identical to the accepted H15 pattern in
`research_compatibility_test.dart:221` (`class _StaticStocks extends
StockRepository`). The fixture subclasses the public notifier class with an
implicit no-arg constructor, so both `overrideWith(_FixtureStockRepository.new)`
sites (lines 395, 648) typecheck against the generated provider's no-arg
creator signature (covariant return `_FixtureStockRepository <: StockRepository`).

**Q5 — No new dependencies / no generated-file edits / no invariant violations: PASS.**
- Import list (lines 35–46) is unchanged from the accepted delivery: `dart:convert`, flutter/riverpod/test, `http`+`http/testing`, three `package:horizon` internals, `shared_preferences` — all pre-existing pubspec deps (`flutter_riverpod`, `riverpod_annotation`, `fl_chart` at pubspec.yaml:37/41/43). No renderer change.
- `stock_repository.g.dart` untouched (mtime 2026-05-22; absent from `git status` modified list) — no generated-file hand editing.
- No secrets read or emitted; no ports opened; no background jobs; no git mutations (`git status`/`diff --check`/`sha256sum`/`grep`/`stat`/`sed` read-only only); no data invented — the fixture stock carries an explicitly empty history with the truthful-unavailable comment intact (line 304).

## Limits — DEFERRED_TO_DEV_PC

No Flutter SDK on this host; `flutter analyze`/`flutter test` were NOT executed
by author or reviewer. This review verifies source-only correctness (base-class
visibility, signature compatibility, structural minimality) and makes no
compilation or test-success claim. All Dart execution remains deferred to the
Dev-PC.

## Verdict restated

`SPEC_PASS_SOURCE_ONLY` — fixture extends the public class; zero library-private
references; change is minimal and documented.

`QUALITY_PASS_SOURCE_ONLY` — accepted data-path-bypass pattern preserved; no new
dependencies, no generated-file edits, no invariant violations.
