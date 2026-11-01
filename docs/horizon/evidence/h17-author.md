# H17 author evidence — full integration, failure injection and build evidence

Status: **AUTHOR DELIVERY ONLY — backend suite green, Flutter execution
DEFERRED_TO_DEV_PC.** Delivered across three runs: t_90250e8b (run 268, budget
exhaustion), t_6d32cb97 attempt 1 (run 271, budget exhaustion) and this run
(272). The combined specification/quality review is the separate card
t_6c34a98b; this file is the author handoff to it. No Flutter runtime check is
claimed as PASS from source inspection anywhere in this file.

Workspace: `/home/ubuntu/apps/Horizon` (dirty main baseline preserved; no
branch change, no commit/push, no source cleanup). Node runtime: `v22.22.2`.
Dart/Flutter SDK on this host: **absent** (`dart --version` / `flutter
--version` → command not found).

## 1. Timeline of the three runs

| Run | Card | Outcome | Contribution |
|-----|------|---------|--------------|
| 268 | t_90250e8b | budget exhausted 60/60 @ 10:19 UTC | authored `backend/test/research-end-to-end.test.cjs` (71,733 B, 15 tests: 8 pass / 7 red) |
| 271 | t_6d32cb97 | budget exhausted 60/60 @ 10:22 UTC | converted the 7 red tests to green (test-side, backend canonical); no docs written |
| 272 | t_6d32cb97 (this) | complete | verified green, authored the 3 remaining docs + integration test |

Run 268's delivered file was re-verified on this run's start: it had already
been superseded by run 271's green version on disk. The 7 tests that were red
at run 268 — A3 (candidate research journey), A4 (owned transition → economics
/ cost edit → thesis unchanged + P/L recomputed), C3 (unavailable evidence
fails before model call), C4 (partial coverage → limited assessment with
visible gaps), C6 (restart recovery stalls orphans without duplicates), C7
(concurrent position edit supersedes the in-flight run), D1 (every configured
instrument gets its own bound run/assessment) — are now green. The fix
direction was the card-mandated one: **mirror the accepted backend interfaces
in the test-side fixtures/assertions, never mutate backend source** (no
`backend/src/**` file was edited in any run; the backend is canonical).

## 2. Final artifacts and hashes (this run)

```text
9f8e9ae253875e3be14ff853600630290142ea208516ebb1e4b2ca6e1d18bbc8  backend/test/research-end-to-end.test.cjs          (72,918 B, 1,635 lines)
4987729534f3ee382acb5f3cf19be007f6b086f28be765e1adc5fdd612c8b9bc  frontend/integration_test/research_journey_test.dart (22,936 B, 608 lines)
9b34b50fb158cf8dca863fdd0140c0c2f2efb843fa1710116749cf817a85c376  docs/horizon/evidence/test-report.md
fb54ef6de32210ed2bfad542cedc80c03f83ec112fe6cd1f5ec66a47c1d6e79e  docs/horizon/DEV_PC_HANDOFF.md
```

## 3. Commands and exits (real output, this run)

```text
MONGODB_URI='mongodb://placeholder-url-shaped.invalid/db' \
JWT_SECRET='placeholder-jwt-secret-for-zod-module-load-only' \
node --test backend/test/research-end-to-end.test.cjs
  → exit 0, 15/15 pass, 0 fail

MONGODB_URI='mongodb://placeholder-url-shaped.invalid/db' \
JWT_SECRET='placeholder-jwt-secret-for-zod-module-load-only' \
node --test backend/test/*.test.cjs
  → exit 0, 264 tests, 264 pass, 0 fail   (249 pre-H17 + 15 new)

git diff --check                         → exit 0 (whitespace clean)
dart --version / flutter --version       → command not found (recorded, not claimed)
```

> Aggregate discipline (orchestrator note): the `249/249` pre-H17 aggregate
> EXCLUDES this suite; the post-H17 aggregate is `264/264`. The live script
> `backend/scripts/test-research-workflow.cjs` was NOT run.

## 4. What each artifact delivers

### 4.1 `backend/test/research-end-to-end.test.cjs` (15/15 green)

