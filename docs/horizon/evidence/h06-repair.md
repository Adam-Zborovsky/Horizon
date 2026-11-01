# H06 — Author Repair: news adapter functionality and review findings

- Task: t_5bc8870f (scoped author repair, third cap-3 slot); parent: t_a88af016; re-review target: existing reviewer t_33cadb23
- Author: worker / zai glm-5.3-flash (vendor-disjoint from reviewer deepseek-v4-pro)
- Date: 2026-10-31 · Workspace: /home/ubuntu/apps/Horizon · Node v22.22.2
- Scope: fixes the blocking Finding 1 and addresses Findings 2–6 from docs/horizon/evidence/h06-review.md. Source-only, hermetic (fixtures/mocks only; no live HTTP, no credentials, no DB). Write allowlist respected: evidence.service.js, providers/company_news.js, providers/sec.js, backend/test/research-evidence.test.cjs, this file, logs under evidence/h06/.

## 1. Changed files (SHA-256)

| File | SHA-256 |
|---|---|
| backend/src/features/research/evidence.service.js | `4254f5df93740c2338c3d56da788571e86f0cf5f0a1fea1cf59b20019a24544b` |
| backend/src/features/research/providers/company_news.js | `77a10d21155815e7d9010fda001de90c087394df658dac64e265af8ad1a71586` |
| backend/src/features/research/providers/sec.js | `2cb3ac027c3f7db8bb3643e2ef291140126a76a66f16a6155661062d57d808c8` |
| backend/test/research-evidence.test.cjs | `bf0ea9b02e98d59ba7d4572ee5bcd9dff9dc11f82e2b6311491c5b5ae66a5eef` |
| docs/horizon/evidence/h06/repair-red-run.log | `1e5ac2b7a63f603b3dd3f7a0714ef9d3746a9acc7fccdfbb726c2c604e6d0461` |
| docs/horizon/evidence/h06/repair-green-run.log | `c6ccde7c666c7de10ebc9f9cf15e1353dab46c76a6a1d85c8af65fcf6a01d164` |
| docs/horizon/evidence/h06/repair-aggregate-run.log | `537d6f6662f4e6e3f5db3b63d2fd634bd672d72b44d109f38cd41c11659547d7` |

## 2. Red → green

