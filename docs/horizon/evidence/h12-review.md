# H12 review — Position editor and candidate/owned experience (combined SPEC + QUALITY)

Reviewer: reviewer (deepseek-v4-pro) · Author: worker (zai) · 2026-10-31
Scope: `position_editor.dart`, `position_badge.dart`, `position_editor_test.dart`
against CONTRACTS §2, the backend `position.service.js`/`position.routes.js`, and the
accepted H11 typed domain. Source-only; all Dart/Flutter execution DEFERRED_TO_DEV_PC.

## Verdicts

| Lane | Verdict |
|---|---|
| SPEC (specification compliance) | **SPEC_PASS_SOURCE_ONLY** |
| QUALITY (code quality) | **QUALITY_PASS_SOURCE_ONLY** |

Both verdicts are source-only. Every unexecuted PC/runtime criterion is listed in
§8. These verdicts release the H12 source dependency only — they are **not** runtime
or release approval, and they do **not** clear the critical cross-lane defect in §5.

## 1. Independent verification performed (not author self-report)

- SHA-256 of all three files recomputed on disk: matches the author evidence hashes
  exactly (`1443cb93…`, `ed201b91…`, `d6ce868e…`).
- `git status --porcelain`: the pre-existing dirty baseline (backend/app.js, env.js,
  briefing.*, scheduler.js) is intact; H12 added only the two widget files and the test
  plus evidence — no commit/push/branch/reset/clean. `git diff --check` exit 0.
- Toolchain probe reproduced: `command -v dart flutter` exit 1 — no SDK on this host,
  so `flutter analyze` / `flutter test` / `build_runner` are legitimately deferred.
- Key cross-reference: all 9 `position-editor-*` keys asserted in the test exist in the
  editor source, and vice versa (no orphans).
- Read the full source of the three H12 files and the H11 `position_models.dart` /
  `position_repository.dart`, and cross-checked every transition against
  `position.service.js` (`ALLOWED_TRANSITIONS`, `clearEconomics`, `REVISION_CONFLICT`,
  `INVALID_TRANSITION`) and `position.routes.js` (PATCH `{expected_revision, changes}`,
  flat `{code, message}` error forwarding).

## 2. Contract mapping — verified correct in source

| CONTRACTS §2 rule | H12 behavior | Verified |
|---|---|---|
| Candidate carries no executed cost/quantity/open date | Create mode renders no economics inputs; `PositionWrite.toJson()` additionally throws `ArgumentError` if a candidate write would carry economics (H11) | ✓ |
| Candidate→owned is explicit, confirmed, never auto | "I now own this…" → confirmation dialog → economics section appears | ✓ |
| Owned may have unknown economics; ask, never invent | Optional fields, "Unknown is OK" text, empty fields omitted not zero-filled | ✓ |
| Legacy imports as `legacy_unclassified`, needs classification | Edit mode on legacy renders a two-choice classify section; save disabled until classified | ✓ |
| Owned→candidate clears economics w/ confirmation, keeps history | "No longer owned…" dialog names the cleared fields; write drops economics; backend `clearEconomics` handles server-side | ✓ |
| Archival reversible, not deletion | "Archive position" dialog states reversibility; emits `archived: true` | ✓ |
| Optimistic concurrency | Every edit write carries `expectedRevision`; 409 `REVISION_CONFLICT` renders distinct reload+retry panel | ✓ |
| Bounded decimals / ISO 4217 / real dates | Reuses H11 `isValidPositiveDecimal` / `isValidSessionDate`; ISO regex; no silent input rewriting | ✓ |
| Currency mismatch disables comparable P/L, no silent FX | Non-blocking banner when cost currency ≠ instrument currency | ✓ |
| Horizon 1/2/3 default 3 | `SegmentedButton`, initial 3 for new records | ✓ |
| Owner server-derived, never client-writable | Editor emits no owner fields; `PositionWrite` has no owner param | ✓ |

Acceptance criteria are met at source level: no hypothetical entry can become a filled
purchase (no economics inputs in candidate mode; explicit transitions only; no P/L or
portfolio-weight computation anywhere), and text-scaling (2.0×), semantics, 48 dp touch
targets, and error/retry + revision-conflict states are all exercised by the authored
(but unexecuted) widget tests.

## 3. Disclosed limitations (author §5) — adjudication

All six are correctly attributed and **non-blocking**:

1. Owned-value clearing without close — H11 explicit-null model extension. Correct.
   **Note:** the root cause is broader than disclosed — it also affects clearing
   `original_thesis` / `review_conditions` in edit mode (see finding F).
2. Thesis bound 4000 (frontend) vs 5000 (backend) — H11 owner decision; editor uses the
   stricter bound to stay parseable. Correct, non-blocking.
3. Open date is a validated text field, not a picker — UX enhancement, non-blocking.
4. Unarchive not in editor (needs duplicate-active UX) — H15 owner, non-blocking.
5. No instrument resolver (create needs a resolved `PositionInstrument`) — backend
   ASSUMPTIONS-PENDING, non-blocking.
6. All runtime checks deferred — DEFERRED_TO_DEV_PC, non-blocking.

## 4. Non-blocking H12 quality findings

- **N1 (currency-without-amount asymmetry).** `_validateCurrency` requires a currency
  when an amount is present, but `_validateAmount` does not require an amount when a
  currency is present. A currency-only entry passes client validation and emits
  `{amount: '', currency: 'USD'}`, which the backend rejects (400 `INVALID_DECIMAL`).
  Not silent, never invented, but the "mirrors backend exactly" claim is asymmetric.
