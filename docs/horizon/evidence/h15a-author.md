# H15A author evidence — Early protected observed-history API slice

Scope: H15A source package only. This delivery mounts the authenticated observed-history market route into the application glue (`backend/src/app.js`), introduces hermetic application-level test isolation, reduces the transport-level JSON body parser limit from legacy 50 MiB to 1 MiB, and provides full hermetic integration test coverage (`backend/test/research-history-integration.test.cjs`).

## Changed files

### 1. `backend/src/app.js` (modified within write allowlist)
- **Application Factory Pattern (`createApp`)**:
  - Implements `createApp({ marketService, marketRouter, authenticate, instrumentResolver, jsonLimit, logging })` allowing complete dependency injection for hermetic testing without live database, server listen, or scheduler bootstrap.
  - Retains backward-compatible default export (`module.exports = defaultApp`) for `server.js` alongside named export `createApp` (`module.exports.createApp = createApp`).
- **Protected Market History Route Mount**:
  - Mounts the market router at `${env.API_PREFIX}/market` (`/api/v1/market`).
  - Route endpoint `/instruments/:instrumentId/history` is reachable via application routing at `GET /api/v1/market/instruments/:instrumentId/history`.
  - Uses `createMarketRouter` with supplied or default `MarketHistoryService`, defaulting to a fail-closed instrument resolver and user authentication middleware.
- **Transport-level DoS Mitigation (Closing H03 Review Boundary)**:
  - Reduced global transport parser limit from `50mb` to `1mb` (`express.json({ limit: jsonLimit })` and `express.urlencoded({ extended: true, limit: jsonLimit })`), configurable via `jsonLimit`.
  - Rejects oversized request entities at the transport boundary with HTTP 413 (`PayloadTooLargeError: request entity too large`) before materializing large payloads in memory.
- **Error Status Propagation**:
  - Added an error status forwarding adapter immediately ahead of `errorHandler`: maps `err.status` / `err.statusCode` to `res.status` so domain request errors (`INVALID_RANGE` -> 400, `INSTRUMENT_NOT_FOUND` -> 404, `SNAPSHOT_NOT_FOUND` -> 404) return their intended HTTP status codes rather than falling back to 500.
- **Unauthenticated Mount Points and Legacy Safety**:
  - Retained `/health` check returning `{ status: 'healthy', version: '1.0.0' }`.
  - Retained `/webhook` legacy mount point in a strictly route-free state (falls through to 404).
  - No premature mounts of `/positions`, `/research`, or `/automation` routes.

### 2. `backend/test/research-history-integration.test.cjs` (created)
- Exercises 11 comprehensive test scenarios against the actual application instance over HTTP:
  1. `protected history route is reachable through actual application routing`: verifies `GET /api/v1/market/instruments/:id/history?range=1D` returns 200 with contract version 1, `data_status: 'available'`, ascending bars, and passes `historyResponseSchema.parse()`.
  2. `anonymous denial`: verifies requests without `Authorization` header are denied with HTTP 401 (`Not authorized, no token provided`).
  3. `invalid token denial`: verifies invalid bearer tokens are rejected with HTTP 401 (`Not authorized, token failed`).
  4. `truthful unavailable response`: verifies provider failure without cached bars returns HTTP 200 with `data_status: 'unavailable'`, `bars: []`, and `unavailable_reason: 'PROVIDER_UNAVAILABLE'`.
  5. `truthful stale-cache response`: verifies provider failure with expired snapshot returns HTTP 200 with `data_status: 'partial'`, `is_stale: true`, cached bars, and warning `STALE_CACHE`.
  6. `unsupported requested resolution`: verifies requesting e.g. `resolution=1d` on `1D` range returns HTTP 200 with `data_status: 'unavailable'` and `unavailable_reason: 'UNSUPPORTED_RESOLUTION'`.
  7. `error shape 400 INVALID_RANGE`: verifies unknown range parameter returns HTTP 400 with `{ success: false, error: { message: 'INVALID_RANGE', code: 'INVALID_RANGE' } }`.
  8. `error shape 404 INSTRUMENT_NOT_FOUND`: verifies unresolvable instrument returns HTTP 404 with `{ success: false, error: { message: 'INSTRUMENT_NOT_FOUND', code: 'INSTRUMENT_NOT_FOUND' } }`.
  9. `error shape 404 SNAPSHOT_NOT_FOUND`: verifies missing snapshot ID returns HTTP 404 with `{ success: false, error: { message: 'SNAPSHOT_NOT_FOUND', code: 'SNAPSHOT_NOT_FOUND' } }`.
  10. `transport-level parser DoS protection`: verifies payloads exceeding `jsonLimit` are rejected with HTTP 413.
  11. `isolated app import and no premature mounts`: verifies app boots isolated from DB/scheduler, `/health` works, `/webhook` is route-free, and `/positions` & `/research` endpoints return 404.

## TDD record

### Red Phase
Command:
```text
node --test backend/test/research-history-integration.test.cjs
```
Result before modifying `backend/src/app.js`:
Exit code 1. 11 subtests failed with:
```text
TypeError: createApp is not a function
```
(Saved in `docs/horizon/evidence/h15a/red-failure.log`)

### Green Phase
Commands and real output:

1. Named integration test suite:
```text
node --test backend/test/research-history-integration.test.cjs
exit 0 — 11 passed, 0 failed (duration ~1170ms)
```
(Full output saved in `docs/horizon/evidence/h15a/named-suite.log`)

2. Full aggregate test suite:
```text
node --test backend/test/*.test.cjs
exit 0 — 43 passed, 0 failed (duration ~2295ms)
```
(Full output saved in `docs/horizon/evidence/h15a/aggregate-suite.log`)

3. Syntax checks:
```text
node --check backend/src/app.js
node --check backend/test/research-history-integration.test.cjs
exit 0 — both clean
```

4. Git diff check:
```text
git diff --check
exit 0 — clean
```

## Durable SHA-256 hashes

```text
142620439aa3cfa8a22440c522b5331e8b474d79a6eb15e3ed6e44e510bf0ccc  backend/src/app.js
763e89c960b3658443b9ad01c5f30b25a53111a31205fb27eedf9c43d52d2c10  backend/test/research-history-integration.test.cjs
```
(Recorded in `docs/horizon/evidence/h15a/sha256sums.txt`)

## Handoff for H15B

H15B is the downstream integration card that mounts owner-scoped position and research panels.
- `backend/src/app.js` now exports `createApp(...)` alongside `defaultApp`.
- H15B can mount position routes (`${env.API_PREFIX}/positions`) and research routes (`${env.API_PREFIX}/research`) within `createApp`, using the established pattern:
  - Injecting routes or services via options (e.g. `positionRouter`, `researchRouter`).
  - Preserving the mounted `${env.API_PREFIX}/market` history route.
  - Preserving the reduced 1 MiB transport body limit and error status adapter.
- The `/webhook` mount remains unauthenticated and route-free; any future automation callbacks should be mounted under `/api/v1/automation` or explicitly protected by `automationMiddleware`.

## Limits and boundaries

- No live MongoDB connection or scheduler was started during tests.
- No live external market providers were called; all data was served via hermetic in-memory repositories and provider mocks.
- Flutter runtime checks are `DEFERRED_TO_DEV_PC`, never `PASS` from source inspection.
- The delivery is confined to `backend/src/app.js`, `backend/test/research-history-integration.test.cjs`, and evidence artifacts under `docs/horizon/evidence/h15a/` and `docs/horizon/evidence/h15a-author.md`.
