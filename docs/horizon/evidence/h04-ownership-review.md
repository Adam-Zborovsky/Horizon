# H04 — Focused ownership and migration safety review

- Task: t_4e6fdd57 (H04 focused extra review), delivery_phase: core_source, scope: source-only
- Reviewer: reviewer/deepseek-v4-pro (vendor-disjoint from author worker/zai)
- Author: worker/zai (H04 author delivery + scoped repair t_f3a6cd05)
- Date: 2026-10-31
- Scope: ownership and migration SAFETY only, per orchestrator. The combined spec/quality review lives in `docs/horizon/evidence/h04-review.md` (t_26fb2a69) and is NOT repeated here.
- Baseline preserved: no branch change, no commit/push, no source edits. Only this file written. No live DB, credentials, containers, or delegation.

## Verdicts

- **Ownership safety: PASS (source-only)** — every route derives the owner server-side from the JWT-verified identity; cross-owner access is denied indistinguishably; owner identity is non-writable at every layer.
- **Migration safety: PASS (source-only)** — the migration is additive, dry-run-first, reversible at the document level, idempotent on re-run, and infers no cost/ownership facts from bare tickers.
- **`average_cost.basis` ownership-integrity: CLEAN** — no cross-owner reference, no leak surface, no misleading P/L path.

No blocking findings. Non-blocking observations are listed in §6 for the relevant lane owners; none invalidate the source-only verdict.

## Scope and method

Independently read all five delivered files (position.model.js, position.service.js, position.routes.js, migrate-positions.cjs, positions.test.cjs) plus the auth middleware and BriefingConfig model, against the ownership/migration invariants. Reproduced the positions suite and added focused offline probes against the real Mongoose schema (no DB connection anywhere). Host node v22.22.2.

Independent reproductions (foreground/hermetic):

- `node --test backend/test/positions.test.cjs` → **40/40 pass, 0 fail**
- Focused probe (real `Position` schema + in-memory repo + migration planner):
  - `owner_id` schema path options → `{"required":true,"immutable":true,"index":true}` ✓
  - `instrument.instrument_id` → `immutable:true` ✓
  - empty-owner `list('')` returns **0** (not a wildcard) ✓
  - migration dedup: `['MSFT','aapl','MSFT','']` → 2 changes (`legacy-mig-owner-A-MSFT`, `legacy-mig-owner-A-AAPL`) ✓
  - re-run idempotency → `positions_to_create=0, duplicates_skipped=2` ✓
  - rollback step ids === inserted ids (sorted) ✓

## 1. Ownership: owner is server-derived on every route

`position.routes.js`:

- `router.use(authenticate || require('../../middleware/auth.middleware'))` — auth enforced; `auth.middleware` verifies the JWT and sets `req.user = await User.findById(decoded.id)` or 401s.
- `GET /` → `positionService.list(String(req.user?._id || ''))`
- `POST /` → `positionService.create(String(req.user?._id || ''), req.body)`
- `PATCH /:id` → `positionService.update(String(req.user?._id || ''), ...)`

No route reads any owner field from the body. The owner is always `req.user._id` (the JWT subject, resolved to a persisted user), stringified for a stable key.

`position.service.js` defense-in-depth:

- `rejectWritableOwnerFields` rejects `owner_id`, `user_id`, `owner`, `userId` in both `create` input and `update` changes → `OWNER_FIELD_NOT_WRITABLE` (400).
- `rejectUnknownFields` rejects `id`, `_id`, `revision`, `created_at`, `updated_at` (not in `ALLOWED_FIELDS`) → `UNKNOWN_FIELD` (400). The `_id` is always assigned server-side by `idFactory`.
- `serialize` omits `owner_id` entirely — no route response ever exposes the owner key.

Schema level (`position.model.js`):

- `owner_id: { type: String, required: true, immutable: true, index: true }`.
- The Mongoose `update` adapter's `record.set({...})` list (`position.service.js:701-712`) excludes `owner_id` — ownership cannot be reassigned after create even at the persistence layer.

## 2. Ownership: cross-owner access is denied indistinguishably

- `service.get` / `service.update`: `if (!doc || doc.owner_id !== String(ownerId)) throw NOT_FOUND` — missing and foreign-owned are the same 404 at the route layer (tests assert byte-identical bodies for both).
- Duplicate-active check on `create` is owner-scoped: `repository.findActive(String(ownerId), instrument_id)` queries `{ owner_id, 'instrument.instrument_id', archived: false }` — a duplicate for owner A never blocks owner B (test 304).
- Unarchive-conflict check on `update` uses `doc.owner_id` (the already-owner-verified document), not the request body.

Confirmed in tests (positions.test.cjs §3, §8): cross-owner GET/PATCH → 404 indistinguishable; owner-spoof POST → 400; list scoped per owner.

## 3. Migration safety: additive, dry-run-first, reversible, idempotent

`planLegacyMigration` (pure, fixture-only) emits only `insert_position` ops. It never updates or deletes existing documents, users, briefings, or briefing configs.

- **Dry-run default:** `dry_run: true` is hard-set in the planner output; the CLI writes nothing unless `--apply`.
- **CLI guards** (`migrate-positions.cjs`, unchanged by repair):
  - no `--uri` → usage, exit 2
  - `--apply` without `HORIZON_MIGRATION_ACKNOWLEDGE=I-AUTHORIZE-LIVE-MIGRATION` → exit 3
  - `--apply` + acknowledgement against a non-loopback `--uri` (without `HORIZON_MIGRATION_ALLOW_REMOTE=1`) → exit 3
  - no `mongoose.connect` is attempted in any of these guard paths (verified in combined review; dry-run only reads via a real connect which is expected).
