# H06 — Primary Evidence Adapters and Registry — Independent Combined Review

- Task: t_33cadb23 (reviewer), delivery_phase: core_source, scope: source-only
- Reviewer: reviewer / deepseek-v4-pro (vendor-disjoint from author zai/glm-5.3-flash per live-board roster)
- Author delivery inspected: docs/horizon/evidence/h06-author.md (t_a88af016)
- Date: 2026-10-31
- Verdicts: **SPEC — FAIL (block)**; **QUALITY — FAIL (block)**. Targeted author repair + independent re-review required.

## 0. Independent verification performed

All commands run in `/home/ubuntu/apps/Horizon`, foreground, hermetic (fixtures/mocks only, no live sources, no credentials, no DB):

| Check | Command | Result |
|---|---|---|
| Delivery hashes (5 files) | `sha256sum …` | Match author handoff §1 exactly (5/5) |
| Evidence suite | `node --test backend/test/research-evidence.test.cjs` | **12 pass / 0 fail** (independently re-run) |
| Aggregate backend suite | `node --test backend/test/*.test.cjs` | **55 pass / 0 fail** (independently re-run) |
| Whitespace | `git diff --check` | clean (exit 0) |
| Secret scan | `grep -rniE "(api[_-]?key|secret|password|token|bearer)\s*[:=]\s*['\"][A-Za-z0-9+/]{16,}"` over package dirs | no matches |
| Node version | `node --version` | v22.22.2 |

Source files read in full: `evidence.model.js`, `evidence.service.js`, `providers/sec.js`, `providers/company_news.js`, `research-evidence.test.cjs`, plus `contracts.js` (shared `evidenceItemSchema`) and `docs/horizon/{SPEC,CONTRACTS}.md`.

The 12/12 and 55/55 reproductions confirm the author's test claims are not self-reported-only: the suites genuinely pass. Passing tests alone do not establish coverage (see Findings below — a defect the suite masks).

## 1. SPEC verdict — FAIL (block)

**Blocking gap — Finding 1:** the canonical step "Implement SEC/company IR/accessible news evidence adapters with bounded retrieval and fair-access behavior" is only half-delivered. The SEC adapter is functional; the company IR / accessible-news adapter (`providers/company_news.js`) cannot retrieve anything in production as wired. Details in §3.

The three acceptance criteria are otherwise **verified satisfied in source and by test**:

1. "Later filings or amended facts cannot enter earlier-cutoff evidence" — **met**. Service-level strict cutoff filter (`evidence.service.js:117–121`) applied to every gathered item before validation/persistence; SEC adapter-level cutoff (`sec.js:160`, `sec.js:214`) and amendment separation (`sec.js:169,218`, distinct evidence items with distinct source_locator); repository `latestForCutoff` uses `cutoff_at <= cutoff` (`evidence.service.js:35–39`). Verified by tests 5, 9.
2. "Untrusted content cannot request tools, secrets, arbitrary HTTP or policy changes" — **met, with a defense-in-depth note (Finding 2)**. Host allowlists (`sec.js:3–7`, `company_news.js:4–16`), internal-IP/localhost blocking (`sec.js:26–35`, `company_news.js:35–44`), prompt-injection/HTML sanitization (`company_news.js:51–85`), and `ARBITRARY_URL_FORBIDDEN` on the analyst accessor (`evidence.service.js:198–200`). Verified by tests 2, 6, 8, 11. The exact-match allowlist is the authoritative SSRF control; it is not bypassable by the tested vectors.
3. "Lean-source gaps are explicit and do not produce generic business claims" — **met**. `LEAN_SOURCE_GAPS` always enumerated (`evidence.service.js:5–9,141`), per-source gap naming (`evidence.service.js:148–153`), no synthesized transcripts/consensus/facts anywhere. Verified by test 10.

**Not blocking on these criteria.** The block is the missing functional company-IR/accessible-news adapter (a named package deliverable), not a taste preference.

## 2. QUALITY verdict — FAIL (block)

