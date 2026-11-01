# H06 — Primary Evidence Adapters and Registry — Author Delivery

- Task: t_a88af016 (H06), delivery_phase: core_source, scope: source-only
- Author: worker/zai/glm-5.3-flash (resumed 2026-10-31 after provider quota wall interrupted a prior partial run)
- Status: AUTHOR DELIVERY — not independent acceptance. Controller verifies delivery; independent reviewer inspects artifacts.
- Baseline preserved: existing dirty/untracked main baseline untouched; no commit/push, no branch change, no cleanup.

## 1. Delivered files (all new, per canonical package)

| Path | Lines | SHA-256 |
|---|---|---|
| backend/src/features/research/evidence.model.js | 22 | 7f5cbd85d1254a5690f0e3ddfb2004fa94afd65efe27047ffb22e053a656e9ec |
| backend/src/features/research/evidence.service.js | 265 | a419a13a4699fab0a2c603b71b96dae7b9c4dee4eb92d2a4290b3b97a2ccb03f |
| backend/src/features/research/providers/sec.js | 272 | 92c6cbf52c9096d856d1ae2b2ebe72bb3fad8d37a630c5f5f5ebd76484822427 |
| backend/src/features/research/providers/company_news.js | 238 | 9def06e07b04d2c80b6ca4a0f7d3dbf50bf219a7a1ecb2b7dd51533336863c9a |
| backend/test/research-evidence.test.cjs | 590 | ebabc35f599713b40615e83eaa0038c4c5e52a813754e1585a7874fcc3e4ad1c |

Evidence artifacts: docs/horizon/evidence/h06/named-suite.log (prior run's suite log, 12/12), docs/horizon/evidence/h06/verification.log (this run's verification battery).

No other files were created or modified. `existing_files` in the package is empty; nothing outside the package was touched.

## 2. Commands and results (this run, host node v22.22.2)

All commands run in /home/ubuntu/apps/Horizon, foreground, hermetic (fixtures/mocks only, no live sources, no credentials, no DB):

```
node --test backend/test/research-evidence.test.cjs
  -> exit 0; tests 12, pass 12, fail 0

node --test backend/test/research-contracts.test.cjs
  -> exit 0; tests 14, pass 14, fail 0   (H01 predecessor suite — no regression)

node --test backend/test/market-history.test.cjs
  -> exit 0; tests 12, pass 12, fail 0   (H05 predecessor suite — no regression)

node --test backend/test/research-auth.test.cjs
  -> exit 0; tests 6, pass 6, fail 0

node --test backend/test/research-history-integration.test.cjs
  -> exit 0; tests 11, pass 11, fail 0   (H15A predecessor suite — no regression)

git diff --check -> exit 0 (no whitespace errors)

sha256sum <five delivered files> -> digests in section 1 (verified this run)

grep -rniE "(api[_-]?key|secret|password|token)\s*[:=]\s*['\"][A-Za-z0-9+/]{16,}" \
  backend/src/features/research/ backend/test/research-evidence.test.cjs
  -> no matches: no embedded credential literals
```

Total: 55/55 tests passing across the five backend research suites. Full per-test output for the evidence suite is in docs/horizon/evidence/h06/named-suite.log (prior run) and the summary counts above (this run, also captured in h06/verification.log).

TDD ordering note: the resumed run inherited the prior run's red→green cycle (tests written first against contracts.evidenceItemSchema, then implementations). This run independently re-executed the suite (exit 0, 12/12) and added the cross-suite regression battery above.

## 3. Canonical-step mapping

