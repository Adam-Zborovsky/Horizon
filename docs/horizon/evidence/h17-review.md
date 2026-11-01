# H17 combined independent review — specification + quality

Reviewer: reviewer/zai-glm-5.3-flash (vendor-disjoint from author
worker/deepseek-v4-pro per orchestrator roster note 2026-11-01 10:25 UTC).
Review card: t_6c34a98b. Scope: the WHOLE H17 package delivered across
t_90250e8b (partial) + t_6d32cb97 (remainder). All source allowlists read-only;
this file and this review are the only writes.

**Verdicts: SPEC_PASS_SOURCE_ONLY — QUALITY_PASS_SOURCE_ONLY.** Every
unexecuted PC/runtime criterion is explicit in §6. Source-only acceptance is
not runtime or release approval; the Dev-PC gate remains operator-held.

## 1. Independent verification performed (not author self-report)

Real commands run by this reviewer on the workspace, this run:

| Check | Result |
|---|---|
| `sha256sum` of all 4 H17 artifacts + 12 frozen Flutter sources + 2 frozen Flutter tests (18 files) | **18/18 match** `DEV_PC_HANDOFF.md` §1 and `h17-author.md` §2 exactly |
| Byte sizes | 72,918 B / 22,936 B match author claims; 1,635 / 608 lines match |
| `MONGODB_URI=…placeholder… JWT_SECRET=…placeholder… node --test backend/test/research-end-to-end.test.cjs` | **exit 0 — 15/15 pass, 0 fail** (reproduced independently) |
| `node --test backend/test/*.test.cjs` (full aggregate) | **exit 0 — 264/264 pass, 0 fail** |
| Aggregate minus new suite (`ls backend/test/*.test.cjs \| grep -v research-end-to-end`) | **249/249 pass** — confirms the 249 + 15 = 264 arithmetic exactly |
| `git diff --check` | clean |
| `dart --version` / `flutter --version` | command not found — confirms DEFERRED_TO_DEV_PC is honest, not an excuse |
| `git status --porcelain \| grep -c '^ M'` | 13 modified tracked files — matches h17-author.md §7 pre-existing dirty baseline claim |
| Generated parts absence | `position_models.freezed.dart`, `position_repository.g.dart`, `research_models.freezed.dart`, `research_repository.g.dart` all absent; all four owning files carry `part` directives to them → the mandatory `build_runner` precondition in handoff §2 is real and coherent |
| `grep integration_test frontend/pubspec.yaml` | absent — handoff §4 correctly flags it as a Dev-PC prerequisite rather than silently editing an out-of-allowlist file |
| Brace/paren/bracket balance of `research_journey_test.dart` | balanced (0/0/0) — corroborates the author's static sanity check |
| Secret scan of the e2e suite | only harness auth tokens (`crypto.randomBytes`, `token-owner-a/b`, `'test-token'` in the Dart test); no credentials, no `.env` reads |

## 2. Review scope (1): the seven red-closed scenarios

All seven previously red tests (A3, A4, C3, C4, C6, C7, D1) are present,
green on my rerun, and carry **strong, specific assertions** — no weakened,
deleted or vacuous assertions found anywhere in the 15-test file:

- **A3** (l.884): exact status codes; deep-equal economics
  `{status: 'unavailable', reason: 'state_without_executed_economics'}`;
  leak-absence checks (`average_cost`, `lease_nonce`, `owner_id_internal`
  asserted absent from the correct surfaces); H11 repaired latest-wire
  separation (`last_success` vs `latest_attempt`); cross-owner reads are
  indistinguishable 404 denials; exactly three server-dated outlooks with
  `numeric_projection: null` (H07A held).
- **A4** (l.974): `INVALID_CANDIDATE_ECONOMICS` refusal before transition;
  revision-conflict 409; full deep-equal computed economics (100→150, PL 500,
  0.5, excluded adjustments); market-thesis deep-equal invariance across the
  cost edit with explicit failure messages; recomputed P/L (300, 0.25) after
  revision 3; immutable paginated history.
- **C3** (l.1212): dedicated starved input provider; run fails with
  `INSUFFICIENT_EVIDENCE`; **`modelClient.calls.length === 0` asserted** — no
  model call may burn on an empty context; zero assessments persisted.
- **C4** (l.1265): `limited` status; `missing_data` must include the injected
  gap (`transcript_coverage_missing`) with the assertion message "coverage
  gaps must be visible in the published assessment".
- **C6** (l.1353): shared persisted store; exact recovery tally
  `{stalled: 1, superseded: 0}`; `RUN_STALLED` error code; replay of the
  stalled orphan returns `replayed: true` with no duplicate claim or
  assessment (repository asserted empty).
- **C7** (l.1391): concurrent owned transition + fresh revision-2 queue;
  stale pipeline finishes to `superseded` with **zero stale assessments
  persisted**; fresh run is the only published result (history deep-equal
  `[2]`).
- **D1** (l.1572): two configured instruments served by one surface; MAIN
  complete, SECOND `limited` with `news_coverage_missing` asserted visible
  ("not silently dropped"); both instruments accounted for in the owner list
  and in observed history (`data_status: 'available'` for both).

Closure mechanism: the author documents (h17-author.md §1) that the reds were
closed **test-side by mirroring the accepted H01–H15 backend interfaces in
fixtures/assertions, with zero `backend/src/**` edits** — the documented
test-adjudication pattern. The backend is canonical and frozen; the current
assertions consume the accepted wire shapes (economics status per H09 N1,
top-level `getLatest` per H11). Verification boundary stated honestly: the
run-268 red version (71,733 B) is not retained on disk, so red→green is
verified via (a) the current assertions' strength read line-by-line, (b) the
author's run log, and (c) the controller's independent reruns — no evidence
of assertion weakening exists, and the current assertions are demonstrably
harder than minimum.

