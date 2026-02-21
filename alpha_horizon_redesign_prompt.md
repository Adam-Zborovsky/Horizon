# Alpha Horizon: War Room Dashboard Redesign

## Core Concept
A tactical "War Room" dashboard for a high-signal intelligence and market monitoring platform. The interface must bridge the gap between static daily AI analysis and real-time market data, providing a "command center" feel for elite decision support.

## Design Aesthetic: "Tactical Intelligence"
- **Style**: Minimalist, high-tech, and data-dense but clean. Avoid generic "AI" glowing brains or space backgrounds.
- **Palette**: Deep Charcoal/Onyx background (`#0A0A0B`). High-contrast accents:
  - **Growth/Positive**: Kinetic Green (`#00C805`) with subtle glow.
  - **Conflict/Negative**: Warning Red (`#FF3B30`) with subtle glow.
  - **Intelligence/Neutral**: Cyan/Blue accents for navigation and data points.
- **Micro-interactions**: Subtle glows and color shifts tied to sentiment scores (-1.0 to 1.0). 

## Screen Structure (Mobile)
### 1. Header: Command Center
- Left-aligned title: "ALPHA HORIZON" in a bold, futuristic sans-serif.
- Right-aligned: "Status: Live" indicator with a pulsing green dot.

### 2. The Daily Briefing (Static AI Narrative)
- A prominent card at the top: "BATTLEFIELD REPORT".
- Displays a concise summary of the `AI Daily Briefing`: "Macro momentum driven by AI sector performance. Geopolitical tensions in Northern Israel creating supply chain friction."
- Sentiment indicator: A horizontal gauge showing the overall market sentiment.

### 3. Intelligence Pillars (Categorized Intel)
- Horizontal scroll or 2-column grid of "Intelligence Cards":
  - **Macro-Market Nexus**: Sentiment Score: 0.65 (Glow Green). Summary: AI momentum vs Inflation.
  - **Israel Geopolitics**: Sentiment Score: -0.82 (Glow Red). Summary: Logistical disruptions.
  - **Pulse of the World**: Sentiment Score: 0.15 (Neutral Blue). Summary: Sustainable energy milestones.
- Each card should show the category name, sentiment score, and a one-line summary.

### 4. Market Nexus (Live Watchlist Integration)
- Section: "WATCHLIST SIGNAL".
- List of tickers (e.g., NVDA, AAPL) with:
  - Real-time price and 24h change.
  - A "Signal" tag: "BULLISH", "CAUTION", or "STABLE" based on AI sentiment.
  - Mini sparkline chart.

### 5. Navigation: Tactical Tabs
- Bottom navigation bar with: Dashboard (War Room), Watchlist (Nexus), Configuration (Intel Setup).

## Technical Directives
- Use **Tailwind CSS** for layout and styling.
- Respect the **Mobile Thumb Zone**: Critical intel and navigation should be reachable with one hand.
- Use **System Fonts** (Inter or SF Pro) for maximum legibility.
- Implement **Dark Mode** exclusively.