**Blocking — Finding 1 (contract fidelity + test fidelity):** the news adapter's default retrieval path is a code defect, and the test suite masks it. See §3.

Security/privacy, immutable-snapshot model (`evidence.model.js` — `immutable:true`, `strict:'throw'`), bounded retrieval (8s `AbortController` timeouts in both adapters), SEC fair-access `User-Agent` (`sec.js:56,83`), deterministic content digest (`evidence.service.js:164–174`), and baseline preservation (`git diff --check` clean, no untracked package drift) all check out. These do not offset the blocking defect.

## 3. Findings

### Finding 1 — BLOCKING (SPEC + QUALITY): company IR / accessible-news adapter is non-functional in production

- `evidence.service.js:112` calls `this.newsProvider.fetchNews(instrument, { cutoffAt: effectiveCutoff })` with **no `sourceUrl`**. This is the only production call site (`grep fetchNews` confirms).
- `company_news.js:145–148`, the no-`sourceUrl` branch, executes:
  ```js
  rawFeed = typeof this.fetch === 'function'
    ? await this.fetch(instrument).then((r) => r?.json?.() || [])
    : [];
  ```
  i.e. it passes the **instrument object** to `fetch`. With the default `globalThis.fetch`, this rejects. Independently reproduced:
  ```
  REJECTED: TypeError - Failed to parse URL from [object Object]
  ```
- `EvidenceService.gatherEvidence` swallows the rejection (`evidence.service.js:110–115`), so company news is **always empty** in production → `coverage.company_news = 'unavailable'`, `gaps += ['news_coverage_unavailable']`.
- Consequence: the "company IR / accessible news" evidence source — a named deliverable of H06 — can never produce evidence through the actual service. It exists only as a mock-backed test path.
- Test-fidelity: the tests that exercise this branch (`research-evidence.test.cjs:332–334` and `:367–369`) inject mocks that **ignore their argument** (`async () => ({ ok: true, json: … })`), so the broken `fetch(instrument)` call is never exercised against a real fetch and the defect is invisible to the suite.

**Required repair (author):** make the company-IR/accessible-news retrieval path real and bounded — e.g. derive a vetted, allowlisted per-instrument IR/accessible-news URL from instrument data and fetch it through `fetchFromUrl`-equivalent bounds (allowlist check, timeout, `User-Agent`, HTTP-status check), and call it from `EvidenceService`; or, if lean news retrieval is explicitly out of scope for this delivery, remove the broken `fetch(instrument)` fallback and have the provider return an explicit `news_coverage_unavailable` result rather than silently throwing. Either way, add a test that drives the no-`sourceUrl` path against a fetch that validates its argument is a real allowlisted URL (so the suite cannot mask a non-URL argument again).

### Finding 2 — suggestion (security defense-in-depth): internal-IP block is incomplete

`sec.js:26–35` and `company_news.js:35–44` block `localhost`, `127.0.0.1`, `169.254.169.254`, `10.*`, `192.168.*`, `.local`, but omit `172.16.0.0/12` (the Docker bridge default range), the rest of `127.0.0.0/8`, `0.0.0.0`, and IPv6 `::1`/`fe80::/10` link-local. **Not a live SSRF hole** because the exact-match host allowlist is authoritative and rejects these hosts, but the advertised "internal-IP blocking" is only partial. Consider adding `172.`/`0.0.0.0`/IPv6 loopback+link-local to the explicit deny list.

### Finding 3 — suggestion: dead allowlist entry `api.company-news.local`

`company_news.js:15` allowlists `api.company-news.local`, but `company_news.js:41` (`hostname.endsWith('.local')`) rejects every `.local` host. Independently reproduced: `https://api.company-news.local/feed` → `URL_NOT_ALLOWED`. The entry is unreachable and should be removed or the deny rule reconciled.

### Finding 4 — suggestion: ticker conflated with CIK