- **Reversible at the document level:** `rollback.steps` lists `delete_position_by_id` per inserted id; ids are deterministic `legacy-mig-<owner>-<ticker>` and — after repair F2 — persisted as `_id` via `buildAppliedDocument(change)` so `applied.position_ids` reference real stored documents and the rollback targets them exactly (test §11, independently re-verified).
- **Idempotent re-run:** the planner builds `activeByKey` (`owner_id|instrument_id`) from non-archived existing positions and skips any ticker already present. Second run → `positions_to_create=0`, `duplicates_skipped=2` (independently reproduced).
- **No inference from bare tickers:** imported docs are `legacy_unclassified` with `average_cost:null`, `quantity:null`, `opened_on:null`, `instrument.currency:null`, `instrument.exchange:null`. Service and model validators both forbid economics in `legacy_unclassified`/`candidate` states.
- **No orphan owners:** `BriefingConfig.user` is `{ type: ObjectId, ref: 'User', required: true, unique: true }`, so `loadSourceDocuments` maps `owner_id: String(c.user)` to a real ObjectId hex — the planner's `!config.owner_id` guard is defensive, never triggered in practice.

Tests are hermetic throughout: in-memory fake repository + `validateSync` + pure planner fixtures; no MongoDB connection is opened anywhere in the suite.

## 4. `average_cost.basis` from an ownership-integrity angle

`basis` (`raw_purchase` | `split_reconciled`, default `raw_purchase`) is per-position owner data inside each position's own `average_cost`. It:

- references no other owner, user, or document;
- is not exposed through any cross-owner path (it rides the owner-scoped position record and is never a query key for another owner's data);
- in `computeProfitLoss` is used only to block misleading same-position P/L (`split_basis_unreconciled`) — a correctness guard, not an ownership channel.

Ownership-integrity verdict: **clean**. Consistent with the combined review's adjudication that `basis` is a legitimate additive field (CONTRACTS §1 permits additive fields that override no ownership/number/reference/required structure). The CONTRACTS §2 documentation amendment (Note A) remains an owner/orchestrator action, non-blocking.

## 5. Verified correct (for the record)

- Server-derived owner on all three routes; no client-supplied owner field honored.
- Cross-owner denial indistinguishable; owner fields and `_id`/`revision`/timestamps non-writable.
- `owner_id` immutable + indexed; persistence adapter cannot reassign owner.
- Migration additive, dry-run-default, reversible, idempotent, no-inference; hermetic tests.

## 6. Non-blocking observations (suggestions for lane owners; do not block source-only acceptance)

1. **Empty-owner fallback shape.** `String(req.user?._id || '')` collapses a missing `req.user` to the empty-string owner bucket. The default auth middleware always sets `req.user` or 401s, so this is unreachable in production; but the shape is fail-open-to-'' rather than fail-closed. Suggestion: reject with 401/403 if `req.user?._id` is falsy. Low risk.
2. **Lost-update race in the persistence adapter.** The service's revision check is check-then-act: `findById` → verify `revision` → `repository.update`, and the Mongoose adapter's `update` re-fetches and `record.set`/`save` with no atomic `{_id, revision}` condition. Two *simultaneous* PATCHes from the same owner can both pass the revision check and the later write clobbers the earlier (one change lost). Sequential stale writes are correctly 409'd. This is within-owner only (cross-owner is fully isolated), so it is not a security issue — but it is a genuine lost-update data-integrity path. Suggestion: atomic `findOneAndUpdate({ _id, owner_id, revision }, { $inc:{revision:1}, $set:{...} })`. Non-blocking for a single-owner app.
3. **Rollback is id-based, not edit-safe after enrichment.** `delete_position_by_id` removes exactly the inserted `legacy-mig-*` ids. If a user transitions an imported position to `owned` (adding real cost/quantity) before a rollback, that enrichment is deleted too. The "reversible" guarantee is document-level and sound only for a prompt rollback. Live execution is operator-only and not authorized in this engagement; the caveat is inherent to id-based rollback. Suggestion: document a "rollback is intended to be run promptly, before user enrichment" caveat, or guard rollback against positions whose `revision > 1`.
4. **`reconcileLegacyTickerUpdate` is owner-agnostic and returns `active_position_ids`.** It matches by instrument only and has no owner parameter; ownership scoping of `activePositions` is the caller's responsibility. If a future integration passes cross-owner positions, `blocked_removals[].active_position_ids` would expose another owner's position ids (and a stranger's position could over-block a removal). It is currently unwired (no route calls it), so there is no live exposure. The briefing-lane owner must pass owner-scoped positions when wiring it.
5. **Deterministic-id delimiter (theoretical).** `legacy-mig-<owner>-<ticker>` uses `-` unescaped; `owner_id` is always a 24-char ObjectId hex and tickers are uppercased alphanumerics (possibly `.`/`-`), so a real collision is not constructible today. Theoretical only.

## 7. Deferred / unexecuted criteria (explicit, unchanged)

- No live MongoDB: the partial unique index `{ owner_id, 'instrument.instrument_id' }` with `partialFilterExpression:{archived:false}`, the real insert/findById round-trip, and the `--apply` write path are **unverified at runtime**.
- HTTP router (`createPositionRouter`) is **not mounted** in `backend/src/app.js` (shared glue owned by H15A→H15B→H15); `/api/v1/positions` is not live.
- Host Node v22.22.2 does not establish deployment-runtime compatibility.
- All Flutter/device/APK/analysis checks: **DEFERRED_TO_DEV_PC**.

## Handoff

Focused ownership/migration safety review complete: **PASS (source-only)** — `SPEC_PASS_SOURCE_ONLY` / `QUALITY_PASS_SOURCE_ONLY` for the ownership and migration-safety scope. No blocking findings. Five non-blocking observations recorded for lane owners (§6). No source repaired; no new cards created.
