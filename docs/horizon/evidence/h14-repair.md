# H14 — Author repair evidence (clamp type error, false-red test, should-fix items)

- Task: t_784ed896 (scoped repair), author profile, phase core_source
- Repairs the review in `docs/horizon/evidence/h14-review.md` (t_7ae965df): SPEC
  FAIL_SOURCE_ONLY / QUALITY FAIL → two blocking findings + two should-fix
  observations addressed. Return to existing reviewer t_7ae965df.
- Date: 2026-11-01
- Workspace: `/home/ubuntu/apps/Horizon` (dirty main baseline preserved; no
  commit/push/reset; only the allowlisted files touched).
- Files modified (write allowlist honored):
  - `frontend/lib/src/features/research/widgets/outlook_panel.dart`
  - `frontend/lib/src/features/research/widgets/research_panel.dart`
  - `frontend/test/research_panel_test.dart`
  - `frontend/lib/src/features/research/widgets/evidence_sheet.dart` —
    **read-only, untouched**; on-disk SHA-256 recomputed as
    `b9c6fdfbf74aa25e95e46730f1e986babcf7da13df8db7a6feee380acafe85d5`,
    identical to the hash recorded in the review.

## F1 (blocking) — num→int clamp compile error — FIXED by omission

The defective site (old outlook_panel.dart:89-92):

```dart
final initialIndex =
    (assessment.recommendation.horizonMonths - 1).clamp(0, 2);
return TabController(length: 3, vsync: this, initialIndex: initialIndex);
```

`int.clamp` is inherited from `num.clamp(num, num)` and returns `num`;
`TabController.initialIndex` is `int`. Fixed by **dropping the redundant
clamp** — the H11 typed model validates `horizonMonths ∈ {1,2,3}`
(research_models.dart:655-657, 1122-1130), so `horizonMonths - 1` is already
in 0..2 and the expression is plain `int`.

New code (outlook_panel.dart:93-103):

```dart
  /// Tab index for a recommendation horizon. horizonMonths is validated by
  /// the H11 typed model to {1,2,3}, so the result is always 0..2.
  /// The num-typed clamp result defect (H14 review finding 1) is fixed by
  /// omission: no clamping is needed, and the expression is plain int.
  int _horizonTabIndex(ResearchAssessment assessment) =>
      assessment.recommendation.horizonMonths - 1;

  TabController _buildController(ResearchAssessment assessment) {
    return TabController(
        length: 3, vsync: this, initialIndex: _horizonTabIndex(assessment));
  }
```

## Clamp-class audit (required by the card)

Scanned ALL THREE writable files for every `.clamp(` call and every
num-typed expression flowing into int/double-typed parameters.

- `.clamp(` sites found: **1** (the F1 site above). Zero in
  research_panel.dart, research_panel_test.dart, and (informationally, since
  it is read-only) evidence_sheet.dart. After the fix: **0** `.clamp(` sites
  remain in all three files (grep-verified, including inside comments).
- Other num/double-flow sites audited: **3** (grep for `toInt|toDouble|as
  num|as int|as double|~/|*|toStringAsFixed|withAlpha`):
  1. outlook_panel.dart:357 `value.toStringAsFixed(2)` — receiver is the
     model's `double?` bound (`NumericProjection.lower/central/upper`);
     `toStringAsFixed` exists on `double`. Sound.
  2. research_panel.dart:311 `actionColor.withAlpha(0x2E)` — int literal into
     `Color.withAlpha(int)`. Sound.
  3. research_panel.dart:603 `theme.danger.withAlpha(0x66)` — int literal
     into `Color.withAlpha(int)`. Sound.
- **Total audited: 4 sites (1 defective, fixed; 3 sound).** No other site
  passes a `num`-typed value into an int/double-typed parameter.

## F2 (blocking) — false-red duplicate-date test assertions — FIXED via distinct fixtures

Chosen option: **distinct contract-valid `evaluation_session_date` values**
(not `findsNWidgets(2)`). Rationale: the review's first option leaves the
executable spec asserting "the same string appears twice", which passes for
either a rendering bug or correct behavior; distinct dates make the
`findsOneWidget` assertions meaningful (target-date line and evaluation-session
line render different strings) and additionally exercise that both lines render
their own value. The old fixtures set `evaluation_session_date ==
calendar_target_date` so `find.textContaining(_target1)` matched two widgets.

New constants (research_panel_test.dart:40-46):

```dart
// Distinct evaluation-session dates per horizon (H14 review finding 2): real
// exchange-session weekdays, each >= _sessionAsOf and <= its calendar target,
// so the target-date line and the evaluation-session line render different
// strings and findsOneWidget assertions stay meaningful.
const String _eval1 = '2026-11-27'; // Friday before the 2026-11-30 target
const String _eval2 = '2026-12-29'; // Tuesday before the 2026-12-30 target
const String _eval3 = '2027-01-29'; // Friday before the 2027-01-30 target
```

Fixture change (research_panel_test.dart:64-71): `evaluation_session_date`
now comes from `{1: _eval1, 2: _eval2, 3: _eval3}` instead of
`targets[horizon]`.

