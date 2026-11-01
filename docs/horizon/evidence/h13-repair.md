# H13 — Scoped author repair (F1 num→double, F2 overlay-defaults-off)

**Package:** H13 — Interactive observed-data chart and projection display
**Date:** 2026-10-31
**Author:** worker (zai) — repair task t_1fc3c09e, responding to
`docs/horizon/evidence/h13-review.md` (SPEC_FAIL_SOURCE / QUALITY_FAIL_SOURCE,
blocking findings F1 + F2 + test-fidelity gap).
**Scope:** two source files edited, per the card allowlist. All runtime checks
are DEFERRED_TO_DEV_PC (no Dart/Flutter SDK on this host — verified honestly).

---

## Files changed (exactly two; allowlist honored)

| File | Before (author delivery) | After (this repair) |
|---|---|---|
| `frontend/lib/src/features/stock/widgets/price_chart.dart` | `7faa125b31b1b0c675d44538d8d858dd5cedc086ce9527823d2014899c2025f1` | `8f1055b8ed8adeaeb96d2239387d5f644d02d0c84e6258e12e5fa207e7662e3f` |
| `frontend/test/price_chart_test.dart` | `b55cacb0d263a84a53dfbcfeba94f8b00e7dbfcc6c60818d332e633d100e0b9f` | `2f835d04f89e324c726870973ccbffce26475ea45f04893f056eff7c243259af` |

- `frontend/lib/src/features/stock/widgets/chart_controller.dart` is **untouched**:
  SHA-256 recomputed post-repair = `3ae015790af36256fbfdf05c64738a0284e63b71bfb627cf0bbff6cf02d8737a`,
  byte-identical to the author-delivery recorded hash.
- `git diff --check` → exit 0 (clean, no whitespace errors).
- `git status --porcelain` unchanged in shape: only the pre-existing dirty
  backend baseline plus the same untracked paths as at delivery; no tracked
  frontend file modified, no commits/pushes.

---

## F1 — num→double compile error in `_buildVolumeStrip` (FIXED)

**Disposition: fixed at line 931 (was 928).** `num.clamp` returns statically
typed `num`; the result is now explicitly widened to `double` before being
passed to `Container(height: double?)`.

Exact edited lines (price_chart.dart:930–934):

```dart
              } else {
                final height =
                    ((volume / maxVolume) * 32).clamp(4.0, 32.0).toDouble();
                fill = Container(
                  height: height,
```

**Class-wide scan (fix the class, not just the site):** the whole file was
scanned for other `num`-typed values flowing into `double?` parameters.

- `grep -n '\.clamp(' price_chart.dart` → exactly **one** site, line 931
  (now `.toDouble()`). No other clamp exists in the file.
- `grep -nE '\.round\(\)|\.toInt\(\)|\.ceil\(|\.floor\(|\.abs\(\)|math\.'`
  → only `value.toInt()` at line 617 (int index use, not a `double?` param).
- Every `height:`/`width:`/`strokeWidth:`/`radius:` parameter receives either a
  literal (Dart converts integer literals to double literals in double
  context), `double.infinity`, a ternary of double literals, or the now-`double`
  `height` local (line 933). The only non-literal `double?` param sites are:
  `width: double.infinity` (line 341) and `height: height` (line 933).
- Conclusion: no bare `num` flows into a `double?` parameter anywhere in the
  file. Scan output quoted in this file; no silent hand-waving.

---

## F2 — scenario banner rendered while overlay toggle OFF (FIXED)

**Disposition: fixed at price_chart.dart:248–251.** The `toggleOff` case now
returns immediately and cannot reach the common render path that emitted
`overlay_badge`. The dashed projection lines and band were already gated on
`projectionGate == ProjectionGateState.visible` (chart_controller.dart:248) and
are unaffected.

Exact edited lines (price_chart.dart:246–253):

```dart
  Widget _buildProjectionBanner() {
    switch (_controller.projectionGate) {
      case ProjectionGateState.toggleOff:
        // Overlay toggle is off: no scenario banner, no projection UI, even
        // when a projection is present (CONTRACTS §7 overlay defaults off).
        return const SizedBox.shrink();
      case ProjectionGateState.visible:
        break;
```