## 3. Review scope (2): DEV_PC_HANDOFF.md accuracy

Verified against disk: §1 hashes 18/18 exact; §2 generated-parts absence
confirmed real (`part` directives present, targets absent) and the generator
order (pub get → build_runner --delete-conflicting-outputs → analyze) is
mandatory and correctly sequenced; §4 `integration_test: {sdk: flutter}` is
genuinely absent from pubspec and is a first-party SDK package (no third-party
license or renderer change; chart remains fl_chart only); §5 requires exact
SHA-256 + size + mtime + `flutter --version` / `flutter doctor -v` identity +
build stdout tail — "do NOT substitute plausible values" is stated; §6
transfer safety forbids git clean/reset and requires hash verification before
§2. Device selection and Wear (minSdk 30, `-t lib/main_wear.dart`) are
covered. Three non-blocking notes in §5 below.

## 4. Review scope (3): h17-author.md evidence integrity

All four artifact hashes and both byte/line counts match disk exactly. All
commands/exits in §3 reproduce identically under my own invocation (15/15,
264/264, diff-check clean, dart/flutter absent). The 249-vs-264 aggregate
distinction is stated and independently confirmed (249/249 minus-suite run).
The live script `backend/scripts/test-research-workflow.cjs` was not run —
correctly declared. Limits (§6) are explicit and accurate: Flutter runtime
DEFERRED_TO_DEV_PC, integration_test dependency not added, H13 PriceChart
unwired (truthful unavailable slot, carried from H15/B), evidence detail
endpoint not mounted. No fabrication found.

## 5. Findings

### Blocking

None.

### Non-blocking (record for the Dev-PC gate; no source repair required)

1. **`flutter drive` path needs an absent harness.** DEV_PC_HANDOFF.md §3
   offers `flutter drive --driver=test_driver/integration_test.dart`, but
   `frontend/test_driver/` does not exist in the snapshot. The primary path
   (`flutter test integration_test/research_journey_test.dart -d <device>`)
   is unaffected. The PC operator must either create the standard
   `test_driver/integration_test.dart` harness or use the primary path only.
2. **Device-id discovery not spelled out.** §3 uses `-d <device-id>` but does
   not include the `flutter devices` enumeration step to obtain the id.
   Obvious to a Flutter operator; noted for completeness.
3. **Signing/build-type limitation unstated.** §5 records artifact identity
   but does not state the amendment's constraint that release signing remains
   operator-controlled (a `--release` build without a signing config is not
   distribution-signed). Per the canonical package supersession the required
   content is "APK artifact/hash requirements", which §5 delivers; this note
   closes the gap at the gate.

### Verification boundary (honest limitation)

The run-268 red test version is not retained on disk, so the red→green
conversion cannot be diffed file-against-file; verification rests on the
line-by-line strength of the delivered assertions (§2) plus author and
controller logs. No evidence of weakening was found. The 13 modified tracked
files match the pre-existing dirty baseline described across H15/H15B review
evidence; no backend/src edit attributable to H17 was found.

## 6. Acceptance criteria disposition

| Criterion | Disposition |
|---|---|
| No critical security/data correctness/continuity/chart regressions remain | SATISFIED at source level — leak-absence, cross-owner denial, revision-conflict, supersession, thesis-immutability, OHLC/truthful-degradation and no-duplicate-recovery assertions all present and green on rerun |
| Absent SDK/device/build access is explicitly blocked, never substituted with plausible output | SATISFIED — dart/flutter confirmed absent and recorded as such in all three artifacts; every Flutter check marked DEFERRED_TO_DEV_PC, never PASS |
| All configured tickers are accounted for, not only AMD; coverage gaps are visible | SATISFIED at source level — D1 exercises two configured instruments through one surface with a visible, asserted coverage gap; no single hardcoded instrument anywhere in the suite. (Live-config accounting is inherently runtime/live-data territory, operator-held.) |

## 7. SPEC verdict — SPEC_PASS_SOURCE_ONLY

All canonical-package steps deliverable without an SDK are delivered and
independently verified (§1–§4): hermetic backend suite authored and green
(15/15, reproduced), full journey exercised including failure injection
(provider, model/schema, evidence starvation, deadline stall, restart
recovery, concurrent edit, callback replay/source injection), multi-instrument
coverage, test-report.md accurate, DEV_PC_HANDOFF.md complete and hash-exact.
No production/live-data access; Dart execution never claimed; no source
repairs by the reviewer; baseline preserved (13 pre-existing modified files,
diff-check clean). Deferred (explicit): flutter analyze/test, widget/device
runs, a11y evidence, web/mobile/Wear builds, APK artifact/hash, generated-part
regeneration, integration_test dev-dependency addition — all Dev-PC gate.

## 8. QUALITY verdict — QUALITY_PASS_SOURCE_ONLY

Test fidelity is high: assertions are exact (status codes, deep-equal wire
shapes, error codes, leak-absence, tally equality), fixtures hermetic and
synthetic (2030 clock, synthetic instruments — no invented market data,
observed/scenario data kept separate), the composition surface is the real
`createApp` + `composeAutomationSurface`, and security-relevant behavior
(lease nonce scoping, cross-owner indistinguishable denial, input redaction)
is asserted, not narrated. Evidence discipline: hashes, exits and limits are
all reproducible; no secrets; no backgrounding; no out-of-allowlist writes.
Maintainability: stage-per-backend-test mapping is documented in both suites;
handoff is self-contained. Non-blocking quality notes are in §5. No renderer
replacement; fl_chart retained; no new third-party dependency.

Both verdicts pass at source level. This completes the last server-side
source review; the board proceeds to the operator-held Dev-PC gate.
