# H03 focused authorization & privacy threat review

Reviewer: `reviewer/deepseek-v4-pro`. Author lane: `worker/gemini-3.8-flash` (vendor-disjoint, 2026-10-31 roster). Gate: focused authorization/privacy threat boundary — the remaining H03 acceptance gate after the combined independent review (`h03-review.md`, which set `SPEC_PASS_SOURCE_ONLY` and `QUALITY_PASS_SOURCE_ONLY`). This review does not repeat the full combined review; it re-inspects the risk-specific artifacts and re-verifies the authorization/privacy boundaries independently.

## Verdict

**QUALITY (authorization/privacy focus): `QUALITY_PASS_SOURCE_ONLY`.**

All three H03 acceptance criteria hold at source scope, re-verified independently from the source and reproduced at runtime:

1. **Anonymous legacy sensitive routes fail; wrong/expired scopes and replay conflicts fail.** `POST /api/v1/briefing` and `GET /api/v1/briefing/config/system` are the only routes in `briefing.routes.js` mounted *before* the `router.use(authMiddleware)` (JWT) fallthrough, and both carry `automationMiddleware(...)`. Anonymous → 401 `automation_auth_required`; invalid token → 401 `automation_auth_invalid`; expired configured token → 401 `automation_auth_expired`; insufficient scope → 403 `automation_scope_denied`; replay conflict → 409 `automation_replay_conflict`. Missing configuration fails closed → 401 `automation_auth_unavailable`.
2. **Client-supplied `userId` cannot authorize position/research operations.** Owner is derived only from server-configured `configured.ownerId` (set on `req.automation` by the middleware), never from the client. `rejectOwnerSpoofing` denies a mismatched client `userId` at the route layer; the controller independently re-derives `ownerId` from `req.automation.ownerId`, rejects a mismatched `userId` again, and strips `userId` before `briefingService.save`. The `createRunCallbackAuthorizer` helper binds owner to `run.owner_id_internal` and denies a mismatched automation owner with `automation_owner_denied` *before* lease/nonce/replay acceptance.
3. **No real credential read/generated/stored.** `env.js` adds only four `.optional()` schema declarations (`AUTOMATION_SERVICE_TOKEN`, `AUTOMATION_SERVICE_SCOPES`, `AUTOMATION_OWNER_ID`, `AUTOMATION_SERVICE_TOKEN_EXPIRES_AT`). The pre-existing `dotenv.config()` call was **not** added by this lane (verified by `git diff` — the diff is schema-only). No literal token/key/credential in any delivered file; tests generate tokens via `crypto.randomBytes(32)`.

Source-only acceptance does not establish runtime, deployment, Flutter/device, live-credential, or release readiness (§ Boundaries).

## Independent reproduction (not author self-report)

Host: Node `v22.22.2`, from `/home/ubuntu/apps/Horizon`.

- `node --test backend/test/research-auth.test.cjs` → **6/6 pass, exit 0** (re-run independently).
- Focused authz/privacy probe (scratch, not committed) exercising the **full middleware → rejectOwnerSpoofing → real controller → mocked service** chain, plus callback-authorizer edge cases → **7/7 pass, exit 0**:
  1. full-chain spoofed `userId` POST → 403 `automation_owner_denied`;
  2. full-chain accepted POST with matching `userId` → 201, service receives server-derived `ownerId` with `userId` stripped from the payload;
  3. full-chain spoofed `userId` query on `GET /config/system` → 403;
  4. `GET /config/system` without `userId` → 200 returning the *server-bound* owner's config (service invoked with the configured owner, not a client value);
  5. token never appears in any response body (asserted across every probe);
  6. callback authorizer denies a mismatched automation owner vs `run.owner_id_internal`;
  7. missing nonce header → `automation_nonce_denied` (fail-closed, not silently accepted).
- Secret-pattern scan (AKIA/sk-/private-key/password/secret/api_key/long-literal-token regex) across all five delivered files → **no matches**.
- `sha256sum` of all five delivered files → **matches** the combined review's recorded hashes exactly (`a737df5a…`, `bdc3917a…`, `0ae95c14…`, `aa91cfb6…`, `99491187…`). Source has not drifted since the combined review.

