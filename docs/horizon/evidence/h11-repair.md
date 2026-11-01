# H11 — Repair evidence: positions wire-shape mirrors backend

Author repair per the orchestrator adjudication on task t_afe44134 (2026-10-31).
Adjudication: the BACKEND is canonical (`backend/src/features/positions/`); Flutter
mirrors it. No backend file was touched. Market/research layers passed review and
were not modified. Author profile worker (zai/glm-5.3-flash); re-review returns to
reviewer t_e4fb9290 (deepseek-v4-pro), vendors disjoint.

## 1. Backend wire facts used (verified by reading source AND executing it)

- `position.routes.js:43` — `GET /` answers `res.status(200).json({ positions })`.
- `position.routes.js:52` / `:65` — POST and PATCH answer with the serialized
  position object directly (no envelope).
- `position.routes.js:60` — PATCH reads `{ expected_revision, changes }` from the body.
- `position.service.js:236-253` — `serialize()` emits the nested `instrument`
  object; there is no top-level `instrument_id`. `average_cost` carries a stored
  `basis` key when present; `original_thesis` is always serialized (may be `''`);
  `review_conditions` always serializes as a list.
- `position.service.js:175-198` — `validateInstrument()` accepts exactly
  `{instrument_id, symbol, exchange, currency, provider_symbol}`; `instrument_id`
  and `symbol` required non-empty strings; `exchange`/`provider_symbol` any string
  or null; `currency` ISO 4217 or null.
- `position.service.js:23-27` — `ALLOWED_FIELDS` contains `instrument`, NOT
  `instrument_id`; `expected_revision` is not an allowed field either, so it must
  never appear in a create body (create rejects unknown fields).
- `position.service.js:356-361` — `update()` requires `changes` to be a JSON
  object of changed fields and `expected_revision` a positive integer.
- `position.routes.js:72-78` — typed service errors are forwarded as a flat
  `{code, message}` body (no `success`/`error` wrapper), e.g. `REVISION_CONFLICT`.

## 2. Per-finding disposition

### B1 (blocking) — GET /positions envelope — FIXED
`position_repository.dart` `getPositions()` now matches only
`{'positions': final List items}` and throws `ContractFormatException`
('GET /positions: expected a {positions: [...]} envelope') otherwise. The bare-list
arm and the incorrect `{data: [...]}` arm were removed; nothing is repaired.
The `{data}` tolerance in the POST/PATCH resource unwrap was also removed
(`_unwrapResource` → `_requirePositionObject`: the backend answers with the
position object directly).

### B2 (blocking) — nested instrument object — FIXED
`position_models.dart` gains a typed `@freezed PositionInstrument`
(`instrumentId, symbol, exchange, currency, providerSymbol`) whose `fromJson`
mirrors `validateInstrument()` (opaque `instrument_id`, bounded-text `symbol`,
string-or-null `exchange`/`provider_symbol` with no emptiness restriction —
matching the backend exactly — and ISO-4217-or-null `currency`). `Position`
replaces `instrumentId: String` with `instrument: PositionInstrument`, parsed from
`json['instrument']`. `PositionWrite` now takes `instrument: PositionInstrument`
and `toJson()` emits the nested `'instrument': instrument.toContractJson()` object
the backend's `create()`/`validateInstrument()` require. `toJson()` no longer emits
`expected_revision` (not in `ALLOWED_FIELDS`; `create()` rejects unknown fields) —
it is PATCH metadata consumed by the repository.

### B3 (blocking) — PATCH body shape — FIXED
`position_repository.dart` `patchPosition()` now sends
`{'expected_revision': ..., 'changes': patch.toJson()}` matching
`position.routes.js:60` / `position.service.js:356-361`. `changes` carries
ALLOWED_FIELDS names — `instrument` (nested object), never `instrument_id`.
`expectedRevision` is required for a patch (client-side `ArgumentError` before any
request; the backend would reject with `MISSING_EXPECTED_REVISION`). Note: the
backend's `update()` reads `changes.instrument` into neither validation nor the
document (it validates state/economics/etc. only); `instrument` is accepted because
it is in `ALLOWED_FIELDS` but is a no-op server-side. That is a backend quirk,
recorded here, not touched (backend is read-only for this repair).

### A3 (should-fix) — flat error envelope — FIXED
`ApiException.fromResponse` now also parses a flat `{code, message}` body when the
global `{success, error: {code, message}}` wrapper is absent, so position-route
typed errors (`REVISION_CONFLICT`, `DUPLICATE_POSITION`, `INVALID_INPUT`, ...)
surface with their real code instead of synthetic `HTTP_409`.

### A1/A2 (record) — /research envelope assumptions — UNCHANGED, MARKED
No backend research routes exist yet (no `research.routes.js` in the workspace).
The research layer's assumptions stand as authored: `/research/positions/:id/latest`
parsed as `{assessment, run}` (A1), `/assessments` as `{assessments, next_cursor}`
with `cursor` as a query param (A1), and `queueRun`/`getRun`/`getEvidence`
parsing the body directly as the run/evidence object (A2). **These are
ASSUMPTIONS-PENDING-H09/H12/H14** — they must be reconciled against the real
research routes when those lanes land. Research files were not modified.

### N2 (hygiene) — one hash table
This file's §4 is the single authoritative hash table for this repair. No hash
strings are posted in handoff comments.

## 3. Test fidelity (red → green)

The positions fixtures/tests in `frontend/test/research_models_test.dart` were
rewritten to encode the backend wire:
- `ownedPositionFixture()` / `legacyPositionFixture()` carry the nested
  `instrument` object (legacy uses the `legacy-ticker-OLD` unresolved-identity
  shape from `planLegacyMigration`).
