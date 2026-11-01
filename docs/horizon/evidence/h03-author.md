# H03 author evidence — scoped automation security and tenancy tests

## Scope and changed paths

- `backend/src/middleware/automation.middleware.js`
- `backend/src/features/briefing/briefing.routes.js`
- `backend/src/features/briefing/briefing.controller.js`
- `backend/src/config/env.js`
- `backend/test/research-auth.test.cjs`
- `docs/horizon/evidence/h03-author.md`

No application integration file, workflow export, scheduler, database, credential store, live endpoint, or production service was accessed or changed.

## Implementation

The legacy external automation endpoints are now fail-closed:

- `POST /api/v1/briefing` requires the server-configured automation identity with `briefing:write`.
- `GET /api/v1/briefing/config/system` requires the same identity with `briefing:read`.
- A missing configuration, absent bearer token, invalid token, expired configured token, or insufficient configured scope returns a safe denial. Responses and code paths do not log a token.
- The configured identity provides the authoritative owner. A client `userId` that names another owner is rejected; matching legacy `userId` is compatibility-only and is removed before `briefingService.save` receives the payload.
- Callback request payloads have a 64 KiB default route-level cap with `Content-Length` and parsed-body enforcement. The existing global JSON parser remains unchanged because `backend/src/app.js` is owned by the integration lane.
- `createRunCallbackAuthorizer` supplies H10 with a pure helper for scoped callback authorization: it validates the persisted run identity, owner/revision shape, unexpired lease, opaque lease nonce, bounded delivery ID, and replay payload digest. Identical delivery retries are idempotent; a conflicting body for the same delivery ID is rejected.

The required deployment configuration names are `AUTOMATION_SERVICE_TOKEN`, `AUTOMATION_SERVICE_SCOPES`, `AUTOMATION_OWNER_ID`, and optional `AUTOMATION_SERVICE_TOKEN_EXPIRES_AT`. No values were read, generated for deployment, stored, or placed in fixtures. Primary/admin must provision and coordinate n8n only as part of the release gate.

## TDD and verification

1. Red phase from repository root:

   `node --test backend/test/research-auth.test.cjs`

   Exit `1` as expected before implementation: `Cannot find module '../src/middleware/automation.middleware'`.

2. Green H03 suite from repository root:

   `node --test backend/test/research-auth.test.cjs`

   Exit `0`: 6 tests passed, 0 failed. The suite exercises missing configuration, anonymous, invalid-token, expired-token, insufficient-scope, spoofed-owner, bounded-body, nonce, and conflicting-replay paths through an ephemeral loopback test server using generated in-memory test values only. It also verifies the real briefing controller removes the client owner field before calling its service.

3. Regression suite from repository root:

   `node --test backend/test/*.test.cjs`

   Exit `0`: 28 tests passed, 0 failed, including the H03 suite, H01 canonical contracts, and existing H05 market tests present in the shared dirty workspace.

4. Hygiene check from repository root:

   `git diff --check`

   Exit `0`.

## Limitations and next-ready package

- H03 is source-only security work. It does not mount future research/position routes, persist run leases or delivery IDs, publish an n8n workflow, provision a credential, execute a live callback, or establish deployment-runtime compatibility.
- The replay cache is deliberately bounded in memory because H03 does not own the run persistence model. H10 must connect `createRunCallbackAuthorizer` to H08's persisted run/lease and idempotency records; process-restart replay protection is not claimed here.
- The global 50 MiB parser in `backend/src/app.js` still parses before the H03 route guard. H03 rejects oversized callback bodies before controller/service processing, but a transport-level smaller parser limit requires the later integration owner's explicit shared-file change.
- Automated verification ran on host Node `v22.22.2`; no Flutter, device, container, database, live API, n8n, or deployment test was run.
- Source is intentionally uncommitted. H04 can consume the fail-closed legacy route behavior and the run callback helper after independent combined review and the focused authorization/privacy review.

## Continuation addendum — 2026-10-31T17:09:15Z

The partial implementation was re-inspected before delivery. A missing callback owner binding was found: `createRunCallbackAuthorizer` checked callback scope, run shape, lease, nonce, and replay data, but did not require the authenticated automation owner to equal `run.owner_id_internal`.

An owner-mismatch assertion was added to `backend/test/research-auth.test.cjs` and first run red:

- Command: `node --test backend/test/research-auth.test.cjs`
- Exit: `1`
- Result: 5 passed, 1 failed.
- Failure: `Missing expected exception.` at `backend/test/research-auth.test.cjs:232`; an automation context for a different owner was accepted.

The helper now rejects a missing or mismatched `requestContext.automation.ownerId` with `automation_owner_denied` before lease/nonce delivery acceptance. The test fixture passes the service-bound owner on the successful callback path.

Post-fix verification:

- `node --test backend/test/research-auth.test.cjs` — exit `0`; 6 passed, 0 failed.
- `node --test backend/test/research-contracts.test.cjs` — exit `0`; 14 passed, 0 failed.
- `node --test backend/test/*.test.cjs` — exit `0`; 28 passed, 0 failed.
- `node --check backend/src/middleware/automation.middleware.js` plus the H03 router, controller, and test files — exit `0`.
- `git diff --check` — exit `0`.

Artifact SHA-256 after the continuation fix:

```text
a737df5a5c8be4cd86cca9b2549eb282996213e8c310200e1e55bb828f2669a7  backend/src/middleware/automation.middleware.js
bdc3917adae14e4a9bf7334a1d063bb49022afe67f6f4dfda09cbef9a18ed631  backend/src/features/briefing/briefing.routes.js
0ae95c14c688421a2a96c29f11b0266ec8fe48db9eda71fd3558f6b0384bb53d  backend/src/features/briefing/briefing.controller.js
aa91cfb639dcdabffce55c76f12a284173d56be7d7e44e0362b78734ec1bb5cb  backend/src/config/env.js
994911879ec4627d280d4911a3f21fe04fa7ba5ca220f8519aec9e182f7a1f8f  backend/test/research-auth.test.cjs
```

After the continuation fix, the named suite also explicitly checks anonymous denial for both `POST /briefing` and `GET /briefing/config/system`.

Operator-note disposition: the independent H05 reviewer reported the earlier `Missing expected exception` at `research-auth.test.cjs:232`. It was reproduced as the owner-binding defect above, fixed in H03 scope without changing any H05 file, and the final H03/H01/full-backend checks all passed.

No live token/configuration, `.env`, credential store, API, database, n8n workflow, service process, or deployment runtime was read or used. The callback helper remains source-only until H10 mounts it against H08's persisted run/lease records. Coordinated n8n authentication deployment, actual credential provisioning, and live readback remain operator-controlled release work.
