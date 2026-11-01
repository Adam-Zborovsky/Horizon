# H12 author evidence — Position editor and candidate/owned experience

Author: worker (H12 author run, 2026-10-31). Scope: source authoring only.
Workspace: /home/ubuntu/apps/Horizon, branch main, dirty baseline preserved —
no branch change, no commit/push, no cleanup, no file outside the H12 package
was touched (verified with `git status --porcelain`; the only paths added by
this run are the three package files plus this evidence document).

## 1. Package delivery

| File | Bytes | SHA-256 |
|---|---|---|
| `frontend/lib/src/features/positions/widgets/position_editor.dart` | 29224 | `1443cb93c3d4435391cd9dcb8a2ec2e4bd831676fb768f0d8e06590b8c1ee4f6` |
| `frontend/lib/src/features/positions/widgets/position_badge.dart` | 5888 | `ed201b9155771f117091f1f7b4c2f222a474fa6c0b19e2b85c4312ac5753cdcf` |
| `frontend/test/position_editor_test.dart` | 19058 | `d6ce868eb96f9803cfb6031a59e2679fb6f1c984764b1042c6bec70881f90af1` |

No `existing_files` were modified. No generated files were hand-authored. No
pubspec/lockfile change; no new dependency (widgets use Material 3 +
`flutter/services` already in the SDK).

## 2. Contract mapping (CONTRACTS §1–§2 → implementation)

| Contract rule | Implementation |
|---|---|
| Candidate records have no executed cost/quantity/open date | Create mode renders no economics inputs at all; `PositionWrite` for a candidate structurally cannot carry economics (H11 model throws `ArgumentError` if it would). Tests: `create mode shows no executed-economics inputs`, `saving a candidate emits state=candidate with no economics`. |
| Candidate → owned is an explicit user action; never auto-convert | `I now own this…` action (key `position-editor-transition-owned`) behind a confirmation dialog stating the consequence. No automatic conversion path exists. |
| Owned records may have unknown cost/quantity: ask, never invent | Economics fields are optional with an explicit "Unknown is OK" statement; empty fields are omitted from the write, never zero-filled. Tests: `classify as owned with unknown economics stays honest`, `unknown economics are labeled, never invented`. |
| Legacy tickers import as `legacy_unclassified`; require classification | `PositionEditor.edit(initial: legacy…)` renders an explicit two-choice classification section (keys `position-editor-classify-candidate` / `-owned`); save is disabled until classified. Tests: 4 in the `classify legacy` group. |
| Owned → candidate clears economics with user confirmation | `No longer owned…` (key `position-editor-transition-candidate`) with a confirm dialog that names exactly what is cleared; the changes payload drops the economics and the backend clears them on the `owned → candidate` transition (position.service.js `clearEconomics`). Test: `closing to candidate requires confirmation and clears economics from the write`. |
| Archival is reversible removal, not deletion | `Archive position` (key `position-editor-archive`) behind a confirm dialog that states reversibility; emitted as `changes.archived = true`. Test: `archive requires confirmation and emits archived: true`. |
| Optimistic concurrency (`{expected_revision, changes}` PATCH) | Every edit write carries `expectedRevision` = loaded position's revision (test: `edits carry expected_revision from the loaded position`); the H11 repository lifts it into the PATCH envelope. `REVISION_CONFLICT` (409) renders a distinct panel with reload guidance (`position-editor-reload`) and a retry path that resubmits the same edit. Tests: 2 in the conflict/error group. |
| Bounded decimal strings, ISO 4217 currency, real session dates | Client validators mirror the backend exactly, reusing H11's `isValidPositiveDecimal` / `isValidSessionDate`; failures are visible field errors, and no input formatter silently rewrites what the user typed into a valid value. Tests: `invalid decimal input is rejected…`, `classify as owned validates economics visibly`. |
| Currency mismatch disables comparable P/L; no silent FX | Visible non-blocking banner when the entered cost currency differs from the instrument currency, stating that comparable P/L is unavailable until a sourced FX conversion exists. Test: `currency mismatch with the instrument is visible`. |
| Preferred horizon 1/2/3, default 3 | `SegmentedButton` with 1/2/3, initial 3 for new records. Test: create-mode write carries `preferred_horizon_months: 3`. |
| Owner identity server-derived, never client-writable | The editor never emits owner fields; H11 `PositionWrite` has no owner parameter. |

Acceptance criteria:

- "No hypothetical entry becomes a filled purchase; no fake portfolio sizing."
  — enforced structurally (no economics inputs in candidate mode; confirmed
  explicit transitions only) and asserted by tests. The editor computes no
  P/L and no portfolio weight anywhere.
- "Text scaling/semantics/touch targets and error/retry states are verified."
  — widget tests assert 2.0 text scaling produces no exception and all
  controls remain findable; state semantics are exposed via `Semantics` and
  asserted with `find.bySemanticsLabel` (with `tester.ensureSemantics()`);
  save/archive/transition buttons enforce a 48dp minimum size asserted by the
  `touch targets meet the 48dp minimum` test; API error + retry and revision
  conflict + reload states each have a dedicated test. **All of these are
  authored but unexecuted here — see §4.**

## 3. TDD record — what was actually run

Red phase: the test file `frontend/test/position_editor_test.dart` was
written and committed to disk **before** the widget sources existed.

Green phase and all Flutter execution: **DEFERRED_TO_DEV_PC** per
AMENDMENT-2026-10-30. Toolchain probe actually run in this workspace:

```
$ which dart
which dart exit: 1
$ which flutter
which flutter exit: 1
$ command -v dart flutter
command -v exit: 1
```

No Dart/Flutter SDK is installed on this host and installing one is outside
this card's scope. Therefore no red-failure log or green pass exists from this
run, and **no Flutter check is claimed as PASS**. The development PC must run:

```bash
cd frontend
dart run build_runner build --delete-conflicting-outputs   # H11 generator step, required for the freezed parts the editor imports transitively
flutter analyze                                            # expect zero new issues for the three H12 files
flutter test test/position_editor_test.dart                # 18 test cases, expected green
```

Source-only verification actually performed here (substitutes for nothing;
recorded for the reviewer):

- Brace/paren/bracket balance check across all three Dart files: balanced.
- Every `Key('position-editor-*')` referenced in tests resolves to a key
  defined in `position_editor.dart`, and vice versa (no orphan keys).
- Every field label used via the test `_field(...)` helper resolves to a
  `labelText` in the editor (`Average cost`, `Currency`, `Quantity`,
  `Opened on`, `Original thesis`, `Review conditions`).
- API surface cross-checked against the accepted H11 sources: the editor
  imports and constructs only `Position`, `PositionInstrument`,
  `PositionState`, `MoneyAmount`, `PositionWrite`, `isValidPositiveDecimal`,
  `isValidSessionDate`, `ApiException` exactly as declared in
  `position_models.dart` / `position_repository.dart` (nested `instrument`
  object; `expectedRevision` is PATCH metadata only; `{positions: [...]}` and
  flat `{code, message}` envelopes are repository concerns, untouched here).
- Transition semantics cross-checked against
  `backend/src/features/positions/position.service.js` (`ALLOWED_TRANSITIONS`,
  `clearEconomics`, `REVISION_CONFLICT`, `INVALID_TRANSITION`).

## 4. Usage contract for H15 (integration)

```dart
// Create (candidate) — from a context that already holds a resolved
// instrument identity (CONTRACTS §1: resolution happens upstream, e.g. the
// stock screen; the editor never invents identity from free text):
PositionEditor.create(
  instrument: instrument,          // PositionInstrument (H11)
  onSave: (write) => ref.read(positionRepositoryProvider).addPosition(write),
  onSaved: (saved) => /* close the sheet, refresh list */,
  onConflict: () => /* refresh + reopen (create mode cannot conflict; kept for symmetry) */,
)

// Edit / classify / archive — from a position list row:
PositionEditor.edit(
  initial: position,               // Position (H11)
  onSave: (write) => ref.read(positionRepositoryProvider).patchPosition(
      position.id, write),         // PATCH {expected_revision, changes}
  onSaved: (saved) => /* replace row with saved */,
  onConflict: () => /* refetch position, replace the editor's initial */,
)
```

- Persistence failures must reach the editor as the H11 `ApiException`;
  409 + `REVISION_CONFLICT` triggers the distinct conflict UI, anything else
  the generic error + retry panel.
- The widget does not own scrolling; embed it in a scroll view / bottom sheet.
- `PositionStateBadge` and `PositionEconomicsLine` (position_badge.dart) are
  standalone presentational widgets for list rows; the economics line states
  "Cost unknown — enter your average cost and quantity to enable profit/loss"
  for owned records with null economics, per CONTRACTS §2.

## 5. Limitations and known asymmetries (non-blocking, disclosed)

1. **Clearing an owned value without closing is not expressible.** H11's
   `PositionWrite.toJson()` omits null fields, so a PATCH cannot carry an
   explicit `average_cost: null` / `quantity: null`. The editor therefore
   keeps prefilled owned values and offers closing (which clears economics
   server-side) as the only path that removes them. If edit-in-place
   clearing is wanted, that is an H11-owned model extension (explicit-null
   changes), not an H12 file.
2. **Thesis bound 4000 vs backend 5000.** The frontend model
   (`maxTextLength = 4000`, H11) would fail to parse a 4001–5000-char thesis
   the backend accepts. The editor enforces 4000 (the stricter bound) to
   stay parseable end-to-end. Aligning the limits is an H11 owner decision.
3. **Open date entry is a validated text field (YYYY-MM-DD), not a calendar
   picker.** Deliberate for this slice (honest validation, testability);
   a picker is a UX enhancement for a later lane.
4. **Unarchive is not in the editor** (archive only). Unarchive needs the
   duplicate-active check UX (`DUPLICATE_POSITION` 409) which belongs to the
   list/archive-management experience owned by H15.
5. **No instrument resolver integration.** Create mode requires a resolved
   `PositionInstrument`; no resolve endpoint exists on the backend yet
   (ASSUMPTIONS-PENDING, consistent with H11's A1/A2 markers).
6. **All runtime checks deferred.** `flutter analyze`, `flutter test`,
   text-scaling rendering, TalkBack/VoiceOver behavior and touch-target
   rendering on device are DEFERRED_TO_DEV_PC. Source-only acceptance is not
   runtime acceptance.

## 6. Baseline integrity

`git status --porcelain` before and after this run shows the same modified
tracked files (pre-existing dirty baseline: backend/app.js, env.js, briefing
files, scheduler.js) and the same untracked tree; this run only added
`frontend/lib/src/features/positions/widgets/` (2 files),
`frontend/test/position_editor_test.dart` and this evidence file. No commits,
no branch operations, no cleanup commands, no credential or `.env` access, no
secrets in source, fixtures or this document.
