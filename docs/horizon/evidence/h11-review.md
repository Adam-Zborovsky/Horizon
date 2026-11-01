# H11 — Independent combined specification and quality review

Reviewer: reviewer / deepseek-v4-pro. Author: zai / glm-5.3-flash. Vendors are disjoint
(DeepSeek vs Z.ai). Date: 2026-10-31. Workspace: /home/ubuntu/apps/Horizon (dirty main
baseline; no branch change, no commit/push, no source edit — review-only).

## 1. Scope and method

Reviewed the seven H11 canonical files against docs/horizon/CONTRACTS.md, SPEC.md, and the
executable backend schemas / services they claim to mirror:

- `backend/src/features/research/contracts.js` (Zod schemas — canonical shape source)
- `backend/src/features/positions/position.routes.js` + `position.service.js` (live positions wire)
- `backend/src/features/market/market.routes.js` + `market.service.js` (H15A history wire)
- `backend/src/middleware/error.middleware.js`, `backend/src/app.js`

Independently re-verified, not trusting author self-report:
- **Hashes:** `sha256sum` over all seven files matches the h11-author.md evidence table
  exactly (7/7). No hash drift between evidence file and disk.
- **Baseline preserved:** `git rev-parse HEAD` = `9fbb26b5519889e0816720530dd60c204dda2bf2`,
  branch `main`. `git status --short` shows only the pre-existing dirty baseline plus the
  new untracked H11 paths (and the other lanes' untracked dirs). No reset/clean/commit.
- **No generated files hand-authored:** no `.freezed.dart` / `.g.dart` present under
  `positions/`, `market/`, or `research/`; the `part` directives point at build_runner
  outputs that do not yet exist. Consistent with DEFERRED_TO_DEV_PC.
- **No new dependency:** `frontend/pubspec.yaml` already declares `freezed_annotation`,
  `riverpod_annotation`, `http` (and dev `freezed`, `riverpod_generator`); `fl_chart ^1.1.1`
  unchanged. Nothing new introduced.
- **No secrets:** grep over all seven files shows only the explicit non-secret literal
  `fixture-token-not-a-secret` used to assert header construction. No credential, password,
  API key, or real bearer token. `.env`/`.env.example` exist but were NOT read.
- **Toolchain:** `flutter` / `dart` are `command not found` on the host (exit 127). All
  analysis/generation/test/device/APK checks are DEFERRED_TO_DEV_PC and are not claimed.

## 2. SPECIFICATION verdict

### Verdict: **FAIL (blocking) — not SPEC_PASS_SOURCE_ONLY**

The market and research model layers faithfully mirror their backend contracts, but the
**positions lane does not mirror the existing backend wire shape on three counts**. These
are static source-vs-source divergences — visible without any Flutter toolchain — so they
fail at source-only scope, not at runtime.

#### B1 — GET /positions response envelope mismatch (blocking)

- Backend `position.routes.js:43` returns `res.status(200).json({ positions })` — a
  `{positions: [...]}` wrapper.
- Flutter `position_repository.dart:112-118` accepts only a bare array or `{data: [...]}`:
  ```dart
  final List<dynamic> items = switch (decoded) {
    List() => decoded,
    {'data': final List items} => items,
    _ => throw ContractFormatException('GET /positions: expected an array of positions'),
  };
  ```
- `{positions: [...]}` matches neither arm → the client throws on the real backend
  response. The `{data: ...}` convention was borrowed from `briefing_config_repository.dart`
  (a different legacy endpoint) and does not apply to the new `/positions` route.

#### B2 — Position `instrument_id` (string) vs backend `instrument` (object) (blocking)

- Backend `position.service.js:236-253` `serialize()` emits `instrument: structuredClone(doc.instrument)`
  — a nested identity object `{instrument_id, symbol, exchange, currency, provider_symbol}`.
  There is no top-level `instrument_id` field on a serialized position.
- Flutter `position_models.dart:446` requires `instrumentId: requireOpaqueId(json, 'instrument_id')`
  — a top-level string. `Position.fromJson` therefore throws on every backend position.
- Write direction is broken too: `PositionWrite.toJson()` (`position_models.dart:516`) emits
  `'instrument_id': instrumentId`, but `position.service.js create()` calls
  `validateInstrument(input.instrument)` and expects `input.instrument` to be an object
  (it rejects `INVALID_INSTRUMENT` when `instrument` is absent). The backend itself uses
  nested `instrument`, not `instrument_id`, in `ALLOWED_FIELDS` (`position.service.js:23-27`).

Note the CONTRACTS ambiguity that caused this: §2's field table lists `instrument_id` as a
Position field, while §1 defines instrument identity as the full object
`{instrument_id, symbol, exchange, currency, provider_symbol}`. The backend followed §1;
the Flutter model followed §2's literal field name. CONTRACTS §1's own rule ("API
request/response shapes are validated in backend code and mirrored by typed Flutter models")
makes the backend the reference, and H11 step 1 required tracing the existing backend before
authoring — which did not happen for `position.service.js`/`position.routes.js`.

#### B3 — PATCH /positions/:id request body shape (blocking)

- Backend `position.routes.js:60` reads `const { expected_revision: expectedRevision, changes } = req.body`
  and `position.service.js:356-361` requires `changes` to be a nested object of changed fields.
- Flutter `position_repository.dart:134-137` sends `patch.toJson()` — a flat body
  `{instrument_id, state, ..., expected_revision}` with no `changes` wrapper.
- The backend would reject it as `INVALID_INPUT` ("changes must be a JSON object"), and the
  field names also disagree (`instrument_id` vs `instrument`).

### What passed specification review (market + research layers)

- **MarketBar / HistoryResponse** (`market_models.dart`) mirror `contracts.js`
  `marketBarSchema`/`historyResponseSchema` field-for-field, including null-vs-zero volume,
  positive finite OHLC with `low <= min(open,close) <= max(open,close) <= high`, ascending
  + unique bars by `session_date|time`, `<=5000` bars, `unavailable` ⇒ empty bars + machine
  reason, stale ⇒ never `realtime`, `available_ranges <= 6`. `MarketRepository` parses the
  body directly, which correctly matches `market.routes.js:20` (`res.status(200).json(response)`).
- **Research models** (`research_models.dart`) mirror §4–§8: claim reference uniqueness,
  outlook triple (1/2/3), `calendarTargetDate` month-end clamping (incl. year-10000 rejection),
  state/action compatibility, projection kind rules, checkpoint exclusive-field rules, and
  run-state invariants (queued/running/terminal/succeeded-limited/failed-stalled/superseded,
  retry ≤ 2). These are faithful transcriptions of the Zod `superRefine` rules.
- **Strictness is real:** parsers throw `ContractFormatException` on malformed known fields
  and never repair; additive unknown fields are ignored (forward-compatibility). Verified by
  reading the validators, not by running the suite (no Dart toolchain).

## 3. QUALITY verdict

### Verdict: **FAIL (blocking) — not QUALITY_PASS_SOURCE_ONLY**

Internal engineering quality is high (see below), but contract fidelity and correctness are
core quality criteria and they fail on the positions lane: the delivered
`Position`/`PositionWrite`/`PositionRepository` cannot interoperate with the backend that
already exists in the workspace (B1–B3). The test suite does not catch this because its
fixtures encode the *author's* wire assumptions rather than the backend's.

#### Test-fidelity finding (reinforces B1/B2)

`frontend/test/research_models_test.dart`:
- `ownedPositionFixture()` (line 25) uses a top-level string `'instrument_id'`, not the
  backend's `instrument` object.
- `getPositions` test (line 803) mocks `{'data': [ownedPositionFixture()]}` — the `{data}`
  envelope, not the backend's `{positions: [...]}`.

So the 37 tests are internally consistent with the (incorrect) model and will pass against
the author's assumptions while the real client fails against the backend. The test count is
accurate (independently counted: 8 groups / 37 cases), but "test fidelity to the actual
backend contract" fails on the positions lane.

#### What is genuinely strong (quality)

- **Strict validating parsers, no silent repair** — every known field is type/range/format
  checked; decimal-string, ISO currency, UTC timestamp, session-date, opaque-ID, bounded-text
  rules match `contracts.js` regexes and limits exactly.
- **Typed error surface** — `ApiException` carries `statusCode`, `code`, `message` and never
  leaks upstream tokens/raw payloads.
- **Cancellation** — injectable `http.Client` + `close()`; `ClientException` surfaced, never
  swallowed; tested with a blocking fake.
- **Credential hygiene** — `Authorization: Bearer` attached only when a token exists; no
  owner/credential written into payloads; no secret in fixtures.
- **Auth convention correctly traced** — `AuthRepository.getToken()` (SharedPreferences
  `auth_token`), `authRepositoryProvider`, `ApiConfig.baseUrl` all exist and are used as the
  author claimed. No invented `api_client.dart`.
- **Generated files** — none hand-authored; only `part` directives, no fabricated outputs.

## 4. Adjudication / non-blocking notes

These are not blocking for a source-only gate but must be resolved before runtime.

- **A1 (author-flagged):** `/research/positions/:id/latest` parsed as `{assessment, run}` and
  `/assessments` as `{assessments, next_cursor}`, with `cursor` sent as a query param. Derived
  from CONTRACTS §9 prose; **no backend research routes exist yet** (verified: no
  `research.routes.js`), so these are assumptions to reconcile when H09/H12/H14 land.
- **A2 (not author-flagged):** `queueRun`/`getRun`/`getEvidence` parse the response body
  directly as the run/evidence object (no `{data}`/`{run}` unwrap) via `_requireObject`.
  Same "shape is an assumption" caveat as A1; reconcile alongside it.
- **A3 (minor):** `ApiException.fromResponse` reads only the global error envelope
  `{success, error: {code, message}}` (`error.middleware.js`). `position.routes.js:72-78`
  forwards typed service errors as `{code, message}` (no `success`/`error` wrapper), so
  position-route codes (e.g. `REVISION_CONFLICT`) would surface as generic `HTTP_409`.
  Not a new defect H11 introduced, but it compounds the positions-lane fidelity gap.
- **N1 (minor):** Flutter `HistoryResponse` applies no `<=100` cap to `warnings` (backend
  caps it); harmless leniency, backend remains authoritative.
- **N2 (hygiene):** the author's handoff *comment* carried two stale hash strings (orchestrator
  flagged). The evidence *file* is self-consistent with disk; non-blocking but the author
  should keep one authoritative hash table.

## 5. DEFERRED_TO_DEV_PC (explicit, unexecuted)

All of the following are unexecuted on this host (`flutter`/`dart` exit 127) and are NOT
passed by this review: `dart run build_runner build --delete-conflicting-outputs`,
`flutter analyze`, `flutter test` (the 37-case suite has never run), any device/APK build,
and any runtime behavior. Source-only acceptance here is not runtime or release approval.

## 6. Decision required

The canonical **positions wire shape** must be adjudicated before H11 can pass: either the
backend `serialize()`/routes change to emit `{positions: [...]}` with a top-level
`instrument_id` and a flat PATCH body (matching CONTRACTS §2's literal field names and the
current Flutter model), or the Flutter `Position`/`PositionWrite`/`PositionRepository` change
to consume `{positions: [...]}`, nested `instrument`, and `{expected_revision, changes}`.
H11 step 1 ("trace existing conventions, never invent") and CONTRACTS §1 ("mirror the
backend") point to the Flutter side as the one to repair, but this is an orchestrator/adjudication
call — the two lanes are owned by different cards.

## 7. Targeted re-review — 2026-10-31 (post-repair t_afe44134)

Scope: independently re-verify B1–B3 and A3 against the repaired source, confirm the
rewritten position tests encode the backend wire, and confirm the A1/A2 research-envelope
assumptions are preserved as pending. No Dart toolchain on the host, so every verification
below is static source-vs-source against `backend/src/features/positions/position.routes.js`
/ `position.service.js` (the adjudicated canonical reference).

Independent verification performed this run (not trusting author self-report):
- `sha256sum` over the three repaired files matches the h11-repair.md §4 table exactly
  (3/3): `position_models.dart` `9a379055…`, `position_repository.dart` `bad936a3…`,
  `research_models_test.dart` `b3ae0465…`. The four untouched files still match the
  h11-author.md table exactly (4/4) — market/research layers are unchanged, no regression.
- HEAD unchanged `9fbb26b5519889e0816720530dd60c204dda2bf2`, branch `main`, dirty baseline
  preserved (no reset/clean/commit).
- No `.freezed.dart`/`.g.dart` under `positions/`, `market/`, or `research/` (only
  pre-existing other-lane outputs). `frontend/pubspec.yaml` unchanged — no new dependency.
- No secret in the repaired files: only `fixture-token-not-a-secret`; the remaining
  token/tokenProvider hits are plumbing, not credentials.

### B1 — {positions:[...]} envelope — RESOLVED
`position_repository.dart:124-128` now matches only `{'positions': final List items}` and
throws `ContractFormatException` otherwise; the bare-array and `{data:[...]}` arms are gone
(confirmed: no `{data}` string remains in the file). Backend `position.routes.js:43` returns
`{positions}`. Test `rejects non-{positions} envelopes` (research_models_test.dart:917-937)
asserts `{data:[...]}` and bare-array bodies throw. Matches the backend wire.

### B2 — nested PositionInstrument (both directions) — RESOLVED
`PositionInstrument` (position_models.dart:398-447) parses the nested `instrument` object
and serializes `{instrument_id, symbol, exchange, currency, provider_symbol}` — the exact
key set `validateInstrument()` accepts. `Position.fromJson` reads `json['instrument']`
(line 503); `PositionWrite.toJson()` emits `'instrument': instrument.toContractJson()`
(line 578) with no top-level `instrument_id` and no `expected_revision` (the only
`instrument_id` literals are the nested object's own key at lines 428/441). Fixtures
(`ownedPositionFixture`, `legacyPositionFixture`, `instrumentFixture`,
`backendSerializedOwnedPosition`) carry the nested object; a malformed-instrument test
(402-423) rejects a missing `symbol` and a lowercase `usd` currency. Write strictness is
asserted at 487-517 (no top-level `instrument_id`/`expected_revision` in the create body).

### B3 — {expected_revision, changes} PATCH body — RESOLVED
`patchPosition` (position_repository.dart:156-159) sends
`{'expected_revision': …, 'changes': patch.toJson()}`; `changes` carries ALLOWED_FIELDS
names (`instrument`, never `instrument_id`). A missing `expected_revision` throws an
`ArgumentError` before any request (test 1030-1051). Matches `position.routes.js:60` and
`position.service.js:356-361`.

### A3 — flat error envelope — RESOLVED
`ApiException.fromResponse` (position_repository.dart:41-71) now parses a flat
`{code, message}` body when the global `{success, error:{…}}` wrapper is absent, so
position-route typed errors surface with their real code. Test 973-994 maps
`{code: REVISION_CONFLICT}` → `ApiException(409, REVISION_CONFLICT)` with the message.

### A1/A2 — research envelope assumptions — PRESERVED, PENDING
Confirmed no `backend/src/features/research/*.routes.js` exists (the dir holds only
`contracts.js`, `evidence.model.js`, `evidence.service.js`, `metrics.js`, `providers/`),
so there is no backend to reconcile against yet. `research_repository.dart` is unchanged
(hash matches h11-author.md) and still encodes the A1/A2 shapes: `/latest` →
`{assessment, run}`, `/assessments` → `{assessments, next_cursor}` with `cursor` as a
query param (A1), and `queueRun`/`getRun`/`getEvidence` parsing the body directly (A2).
These remain ASSUMPTIONS-PENDING-H09/H12/H14, recorded in h11-author.md §Limitations and
h11-repair.md §2. Non-blocking (no backend reference exists); note the marker lives in the
evidence files, not as an inline source comment.

### Test fidelity — encodes the backend wire
The position fixtures/tests now mirror `serialize()`/route output field-for-field (nested
`instrument`, `average_cost.basis`, `original_thesis: ''`, `review_conditions: []`,
`risk_context: null`, one additive unknown field), and the envelope/PATCH/error tests assert
the backend shapes rather than the author's prior assumptions. Suite grew 37 → 43 cases
(8 groups). No Dart toolchain, so the suite remains unexecuted.

### New minor notes (non-blocking)
- **N3** — repair evidence's "MARKED" for A1/A2 is loose: no literal `ASSUMPTIONS-PENDING`
  string is in the Dart source; the assumptions are recorded in the evidence files. Research
  files correctly left unmodified.
- **N4** — `PositionInstrument.fromJson` is stricter than `validateInstrument()` on parse:
  `requireOpaqueId` caps `instrument_id` at 160 chars and `requireBoundedText` caps `symbol`
  at 4000, while the backend only requires non-empty strings. Safe direction (backend ids
  are `pos-<uuid>` / `legacy-ticker-*`), but h11-repair.md's "bounded-text symbol …
  matching the backend exactly" is slightly overstated.
- **N5** — PATCH always includes `instrument` in `changes` (a required `PositionWrite`
  field), which the backend accepts as a no-op (`update()` ignores `changes.instrument`).
  Harmless; a minimal-changes patch would omit it. Backend quirk already flagged by the
  author repair.

### DEFERRED_TO_DEV_PC (explicit, unexecuted — not passed)
`dart run build_runner build --delete-conflicting-outputs` (now mandatory: the new
`PositionInstrument` freezed class has no generated output yet), `flutter analyze`,
`flutter test` (all 43 cases), and any device/APK/runtime check. `flutter`/`dart` exit 127
on this host. Source-only acceptance is not runtime or release approval.

## 8. Re-review verdicts

- **SPEC verdict: SPEC_PASS_SOURCE_ONLY.** The positions lane now mirrors the backend wire
  shape on all three previously-blocking counts (B1/B2/B3) plus the flat error envelope
  (A3). Market/research layers unchanged and previously passed.
- **QUALITY verdict: QUALITY_PASS_SOURCE_ONLY.** Test fidelity now encodes the backend
  wire; strict validators, typed ApiException, cancellation, credential hygiene, no
  generated files, no new dependency, no secrets all re-confirmed.

## 9. Targeted re-review — empty-thesis cross-lane repair (t_543a90c0) — 2026-10-31 22:00 UTC

Reviewer: reviewer / deepseek-v4-pro. Author: zai / glm-5.3-flash (vendor-disjoint). This is a
re-review of the routed cross-lane empty-thesis fix from H12 review §5, not a new fan-out. The
accepted H11 verdict history (sections 1–8) is preserved verbatim; this section appends only.

Scope (independently verified from artifacts; no source repair, no new cards):
(1) backend `create()` absent-`original_thesis` → null; `serialize()` `''` → null;
(2) Flutter `position_models.dart` accepts null so `Position.fromJson` no longer throws;
(3) red-first regression + suites re-run independently; (4) no contract drift beyond the
documented null-normalization.

### Independent verification performed this run

- **Hashes:** `sha256sum` over the four changed files matches `h11-repair-thesis.md` §SHA-256
  exactly (4/4): `position.service.js` `507c63c1…`, `positions.test.cjs` `07080ca9…`,
  `position_models.dart` `2ef79950…`, `research_models_test.dart` `98b2f6b4…`. No drift
  between evidence file and disk.
- **Suites re-run (not trusting the controller's report):** `node --test backend/test/positions.test.cjs`
  → **41/41 pass**. Full aggregate over all eight `backend/test/*.test.cjs` suites →
  **151/151 pass** (market-history 12, positions 41, research-auth 6, research-contracts 14,
  research-evidence 19, research-history-integration 11, research-metrics 24, research-state 24).
  Independent count matches the controller's 41/41 + 151/151 exactly.
- **Whitespace:** `git diff --check` exit 0; additionally 0 trailing-whitespace lines in all
  four changed files (they are untracked, so `git diff --check` alone would not cover them).
- HEAD unchanged `9fbb26b5519889e0816720530dd60c204dda2bf2`, branch `main`, dirty/untracked
  baseline preserved.

### (1) Backend create() — RESOLVED, matches CONTRACTS §2

`position.service.js:318-321`: absent → `null` (never `''`); explicit `null` is treated as
absent. The guard `if (thesis !== null && (typeof thesis !== 'string' || thesis.length >
MAX_THESIS_LENGTH))` leaves string type + `MAX_THESIS_LENGTH = 5000` overlength validation
semantically unchanged. This is consistent with CONTRACTS §2 (`original_thesis` — "User text,
bounded length, optional") and with the Zod schema `research/contracts.js:143`
(`z.string().max(MAX_TEXT).nullable().optional()`), which already accepted null/absent. The
one deliberate relaxation (explicit `null` now = absent instead of `INVALID_INPUT`) is
documented in the repair evidence and does not contradict any existing consumer: the Dart
`PositionWrite.toJson()` omits null keys entirely.

### (1) serialize() — RESOLVED

`position.service.js:248`: `original_thesis: doc.original_thesis === '' ? null : doc.original_thesis`
normalizes a stored `''` to null at the wire boundary only. Storage is untouched:
`position.model.js:120` still carries the Mongoose default `''`; `update()`'s repository write
path is untouched. Every read path (`list`/`get`/`create`/`update` all return via `serialize()`)
therefore never emits `''`. Correct placement of the normalization.

### (2) Flutter position_models.dart — RESOLVED

`optionalBoundedText` (`position_models.dart:185-195`) now returns `null` for an empty string
instead of throwing, so `Position.fromJson` (`originalThesis: optionalBoundedText(json,
'original_thesis')` at line 517, typed `String?`) no longer raises `ContractFormatException`
on a no-thesis position. Required-text parsing is untouched (`requireBoundedText` still rejects
empty), so the change is confined to the optional variant.

### (3) Red-first regression + suite fidelity — RESOLVED

`backend/test/positions.test.cjs:229-266` is non-vacuous and encodes the exact defect: asserts
`created.original_thesis === null` (the `'' !== null` red failure), the wire never containing
`"original_thesis":""`, explicit-null → null, legacy stored `''` → null via `get()`/`list()`,
and overlength 5001 still `INVALID_INPUT`. `frontend/test/research_models_test.dart`:
`backendSerializedOwnedPosition()` fixture now carries `'original_thesis': null` (line 126);
the exact-serialize-shape test asserts `isNull` (399); a new test (405-413) mutates the fixture
to `''` and asserts `Position.fromJson` yields null. All meaningful, none vacuous. Flutter
tests remain DEFERRED_TO_DEV_PC (no `dart`/`flutter` on this host — `command -v` exits 1).

### (4) Contract drift — NONE beyond the documented null-normalization

The only behavior changes are the documented ones (create absent/null → null; serialize
`''` → null; `optionalBoundedText` `''` → null). The `optionalBoundedText` relaxation is shared
with other optional text fields (`portfolio_context`, `label`, `unit`, `basis`, `excerpt`,
`source_locator`, `error_code`, `next_cursor`, `unavailable_reason`) — all optional fields
where empty ≡ absent; it is the card's explicitly instructed approach and is disclosed in the
repair evidence. Required fields are unaffected. No other contract term changed.

### Non-blocking notes (new, not blocking)

- **N6** — `update()` (position.service.js:428-433) still rejects an explicit `null` for
  `original_thesis` (INVALID_INPUT), asymmetric with `create()`'s new null-as-absent handling.
  A client clearing a thesis via PATCH must send `''` (stored, then re-normalized to null on
  read). Out of this repair's scope (update path intentionally untouched); not a drift.
- **N7 (cosmetic)** — `optionalBoundedText`'s error message still reads "expected a non-empty
  string …" though an empty string now returns null; the message fires only for type/overlength
  errors now. No functional impact.

### Verdicts

- **SPEC verdict: SPEC_PASS_SOURCE_ONLY.** The empty-thesis cross-lane defect is resolved in
  source: backend create/serialize null-normalization and Flutter null-acceptance align the two
  lanes; string type/overlength validation is unchanged; no contract drift beyond the
  documented null-normalization.
- **QUALITY verdict: QUALITY_PASS_SOURCE_ONLY.** Red-first regression and strengthened Flutter
  assertions are non-vacuous and independently re-verified; positions suite 41/41 and full
  aggregate 151/151 re-run green; hashes, whitespace, and baseline integrity confirmed.
  Flutter runtime remains DEFERRED_TO_DEV_PC (no toolchain here), so source-only acceptance is
  not runtime or release approval.

## 10. Targeted re-review — getLatest wire-drift repair (t_fa26099c) — 2026-11-01 09:09 UTC

Reviewer: reviewer / deepseek-v4-pro. Author: zai (vendor-disjoint). This is a re-review of the
controller-routed `getLatest` wire-drift repair t_fa26099c, not a new fan-out. The accepted H11
verdict history (sections 1–9) is preserved verbatim; this section appends only.

Scope (independently verified from artifacts; no source repair, no new cards): (1) ResearchLatest
now mirrors the real top-level wire from `research.routes.js`/`research.service.js` — `position_id`,
nullable `latest_assessment`, and `run_state` with SEPARATE `last_success`/`latest_attempt`
projections (per the H15B-era wire, including the `owner_id_internal` reconciliation); (2) the
wire-trace table in `h11-repair-latestwire.md` is accurate field-by-field against the actual backend
source; (3) the rewritten test fixtures encode the REAL wire, not author assumptions; (4) no backend
file touched and the 234/234 aggregate undrifted.

### Independent verification performed this run (not trusting author self-report)

- **Hashes:** `sha256sum` over the four changed files matches the parent handoff exactly (4/4):
  `research_repository.dart` `2d1717e1…`, `research_models.dart` `e115eebf…`,
  `research_models_test.dart` `a8a9daa3…`, `h11-repair-latestwire.md` `70adfd86…`. No drift between
  the handoff, the evidence file, and disk.
- **No backend file touched:** file mtimes confirm the backend research source predates this repair —
  `research.routes.js` (2026-10-31 21:44) and `research.service.js` (2026-10-31 22:02) — while the
  four changed files are 2026-11-01 09:00–09:03. This repair is frontend + evidence only.
- **Aggregate re-run (not trusting the controller's report):** `node --test test/*.test.cjs` with the
  repo `.env` sourced → **234/234 pass, 0 fail** (12 suites). Matches the controller's 234/234
  exactly. (Note: without `MONGODB_URI`/`JWT_SECRET` the two DB-integration suites
  `research-history-integration` and `research-panel-integration` fail at env validation — an
  environment-configuration artifact, not a code regression; the aggregate is only meaningful with
  the `.env` loaded.)
- **queueRun / getRun unchanged and correct:** `POST /positions/:id/runs` → `{run:
  toPublicRunView(run), idempotent_replay}` (routes:118) and `GET /runs/:runId` → `{run:
  toPublicRunView(run)}` (routes:130) still map to `ResearchRun.fromJson(_requireObject(decoded,
  'run'))` (repository:103/112). No change made.

### (1) ResearchLatest mirrors the real top-level wire — RESOLVED

`research.routes.js:67-74` returns a top-level `{position_id, latest_assessment, run_state:
{last_success, latest_attempt}}` — exactly as quoted in the evidence. The client `ResearchLatest`
(research_models.dart:1446-1478) parses `position_id` via `requireOpaqueId`, `latest_assessment`
as nullable via `_optionalObject` → `ResearchAssessment.fromJson`, and `run_state` as a required
object with two SEPARATE projection models. The card's original handoff claim that the `run_state`
entries "carry run views (toPublicRunView …)" was FALSE — they are service projections
(`research.service.js:816-822` for `last_success`, `823-831` for `latest_attempt`), correctly
modeled as `ResearchLastSuccess`/`ResearchLatestAttempt` rather than `ResearchRun`. Verified the
projection fields are a strict subset of `ResearchRun` (no `owner_id_internal`, `position_revision`,
`run_kind`, `idempotency_key`, `created_at`, `heartbeat_at`, `retry_count`, `versions`), so
`ResearchRun.fromJson` cannot parse them — the separate-model decision is correct.

**`owner_id_internal` reconciliation state — RESOLVED.** `#assessmentView` (`service:1018-1020`) is
a plain `structuredClone` (no strip); the routes layer's `toPublicAssessmentView` (`routes:42-47`)
deletes `owner_id_internal`. The client `ResearchAssessment.fromJson` carries no `owner_id_internal`
field — correct. Conversely `#runView` (`service:1011-1016`) and `toPublicRunView` (`routes:35-40`)
retain `owner_id_internal` (only `lease_nonce` is stripped), and `ResearchRun.fromJson` requires it
(`models:1311`) — correct. The two lanes are reconciled exactly as the wire demands.

### (2) Wire-trace table accuracy — ACCURATE (one prose nit, non-blocking)

The per-field table in `h11-repair-latestwire.md` §3 maps every wire field to the correct client
parse and model field against the actual source. Service line numbers (816-822, 823-831) are exact;
model line numbers are exact or off-by-one/two (immaterial doc refs). `last_success` and
`latest_attempt` are kept separate and never collapsed, matching the service comment
(`service:811-812`).

**Non-blocking note (N8):** both the evidence §2 prose and the model docstring
(`research_models.dart:1441-1442`) list `deadline_at` among the fields the projections "lack", but
`latest_attempt` DOES carry `deadline_at` (`service:830`), and the model parses it
(`requireUtcTimestamp`, `models:1528`). The TABLE and the CODE are correct; only the prose/docstring
list-item is wrong. No runtime impact, but a future maintainer could misread it. Should be corrected
in a follow-up doc edit, not a blocker.

### (3) Test fixtures encode the real wire — RESOLVED

`frontend/test/research_models_test.dart` now encodes the canonical top-level wire: a populated-state
case asserting `last_success` (run-0001, succeeded) and `latest_attempt` (run-0002, failed) stay
distinct (`models:897-938`), an empty-state case (null assessment + null run_state entries,
`940-950`), and a drift-rejection case where the pre-repair assumed `{assessment, run}` envelope
throws `ContractFormatException` (`952-978`). Repository-level `getLatest` tests (`1229-1294`)
assert the same canonical shapes. These encode the backend wire, not author assumptions — the prior
defect pattern (fixtures mirroring the model rather than the backend) is gone.

### (4) No backend file touched + 234/234 aggregate — RESOLVED

Confirmed by mtime (see above) and by re-running the aggregate: 234/234 pass. No contract drift
introduced by this repair (backend source unchanged).

### Verdicts

- **SPEC verdict: SPEC_PASS_SOURCE_ONLY.** `ResearchLatest` now mirrors the real top-level wire
  field-for-field (position_id, nullable latest_assessment, separate last_success/latest_attempt
  projections), with the `owner_id_internal` reconciliation matching the routes/service view
  behavior exactly. The card's "full run views" claim was correctly overturned in favor of the
  service projections.
- **QUALITY verdict: QUALITY_PASS_SOURCE_ONLY.** Test fixtures now encode the backend wire (not
  author assumptions), drift-rejection and empty-state cases are non-vacuous, hashes match, backend
  untouched, and the 234/234 aggregate re-runs green. One non-blocking documentation nit (N8:
  stray `deadline_at` in the "lacks" list). Dart execution remains DEFERRED_TO_DEV_PC — no
  Flutter/Dart toolchain on this host, so source-only acceptance is not runtime or release approval.
