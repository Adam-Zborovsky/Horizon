# H07 — Repair F1: metric registry frozen-record storage

- Task: t_56142c25 (scoped repair); repairs finding F1 from docs/horizon/evidence/h07-review.md (QUALITY_FAIL_SOURCE, single blocking finding)
- Author: worker (zai); reviewer deepseek (vendor-disjoint per release note) — returns to existing reviewer t_68e6a5b2 for targeted re-review
- Date: 2026-10-31
- Scope: F1 only. Non-blocking observations B–E from the review are explicitly NOT addressed (not in scope for this repair).
- Baseline: HEAD `9fbb26b` unchanged; no commit/push/history rewrite; existing dirty/untracked baseline preserved. Files are untracked in the working tree, consistent with the pre-existing delivery state.

## F1 — what was wrong

`createMetricRegistry().register` (metrics.js) validated via `createMetric` — which returns a frozen, sanitized record — then stored and returned the caller's original mutable object, discarding the frozen copy. Post-registration mutation of the original leaked into the registry, and `get`/`list` handed out live mutable references.

## Change 1 — red test first (backend/test/research-metrics.test.cjs)

Added regression test `metric registry stores and returns the frozen validated record, never the caller mutable original` (test file ~line 279): registers a raw (non-frozen) mutable object, then mutates the original (`value = 999`, `currency = 'EUR'`, pushes into `input_evidence_ids`) and asserts:

- `Object.isFrozen(returned) === true` and `Object.isFrozen(registry.get('metric-raw')) === true`
- stored/returned values are the validated ones (`value 0.3`, `currency 'USD'`, ids unchanged) — the caller's mutations do not leak
- `returned === registry.get('metric-raw')` (registry stores and returns the same frozen record)
- every record from `list()` is frozen

Also adjusted the existing registry test's identity assertion per the reviewer's F1 note: `registry.get('metric-a') === first` (identity) → `assert.deepEqual(registry.get('metric-a'), first)` plus `Object.isFrozen` check, because `register` now stores the re-validated frozen record rather than the exact object passed in.

### RED run (before the source fix)

```
node --test backend/test/research-metrics.test.cjs
  -> # tests 24  # pass 23  # fail 1

not ok 17 - metric registry stores and returns the frozen validated record, never the caller mutable original
  location: 'backend/test/research-metrics.test.cjs:279:1'
  failureType: 'testCodeFailure'
  error: |-
    Expected values to be strictly equal:
    false !== true
  code: 'ERR_ASSERTION'
  stack: TestContext.<anonymous> (backend/test/research-metrics.test.cjs:299:10)
```

Line 299 is `assert.equal(Object.isFrozen(returned), true)` — the register return value was the unfrozen original, exactly F1's independently reproduced symptom. Red is real, not a setup failure (the other 23 tests passed).

## Change 2 — the fix (backend/src/features/research/metrics.js)

`register` (~lines 350–357) now stores and returns the frozen validated record:

```js
register(metric) {
  const validated = createMetric(metric);
  if (metricsById.has(validated.id)) {
    throw new RangeError(`Metric id '${validated.id}' is already registered`);
  }
  metricsById.set(validated.id, validated);   // was: metric
  return validated;                           // was: metric
},
```

`has`/`get`/`list`/`size` unchanged — they already read from the same Map, so they now hand out frozen records.

### GREEN run (after the fix)

```
node --test backend/test/research-metrics.test.cjs
  -> # tests 24  # pass 24  # fail 0

node --test backend/test/*.test.cjs        (full aggregate, all 7 backend suites)
  -> # tests 126  # pass 126  # fail 0     (prior accepted aggregate 125/125 + 1 new regression test)

git diff --check
  -> clean, exit 0
```

Environment: host node v22.22.2, hermetic offline — no live APIs, credentials, DB, installs, backgrounding. Commands run foreground.

## SHA-256 of changed files

```
2730600850491270f878703c0f65c06d1d1424fc8377ebad7981f17d44cb3d1b  backend/src/features/research/metrics.js
bf411b7bf09f927b52792e2140954b66f3727ae674e7326c26c5582e6682b347  backend/test/research-metrics.test.cjs
9206f594052a0326d0ae20295d334f7fac70aade3550d92b05b259ca1eb7127e  backend/test/fixtures/research/metrics-fixtures.json  (UNTOUCHED — matches h07-review.md hash)
```

Only the two allowlisted files changed; the fixture is byte-identical to the reviewed delivery. `git diff --check` clean. No other files touched.

## Limitations / disclosures

- Repair scope is F1 only; review notes B–E remain open, non-blocking, for the reviewer's discretion.
- `register` re-validates via `createMetric`, so registering an already-frozen record returns a new frozen copy with equal fields (deep-equal, not reference-identical) — this is the exact behavior change the F1 note prescribes, and the test asserts field equality accordingly.
- Source-only repair: no runtime/release acceptance, no Flutter/PC checks (DEFERRED_TO_DEV_PC), no numeric_projection change (H07A still held).
- Host node version does not establish deployment-runtime compatibility.