`sec.js:109,115` use `instrument.cik || instrument.provider_symbol`; `cleanCik` (`sec.js:48–51`) strips non-digits, so an instrument with no CIK (ticker only, e.g. `AAPL`) yields CIK `0000000000` and queries `CIK0000000000.json` (reproduced → HTTP 404 → `PROVIDER_UNAVAILABLE`). A ticker is not a CIK; a missing CIK should be treated as "SEC unavailable" explicitly rather than fabricating a zero CIK.

### Finding 5 — suggestion: news provider sets no User-Agent

`company_news.js:125–129` sends only `Accept: application/json`. The author handoff §3 claims "company_news.js same pattern" for fair-access `User-Agent` as `sec.js` — inaccurate. Add a declared `User-Agent` to the news fetch for fair-access hygiene.

### Finding 6 — suggestion (robustness): `cutoffAt` not normalized

`evidence.service.js:100` sets `effectiveCutoff = cutoffAt || this.now().toISOString()`, then compares strings at `evidence.service.js:120` (`itemAvailability <= effectiveCutoff`). A `Date`-typed `cutoffAt` would coerce to a non-ISO local-time string and corrupt the comparison. Normalize `cutoffAt` to an ISO string (or document string-only) to make the point-in-time invariant robust against the caller's type.

## 4. Regression evidence

- `node --test backend/test/research-evidence.test.cjs` → 12/12 pass (independently re-run this review).
- `node --test backend/test/*.test.cjs` → 55/55 pass (no cross-suite regression).
- `git diff --check` → clean.
- Secret-scan regex over `backend/src/features/research/` and `backend/test/research-evidence.test.cjs` → no credential literals.
- Delivery hashes match author handoff §1 for all five files.

## 5. Limitations and deferred checks (explicit, not passed)

- **Source-only** scope: no live HTTP/SEC/news exercised; adapter behavior verified via injected fixtures/mocks. Real network behavior, rate-limit interaction, and upstream response-shape compatibility remain runtime checks.
- Host Node v22.22.2 does not establish deployment-runtime compatibility.
- MongoDB persistence exercised only through the injected repository abstraction and the Mongoose schema; no live DB touched (contract). Actual index/behavior verification deferred.
- All Flutter analysis/generation/tests/device/APK checks remain **DEFERRED_TO_DEV_PC** — out of H06 scope.
- Analyst accessors (`getFilingExcerpt`/`getMaterialNews`) are service-level; HTTP route wiring is not part of the H06 file list (intentional).
- Source-only verdicts are not runtime or release approval.

## 6. Historical findings

First review for H06 — no prior H06 findings to preserve. The archived duplicate `t_7e170254` was a review-sequencing card only, not a source of findings.

## 7. Targeted re-review — 2026-10-31 (post-repair t_5bc8870f)

Re-review scope: the six findings from the failed review (§3). Source-only, hermetic. Reviewer independently re-ran the suites and re-verified every finding in source. The FAIL history above is preserved unchanged.

### 7.1 Independent verification (this re-review)

| Check | Command | Result |
|---|---|---|
| Evidence suite | `node --test backend/test/research-evidence.test.cjs` | **19 pass / 0 fail** |
| Research suites (excl. `positions.test.cjs` — H04 lane) | `node --test backend/test/research-auth.test.cjs backend/test/research-contracts.test.cjs backend/test/research-evidence.test.cjs backend/test/research-history-integration.test.cjs backend/test/market-history.test.cjs` | **62 pass / 0 fail** |
| Repair delivery hashes (7 files) | `sha256sum …` | match `h06-repair.md` §1 exactly (7/7) |
| Whitespace | `git diff --check` | clean (exit 0) |
| Secret scan | grep regex over package dirs | no matches |
| Node | `node --version` | v22.22.2 |

`backend/test/positions.test.cjs` is the in-flight H04 lane and is excluded from this H06 judgment per orchestrator direction.

### 7.2 Per-finding disposition

