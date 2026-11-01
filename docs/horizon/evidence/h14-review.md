# H14 — Combined independent specification and quality review

> **FINAL (targeted re-review, 2026-11-01): SPEC_PASS_SOURCE_ONLY / QUALITY_PASS_SOURCE_ONLY.**
> First-pass FAIL history is preserved below; the dated re-review section at the
> bottom records the repair verification that supersedes it. All Flutter
> analyze/test/a11y and `.freezed.dart` generation remain DEFERRED_TO_DEV_PC.

- Task: t_7ae965df (H14), reviewer profile, phase core_source
- Author delivery reviewed: t_5f43465d (author handoff `docs/horizon/evidence/h14-author.md`)
- Date: 2026-11-01
- Baseline: branch `main`, HEAD `9fbb26b5519889e0816720530dd60c204dda2bf2` (unchanged); dirty/untracked baseline preserved; no commit/push/branch change.
- Review basis: `SPEC.md`, `CONTRACTS.md` §4–§9, `TASKS.md`, `AMENDMENT-2026-10-30.md`, the H11 typed domain (`frontend/lib/src/features/research/research_models.dart`), the actual backend wire (`backend/src/features/research/research.routes.js`, `research.service.js:803-835`), and the four H14 artifacts read in full.

## Verdicts

| Dimension | Verdict |
|---|---|
| SPEC | **FAIL_SOURCE_ONLY** |
| QUALITY | **FAIL** |

Both must pass to accept this gate; both fail. Targeted author repair required, then independent re-review.

## Blocking findings (author repair required)

1. **Compile error — `outlook_panel.dart:89-92` (QUALITY, and blocks SPEC realization).**
   `_buildController` computes
   ```dart
   final initialIndex = (assessment.recommendation.horizonMonths - 1).clamp(0, 2);
   return TabController(length: 3, vsync: this, initialIndex: initialIndex);
   ```
   `int.clamp(...)` returns `num`, not `int` (Dart `num.clamp` is declared `num clamp(num, num)` and `int` does not override it). `TabController.initialIndex` is typed `int`. The implicit `num` → `int` downcast is not allowed under sound null safety, so this file does not compile, and `flutter test test/research_panel_test.dart` (which imports `outlook_panel.dart`) fails at compile time. Fix: `.toInt()` / `as int`, or simply drop the redundant `clamp` (the typed model already validates `horizonMonths ∈ {1,2,3}`). This is a definite static type error; it could not be observed by the author's brace-balance tokenizer, which the author correctly disclaimed.

2. **Test assertion defect — `research_panel_test.dart` "three tabs exist and are independent" (QUALITY; breaks the executable spec for the core 1/2/3-tab step).**
   The fixture (`_outlooksJson`) sets `evaluation_session_date` equal to `calendar_target_date` for every horizon. `_OutlookView` renders BOTH:
   - `Outlook target date: <target>` and
   - `Evaluated at the last exchange session on or before the target: <evaluation_session_date>`
   so the same date string appears twice per built horizon. The three `findsOneWidget` assertions
   ```dart
   expect(find.textContaining(_target1), findsOneWidget); // line 455
   expect(find.textContaining(_target3), findsOneWidget); // line 460
   expect(find.textContaining(_target1), findsOneWidget); // line 466
   ```
   each match **two** widgets and will fail (false red) on the dev PC. Fix: assert `findsNWidgets(2)` (or `findsWidgets`), or give the fixtures a distinct, still-contract-valid `evaluation_session_date` (e.g. an exchange-session date `≤ calendar_target_date` and `≥ session_as_of`).

## Non-blocking observations (do not gate; address with the repair or defer)

3. `_OutlookPanelState.didUpdateWidget` (outlook_panel.dart:79-87) disposes `_controller` and rebuilds it while the old `TabBar`/`TabBarView` are still attached and listening. On an assessment identity/horizon change without remount this risks a "TabController disposed while in use" error. Prefer updating `_controller.index` (and `length` only if needed) over dispose-and-recreate. Not exercised by the current fixtures (all use id `ass-1`, horizon 1), so it is latent, not a test-visible failure.

4. Copy: `Research horizon: ${horizonMonths} month` renders "2 month"/"3 month" (research_panel.dart:315 and outlook_panel.dart:218). Cosmetic; suggest pluralization or "month(s)".

5. Backend note (out of H14 scope; informational for H09/H11-owner/H15B): `toPublicRunView` does not strip `owner_id_internal` (only `lease_nonce`), whereas `toPublicAssessmentView` strips it — and `ResearchRun.fromJson` *requires* `owner_id_internal`. Not an H14 defect (widgets consume already-parsed typed models), but it must be reconciled with the real run wire before H15B integrates `ResearchRun`. The author's §6 wire-trace is **accurate**: I independently confirmed all four rows against `research.routes.js` / `research.service.js`.

