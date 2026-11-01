# Holding-focused research release

## Scope

Configured tickers are treated as existing holdings. Entry price, position size, risk tolerance and investment horizon remain unknown. No purchase-price UI, chart controls, database migration or mobile build is included.

## Workflow

`Fetch Holding History` augments daily quotes with one year of observed daily bars, weekly/monthly/three-month/six-month returns, 20/50/200-session moving averages, recent range and volume context. Five-minute observed closes provide the existing daily chart history. Long-range `chartPreviousClose` is not used to compute daily change.

`Fetch Holding News` retrieves up to six dated company-specific Google News RSS headlines per holding from the past 14 days. These are headline evidence, not full article or filing research. Source links and dates are retained in delivered stock records when cited; existing mobile screens do not expose all new metadata.

The market analyst explains daily performance in broader context, implications for an existing holder, conditional review criteria and missing evidence. Current facts must come from supplied evidence. Output validation requires every holding exactly once, bounded sentiment, required text/list fields and only supplied evidence IDs.

Existing mobile-consumed fields remain: `analysis.market_outlook`, `analysis.catalysts`, `analysis.risks`, `analysis.potential_price_action`, and numeric `history`.

Opportunity scouting and general topic news behavior are unchanged. Their existing limitations, and synthetic-history fallback paths for old briefings/opportunities/mobile missing data, are not fixed by this release. New holding records supply actual history or an empty array on failure, not fabricated points.

## Verification

## Plain-language teaching refinement

The market prompt explicitly targets a public audience with no assumed finance training and varied English proficiency. It preserves basic terms (support, resistance, trend, volume, moving average), explains them on first use and connects them to the holder's assessment. Advanced jargon and dense lists of indicators are discouraged. Reports start with a direct evidence-based end-of-day assessment and include a `What to watch next:` section. This is not a determination of a personally optimal trade or a legal-compliance claim.

Prompt-only version `cd4685d0-deb1-4839-8110-fbf30778a554` was published and read back. Real execution `60` succeeded; briefing `6abcd859a3e22de8a54060ef` was independently read from MongoDB, created `2026-09-30T09:37:29.546Z`. Both holdings started with a direct assessment and explained trend and moving average in ordinary language. The generated output still exceeded the requested sentence target; that target is a prompt preference, not a hard validator. No stock-specific support/resistance claim was forced from insufficient evidence.

## Initial release verification

Run `node backend/scripts/test-research-workflow.cjs` from the repository. This fetches live AMD/ALAB market/news input, compiles all Code nodes as async n8n bodies and tests holding context, assembly compatibility, missing data, missing/duplicate holdings and invented evidence IDs. Explicit analysis fixtures are parser tests, not investment output.

Published n8n workflow: `YrZSZFqopEgqTpfp`.
Published version verified: `254c7deb-e12b-4036-aa0f-8ba8a3410e45`.
Real execution: `59`, status `success`, finished `2026-09-30T09:09:03.462Z`.
Persisted briefing: `6abcd1afa3e22de8a54060cf`, created `2026-09-30T09:09:03.337Z`.
AMD and ALAB each had 251 daily sessions, 79 actual intraday points and two cited headline sources. Latest observed session was September 29; the generated analysis explicitly named that date.

Published workflow was read back and compared to the patch. Stored briefing was independently read from MongoDB and checked for holder context, real history and completed analysis. Flutter field mapping was inspected, but the installed mobile app was not visually exercised.

One original workflow baseline is retained at `/home/ubuntu/.hermes/review/horizon/workflow-baseline.json`. Existing scheduler edits were preserved. No secrets are embedded in the workflow export. No commit or push was performed.