| Canonical step | Implementation | Test evidence |
|---|---|---|
| Cutoff tests | evidence.service.js L117–121 strict point-in-time filter on available_at/published_at against effectiveCutoff; repository latestForCutoff uses cutoff_at ≤ query (L35–39) | 'EvidenceService: creates immutable snapshot, enforces point-in-time cutoff...' ; 'SEC adapter: respects point-in-time cutoff...' |
| Filing-period/unit tests | sec.js parses reporting periods and financial facts into normalized facts; evidenceItemSchema validation on every item | 'SEC adapter: parses filings, source locators, reporting periods, and financial facts' ; 'Every produced EvidenceItem adheres strictly to contracts.evidenceItemSchema' |
| Amendment tests | sec.js separates amendments from original filings (distinct evidence items, both cutoff-checked) | 'SEC adapter: respects point-in-time cutoff and separates amendments from original filings' |
| URL allowlist tests | sec.js assertAllowedSecUrl (host allowlist data.sec.gov/www.sec.gov/sec.gov + internal-IP/localhost blocking); company_news.js assertAllowedNewsUrl (same pattern) | 'SEC adapter: enforces official SEC URL allowlist...' ; 'Company News adapter: enforces news URL allowlist and rejects SSRF/arbitrary destinations' |
| Duplicate-news tests | company_news.js dedupes repeated stories | 'Company News adapter: deduplicates repeated stories and marks headline-only status' |
| Unavailable-coverage tests | evidence.service.js L138–161 explicit LEAN_SOURCE_GAPS + coverage status available/partial/unavailable with named gaps | 'EvidenceService: explicitly documents lean-source gaps and does not invent transcripts or consensus' |
| Bounded retrieval + fair access | sec.js fair-access User-Agent, 8s AbortController timeout, bounded body; company_news.js same pattern; service bounds excerpt retrieval | 'SEC adapter: enforces fair-access User-Agent header and handles timeouts safely' ; 'EvidenceService: analyst tools retrieve bounded excerpts...' |
| Persist locators + times + headline flags | evidence.model.js immutable EvidenceSnapshot (snapshot_id, cutoff_at, coverage, content_digest, items); providers set source_locator, published_at, available_at, retrieved_at, coverage_status='headline_only' when no excerpt | tests 3, 7, 9; schema conformance test 12 |
| Normalized fact/excerpt outputs | getFilingExcerpt / getMaterialNews analyst-tool accessors returning normalized excerpts and facts | 'EvidenceService: analyst tools retrieve bounded excerpts and reject arbitrary URLs or unknown IDs' |

## 4. Acceptance-criteria mapping

1. "Later filings or amended facts cannot enter earlier-cutoff evidence" — service-level cutoff filter (L117–121) applies to every gathered item before validation/persistence; SEC adapter-level cutoff and amendment separation additionally tested; immutable snapshot schema (immutable: true fields, strict: 'throw').
2. "Untrusted content cannot request tools, secrets, arbitrary HTTP or policy changes" — provider host allowlists + internal-IP blocking; sanitizeUntrustedText strips HTML/scripts/interpolation and neutralizes prompt-injection directives; getFilingExcerpt throws ARBITRARY_URL_FORBIDDEN on a url argument; unknown snapshot/evidence IDs rejected with typed errors. Tested by tests 6, 8, 11.
3. "Lean-source gaps are explicit and do not produce generic business claims" — LEAN_SOURCE_GAPS constants (consensus estimates / complete transcripts / broker price targets unavailable) are always enumerated; coverage gaps named per-source; no synthesized facts. Tested by test 10.

## 5. Limitations and deferred checks

- Source-only delivery: no live HTTP, no live SEC/news sources exercised — all adapter behavior verified via fixture/mock fetch injections. Real network behavior, rate-limit interactions and upstream response shapes remain downstream runtime checks.
- Host Node v22.22.2 tests do not establish deployment-runtime compatibility.
- MongoDB persistence exercised through the injected repository abstraction and the mongoose model definition; no live database touched (contract prohibits). Actual MongoDB index/behavior verification deferred.
- No Flutter/frontend checks in scope; all device/APK/analysis checks remain DEFERRED_TO_DEV_PC per amendment.
- Analyst tool accessors (getFilingExcerpt/getMaterialNews) are service-level; HTTP route wiring is not part of the H06 package file list and was intentionally not added.
- The evidence suite log named-suite.log is from the interrupted prior run; this run's results are the summary counts and verification.log above (identical 12/12 outcome, independently re-executed).

## 6. Handoff

Author delivery ready for controller verification and independent combined specification + quality review. Per handoff override, this task is blocked as needs_input with reason "review-required: author delivery ready". Never self-completed; no review tools invoked.