## What I independently verified (green)

- **SHA-256** of all four H14 files match the author handoff exactly (recomputed on disk):
  - `research_panel.dart` `82653c03…c01506`
  - `outlook_panel.dart` `05f0dc54…f177e9`
  - `evidence_sheet.dart` `b9c6fdbf…afe85d5`
  - `research_panel_test.dart` `9d6fb84a…352ed4d`
- **Baseline integrity**: `git diff --check` clean (exit 0); HEAD unchanged at `9fbb26b…`; no existing file modified; only the four allowlisted new files added (the pre-existing dirty/untracked set is unchanged).
- **No new dependency**: pubspec unchanged; `flutter`, `freezed`/`freezed_annotation`/`build_runner` already present; SDK `^3.11.0` (so switch expressions and logical-or `||` patterns are valid).
- **Label-map fidelity to CONTRACTS**: `recommendationActionLabel` covers all 9 §5 actions; `runStatusLabel` all 7 §8 statuses; `evidenceKindLabel` all 8 §4 kinds; `coverageStatusLabel` maps `headline_only` → "Headline only — not a verified article" (§4); `claimTypeLabel` observed/interpretation/assumption; direction and projection-kind framings match §5/§7. The §7 verbatim "No quantified projection for this assessment" is reproduced exactly.
- **Model-field cross-reference**: every field the widgets read (`assessment.recommendation.*`, `market_thesis.*`, `position_context.*`, `outlooks[]` incl. `numeric_projection.*`, `changes_since_previous.*`, `EvidenceItem.*`, `EvidenceFact.*`, `ReportingPeriod.*`, `MoneyAmount.amount/currency`, `PositionState.{candidate,owned,legacyUnclassified}`) exists on the H11 typed models. No invented field access.
- **Decision-first structure, business-vs-price distinction, candidate-vs-owned economics, honest run state, headline-only marking, snapshot/evidence delegation**: all present in source and non-vacuously asserted by the tests (verified by reading the widgets and the test bodies, not by execution).
- **H09 N1 guard honored**: `economics_status` (hasCost&&hasQuantity-derived) is never surfaced as comparable P/L; owned inputs are labeled user data; the "P/L"/"Profit / loss" non-presentation assertions are non-vacuous (the user-data note uses lowercase "profit and loss", so the specific patterns correctly find nothing).

## Regression evidence (backend, re-verified)

- The single red backend test `backend/test/research-workflow.test.cjs` is the in-flight H10 lane's TDD red phase (matches the orchestrator note); it is not an H14 regression and is excluded from H14 judgment. H14 touches no backend file.

## Limitations (explicitly deferred, never PASS)

- No Dart/Flutter SDK on this host (`dart: command not found`, exit 127). Therefore `dart run build_runner build --delete-conflicting-outputs`, `flutter analyze`, `flutter test`, a11y/`Semantics` tree verification, and runtime behavior are all **DEFERRED_TO_DEV_PC** and not passed here. Source-only verdicts never imply runtime or release acceptance.
- Findings 1 and 2 are static-language/test-semantics conclusions that do not require an SDK to establish, but their dev-PC confirmation (`flutter analyze`, `flutter test`) remains pending on the deferred gate.
- H11 `.freezed.dart`/`.g.dart` parts are not checked in; generation is H11-owned and mandatory before any H14 code compiles.

## Verdict rationale

SPEC semantics (decision-first panel, explicit insufficient-evidence, business-vs-price, three independent horizons, source/freshness/run-status fidelity, verbatim no-projection message) are correctly implemented in source and map cleanly onto the acceptance criteria. But the acceptance criteria cannot be *realized or demonstrated* while the widget does not compile (finding 1), and the executable specification for the core 1/2/3-month tab step is broken by a false-red assertion (finding 2). QUALITY fails on the same compile error plus the test defect, with the TabController dispose anti-pattern noted. Neither verdict can pass as delivered.

---

## Targeted re-review (2026-11-01 08:04 UTC) — repair t_784ed896

Repair-parent: `t_784ed896` (worker; controller-verified delivery, 4/4 hashes,
0 `.clamp(` sites). Scope: F1/F2 plus should-fix items 3–4. All verification
below is independent source inspection and command reproduction on this host;
no author self-report substituted.

### Final verdicts

| Dimension | Verdict |
|---|---|
| SPEC | **PASS_SOURCE_ONLY** |
| QUALITY | **PASS_SOURCE_ONLY** |

