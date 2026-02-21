# Alpha Horizon: Project Context & Blueprint

## Core Philosophy
Alpha Horizon is a tactical intelligence and market monitoring platform. It bridges the gap between **Static Deep Analysis** (received once daily) and **Live Market Interactivity** (real-time tracking). It is designed for high-signal decision support.

## Core Features & Requirements
### 1. The Daily Briefing (Static)
- **Source**: `daily_briefing.json` updated once every 24 hours.
- **Content**: Market Narrative, Macro Drivers, Intelligence Pillars (Geopolitics, Tech, etc.), and Opportunity Scout (Hidden Connections).
- **Sentiment & Feedback**: Each category includes a `sentiment_score` (-1 to 1). 
- **Scale**: Must handle any number of items/categories without layout breakage.

### 2. Market Nexus (Hybrid)
- **Watchlist**: Interactive system to add/remove tickers throughout the day.
- **Live Integration**: Display real-time price data and charts alongside the backend's static analysis.
- **Stock Details**: Deep-dive pages combining live candles with the AI-driven "Signal" and "Analysis" text.

### 3. Intelligence Configuration
- **Category Management**: Screen to toggle/filter intelligence pillars.
- **Recommendations**: UI elements that suggest sectors or categories to watch based on briefing data.

### 4. Design Mandates
- **Clean & Modern**: Minimalist but "alive." Avoid generic AI aesthetics.
- **Visual Feedback**: Use **subtle glows** and color shifts (Green for Positive/Growth, Red for Negative/Conflict) tied to `sentiment_score`.
- **Interactive**: Meaningful use of icons, high-contrast palettes, and smooth transitions.
- **Platform**: Native Mobile (Flutter).

## Technical Architecture
- **Framework**: Flutter with Riverpod (State Management).
- **Navigation**: Multi-page (GoRouter) with a Dashboard/War Room as the entry point.
- **Data Flow**: `AssetBriefingRepository` (initial) -> `InteractiveStockProvider` (Live).

## UI Generation Strategy (Stitch)
- **War Room Dashboard**: High-level intel overview with sentiment glows.
- **Watchlist View**: List with mini-sparklines.
- **Intelligence Detail**: Categorized news stream.
- **Market Intel Detail**: The deep-dive view for specific tickers.
