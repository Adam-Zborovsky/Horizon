# H15A combined independent review — Early protected observed-history API slice

Reviewer: `reviewer/deepseek-v4-pro` (vendor-disjoint from author `worker/gemini-3.8-flash`).
Scope: source-only combined SPEC + QUALITY review of the H15A delivery (`backend/src/app.js`, `backend/test/research-history-integration.test.cjs`).
Date: 2026-10-31.

## Verdicts

- **SPEC verdict: `SPEC_PASS_SOURCE_ONLY`**
- **QUALITY verdict: `QUALITY_PASS_SOURCE_ONLY`**

Both verdicts are source-only. Every PC/runtime criterion is deferred, listed explicitly at the bottom.

## Independent verification (real commands and outputs)

All commands run from the repository root on the live dirty main baseline. Author hashes were re-verified on disk before any re-run.

| Check | Command | Result |
|---|---|---|
| Delivery hash — `app.js` | `sha256sum backend/src/app.js` | `142620439aa3cfa8a22440c522b5331e8b474d79a6eb15e3ed6e44e510bf0ccc` — matches author evidence |
| Delivery hash — test | `sha256sum backend/test/research-history-integration.test.cjs` | `763e89c960b3658443b9ad01c5f30b25a53111a31205fb27eedf9c43d52d2c10` — matches |
| Syntax | `node --check backend/src/app.js && node --check backend/test/research-history-integration.test.cjs` | exit 0 |
| Whitespace | `git diff --check` | exit 0 |
| Named integration suite | `node --test backend/test/research-history-integration.test.cjs` | **11 passed / 0 failed**, exit 0 |
| Full aggregate suite | `node --test backend/test/*.test.cjs` | **43 passed / 0 failed**, exit 0 |

Independent rerun logs are stored sanitized at `docs/horizon/evidence/h15a/reviewer-named-suite.log` and `docs/horizon/evidence/h15a/reviewer-aggregate-suite.log`.

## Acceptance criteria — one by one

1. **Protected history route reachable through actual application routing in isolated tests.** VERIFIED. The tests construct `createApp(...)` and drive it over a real loopback HTTP server (`http.createServer(app)`), hitting `GET /api/v1/market/instruments/:id/history`. This exercises the actual Express route stack (helmet → cors → parsers → route → error adapter → errorHandler), not a detached service call. 11/11 named tests pass over real HTTP.

2. **No live bootstrap, fabricated history or premature position/research/automation mount.** VERIFIED.
   - `createApp` contains no `connectDB`, no `listen`, no `startScheduler`; those remain solely in `server.js`. Requiring `./app` does not open a DB connection, bind a port, or start a scheduler.
   - All market data is served from in-memory hermetic mocks (synthetic `ACME` fixture, in-memory repository); no provider network call, no Mongo connection, no fabricated *real* observed data. Fixtures are clearly synthetic test doubles.
   - `GET /api/v1/positions`, `/api/v1/research/...` and `/webhook` all return 404 (test 11 asserts this). No `/automation` mount exists in `app.js` (grep-verified: only `/market`, `/auth`, `/briefing`, `/health`, `/webhook`).

3. **Publish exact shared app.js handoff for H15B.** VERIFIED (with one non-blocking note below). `docs/horizon/evidence/h15a-author.md` §"Handoff for H15B" publishes the interface H15B consumes: `createApp` and `defaultApp` exports; the DI option names (`marketService`, `marketRouter`, `authenticate`, `instrumentResolver`, `jsonLimit`, `logging`); the instruction to add `positionRouter`/`researchRouter`; and the invariants to preserve (mounted `/market` history route, 1 MiB transport limit, error status adapter, route-free `/webhook`). H15B's card body names `backend/src/app.js` in its own write allowlist, confirming the shared-file handoff is the intended seam.

## Security boundaries (H03 constraints) — verified