Comment/code sync: the stale comment at the (former) line 316–317 — "Render
the scenario banner only when the overlay is actually on", which contradicted
the code — is replaced with a comment matching the post-fix flow
(price_chart.dart:319):

```dart
    // Gate is visible — the overlay toggle is on. Render the scenario banner.
```

Only `ProjectionGateState.visible` now falls through to the common path;
`toggleOff/none/stale/basisMismatch/noHistory` all return their own widgets.

---

## Test-fidelity gap — "overlay banner separates scenarios" (STRENGTHENED)

**Disposition: fixed in price_chart_test.dart:453–484.** The previous test
asserted `overlay_badge` absent before any pump following `setProjection`, so
the inspected tree still had a null projection and the assertion was vacuous.
The strengthened test now: sets the projection, **pumps** (the widget rebuilds
via `AnimatedBuilder(animation: _controller)` — `setProjection` ends in
`notifyListeners`, chart_controller.dart:410–414), asserts the badge AND the
banner text are absent while the toggle is still off, then enables the toggle
and asserts the badge appears.

Exact edited lines (price_chart_test.dart:459–473):

```dart
      await tester.pumpWidget(harness(controller));
      await tester.pumpAndSettle();
      controller.setProjection(freshProjection());
      await tester.pump();

      // Projection present but the overlay toggle is still off (defaults off,
      // CONTRACTS §7): no scenario banner. The pump above rebuilds the tree
      // with the projection set, so this assertion is non-vacuous — it fails
      // if the toggle-off case ever renders the banner.
      expect(find.byKey(const Key('overlay_badge')), findsNothing);
      expect(
          find.textContaining('Conditional scenarios — not observed prices'),
          findsNothing);
```

Fidelity argument: against the pre-repair source this new assertion pair
**fails** — the old `toggleOff` fall-through rendered the badge Column
(`overlay_badge`) with the "Conditional scenarios — not observed prices" text
whenever a projection was set, so `findsNothing` would not hold after the
pump. Against the repaired source it passes. The regression the reviewer
called invisible is now exercised.

---

## Static verification actually run (all exit codes real)

| Check | Command | Result |
|---|---|---|
| Whitespace/conflict markers | `git diff --check` | exit 0 |
| Clamp sites | `grep -n '\.clamp(' price_chart.dart` | 1 site (line 931, `.toDouble()` present) |
| num→double param flow | greps quoted above | only `double.infinity` + now-`double` `height` local |
| Controller untouched | `sha256sum chart_controller.dart` | matches author-delivery hash exactly |
| Post-repair file hashes | `sha256sum` both changed files | quoted in table above |
| Comment/code sync | `sed -n '316,320p'` | comment matches post-fix flow |

## Limitations — DEFERRED_TO_DEV_PC (no SDK on this host, honestly probed)

- No Dart/Flutter SDK exists on this server; the widget/controller suite was
  **not executed** and its green/red status is unknown. The strengthened test
  and the F1 type fix are verified as source structure + static argument-type
  scan only.
- `flutter analyze`, `flutter test` (including the strengthened 21-case suite),
  and any build remain Dev-PC checks.
- The static scan proves the clamp result is explicitly `double`; it cannot
  prove the absence of every conceivable type error — full analyzer output
  belongs to the Dev PC run.
- No runtime, release, or deployment acceptance is claimed or established by
  this repair under any circumstance.

## Per-finding summary

- **F1** — fixed (`.toDouble()` appended at the single clamp site; class-wide
  scan clean; static evidence quoted).
- **F2** — fixed (`toggleOff` returns `SizedBox.shrink()`; comment synced to
  code).
- **Test fidelity** — strengthened (pump after `setProjection`; badge + banner
  text asserted absent with toggle off; non-vacuous by construction).
- **N1/N2/N3** (non-blocking reviewer notes) — not addressed in this scoped
  repair; remain for the reviewer/human queue as the review stated
  ("do not gate").