Contract validity, verified programmatically (Python `datetime`, weekdays
shown) and against the H11 model rules:

- `2026-11-27` Friday, `2026-12-29` Tuesday, `2027-01-29` Friday — real
  exchange-session weekdays (no US-market holiday falls on these dates).
- Model rules (research_models.dart:1141-1149): evaluation session must be
  `>= session_as_of` (`2026-10-30`) and `<= calendar_target_date`. All three
  satisfy both (`2026-11-27 ≥ 2026-10-30 ≤ 2026-11-30`, etc.). The model's
  `isValidSessionDate` (position_models.dart:45-51) checks format + day-range
  only; the weekday/exchange-session quality is a fixture-construction
  guarantee documented here.
- Weekday computation (real command output):
  `2026-11-27 Friday / 2026-12-29 Tuesday / 2027-01-29 Friday /
  2027-01-30 Saturday / 2026-11-30 Monday / 2026-12-30 Wednesday`.

Coupled change (required, not optional): the H11 model rejects a projection
whose `targetSessionDate != outlook.evaluationSessionDate`
(research_models.dart:1150-1159). The conditional-scenario fixture's
projection therefore changed `'target_session_date': _target1` →
`'target_session_date': _eval1` (research_panel_test.dart:501-504); without
this the projection test would throw `ContractFormatException`.

Strengthened assertions in 'three tabs exist and are independent'
(research_panel_test.dart:462-486): `find.textContaining(_eval1/_eval3)`
`findsOneWidget` added at initial tab, tab 3, and after returning to tab 1.

## F3 (should-fix) — didUpdateWidget dispose-and-recreate — FIXED

Old code disposed `_controller` and rebuilt it while the live
`TabBar`/`TabBarView` were still attached. New code (outlook_panel.dart:78-91)
keeps the controller alive and updates only the index; the tab `length` is a
constant 3 and never changes:

```dart
      // The H11 typed model validates horizonMonths ∈ {1,2,3}, so the tab
      // length (3) never changes; only the selected index follows the new
      // horizon. The controller is kept alive: disposing it here would
      // dispose a controller still attached to the live TabBar/TabBarView
      // (H14 review finding 3).
      _controller.index = _horizonTabIndex(widget.assessment);
```

`_controller.index` setter accepts 0..2; `_horizonTabIndex` returns 0..2 by
the typed model's validation.

## F4 (should-fix) — horizon pluralization — FIXED in both widgets

- outlook_panel.dart:228-229:
  `'Research horizon: ${outlook.horizonMonths} '` /
  `'month${outlook.horizonMonths == 1 ? '' : 's'}'`
- research_panel.dart:316-317:
  `'Research horizon: ${recommendation.horizonMonths} '` /
  `'month${recommendation.horizonMonths == 1 ? '' : 's'}'`

Renders "1 month" / "2 months" / "3 months". The test's
`find.textContaining('Research horizon')` (findsWidgets) is prefix-based and
unaffected. No test asserted the old singular string.

## Verification (actual commands and output)

- `git diff --check` → exit 0, clean (no whitespace errors).
- Clamp/flow audit grep (counts above): `.clamp(` = 1 before fix in
  outlook_panel.dart, 0 everywhere else; 0 after fix in all three files.
- Dart-aware brace/paren/bracket balance check (custom interpolation-aware
  counter, since no Dart toolchain exists here): **OK for all three modified
  files**, and control file evidence_sheet.dart also OK.
- Fixture-date ordering validated programmatically: all three evaluation
  dates `>= 2026-10-30` and `<= their calendar_target_date`.
- `dart --version` → `bash: dart: command not found`, exit 127. `flutter` not
  on PATH.

## SHA-256 of changed files (final, on disk)

```
70b3932d338ebc168ba95f79aaf2591b9672c768490084dbb79ca94ab2d80ba7  frontend/lib/src/features/research/widgets/outlook_panel.dart
e1bcc2e8ba97ca4d1ec713109d330e0bc84ed9a1612751c515bbd6b923a3963a  frontend/lib/src/features/research/widgets/research_panel.dart
886455ebb1fa8fa288bfa76c3d01fab8c0c6983099155685eb013610870f8a6c  frontend/test/research_panel_test.dart
b9c6fdfbf74aa25e95e46730f1e986babcf7da13df8db7a6feee380acafe85d5  frontend/lib/src/features/research/widgets/evidence_sheet.dart (untouched, matches review)
```

## Limitations

- No Dart/Flutter SDK on this host (exit 127). `flutter analyze`,
  `flutter test test/research_panel_test.dart`, `dart run build_runner build
  --delete-conflicting-outputs` (mandatory for the H11 freezed models), and
  all runtime behavior are **DEFERRED_TO_DEV_PC** — never PASS from source
  inspection.
- The red-first requirement is satisfied statically: the reviewer established
  finding 2 as a definite false red (each `findsOneWidget` matched two
  widgets) and finding 1 as a definite compile error; neither required
  execution to establish, and neither could be executed here. The dev-PC run
  remains the confirmation gate.
- Backend untouched; F5 (backend `owner_id_internal` wire note) is routed to
  H15B, not part of this repair.
