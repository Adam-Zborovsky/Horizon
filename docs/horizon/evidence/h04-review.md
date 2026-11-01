# H04 — Combined independent specification and quality review

- Task: t_26fb2a69 (H04 review), delivery_phase: core_source, scope: source-only
- Reviewer: reviewer/deepseek-v4-pro (vendor-disjoint from author worker/zai)
- Author: worker/zai (H04 author delivery, run 186); parent delivery t_8cd5755e (controller-verified, NOT independent acceptance)
- Date: 2026-10-31
- Baseline preserved: no branch change, no commit/push, no source edits. Only this review file and sanitized logs written under docs/horizon/evidence/h04/.

## Verdicts

- **SPEC verdict: SPEC_FAIL_SOURCE** — blocking defects below violate CONTRACTS §1 ("all identifiers are opaque strings") and the canonical acceptance step "reversible change manifest / exact counts".
- **QUALITY verdict: QUALITY_FAIL_SOURCE** — blocking defects below break the shipped persistence adapter (`createMongoosePositionRepository`) and the migration `--apply` determinism; reproduced offline against Mongoose casting (no DB connection required).

This is NOT a runtime/release acceptance and does NOT pass source-only scope. PC/runtime criteria remain deferred (see §6).

## Scope and method

Independently inspected all five delivered files plus the test file, against CONTRACTS.md (esp. §1 core decisions, §2 Position, §9 API surface, §10 legacy compatibility) and SPEC.md. Reproduced the author's safe offline checks and added my own offline probes against Mongoose schema casting. No source was repaired; no live DB, credentials, containers, or delegation were used.

Independent reproductions (host node v22.22.2, all foreground/hermetic):
- `node --test backend/test/positions.test.cjs` → **36/36 pass**
- `node --test backend/test/*.test.cjs` → **98/98 pass**
- SHA-256 of the five delivered files → **all 5 match** the author's evidence (§1 of h04-author.md)
- Migration CLI guards → exit 2 (no `--uri`), exit 3 (`--apply` without acknowledgement), exit 3 (`--apply` + acknowledgement against non-loopback `mongodb://10.0.0.5:...`); dry-run default, no `mongoose.connect` executed
- Secret-literal scan over positions source/script/test → no matches

## Blocking findings

### 1. `_id` typed as ObjectId contradicts the "opaque string identifier" contract and breaks the shipped repository adapter

`position.model.js` declares no `_id` path, so Mongoose 9 defaults it to ObjectId (`schema.path('_id').options === { auto: true, type: 'ObjectId' }`). CONTRACTS §1 states "All identifiers are opaque strings"; §2 lists `id` as an opaque ID. The service generates opaque string ids (`pos-<uuid>` via `idFactory`, `legacy-mig-*` via `legacyInstrumentId`), and `createMongoosePositionRepository` (position.service.js:676–717, the adapter "used by the real app") does:

- `insert()` (line 695): `model.create({ ...doc, _id: doc.id })` with `doc.id === 'pos-<uuid>'`
- `findById(id)` (line 691): `model.findById(id)` with `id === 'pos-<uuid>'`

Both cast the string to ObjectId and fail. Reproduced offline:

```
new Position({ ...doc, _id: 'pos-abc-123' }).validateSync()
  -> _id CastError: "Cast to ObjectId failed for value \"pos-abc-123\" ... BSONError"
Position.findById('pos-abc-123')
  -> CastError: "Cast to ObjectId failed for value \"pos-abc-123\" ... model \"Position\""
```

Consequence: with the real adapter, `get`/`create`/`update` all fail at the repository layer, and the opaque string id is silently lost (`mapRecord` derives `id: String(plain._id)`, never the `idFactory` value). The 36/36 tests pass only because they inject an in-memory fake repository that stores arbitrary string ids; the real adapter path is never exercised (see §5 Note D).

Required fix (author): declare `_id: { type: String }` in `positionSchema` so opaque string ids are honored end-to-end (consistent with the service `idFactory` and the "opaque strings" contract). Do NOT switch to ObjectId ids — that would contradict §1 and break the deterministic `legacy-mig-*` migration ids.

### 2. Migration `--apply` never persists the manifest's deterministic ids, so the "reversible change manifest" is not satisfiable in apply mode

`planLegacyMigration` emits `change.position_id = 'legacy-mig-<owner>-<ticker>'` and rollback steps `delete_position_by_id` keyed on that id. But `migrate-positions.cjs` apply path (line 114) does `await Position.create(change.document)` where `change.document` carries `id` (a Mongoose virtual getter, not a real schema path) and **no `_id`**. Reproduced offline:

```
new Position(change.document).validateSync()  -> clean
constructed _id -> auto-generated ObjectId "6ae65757b736aef3b3c1730d"   // ≠ "legacy-mig-owner-1-MSFT"
document has _id? -> false
```

