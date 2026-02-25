# Alpha Horizon Data Schema

This document defines the expected JSON structure for the Daily Briefing data. All agents (n8n, manual scripts, etc.) MUST adhere to this format to ensure full functionality across the dashboard, scanner, and nexus.

## 1. Top-Level Structure
The response from the backend `/api/v1/briefing` should contain a `data` object with the following optional containers:

```json
{
  "success": true,
  "data": {
    "news_intel": { ... },      // Maps to "Strategic News Intel"
    "market_analyst": [ ... ],  // Maps to "Market Analysis"
    "opportunity_scout": [ ... ] // Maps to "Alpha Opportunities"
  }
}
```

---

## 2. News Containers (`news_intel`, `news`, etc.)
Nested object where keys are category names and values are arrays of news items.

### News Item Fields:
- `title` (String): The headline.
- `l` (String): URL to the source.
- `takeaway` (String): Concise summary of the impact.
- `sentiment` (Double/String): Numeric (-1 to 1) or descriptive (e.g., "Bullish").
- `img` (String, optional): URL to a thumbnail.

---

## 3. Market Analysis (`market_analyst`)
Array of objects containing technical and fundamental analysis for specific tickers.

### Market Item Fields:
- `ticker` (String, Required): e.g., "NVDA".
- `name` (String, Optional): e.g., "NVIDIA Corporation".
- `price` (String/Number, Optional): Current spot price (e.g., "$420.69"). **CRITICAL for Nexus accuracy.**
- `change` (String/Number, Optional): Daily % change (e.g., "+2.5%").
- `analysis` (Object/String):
    - If Object: Should contain `outlook`, `catalysts` (List), `risks` (List), and `potential_price_action`.
    - If String: A direct summary.
- `sentiment_score` (Double): -1.0 to 1.0.
- `history` (List of Doubles, Optional): 15-point sparkline data.

---

## 4. Alpha Opportunities (`opportunity_scout` / `opportunities` / `high_signal_divergent`)
Array of objects identifying high-conviction trade setups or macro shifts. These are your "High Signal Divergent" items.

### Opportunity Item Fields:
- `ticker` (String, Optional): Associated asset ticker.
- `name` (String): Name of the opportunity or asset.
- `explanation` (String): Why this is an opportunity.
- `sentiment` (Double/String): Strength of the signal.
- `horizon` (String): Expected timeframe (e.g., "1-3 months").
- `price` / `change` (Optional): Same as Market Analysis.

---

## 5. Integration Notes
- **Fallback Logic**: If `price` is missing, the app attempts to extract it from text (e.g., "$420") in the `potential_price_action` or `explanation` fields. If extraction fails, it defaults to a normalized $100.0 baseline.
- **Sentiment Normalization**: Textual sentiment (e.g., "Very Bullish") is automatically converted to numeric values for UI progress bars and glows.
- **Key Mapping**: Internal keys are automatically formatted for the UI (e.g., `ai_acquisitions` -> **Ai Acquisitions**).