- **1 MiB transport parser reduction.** `express.json({ limit: jsonLimit })` and `express.urlencoded({ extended: true, limit: jsonLimit })` default `jsonLimit = '1mb'`, closing the H03-flagged 50 MiB global DoS boundary. The 413 path is exercised by test 10 (a 70 KiB body against a `64kb`-limited app returns HTTP 413 at the transport layer, before any route handler). The limit is configurable rather than hard-coded.
- **Fail-closed auth preserved.** `createMarketRouter` mounts `authenticate || require('../../middleware/auth.middleware')`. In the default (production) app, `authenticate` is null so the real JWT auth middleware applies — anonymous and invalid-token requests are denied with 401. The integration tests inject a `dummyAuth` double only to keep the suite hermetic; they do not weaken the shipped middleware (source re-read confirms `auth.middleware.js` is unchanged and fail-closed).
- **`/webhook` stays route-free.** `webhook.routes.js` exports an empty `express.Router()`; mounted at `/webhook` it falls through to 404 (test 11 asserts 404). No unauthenticated route is added.
- **Error status mapping.** A forwarding adapter ahead of `errorHandler` maps `err.status`/`err.statusCode` to `res.status` when nothing has set the status yet, so domain request errors surface as `INVALID_RANGE`→400, `INSTRUMENT_NOT_FOUND`→404, `SNAPSHOT_NOT_FOUND`→404 (tests 7–9 assert the exact status and `error.code`). This respects `errorHandler`'s pre-existing `res.statusCode === 200 ? 500 : res.statusCode` contract.
- **Secret scan clean.** A pattern scan across `app.js`, the test, `h15a-author.md`, and every file under `docs/horizon/evidence/h15a/` found no credentials. The only bearer tokens are synthetic fixtures (`valid-test-token`, `bad-or-forged-token`); the only `.env`-adjacent line is dotenv's non-revealing `injecting env (6) from .env` log banner.

## Non-blocking observations (recorded, do not block)

1. **Hermeticity is from live systems, not from `.env` config.** The integration test imports `../src/app`, which transitively loads `config/env.js` → `dotenv.config()` → schema validation requiring `MONGODB_URI`/`JWT_SECRET`. The rerun logs confirm dotenv injects 6 vars. This is pre-existing backend architecture (every module importing env.js behaves this way), leaks no secret values, and establishes no live connection — so the acceptance criterion (isolate from live server/database/scheduler) is satisfied. For future hardening, a test-only env preset would remove the `.env` dependency entirely.
2. **Error status adapter is global, not market-scoped.** It applies to every route's error path, changing status semantics for any error carrying `status`/`statusCode`. This is a strict correctness improvement consistent with `errorHandler`'s design, and 43/43 aggregate tests show no regression; flagging only because it is a cross-cutting change that belongs in the shared-file handoff narrative (it already is).
3. **Mock `source` claim.** The hermetic provider double emits `source: { provider: 'yahoo_chart', name: 'Yahoo Finance chart' }` for a synthetic `ACME` instrument. This is a test-double exercising the schema shape, not fabricated real observed data, and is consistent with the mandated "fixtures/mocks only" rule. No real observed market data or source claim appears in any deliverable.
4. **Fail-closed instrument resolution by default.** The default `instrumentResolver` is `async () => null`, so the production app resolves every instrument to 404 until a later lane (H15B/H15) wires a vetted resolver. This is a safe truthful default — no fabricated data can be served — but H15B must not forget to wire it.

## Deferred criteria (DEFERRED_TO_DEV_PC — not exercised, never PASS from source)

- Flutter: analysis, code generation, unit/widget tests, device/web/mobile/Wear execution, APK build — all `DEFERRED_TO_DEV_PC`.
- Runtime/deployment: live MongoDB connection, scheduler execution, live Yahoo provider calls, DNS/tunnel/Cloudflare changes, Docker compose `ports:` — not exercised (source-only review).
- `backend/scripts/test-research-workflow.cjs` is live and was NOT run (per command policy).

## Conclusion

The H15A source slice is correct, fail-closed, hermetic, and truthful. All three acceptance criteria are met by independent re-execution of the named and aggregate suites plus source inspection. No blocking defect found. Approve at source-only scope.