Consequence: the created documents get fresh ObjectIds; `applied.position_ids` (line 118) records `legacy-mig-*` strings that match no stored document, and `delete_position_by_id` rollback cannot find them. The "reversible at the document level" guarantee and the deterministic-id/exact-count acceptance step do not hold in apply mode. This depends on, and is additive to, Finding 1.

Required fix (author): in the apply loop, persist the deterministic id explicitly (e.g. `Position.create({ ...change.document, _id: change.position_id })`), and rely on Finding 1's `_id: { type: String }` so that assignment casts cleanly.

## Non-blocking findings

### Note A — `average_cost.basis` extension: legitimate addition, not contract drift

Judgment requested by the orchestrator. The added `basis` field (`raw_purchase` | `split_reconciled`, default `raw_purchase`) is:
- **optional and backward-compatible** — default preserves prior `{amount, currency}` behavior;
- **strictly additive** — does not relax `amount`/`currency` validation, and overrides no ownership, numbers, references, or required structure (CONTRACTS §1 permits additive fields that do not do so);
- **an enabler of an explicit contract requirement** — §2 "matching basis" and "Splits must be reconciled or comparable P/L is unavailable with explanation" need a cost-basis discriminator; `computeProfitLoss` enforces the raw↔split_adjusted basis match and blocks mismatch with `split_basis_unreconciled`.

Conclusion: legitimate addition, not drift requiring a blocking amendment. **Action (not mine to take):** CONTRACTS.md §2 still lists `average_cost` as `{amount, currency}`; the owner/orchestrator should add a documentation amendment recording `basis` so the write schema and contract table do not diverge silently. Non-blocking.

### Note B — model validator `isPositiveDecimalString` uses `parseFloat`, not the service's bounded BigInt rules

The model's `average_cost.amount`/`quantity` validators accept values the service rejects (e.g. `'0.0000000000001'`, 13 fraction digits — reproduced: model ACCEPTS, service `assertDecimalString` rejects with `INVALID_DECIMAL`). The model message claims "bounded decimal string" but enforces only the `/^[0-9]+(\.[0-9]+)?$/` regex plus `parseFloat > 0`. Non-blocking because the service is the authoritative gate on every client write path (`create`/`update`); the model is defense-in-depth. Suggestion: align the model validator with the ≤18-total / ≤12-fraction bound for consistency.

### Note C — percent P/L half-up rounding is asymmetric for losses

`computeProfitLoss` percent division (lines 491–494) rounds half-up only for gains; for losses the BigInt `%` takes the dividend's sign, so the inline `percentRemainder * 2n >= cost` condition never fires and the division truncates toward zero. `roundScaled` then correctly rounds the final 8-decimal output, so the residual error (≤ 0.5e-12 at scale 12) is far below the output precision — no misleading P/L. Cosmetic; non-blocking.

### Note D — the real persistence path is untested

`createMongoosePositionRepository` is never exercised against Mongoose; tests inject in-memory fakes and use only `validateSync` offline. This is precisely why Findings 1–2 escaped both the author and the controller's hash/test verification. Suggestion: add an offline test pinning the id-type contract (e.g. assert `Position.schema.path('_id').instance === 'String'`, or exercise the adapter's insert/findById against a string-id document). Overlaps with Finding 1's fix.

## Verified correct (for the record)

- Owner isolation: `get`/`update` throw indistinguishable `NOT_FOUND` for missing vs foreign-owned ids; `owner_id`/`user_id`/`owner`/`userId` rejected as `OWNER_FIELD_NOT_WRITABLE`; `serialize` never exposes `owner_id`; routes derive owner server-side from `req.user._id` and enforce auth (401 without token). ✓
- Transitions: `ALLOWED_TRANSITIONS` matches contract; `owned -> candidate` clears economics; `candidate/owned -> legacy_unclassified` rejected. ✓
- Economics-null for `candidate`/`legacy_unclassified`; duplicate active identity pre-check + partial unique index; revision optimistic concurrency (missing → 400, stale → 409, valid → 200 rev+1). ✓
- P/L guards: `unknown_cost` / `currency_mismatch` / `split_basis_unreconciled` all block with explanation; no FX approximation; fees/dividends labeled excluded. ✓
- Migration planner: `dry_run` hard-set true; legacy tickers → `legacy_unclassified` with null economics (no currency/exchange/cost/quantity inferred); idempotent second run; reversible manifest shape at the planner level (the apply-path gap is Finding 2). ✓
- `reconcileLegacyTickerUpdate` policy function correct per §10 (blocked removals carry `active_position_ids`, archived do not block, case-insensitive) — but it is not wired into any request path; that integration is the briefing-lane owner's shared-file responsibility, acceptable here, noted as an outstanding end-to-end gap. ✓

## Deferred / unexecuted criteria (explicit)