- **Red** (tests written first, run against the pre-repair code): `node --test backend/test/research-evidence.test.cjs` → **9 pass / 10 fail**. The new Finding-1 regressions failed exactly as the review predicted: the no-sourceUrl test observed `fetch` receiving a non-URL argument, and the end-to-end wiring test observed `coverage.company_news = 'unavailable'` with the production call path. See `evidence/h06/repair-red-run.log`.
- **Green** (after implementation): `node --test backend/test/research-evidence.test.cjs` → **19 pass / 0 fail**. See `evidence/h06/repair-green-run.log`.
- Aggregate: `node --test backend/test/*.test.cjs` → **95 pass / 3 fail**; the 3 failures are in `backend/test/positions.test.cjs` (model/pl/ticker-policy tests importing only `src/features/positions/*` — zero overlap with this task's files). They fail identically when run standalone, so they are a pre-existing/concurrent-baseline condition (the positions lane is in flight), **not** a regression from this repair. Evidence-related files were also run together: `node --test backend/test/research-evidence.test.cjs backend/test/market-history.test.cjs backend/test/research-history-integration.test.cjs` → 42/42 pass. See `evidence/h06/repair-aggregate-run.log`.
- `git diff --check` → clean (exit 0).
- Secret scan (review regex) over all four changed code files → no matches.

## 3. Per-finding disposition

### Finding 1 — BLOCKING — company IR / accessible-news adapter non-functional — **FIXED (preferred path implemented)**

The broken `fetch(instrument)` fallback is removed. `CompanyNewsProvider` now derives a vetted, allowlisted, per-instrument feed URL and retrieves it through the same bounds as the sourceUrl path, called from the production `EvidenceService` call chain (`gatherEvidence` → `fetchNews(instrument, { cutoffAt })`):

- `deriveNewsFeedUrl(instrument)` (company_news.js): uses an explicit `instrument.news_feed_url` / `instrument.ir_feed_url` when present; otherwise derives `https://feeds.finance.yahoo.com/rss/2.0/headline?s=<symbol>&region=US&lang=en-US` from the instrument symbol. `feeds.finance.yahoo.com` was added to `ALLOWED_NEWS_HOSTS` (exact-match, still authoritative SSRF control).
- The derived URL is fetched through one shared bounded path `fetchBounded(url, parseBody)`: `assertAllowedNewsUrl` (allowlist + internal-IP deny), declared `User-Agent`, 8s `AbortController` timeout, HTTP-status check (`!response.ok` → `PROVIDER_UNAVAILABLE`), and the body read raced against the same timeout (bounded response body preserved).
- The derived path parses RSS 2.0/Atom (title/link/pubDate/description, CDATA- and entity-aware, capped at 50 entries) or JSON feeds; parsed headlines flow through the existing cutoff filter, allowlist re-validation of every entry URL, dedup, sanitization and schema validation. If the instrument has no symbol and no explicit feed URL, the provider returns `[]` and the service reports `news_coverage_unavailable` explicitly — no fabricated coverage.
- Retrieval failure (non-ok/timeout/parse) propagates as a provider error; `EvidenceService` marks `company_news: unavailable` + the explicit gap, exactly as for the SEC path. No swallowed throw of a broken call remains.
- **Regression tests so the suite can never again mask a non-URL argument:**
  - `no-sourceUrl path fetches a real allowlisted per-instrument URL (regression: never fetch(instrument))` — the fetch mock asserts its argument is a `string`, parses as a URL, has an allowlisted host, is per-instrument (`?s=AAPL`), carries the declared User-Agent, and yields parsed evidence items. Against the pre-repair code this test failed red (fetch received the instrument object).
  - `real provider wiring produces SEC filings and company news end-to-end (production call path)` — `EvidenceService` with the real `SecEvidenceAdapter` + real `CompanyNewsProvider` (mocked fetch only) must produce `coverage.company_news = 'available'` and news-kind items. Failed red pre-repair; green now.
  - `accepts an explicit instrument IR/news feed URL … and still validates it against the allowlist` — explicit `ir_feed_url` is used verbatim and a `.local` feed URL is rejected `URL_NOT_ALLOWED`.

### Finding 2 — internal-IP deny list incomplete — **FIXED (both adapters)**

`isInternalNewsHost` / `isInternalSecHost` now deny: `172.16.0.0/12` (second-octet 16–31), `0.0.0.0`, the full `127.0.0.0/8` remainder, `::1` (incl. WHATWG bracket form `[::1]`), `fe80::/10` link-local, `.localhost`, and IPv4-mapped IPv6 (`::ffff:` in dotted or WHATWG-hex form, e.g. `[::ffff:7f00:1]` → `127.0.0.1`); unparseable mapped addresses deny conservatively. The exact-match host allowlist remains the authoritative control; this list is defense-in-depth. Regression test asserts both adapters reject all six listed vectors with the internal-IP rejection (not merely the allowlist rejection). Note: the deny predicate is deliberately duplicated in the two provider files because the write allowlist permits no new shared module; both copies are hash-recorded here.

### Finding 3 — dead allowlist entry `api.company-news.local` — **REMOVED**

Deleted from `ALLOWED_NEWS_HOSTS`; replaced by the real, used `feeds.finance.yahoo.com`. Regression test asserts the entry is absent and `https://api.company-news.local/feed` is still rejected `URL_NOT_ALLOWED`. (`news.company.com` / `investor.company.com` / `press.company.com` are retained: `news.company.com` is the existing deterministic locator fallback for feed entries without links, and `investor.company.com` is the first-party IR feed host exercised by the explicit-feed-URL test.)

### Finding 4 — ticker conflated with CIK — **FIXED**

`requireCik(instrument)` (sec.js) throws `CIK_MISSING` when the instrument carries no CIK digits; `fetchSubmissions`/`fetchCompanyFacts` use it instead of `cleanCik(instrument.cik || instrument.provider_symbol)`. `fetchEvidence` rethrows `CIK_MISSING` alongside timeout/URL errors, so a ticker-only instrument is an explicit SEC unavailability (service → `sec_filings_unavailable` gap) and **no** `CIK0000000000` request is ever issued. Regression test asserts rejection with `code === 'CIK_MISSING'` and zero fetch calls. (`cleanCik` remains only for normalizing the CIK echoed by SEC responses.)

### Finding 5 — news fetch sets no User-Agent; handoff claim inaccurate — **FIXED**

`CompanyNewsProvider` now takes `userAgent` (default `HorizonResearch contact@horizon.local`, matching the SEC fair-access pattern) and sends `User-Agent` on every retrieval — both the sourceUrl path and the derived per-instrument path — plus a broader `Accept` for JSON/XML feed negotiation. The inaccurate handoff claim ("company_news.js same pattern") belonged to h06-author.md, which is outside this task's write allowlist; this paragraph is the correcting record: the claim was false for t_a88af016's delivery and is true for this one, verified by the captured-headers assertion in the regression test.

### Finding 6 — `cutoffAt` not normalized — **FIXED (normalized to ISO string)**

`normalizeCutoffAt(cutoffAt, now)` in evidence.service.js: `null`/`''` → now (ISO); `Date` → `toISOString()`; string → parsed and re-emitted as canonical ISO (`…000Z` form, satisfying `UTC_TIMESTAMP_RE` in contracts.js); any other type or unparseable value → `INVALID_CUTOFF`. All cutoff comparisons (service filter, snapshot `cutoff_at`, repository string compare) now operate on one canonical format, making the point-in-time invariant robust to the caller's type. The existing snapshot test's expectation was updated to the canonical `'2023-11-04T00:00:00.000Z'` form; new regression tests cover `Date` input normalization and `INVALID_CUTOFF` rejection of a garbage string.

## 4. Acceptance criteria status (unchanged, re-verified)

1. Later filings/amended facts cannot enter earlier-cutoff evidence — unchanged logic, now with ISO-normalized cutoffs; original tests 5/9 still green.
2. Untrusted content cannot request tools, secrets, arbitrary HTTP or policy changes — unchanged sanitization/allowlist logic plus a wider deny list; original tests 2/6/8/11 plus the new deny-list and feed-URL tests green.
3. Lean-source gaps explicit — unchanged gap enumeration; the news path can now genuinely produce coverage, and when it cannot, the `news_coverage_unavailable` gap is explicit. Original test 10 green.

## 5. Limitations (explicit, not passed)

- **Source-only**: the derived `feeds.finance.yahoo.com` RSS URL and SEC endpoints are exercised only through injected fixtures; real network behavior, Yahoo feed shape/rate-limit interaction and live CIK coverage remain runtime checks (no live HTTP per contract).
- The RSS/Atom parser is a lean bounded extractor (CDATA/entities/`<link href>`; 50-entry cap), not a full feed-spec implementation; malformed feeds yield `[]` → explicit gap, not invented items.
- The 3 pre-existing failures in `backend/test/positions.test.cjs` are outside this task's files and ownership; they fail standalone and were not modified here (positions lane in flight).
- `feeds.finance.yahoo.com` allowlist addition follows the exact-match policy; if the feed moves hosts in future, the derivation must be updated — recorded here as the owner decision.
- No Flutter/runtime/release claims; source-only evidence.