Note: `read_file`/`grep` output shows the test-file bearer header as `authorization: *** ${...}`. Hexdump of the bytes confirms this is a display-layer redaction of the `` `Bearer `` prefix (`60 42 65 61 72 65 72 20` = backtick + "Bearer "); the source actually contains `` `Bearer ${token}` ``. Not a source defect. The same display redaction affects the word "validates" in `h03-author.md:23`; hexdump confirms the real text.

## Threat-boundary assessment of the combined review's non-blocking observations

These four items are correctly non-blocking for H03's own acceptance, but each is a **must-close-before-release** security boundary. I reproduce the analysis from a threat standpoint and sharpen ownership:

1. **Body cap vs global 50 MiB parser (DoS residual).** `backend/src/app.js:17` mounts `express.json({ limit: '50mb' })` globally; H03's 64 KiB route-level cap runs only *after* the body is fully parsed into memory. Consequence: a 50 MiB body is materialized in memory before the 413 `automation_body_too_large` is issued, so the route-level cap prevents oversized payloads from reaching controller/service work but does **not** prevent memory-exhaustion from the transport layer. Correctly attributed to the integration lane (H15A owns `app.js`). **Release gate:** the automation (and any new research/automation) routes must have a small raw-body limit applied before JSON parsing — a per-route `express.json({ limit })` or a `raw-body` size check ahead of the global parser — otherwise the legacy ingestion endpoint remains a memory-DoS vector even though it is authenticated. Not an H03 defect.

2. **In-memory replay cache (non-durable idempotency).** `createRunCallbackAuthorizer` keeps the delivery digest in a process-local `Map` (bounded, TTL = min(lease expiry, 15 min)). CONTRACTS §8 requires idempotency state to persist across process restarts and duplicate delivery to be idempotent — the helper alone does not satisfy that; it is a pure forward-looking interface. `prune()` trims oldest-first to `maxEntries` (verified: does not nuke the whole cache). The `JSON.stringify(body)` digest is key-order-sensitive, so a semantically identical retry with reordered keys could surface as a false 409. **Release gate (H08/H10):** persist the delivery digest in the run/idempotency records and canonicalize the payload (or hash a canonical form) before comparing. Correctly scoped out of H03.

3. **Lease field shape (interface gap).** `run.lease_nonce` / `run.lease_expires_at` are referenced by the helper but are **not** fields in the canonical `ResearchRun` schema (CONTRACTS §8 lists no `lease_*` fields; §9 line 183 references "run-bound lease nonce" conceptually). Behavior today: absent fields → `parseExpiration(undefined)` → null → 409 `automation_lease_expired` (fail-closed, safe, but the helper is non-functional until the schema is extended). **Release gate (H08):** materialize `lease_nonce`/`lease_expires_at` on the run record (or adapt the helper) at integration; the helper must remain fail-closed if they are missing.

4. **Token-length oracle in `constantTimeEquals`.** `leftBuffer.length === rightBuffer.length && crypto.timingSafeEqual(...)` short-circuits on length mismatch, leaking the configured token's byte length through response timing. With the prescribed high-entropy `crypto.randomBytes(32)` token this is negligible (length is not the secret; brute-forcing 256 bits is infeasible). **Recommendation (cheap, adopt at integration):** hash both sides (e.g. SHA-256) before `timingSafeEqual` so both inputs are fixed-length — this closes the oracle and the unequal-length exception risk in one move, and would remain safe even if a short/weak token were ever provisioned by mistake. Not blocking; not an H03 acceptance criterion.

## Cross-lane / baseline notes

- `git status` shows `backend/src/utils/scheduler.js` modified (13 lines) and several untracked paths (`backend/src/features/market/`, `backend/src/features/research/`, `backend/test/`, etc.). `scheduler.js` is **not** an H03 file and is outside H03's canonical allowlist; this is concurrent-lane activity in the shared dirty workspace (H05 timeout-repair lane was running concurrently). Not attributable to H03. H03's own diff is confined to its five canonical files (plus evidence).
- `backend/src/features/briefing/webhook.routes.js` is an empty router mounted at `/webhook` (`app.js:30`). CONTRACTS §9 line 190 already states "the empty legacy /webhook router is not proof of ingestion protection." It accepts no routes today, but it is an **unauthenticated mount point**: any route added there later would be anonymous. H03 does not own this file; flagging as a residual boundary for the integration lane (H15A) to keep unauthenticated-route-free until a service-identity guard is applied.

## Boundaries (unexecuted / deferred criteria — explicit)

- **Flutter analysis / generation / tests / device / APK → `DEFERRED_TO_DEV_PC`.** Not run on this host; never `PASS` from source inspection.
- **Runtime / deployment / live-credential provisioning / n8n publication / database readback → release gate (operator-only).** The `createRunCallbackAuthorizer` is source-only until H10 mounts it against H08's persisted run/lease/idempotency records.
- **Global 50 MiB parser reduction → H15A integration lane** (transport-level DoS residual, see observation 1).
- **Durable replay/idempotency persistence → H08/H10** (see observation 2).
- **`lease_nonce` / `lease_expires_at` schema materialization → H08** (see observation 3).
- **Token-length oracle hardening (hash-then-compare) → recommendation at integration** (see observation 4).

No source files were modified by this review. No `.env`, credential store, live API, database, scheduler, or production service was read or touched. No secret or confidential business data is present in this document.