Both pass; H14 may release its source-development dependencies. Flutter
`analyze`/`test`/a11y execution and H11 `.freezed.dart`/`.g.dart` generation
remain **DEFERRED_TO_DEV_PC** and are not passed here.

### F1 — clamp compile error: FIXED

- `outlook_panel.dart:97-98` now `int _horizonTabIndex(...) => assessment.recommendation.horizonMonths - 1;` — plain `int`, no `.clamp(...)`.
- `_buildController` (lines 100-103) passes `initialIndex: _horizonTabIndex(assessment)` → `int`, so `TabController(initialIndex: int)` type-checks.
- Model basis re-verified: `research_models.dart:565` declares `required int horizonMonths`; `:576-577` rejects anything not `{1,2,3}`. `horizonMonths - 1` is therefore inherently `0..2` as a plain `int`.
- `grep -rn "\.clamp("` across all three writable files → **NONE** (matches the controller's 0-site claim).

### F2 — false-red "three tabs" assertion: FIXED

- The fixture now carries distinct evaluation-session dates (`research_panel_test.dart:44-46`): `_eval1='2026-11-27'`, `_eval2='2026-12-29'`, `_eval3='2027-01-29'`, each distinct from its `_target1/2/3` (`2026-11-30`/`2026-12-30`/`2027-01-30`).
- The three assertions (lines 465-466, 471-472, 478-479) now assert `find.textContaining(_targetN)` **and** `find.textContaining(_evalN)` separately with `findsOneWidget`, and no `_targetN` is a substring of the corresponding `_evalN`.
- Contract-validity of the eval dates re-verified against `ResearchAssessment.fromJson` cross-field rules (`research_models.dart:1141-1149`): each `evaluation_session_date` is `>= session_as_of` (`2026-10-30`) and `<= calendar_target_date`. Verified: `11-27 ≥ 10-30` and `≤ 11-30`; `12-29 ≤ 12-30`; `01-29 ≤ 01-30`. All weekdays (Fri/Tue/Fri). The projection test's `target_session_date == _eval1` also satisfies the projection-identity rule (`:1155`).
- The chosen approach is the "distinct contract-valid fixtures" option, not `findsNWidgets`.

### Should-fix 3 — TabController dispose anti-pattern: FIXED

- `didUpdateWidget` (`outlook_panel.dart:79-91`) no longer disposes/recreates `_controller`. On assessment-id/horizon change it now sets `_controller.index = _horizonTabIndex(widget.assessment)` and keeps the controller alive (the `length` is constant `3`, since the model enforces exactly one 1/2/3 outlook). The in-line comment explicitly cites "H14 review finding 3".

### Should-fix 4 — "N month" singular copy: FIXED

- `research_panel.dart:316-317` and `outlook_panel.dart:228-229` both now render `month${horizonMonths == 1 ? '' : 's'}`.

### Should-fix 5 — backend `toPublicRunView` / `owner_id_internal`: UNCHANGED, out of scope

- Informational only; not an H14 defect. Reaffirmed deferred to the H09/H11-owner/H15B reconciliation. No H14 file touches it.

### Integrity re-verified (independent)

- `git diff --check` → exit 0 (clean).
- `HEAD` unchanged at `9fbb26b5519889e0816720530dd60c204dda2bf2`; no branch/commit/push.
- `git status --short` shows only the pre-existing dirty/untracked baseline plus the research dirs; no unexpected file.
- SHA-256 (recomputed on disk after repair):
  - `research_panel.dart` `e1bcc2e8ba97ca4d1ec713109d330e0bc84ed9a1612751c515bbd6b923a3963a`
  - `outlook_panel.dart` `70b3932d338ebc168ba95f79aaf2591b9672c768490084dbb79ca94ab2d80ba7`
  - `evidence_sheet.dart` `b9c6fdfbf74aa25e95e46730f1e986babcf7da13df8db7a6feee380acafe85d5` — **byte-identical** to the first-pass delivery (untouched, as claimed)
  - `research_panel_test.dart` `886455ebb1fa8fa288bfa76c3d01fab8c0c6983099155685eb013610870f8a6c`

### Remaining limitations (unchanged, explicit)

- No Dart/Flutter SDK on this host (`dart: command not found`). `dart run build_runner build --delete-conflicting-outputs`, `flutter analyze`, `flutter test`, a11y/`Semantics` tree verification, and runtime behavior all remain **DEFERRED_TO_DEV_PC**; source-only verdicts never imply runtime or release acceptance.
- F1/F2 conclusions are static-language/test-semantics conclusions; their dev-PC confirmation (`flutter analyze`/`flutter test`) remains pending on the deferred gate.