- No live MongoDB; partial-unique-index behavior, Mongoose persistence, and the migration `--apply`/`--uri` write path are defined but **unverified at runtime** (Findings 1–2 are determinable offline and are NOT deferred).
- HTTP router is shipped as `createPositionRouter(...)` and is **not mounted** in `backend/src/app.js` (shared glue owned by the H15A→H15B→H15 sequence); the `/api/v1/positions` endpoints are not live yet.
- Host Node v22.22.2 does not establish deployment-runtime compatibility.
- All Flutter/device/APK/analysis checks: **DEFERRED_TO_DEV_PC** (out of scope).

## Handoff

Independent combined review complete: **SPEC_FAIL_SOURCE / QUALITY_FAIL_SOURCE** with two blocking findings (reproduced offline). Review card blocked `needs_input` with `review-required:` reason; full numbered list also posted as a board comment. No source repaired; no review/synthesis cards created.

---

## Re-review (2026-10-31, targeted after scoped repair t_f3a6cd05)

Scope: independently re-verify the two blocking findings (F1, F2) and Note B against the repaired source and the REAL Mongoose model — not the in-memory fake. No source repaired; no live DB, credentials, or delegation.

Independently reproduced (host node v22.22.2, foreground/hermetic):
- `node --test backend/test/positions.test.cjs` → **40/40 pass** (includes the four repair tests in §11)
- Own offline probe against the real `Position` schema:
  - `Position.schema.path('_id').instance` → **`"String"`**
  - `pos-<uuid>` and `legacy-mig-owner-1-MSFT` `_id` values → `validateSync()` **CLEAN**, `doc._id` preserved exactly
  - `buildAppliedDocument(change)._id === change.position_id` → **true**; `plan.rollback.steps[0].position_id === change.position_id` → **true**; applied document `validateSync()` CLEAN
  - decimal validator: `'0.0000000000001'` (13 frac) → rejected; `'1234567890123456789'` (19 total) → rejected; `'123456.123456789012'` (18/12 boundary) → accepted
- Migration CLI guards unchanged: exit 2 (no `--uri`), exit 3 (`--apply` without acknowledgement), exit 3 (`--apply` + ack vs non-loopback). No `mongoose.connect` attempted.
- SHA-256 of all five delivered files recomputed (model/service/routes/script/test) — see re-review log for values.

### Finding 1 — RESOLVED

`position.model.js:80` now declares `_id: { type: String }` with an explanatory comment citing CONTRACTS §1 opaque strings. `pos-<uuid>` and `legacy-mig-*` ids now cast cleanly on the real schema (verified independently, not via the injected fake). The `createMongoosePositionRepository` `findById`/`insert` paths are now consistent with the opaque-string contract.

### Finding 2 — RESOLVED

`migrate-positions.cjs:93-95` introduces `buildAppliedDocument(change)` returning `{ ...change.document, _id: change.position_id }`, and the apply loop (`:125`) calls `Position.create(buildAppliedDocument(change))`. `applied.position_ids` now reference stored documents, and `delete_position_by_id` rollback steps target the persisted `legacy-mig-*` ids. Reversible-manifest and exact-count acceptance criteria now hold at the source level.

### Note B — RESOLVED

`position.model.js:13-19` replaces the `parseFloat` validator with a BigInt-bound `isPositiveDecimalString` enforcing ≤18 total digits / ≤12 fraction digits / strictly positive, matching the service's `assertDecimalString`. Independent probe confirms model and service now reject the same out-of-bound values.

### Aggregate note (not an H04 regression)

`node --test test/*.test.cjs` → 114 pass / 1 fail; the single failure is `test/research-history-integration.test.cjs`, which aborts at module load because `MONGODB_URI` and `JWT_SECRET` are undefined (it loads `backend/src/config/env.js`, requiring a live `.env`). That is a live-DB integration test in the research lane, not the H04 positions suite, and its failure is an intentional no-credentials condition, not a code defect. Excluded from H04 judgment per orchestrator cross-lane note. Positions suite: 40/40.

### Re-review verdicts

- **SPEC verdict: SPEC_PASS_SOURCE_ONLY** — both blocking spec violations (opaque-string `_id`, unsatisfiable reversible manifest) are resolved in source; the remaining acceptance criteria were already verified correct in the prior review and are unchanged.
- **QUALITY verdict: QUALITY_PASS_SOURCE_ONLY** — the two blocking quality defects and the defense-in-depth divergence (Note B) are resolved; source and offline model behavior verified independently.

### Deferred / unexecuted (explicit, unchanged)

- No live MongoDB: the partial-unique index, `--apply` write path, and repository persistence against a running instance remain unverified at runtime.
- HTTP router (`createPositionRouter`) is still not mounted in `backend/src/app.js` (H15A→H15B→H15 shared glue); `/api/v1/positions` is not live.
- Host Node v22.22.2 ≠ deployment-runtime compatibility.
- All Flutter/device/APK/analysis: **DEFERRED_TO_DEV_PC**.
- Note A remains a non-blocking documentation amendment for the owner/orchestrator (CONTRACTS §2 `average_cost.basis`).