- **N2 (retry success does not clear `_apiError`).** `_retry` → `_submit` never clears
  `_apiError` on success; if `onSaved` leaves the editor open, the error panel would
  persist after a successful retry. Minor.
- **N3 (stale create-mode section after own transition).** After "I now own this…" in
  create mode, the header badge shows "Owned" but the section still reads "New
  candidate" with a disabled own button. Cosmetic.
- **N4 (edit re-sends full `instrument`).** `_buildWrite` always puts
  `instrument: initial.instrument` into the PATCH `changes`; the backend accepts and
  ignores it. Already noted as H11 N5. Harmless, slightly wasteful.
- **N5 (disclosure gap).** Clearing `original_thesis` or `review_conditions` in edit mode
  yields `null`, which `PositionWrite.toJson()` omits, so the PATCH never clears them
  server-side — the user's deletion silently no-ops. Same explicit-null root cause as
  disclosed limitation #1, but only economics was disclosed; thesis/conditions clearing
  is not.

None of N1–N5 violate the acceptance criteria or a contract invariant; all are author-
repairable and non-blocking for source acceptance.

## 5. CRITICAL cross-lane finding (owner: H11 + backend — NOT an H12 file)

**Empty-thesis round-trip breaks the "add candidate" flow, and it fails silently.**

- Backend `position.service.js` stores `original_thesis: ''` when a create omits it
  (line 312: `input.original_thesis === undefined ? '' : …`), and `serialize()` emits it
  verbatim (line 246).
- H11 `position_models.dart` parses `original_thesis` with `optionalBoundedText`
  (line 511), which **throws** on an empty string (line 184: `value.isEmpty` → error).
- H12 create mode correctly omits an empty thesis (`_textOrNull` → null → `toJson`
  omits the key).

Consequence: creating a candidate without a thesis (the common minimal case) returns
`201 {original_thesis: ''}`; `addPosition` → `Position.fromJson` then throws
`ContractFormatException`. Because `ContractFormatException` is not an `ApiException`,
the editor's `_submit` catch (`on ApiException`) does not handle it — the failure is an
uncaught async error with no error panel. **Silent failure of the primary create path.**

This is a real defect in the "accepted" H11 wire (it does not actually accept the
backend's serialize output) plus a latent H11 test failure: `research_models_test.dart:389-397`
asserts `Position.fromJson(backendSerializedOwnedPosition())` succeeds with
`original_thesis == ''`, which will throw on the dev PC. The H11 review passed this
fixture ("mirrors serialize output") without noticing that `optionalBoundedText` rejects
`''`.

**Owner:** H11 (`position_models.dart` — accept `''` and normalize to null, or align
`optionalBoundedText`) and/or backend (`serialize` `null` instead of `''`). H12 cannot
repair it — H11 owns the model and the backend is operator/other-lane scope. H12 is
doing the right thing (omitting the empty thesis).

**Impact on this gate:** it does not make H12's deliverable incorrect, so it does not
fail the H12 SPEC/QUALITY verdicts — but it must be repaired by H11/backend before H15
integration, or the candidate-create feature is broken end-to-end. Flagged for
orchestrator routing (no repair card created here, per card constraints).

## 6. Test fidelity

`position_editor_test.dart` (18 cases, unexecuted) covers: create-no-economics,
candidate-save-shape, explicit own transition, legacy classification (4), owned edit
(revision/validation/mismatch/close/archive/touch-targets), error+retry, revision
conflict+reload, 2.0× text scaling (2), badge semantics and honest economics. Fixtures
mirror the backend wire (nested `instrument`, `basis`, UTC timestamps); repository is
faked via an injected `onSave` spy, never called live. Good coverage of the stated
criteria; the empty-thesis gap (§5) is not exercised because fixtures use a non-empty
thesis or explicit `null`.

## 7. Secrets / privacy / baseline

No secrets or confidential business data in the source, fixtures, or evidence. No owner
field is client-writable. No `.env`/credential reads. No new dependency (Material 3 +
`flutter/services`). No generated files hand-authored; no lockfile fabrication. Baseline
dirty tree preserved (verified §1).

## 8. Explicit DEFERRED_TO_DEV_PC (unexecuted — not PASS)

- `dart run build_runner build --delete-conflicting-outputs` (H11 freezed generation,
  required before the editor's transitive imports compile).
- `flutter analyze` (zero-new-issue expectation for the three H12 files).
- `flutter test test/position_editor_test.dart` (18 cases).
- 2.0× text-scaling rendering, TalkBack/VoiceOver semantics behavior, and 48 dp
  touch-target rendering on device.
- Any device/APK/runtime check.

Source-only acceptance does not establish runtime or release readiness.

## 9. Verdicts (final)

- **SPEC_PASS_SOURCE_ONLY** — H12 implements every CONTRACTS §2 lifecycle rule the
  card names; acceptance criteria satisfied at source level.
- **QUALITY_PASS_SOURCE_ONLY** — strict validators, honest unknown handling, visible
  error/conflict states, semantics/touch-targets/text-scaling exercised; non-blocking
  notes N1–N5.
- **Critical cross-lane defect (owner H11+backend, §5)** must be repaired before H15;
  it does not change the H12 verdicts but is escalated for routing.
