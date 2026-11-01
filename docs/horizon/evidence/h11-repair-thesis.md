# H11 Repair — Empty-thesis round-trip (backend serialize `''` vs `optionalBoundedText`)

Task: `t_543a90c0` · Author: worker/zai/glm-5.3-flash · 2026-10-31
Source of defect: `docs/horizon/evidence/h12-review.md` §5 (cross-lane finding, owner H11+backend).

## Defect

Creating a position without `original_thesis` stored `''` in the backend, `serialize()`
emitted it verbatim, and the H11 Dart parser (`optionalBoundedText`) throws on an
empty string → `Position.fromJson` raised `ContractFormatException` (not an
`ApiException`), uncaught by the H12 editor's `_submit` — silent failure of the
primary create path.

## Per-finding disposition

| # | Finding (h12-review §5 / card ROOT CAUSE) | Disposition |
|---|---|---|
| 1 | `position.service.js:312` create default `''` for absent thesis | **Fixed.** Absent → `null`. String validation (type + `MAX_THESIS_LENGTH = 5000`) unchanged. Explicit `null` at create is now treated as absent per CONTRACTS §2 ("optional") — one deliberate behavior change from the old strict non-string rejection, documented here. |
| 2 | `position.service.js:245` serialize emits `doc.original_thesis` verbatim | **Fixed.** `serialize()` normalizes a stored `''` to `null`, so legacy rows and the pre-repair storage default never reach the wire as `''`. Repository write path (`update`, L707 area) untouched — normalization happens at the wire boundary only. |
| 3 | `position_models.dart:184` `optionalBoundedText` throws on `isEmpty` | **Fixed (defensive).** `''` now returns `null` instead of throwing, so any producer still emitting `''` parses. Note: this helper is shared by research/market models (`label`, `unit`, `basis`, `excerpt`, `source_locator`, `error_code`, `next_cursor`, `unavailable_reason`) — all get the same defensive `'' → null` normalization, per the card's explicit instruction to change `optionalBoundedText` itself. |
| 4 | `research_models_test.dart:389-397` asserts `originalThesis == ''` | **Fixed.** Exact-serialize-shape test now expects `isNull` (fixture carries `original_thesis: null`, mirroring the repaired backend); new test asserts a `''` input normalizes to `null`. |

Out of scope, verified no drift: `position.model.js:120` still carries the Mongoose
storage default `''` (file not in the write allowlist; wire normalization covers it);
`research/contracts.js:143` Zod schema already accepts `nullable().optional()`;
`position_editor_test.dart` already uses `original_thesis: null`.

## Changes (exact edited lines)

**backend/src/features/positions/position.service.js** (serialize, now L245-248):

```js
    // H11 cross-lane empty-thesis repair: the wire never carries an empty
    // original_thesis — a stored '' (pre-repair default, legacy rows) is
    // normalized to null so optionalBoundedText on the Dart side parses it.
    original_thesis: doc.original_thesis === '' ? null : doc.original_thesis,
```

**backend/src/features/positions/position.service.js** (create, now L316-319):

```js
    // H11 cross-lane empty-thesis repair: absent original_thesis defaults to
    // null (never ''). Validation is unchanged for strings (type + overlength);
    // an explicit null is treated as absent per CONTRACTS §2 (optional field).
    const thesis = input.original_thesis === undefined ? null : input.original_thesis;
    if (thesis !== null && (typeof thesis !== 'string' || thesis.length > MAX_THESIS_LENGTH)) {
```

**frontend/lib/src/features/positions/position_models.dart** (`optionalBoundedText`, now L179-195):

```dart
  final value = json[field];
  if (value == null) return null;
  if (value is! String || value.length > maxLength) {
    throw _contractError(
        field, 'expected a non-empty string of at most $maxLength characters');
  }
  if (value.isEmpty) return null;
  return value;
```

**backend/test/positions.test.cjs** — new red-first regression
`service: create without original_thesis serializes null, never empty string`
(L229-267): create without thesis asserts serialized `null` and that the JSON wire
never contains `"original_thesis":""`; explicit `null` create → `null`; legacy
stored `''` row (seeded repository) → `get()`/`list()` return `null`; overlength
(5001 chars) still rejected with `INVALID_INPUT`.

**frontend/test/research_models_test.dart** — fixture `backendSerializedOwnedPosition()`
now carries `'original_thesis': null` (doc comment updated); exact-serialize-shape
test expects `position.originalThesis, isNull`; new test
`normalizes a legacy empty-string original_thesis to null`.

## Verification (real commands, this host)

Toolchain probe: `node` present, `dart`/`flutter` absent (`command -v dart flutter`
→ exit 1) — Flutter tests are source-recorded only.

RED (before service fix, after adding the regression test):

```
$ node --test backend/test/positions.test.cjs
not ok 10 - service: create without original_thesis serializes null, never empty string
  error: |-
    absent thesis must serialize as null
    '' !== null
  ...
# fail 1   → suite exit 1
```

GREEN (after service fix):

```
$ node --test backend/test/positions.test.cjs
# tests 41
# pass 41
# fail 0
```

All backend suites on the touched-code path:

```
$ for f in backend/test/*.test.cjs; do node --test "$f" >/dev/null 2>&1 && echo "PASS $f" || echo "FAIL $f"; done
PASS backend/test/market-history.test.cjs
PASS backend/test/positions.test.cjs
PASS backend/test/research-auth.test.cjs
PASS backend/test/research-contracts.test.cjs
PASS backend/test/research-evidence.test.cjs
PASS backend/test/research-history-integration.test.cjs
PASS backend/test/research-metrics.test.cjs
PASS backend/test/research-state.test.cjs
```

(`research-history-integration` and `research-state` reference positions only as
IDs/404-mount assertions — neither imports the position serializer; verified by grep.)

```
$ git diff --check   → exit 0
```

SHA-256 after repair:

```
507c63c16d5805c2e57287ce2cf15ed0828f2ce0fe4ad42242852226d79bbe1b  backend/src/features/positions/position.service.js
07080ca9211b5cfc7ad949edd36da69593d80eabf7a72628da2c83f238fd05a1  backend/test/positions.test.cjs
2ef79950fde0534821ffcae84620791bbe50ed6fc6bebdb8bb69952808b2d20d  frontend/lib/src/features/positions/position_models.dart
98b2f6b44a4da66bfe4c7602db7611e3ed505b8d87219dd8dc16fb37f0827a8e  frontend/test/research_models_test.dart
```

## Limitations (honest)

- Flutter tests NOT executed here (no Dart/Flutter SDK on this host): the
  strengthened assertions in `research_models_test.dart` and the Dart source change
  are recorded as source only. **DEFERRED_TO_DEV_PC**: `flutter test
  test/research_models_test.dart` (and `flutter analyze`) must run on the dev PC.
  Per invariants, no Flutter runtime PASS is claimed from source inspection.
- Explicit `null` at create now parses as absent instead of `INVALID_INPUT` — a
  deliberate, documented relaxation consistent with CONTRACTS §2 ("optional") and
  with the card's "absent → null" direction. The H12 editor's `toJson` omits null
  keys, so no sanctioned client relies on either behavior.
- Storage layer unchanged: pre-repair documents keep `''` in MongoDB until
  rewritten; every read normalizes at `serialize()`. A future storage migration
  could rewrite stored `''` → `null`, but that is an operator-owned action and out
  of this card's scope.
- No commit/push, no branch change; pre-existing dirty/untracked baseline preserved.

## Handoff

Author delivery ready for controller verification and the separate combined
reviewer (t_0b9ed167, deepseek-v4-pro). This card blocks H15 create-candidate
integration.