Hermetic composed-application integration over one shared runs store
(in-memory repositories + scripted model clients; no MongoDB, no network, no
scheduler, no live model, no secrets). Exercises the complete surface
`createApp` + `composeAutomationSurface` end-to-end: candidate add → research
run → owned transition → cost edit → chart ranges → snapshot/source/forecast
reads → failure injection (provider, model/schema, evidence starvation,
deadline/timeout stall, restart recovery, concurrent position edit, callback
replay/source injection) and multi-instrument ticker coverage (D1). Interface
consumption is the accepted H01–H15 set listed in the card body; economics
status follows H09 review N1 (authoritative), run-state projections follow the
H11 repaired top-level `getLatest` wire.

### 4.2 `frontend/integration_test/research_journey_test.dart` (source only)

Device-level integration test (`integration_test` package) driving the
accepted H15B `StockDetailScreen` flow through the full journey against a
hermetic scripted MockClient transport: candidate → queue run (Idempotency-Key
asserted) → owned transition → cost edit (PATCH `{expected_revision, changes}`
envelope asserted; comparable P/L explicitly never derived — H09 N1) → limited
assessment with visible gaps → failed/stalled attempt separated from prior
success → no-tracked-position truth. Wire fixtures are hand-built from the
traced canonical wire and parsed through the strict H11 models. **Not
executed** — no SDK on this host. Balance check (braces/parens/brackets) and
no-library-private-ref greps passed; that is a static sanity check, not a
compile.

### 4.3 `docs/horizon/evidence/test-report.md`

15-test inventory with contract mapping, exact commands/exits, the
`264/264` vs `249/249` aggregate distinction, the mandatory generator
prerequisite, and the deferred-not-claimed boundary.

### 4.4 `docs/horizon/DEV_PC_HANDOFF.md`

Exact source snapshot hashes, the mandatory generator order (`dart run
build_runner build --delete-conflicting-outputs` — the H11 position/research
`.freezed.dart`/`.g.dart` parts are **absent on disk** and must be generated
before any Flutter command), the deferred-criteria list, the one-line
`integration_test: {sdk: flutter}` dev-dependency prerequisite, safe transfer
steps, and APK artifact/hash requirements.

## 5. Commands/exits across both prior runs (recorded, not re-derived)

Run 268 delivered the initial 15-test file under the same command (8 pass /
7 red) before its iteration budget was exhausted at 10:19 UTC — a budget
failure, not a correctness failure. Run 271 finished the red→green conversion
and re-ran the same command to 15/15 before its own budget was exhausted at
10:22 UTC (the `worker_result` recorded "The green suite is the hard, verified
unit"). This run re-ran the command and confirmed 15/15 exit 0 on the file
currently on disk (hash §2). No run ran the live workflow script, contacted a
live API/model/MongoDB, or read `.env`/credential stores.

## 6. Limits (explicit — not claimed)

- **Flutter runtime verification is DEFERRED_TO_DEV_PC**: compile, analyze,
  widget/device tests, a11y, web/mobile/Wear build, APK — none performed here,
  none claimed as PASS from source inspection. Source-only acceptance is not
  runtime/release approval.
- **`integration_test` dependency not yet in `pubspec.yaml`** (outside this
  card's write allowlist): flagged as a Dev-PC prerequisite, not silently
  added.
- **H13 `PriceChart` remains unwired** into the stock detail chart slot (per
  H15/H15B evidence — needs an instrument-resolved market-history loader); the
  slot renders its truthful unavailable state, and the panels never wait for
  chart completion.
- **Evidence detail endpoint** (`GET /research/evidence/:id`) is not in the
  mounted route surface, so `onOpenEvidence`/`onViewSnapshot` stay null and
  evidence chips render as plain text (carried from H15B).
- Backend `/automation/research` production activation is operator-provisioning
  territory (frozen backend), unchanged.

## 7. Contract adherence

- Secrets: none in output, logs, fixtures or this file; no `.env` or
  credential-store reads. The only token in the Dart test is the static fixture
  string `'test-token'`.
- Backend source files: zero modifications across all three runs (backend is
  canonical; only `backend/test/` was written). The 13 modified tracked files
  in `git status` are the pre-existing dirty baseline (frozen H15 backend +
  briefing/scheduler), untouched.
- No ports/DNS/tunnel changes; no backgrounding; no git mutations; no
  production operations; no nested delegation; no worker-created cards; no new
  dependency beyond the first-party `integration_test` SDK package (flagged, not
  added); no hand-authored generated files; no `num.clamp()` usage; no
  renderer replacement (chart remains `fl_chart` only).