- New `backendSerializedOwnedPosition()` mirrors `serialize()` output
  field-for-field, including `average_cost.basis`, `original_thesis: ''`,
  `review_conditions: []`, `risk_context: null` and one additive unknown field.
- `getPositions` mocks return `{'positions': [...]}`; a new test asserts
  `{'data': [...]}` and bare-array bodies throw `ContractFormatException`.
- PATCH test asserts the `{expected_revision, changes}` body with `changes`
  keys `{state, instrument}`; a new test asserts a patch without
  `expected_revision` throws before any request.
- Create test asserts the nested `instrument` object, and that `instrument_id` /
  `expected_revision` never appear in the create body.
- New test maps the flat `{code: REVISION_CONFLICT, message}` error envelope to a
  typed `ApiException(409, REVISION_CONFLICT)` with the message surfaced.

**Execution status, stated plainly: `flutter test` was NOT run.** No Dart/Flutter
SDK exists on this host (`flutter`/`dart` exit 127); installing one is prohibited
by this card's invariants. The red/green runs are therefore recorded as follows:

- **Red (static):** the rewritten assertions were checked, statement by
  statement, against the pre-repair sources (author delivery under
  t_e395dcf4): `Position.fromJson` on the nested-instrument fixture would throw
  `ContractFormatException` at `requireOpaqueId(json, 'instrument_id')` (old line
  446); `getPositions` on `{'positions': [...]}` would throw in the old switch
  (old lines 113-118) which matched only `List`/`{'data': ...}`; the PATCH body
  assertion would fail because the old code sent a flat body with no `changes`
  wrapper; the create-body assertions would fail on the old
  `'instrument_id': instrumentId` emission; the flat-envelope error test would
  fail against the old `fromResponse` (code stayed `HTTP_409`). Every new or
  changed position test fails against the pre-repair models — the suite was
  genuinely red-by-construction, not asserted green from the start.
- **Green (structural + backend-execution):** post-repair checks recorded in §5.

Suite size: 43 test cases (8 groups), up from 37 — 6 added (serialize-shape
parser, malformed instrument, envelope rejection, flat error envelope, missing
expected_revision, plus strengthened create-body assertions folded into existing
cases). Market/research tests were not weakened; only position-lane cases changed.

## 4. Authoritative hash table (SHA-256)

| File | SHA-256 |
|---|---|
| `frontend/lib/src/features/positions/position_models.dart` | `9a3790556272a9bf2d3fd50977621e7df79e41589cbf6fc316a68a548145dc39` |
| `frontend/lib/src/features/positions/position_repository.dart` | `bad936a37951ad1bb5dcd570241378a6d2b7e9b0312a9dd3b4d1ad5b4976c67a` |
| `frontend/test/research_models_test.dart` | `b3ae0465b3ef85a9c9318517ef4c59a85b03a15da565afe26c3a95921c322de1` |

Changed-file count: 3 code files + this evidence file. Nothing else was modified.

## 5. Verification performed (real commands and output)

1. `git diff --check` → clean, exit 0. `git status --short` → 22 entries,
   identical set to the pre-repair dirty baseline (5 modified tracked + 17
   untracked lane dirs); HEAD unchanged at `9fbb26b5519889e0816720530dd60c204dda2bf2`.
   No reset/clean/commit. No new dependency (`pubspec.yaml` untouched). No
   generated files created or edited (`.freezed.dart`/`.g.dart` still absent; the
   `part` directives keep pointing at build_runner outputs produced only on the
   dev PC).
2. Structural checks over all three changed Dart files: `{}/()/[]` delimiter
   balance exact; no leftover top-level `instrument_id` write/parse path
   (the only remaining literal is the nested object's own `'instrument_id'` key
   inside `PositionInstrumentX.toContractJson`, which the backend requires);
   no `{data}` envelope acceptance remains; `expected_revision` emitted only in
   the repository PATCH envelope.
3. **Backend wire probe (real execution, Node, read-only):** ran the actual
   `backend/src/features/positions/position.service.js` in-memory with a stub
   repository:
   - `create()` accepted the exact body `PositionWrite.toJson()` now emits and
     `serialize()` returned the nested-instrument shape with
     `average_cost.basis: 'raw_purchase'`.
   - `update()` accepted `{expected_revision: 4, changes: {state, instrument}}`
     and returned revision 5.
   - A stale `expected_revision` raised the typed
     `{code: 'REVISION_CONFLICT', message: 'expected_revision 5 does not match
     current revision 4'}` — the flat envelope `ApiException.fromResponse` now parses.
   - `serialize()` output compared key-for-key against
     `backendSerializedOwnedPosition()`: all 14 keys match exactly.
   The probe script lives outside the repo (agent scratch) — no repo file added.

## 6. DEFERRED_TO_DEV_PC (explicit, unexecuted)

`flutter analyze`, `flutter test` (all 43 cases), `dart run build_runner build
--delete-conflicting-outputs` (regenerating `position_models.freezed.dart` and
`position_repository.g.dart` for the new `PositionInstrument` freezed class),
and any runtime/device check were NOT run — no Dart toolchain on this host.
Source-only acceptance here is not runtime or release approval. The new freezed
class makes regeneration mandatory before compilation.

## 7. Remaining limitations

- Backend `update()` ignores `changes.instrument` (accepted, no-op) — flagged
  above; fixing it would require a backend change, which this card forbids.
- A1/A2 research envelope assumptions remain ASSUMPTIONS-PENDING-H09/H12/H14.
- Average-cost `basis` is tolerated on parse (additive unknown key) but not
  surfaced as a typed field; write payloads rely on the backend's
  `raw_purchase` default. If the UI later needs basis selection, the model and
  backend contract both need extending — out of scope for this repair.
