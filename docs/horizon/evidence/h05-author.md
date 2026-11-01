# H05 author evidence — observed OHLCV history, snapshots and chart API

Scope: H05 source package only. This delivery creates the detached market module/router/model and hermetic tests. It does not mount the router in `backend/src/app.js`, read credentials, call a live provider, alter shared contracts, or perform any deployment/database operation.

## Changed files

- `backend/src/features/market/market.service.js`
  - Defines all six contract ranges and their requested resolutions: 1D/5m, 1W/30m, and 1M/3M/6M/1Y at 1d.
  - Resolves only a vetted instrument injected by the integration layer; unknown instrument IDs return a 404-style typed error.
  - Uses cache keys scoped by contract version, instrument, range, and resolution; persists immutable snapshot payloads through an injected repository.
  - Validates/ascending-sorts/deduplicates observed bars, reports omitted invalid rows, and returns explicit unavailable or stale-cache responses rather than quotes or synthetic bars.
  - Rejects unsupported requested resolutions as `UNSUPPORTED_RESOLUTION`; provider resolution fallback is surfaced by `actual_resolution` plus a warning.
- `backend/src/features/market/providers/yahoo.js`
  - Implements an injected-fetch Yahoo chart adapter with a bounded abort timeout, exact provider rows only, exchange-zone session dates, raw OHLC adjustment basis, and truthful delayed/unknown status.
  - It never derives OHLC from close values or fills missing sessions.
- `backend/src/features/market/market_snapshot.model.js`
  - Adds immutable Mongoose snapshot/cache fields and a cache-key/fetch-time index.
- `backend/src/features/market/market.routes.js`
  - Adds an owner-authenticated router factory. It accepts an injected authentication middleware for hermetic tests and passes the server-derived owner ID only.
- `backend/test/market-history.test.cjs`
  - Covers ranges, unsupported resolution, ordering/deduplication/invalid bars, metadata serialization, stale timeout cache, provider unavailability, early close/DST timestamps, Yahoo parsing, and route injection.

## TDD record

Red command:

```text
node --test backend/test/market-history.test.cjs
```

Before implementation it exited 1 with:

```text
Error: Cannot find module '../src/features/market/market.service'
code: 'MODULE_NOT_FOUND'
```

Green commands and real output:

```text
node --test backend/test/market-history.test.cjs
exit 0 — 8 passed, 0 failed

node --test backend/test/*.test.cjs
exit 0 — 27 passed, 0 failed

git diff --check
exit 0

node --check backend/src/features/market/market.service.js
node --check backend/src/features/market/market.routes.js
node --check backend/src/features/market/market_snapshot.model.js
node --check backend/src/features/market/providers/yahoo.js
node --check backend/test/market-history.test.cjs
all exit 0
```

## Durable source hashes

```text
ea69d9607b13157cd06af5af701e40d939a7b5497cea943023392e202db1da74  backend/src/features/market/market.service.js
b5413173f0c39dd110a41e50775bf0345eaa9169d18208144a1fd4ba24e9cee7  backend/src/features/market/market.routes.js
d30889e86d9cbe0f33a8a9f8949e185cd36c19d517d542130e1cf31b50c25b0d  backend/src/features/market/market_snapshot.model.js
9f71a85284a06eface8922c7ad9673b5644caac1ab3d99dfc16370280e2739d8  backend/src/features/market/providers/yahoo.js
801371ff09caa2f37737f75bb0ab435e5ecba7194f4437a3d8b885531fa71fad  backend/test/market-history.test.cjs
```

## Limits and integration handoff

- No live Yahoo request was made. The provider adapter was exercised only with an injected offline response.
- The snapshot model was exercised through an in-memory injected repository; no database was connected or modified.
- H05 deliberately does not mount `market.routes.js` or supply the production vetted-instrument resolver. H15A owns `backend/src/app.js` and must inject/compose the resolver using its accepted ownership/security interfaces before the route is application-reachable.
- Existing authentication middleware is retained as the router default. The isolated route test injects its substitute to avoid loading credentials or a database.
- Source-only backend evidence does not establish deployment runtime compatibility, Flutter/chart UI behavior, real provider availability/retention, or release readiness.

Author delivery ready for independent combined specification/quality review.
