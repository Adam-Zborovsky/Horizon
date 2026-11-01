# Task: Recreate the Horizon n8n Briefing Workflow

Rebuild the n8n workflow that generates the daily strategic briefing consumed by the Horizon app. The backend side is already deployed and working — this task is the n8n workflow only. Verify every HTTP call below against the running backend before declaring done.

## Environment

- n8n instance: `https://n8n.zborovsky.cloud` (self-hosted)
- Horizon backend (public, through Cloudflare tunnel): `https://horizon.adamzborovsky.com`
- Backend source (for reference, on this VPS): `/home/ubuntu/apps/Horizon/backend/`
- Expected payload shape (golden example): `/home/ubuntu/apps/Horizon/example_data.json`

## The contract (derived from backend source — do not invent alternatives)

**Inbound trigger — backend → n8n.** The backend fires `POST https://n8n.zborovsky.cloud/webhook/trigger-briefing` (production URL) with this exact body (`briefing.service.js` → `triggerWorkflow()`):

```json
{
  "event": "config_change",
  "reason": "scheduled_daily | manual_trigger | hallucination_detected_retry",
  "userId": "<mongo ObjectId string>",
  "username": "<username>",
  "config": { "topics": [{"name": "...", "enabled": true}], "tickers": ["AAPL"] },
  "timestamp": "2026-09-05T09:00:00.000Z"
}
```

Note: backend calls the **production** webhook path (`/webhook/trigger-briefing`). If you test with the workflow in "listening/test" mode it registers `/webhook-test/...` instead — either toggle the workflow Active or pin a test URL consciously.

**Config fetch — n8n → backend.** `GET https://horizon.adamzborovsky.com/api/v1/briefing/config/system?userId=<userId>` (no auth — public unversioned route, `briefing.routes.js:20`). Returns `{ userId, topics, tickers }`. Only act on topics with `enabled: true`; treat `tickers` as mandatory watchlist for the market section.

**Delivery — n8n → backend.** `POST https://horizon.adamzborovsky.com/api/v1/briefing` (no auth) with body `{ "userId": "<same userId>", "source": "n8n", "data": <payload> }`. The backend sanitizes trailing commas, enriches tickers with real market prices, and rejects the payload with 422 if configured tickers are missing from `data` (hallucination guard — see `briefing.service.js:130-143`). On 422, the backend auto-retriggers the workflow with `reason: hallucination_detected_retry` — your workflow must tolerate this loop (don't create infinite retries: cap your own re-run depth if reason matches).

## Required `data` payload shape (validated against `example_data.json`)

```
{
  "news": {
    "<Topic Name — must match config topic names>": [
      { "title": "...", "l": "<article url>", "img": "", "takeaway": "<2-3 sentence summary>" }
    ]
  },
  "market_analysis": [
    { "ticker": "MU", "name": "Micron Technology, Inc.", "price": 412.37, "change": -0.77,
      "sentiment_score": 0.65,
      "analysis": { "market_outlook": "...", "<free-form analysis keys>": "..." } }
  ],
  "opportunities": [
    { "ticker": "SEED", "name": "Origin Agritech Ltd.", "price": 1.06, "change": 2.91,
      "explanation": "<why this is an opportunity>" }
  ]
}
```

Rules the app depends on:
- Every `ticker` string in `market_analysis` + `opportunities` must be a real tradable symbol and, when `config.tickers` is non-empty, at least one configured ticker must appear (the 422 guard). Price/change/sentiment enrichment happens server-side; still include best-effort values.
- `news` keys MUST be a subset of the user's enabled topic names (the app filters briefing sections by topic name).
- `img` may be empty string. `l` is the article link (the app renders it).

## Suggested workflow skeleton

1. **Webhook** node — POST path `trigger-briefing`, respond immediately (202-style ack) so backend fetch doesn't hang; do generation async if your n8n version allows, else synchronous is acceptable (backend has no short timeout on this call).
2. **HTTP Request** — fetch config from `config/system` endpoint using `{{$json.userId}}`.
3. **Filter** — keep only enabled topics; split tickers.
4. **Per topic: news gathering** — Google News RSS per topic name (or your preferred source), take 4-6 items, LLM node writes the `takeaway` per item. LLM output MUST be valid JSON matching the news item schema (instruct: no markdown fences, no trailing commas).
5. **Market analysis** — for `config.tickers`: fetch quotes (e.g. Yahoo Finance public endpoints), LLM node produces `analysis` object + `sentiment_score` in [-1, 1].
6. **Opportunities** — LLM/serper-style node proposes 3-5 tickers with `explanation`; merge real quote data.
7. **Assemble + Set node** — build exact payload shape above.
8. **HTTP Request** — POST to `/api/v1/briefing` with `{userId, source: "n8n", data}`. Handle 422 (log, don't retry automatically — backend already re-triggers itself).
9. **Error branch** — on any failure, still respond to the webhook gracefully and log; never leave the backend webhook hanging.

## Acceptance criteria

- [ ] Workflow imports cleanly into n8n at n8n.zborovsky.cloud and activates
- [ ] `curl -X POST https://horizon.adamzborovsky.com/api/v1/briefing/trigger` (with a Bearer token from a real login) results in a new document appearing in `horizon.briefings` (check: `docker exec horizon-db mongosh horizon --eval 'db.briefings.find().sort({createdAt:-1}).limit(1)'`)
- [ ] Delivered `data` passes the app: the Horizon web dashboard renders the new briefing with news sections named after enabled topics
- [ ] 422 guard test passes: temporarily set a bogus ticker in a test user's config, confirm backend rejects and re-triggers, then restore
- [ ] No plaintext secrets inside the workflow JSON; n8n credentials store used for any API keys
- [ ] Export the final workflow JSON to `/home/ubuntu/apps/Horizon/n8n-workflow.json` so it lives in the repo
