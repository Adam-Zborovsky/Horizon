# H01 author evidence — executable shared contracts and offline fixtures

## Scope and changed paths

- `backend/src/features/research/contracts.js`
- `backend/test/research-contracts.test.cjs`
- `backend/test/fixtures/research/observed-bars.json`
- `backend/test/fixtures/research/contract-cases.json`
- `docs/horizon/evidence/h01/observed-bars-provenance.json`

No existing source file, workflow, configuration, database, credential store, or live endpoint was modified.

## Implementation

`contracts.js` exports contract version `1`, one canonical `schemas` registry, and deterministic calendar helpers. It supplies strict position-write and market-bar schemas plus canonical claim, evidence, assessment, numeric-projection, research-run, position-economics, and history-response validators.

The validators reject numeric strings for numeric analytical values, malformed OHLC ordering, candidate economics, unexpected write fields, incompatible state/action pairs, missing or duplicate 1/2/3-month outlooks, unordered projection bounds, stale-as-realtime history, and cross-currency economics without an FX policy.

`observed-bars.json` is an offline, source-dated IBM daily OHLCV recording. It is explicitly labelled `observed_recording`, points to a source-specific public capture URL and a SHA-256-verified sanitized provenance artifact, preserves the provider daily UTC timestamp, and keeps raw OHLCV separate from adjusted-close data. `contract-cases.json` is separately labelled `engineered_contract_cases`; every value in it is synthetic.

## Specification-repair disposition

The independent H01 specification review reported seven findings. This repair maps each finding to Contract v1 behavior:

1. Contract §1/§3/§5/§8 date semantics: date-only and UTC timestamp validators now reject impossible calendar dates and clock values, while retaining date-only versus UTC-instant separation. Leap-day positive and invalid date/time negative tests cover this.
2. Contract §1/§2 decimal inputs: cost and quantity stay decimal strings; validation bounds total length, integer digits, fractional digits, and nonzero digits without `Number()` conversion. Boundary and 400-digit overflow cases are covered.
3. Contract §8 lifecycle: queued, running, succeeded, limited, failed, stalled, and superseded states now enforce their timestamp/result/error combinations and chronology. Named positive lifecycle tests cover every status; invalid terminal combinations are negative coverage.
4. Contract §2/§4/§5/§6/§7 structures: risk context, version maps, reporting periods/facts, calibration evidence, market-thesis sections, position context, checkpoints, and change records are bounded structured validators. Response schemas retain `.passthrough()` only where Contract §1 permits additive response fields. Assessment validation checks position/checkpoint/projection identity against its assessment, instrument, revision, snapshot, and evaluation session.
5. Contract §5 horizons: `calendarTargetDate` deterministically adds one/two/three calendar months with month-end clamping. `evaluationSessionDate` takes the exchange-session predicate owned by the provider/calendar adapter; canonical assessment validation requires the clamped target and an evaluation date on or before it. The schema cannot assert an exchange holiday calendar without that adapter, so that live-calendar resolution remains a downstream integration requirement.
6. Contract §1/§2/§3/§4/§5/§7/§8: every canonical schema now has a named positive and negative fixture case, with direct regressions for dates, decimals, nested thesis structure, projection identity, run states, duplicate bars, and out-of-order bars.
7. Contract §3 fixture provenance: the earlier generic Alpha Vantage documentation locator could not substantiate its original recording. The fixture was replaced with a genuine public, read-only Yahoo Finance chart capture and `docs/horizon/evidence/h01/observed-bars-provenance.json`. The fixture stores that artifact's SHA-256 and the suite verifies it. No API key, account, or source-response byte digest is claimed or stored.

## TDD and verification

1. Red phase, from repository root:

   `node --test backend/test/research-contracts.test.cjs`

   Exit `1` as expected before implementation: `Cannot find module '../src/features/research/contracts'`.

2. The locked dependency tree was absent locally. Restored it without lifecycle scripts:

   `npm ci --ignore-scripts --prefix backend`

   Exit `0`; this installed the already locked dependencies only. npm reported 7 pre-existing dependency audit findings (3 moderate, 3 high, 1 critical); no audit remediation was attempted because it is outside H01.

3. Green phase, from repository root:

   `node --test backend/test/research-contracts.test.cjs`

   Exit `0`: 5 tests passed, 0 failed.

4. Hygiene check:

   `git diff --check`

   Exit `0`.

5. Specification-repair red phase, from repository root after adding the regression cases:

   `node --test backend/test/research-contracts.test.cjs`

   Exit `1`: 6 tests failed as expected. Failures included missing source-specific provenance fields, absent canonical samples, acceptance of `2024-02-30`, and `calendarTargetDate is not a function`.

6. Specification-repair green phase, from repository root:

   `node --test backend/test/research-contracts.test.cjs`

   Exit `0`: 13 tests passed, 0 failed.

7. Post-repair hygiene check:

   `git diff --check`

   Exit `0`.

## Fixture provenance

The original Alpha Vantage demo source cannot be substantiated from its generic documentation locator and is not represented as recovered provenance. The replacement recording was read from the public Yahoo Finance chart response at `2026-10-30T15:26:01Z`; the source-specific URL, sanitized selected records, normalization, and provenance-artifact SHA-256 are recorded. The fixture contains no user cost, quantity, account, credential, or live-write data.

## Limitations and next-ready packages

- This is an offline contract/fixture package only. It does not mount routes, call providers in production, create positions, or execute a research run.
- The observed fixture has raw provider daily OHLCV and intentionally omits the separate adjusted-close field, so it cannot be misread as adjusted candles.
- The public source extractor did not retain provider response bytes for a byte-for-byte provider digest. The committed SHA-256 verifies the sanitized provenance artifact only; it is not represented as a provider raw-response digest.
- Exchange-holiday/session validation requires the downstream provider/calendar adapter; the H01 helper accepts its deterministic session predicate and the schema enforces the calendar target/evaluation ordering.
- The test suite depends on the existing Zod 4 lockfile dependency. No dependency was added.
- H02, H03, H05, H06, and H11 can consume this version-1 canonical registry and fixtures after independent review.