1. **Finding 1 (BLOCKING) — RESOLVED.** `deriveNewsFeedUrl(instrument)` (`company_news.js:77–87`) returns an explicit `news_feed_url`/`ir_feed_url` or the derived `https://feeds.finance.yahoo.com/rss/2.0/headline?s=<symbol>&…`; `feeds.finance.yahoo.com` is allowlisted (`company_news.js:12`). The no-`sourceUrl` branch (`company_news.js:267–279`) routes through the shared bounded `fetchBounded` path (allowlist check, declared `User-Agent`, 8s timeout, HTTP-status check). No `this.fetch(instrument)` remains (grep confirmed). No symbol + no explicit feed → `[]` → explicit `news_coverage_unavailable`. Regression tests 13, 19 (and 14) assert the fetch argument is a real allowlisted per-instrument URL **string**, so the suite cannot again mask a non-URL argument; test 19 drives the full `EvidenceService` wiring and asserts `coverage.company_news = 'available'`.
2. **Finding 2 — RESOLVED (both adapters).** `isInternalNewsHost`/`isInternalSecHost` now deny `172.16/12`, `0.0.0.0`, full `127/8`, `::1`/`::`, `fe80::/10`, IPv4-mapped `::ffff:` (dotted and hex), plus `.localhost`. Test 16 asserts both adapters reject the six vectors with the internal-IP message. The exact-match allowlist remains authoritative.
3. **Finding 3 — RESOLVED.** `api.company-news.local` removed from `ALLOWED_NEWS_HOSTS` (`company_news.js:4–16`). Test 15 asserts absence + rejection.
4. **Finding 4 — RESOLVED.** `requireCik(instrument)` (`sec.js:78–84`) throws `CIK_MISSING` when no CIK digits; `fetchSubmissions`/`fetchCompanyFacts` use it; `fetchEvidence` rethrows it. No `cik || provider_symbol` conflation remains (grep confirmed). Test 17 asserts `CIK_MISSING` + zero fetch calls.
5. **Finding 5 — RESOLVED.** `CompanyNewsProvider` sends `User-Agent` on every retrieval through `fetchBounded` (`company_news.js:238`), default `HorizonResearch contact@horizon.local`. Test 13 asserts the header.
6. **Finding 6 — RESOLVED.** `normalizeCutoffAt` (`evidence.service.js:19–35`) normalizes null/`Date`/string to a canonical ISO string and throws `INVALID_CUTOFF` on non-temporal input; used at `evidence.service.js:120`. Test 18 covers `Date` normalization and garbage-string rejection.

TDD fidelity independently confirmed: `repair-red-run.log` shows the seven new/updated regression tests (13–19) plus tests 7/8/9 failing red against pre-repair code (9 pass / 10 fail), consistent with the review's prediction. The red log is hash-recorded in `h06-repair.md` §1.

### 7.3 Verdicts

- **SPEC — SPEC_PASS_SOURCE_ONLY.** All three acceptance criteria re-verified satisfied (point-in-time cutoff/amendment separation; untrusted-content containment incl. `ARBITRARY_URL_FORBIDDEN`; explicit `LEAN_SOURCE_GAPS`). The Finding-1 deliverable gap is closed: the company IR / accessible-news adapter is now wired and functional through the production call chain.
- **QUALITY — QUALITY_PASS_SOURCE_ONLY.** Blocking defect removed; regression coverage added so the suite cannot mask a non-URL fetch argument again. Security, contract fidelity, maintainability, and test fidelity all hold at source scope.

### 7.4 Residual non-blocking observation

- Pre-existing and out of repair scope: the fallback `source_url` for feed entries lacking a link (`https://news.company.com/<symbol>/<Date.now()>`, `company_news.js:288`) is non-deterministic and could perturb the content digest across runs for such entries. Rare (RSS/JSON feeds virtually always carry links); noted for a future owner, not a blocker.

### 7.5 Deferred (explicit, not passed)

- All Flutter analysis/generation/tests/device/APK checks — **DEFERRED_TO_DEV_PC** (out of H06 scope).
- Live HTTP/SEC/news shape/rate-limits, MongoDB persistence, and deployment-runtime compatibility — runtime checks, not exercised.
- Source-only verdicts are not runtime or release approval.
