# Primary sources and evidence limitations

These sources informed the design. They do not prove future individual-stock forecasting outperformance or authorize installation. Live documentation can change; use the pinned project's actual API/version during implementation.

## Research patterns

- FinAgent: https://arxiv.org/html/2402.18485v3 — multimodal prices/charts/text, tools, reflection and memory. Useful architecture; it does not isolate a reliable chart-vision advantage for Horizon's one/three-month task.
- FinMem: https://arxiv.org/abs/2311.13743 — layered memory/reflection. Transfer explicit dated thesis, rationale, risk and outcome state rather than treating old model text as facts.
- FinCON: https://arxiv.org/abs/2405.14767 — multi-agent financial analysis architecture. More debate is not a substitute for source/number/cutoff validation.
- TradingAgents: https://github.com/TauricResearch/TradingAgents — analyst/tool/researcher separation and debate patterns. No need to adopt its whole runtime.
- FinRobot: https://github.com/AI4Finance-Foundation/FinRobot — financial retrieval/analysis tool patterns. Evaluate source availability/cost before adopting adapters.
- SEC developer APIs: https://www.sec.gov/search-filings/edgar-application-programming-interfaces — filings/company facts; period, unit, amendment and availability handling are required. SEC facts are not consensus, all transcripts or all global-company coverage.

Horizon should evaluate evidence quality, continuity and decision clarity separately from predictive returns. Pretrained future-event knowledge can contaminate historical LLM tests despite date filters. Use point-in-time snapshots and forward-recorded outcomes before claims of edge.

## Chart libraries

- fl_chart exact package metadata: https://pub.dev/api/packages/fl_chart/versions/1.1.1
- Versioned package/changelog: https://pub.dev/packages/fl_chart/versions/1.1.1/changelog
- Current package page: https://pub.dev/packages/fl_chart

Planning verification downloaded the official archive **in memory only**, inspected `lib/src/chart/candlestick_chart/` and `lib/src/chart/base/axis_chart/transformation_config.dart`, and confirmed OHLC candle fields in version 1.1.1. Volume/timestamp are not native CandlestickSpot fields; Horizon must keep its own typed bars and mapping. The pubspec constraint does not establish the lock resolution, and current API documentation may redirect to a newer release. Source capability is not proof the finished UI passes mobile interactions.

- Syncfusion candle charts: https://help.syncfusion.com/flutter/cartesian-charts/chart-types/candle-chart
- Syncfusion interaction: https://help.syncfusion.com/flutter/cartesian-charts/trackball-crosshair and https://help.syncfusion.com/flutter/cartesian-charts/zoom-pan
- Syncfusion licensing: https://www.syncfusion.com/products/communitylicense — eligibility/license acceptance must be confirmed; not preapproved.
- TradingView hosted-widget FAQ: https://www.tradingview.com/widget-docs/faq/ — do not mistake hosted widgets for a custom Horizon datafeed/overlay engine.
- Lightweight Charts: https://www.tradingview.com/lightweight-charts/ and https://tradingview.github.io/lightweight-charts/docs — self-hosted observed line/candle data and custom series/primitives, with attribution requirements; Flutter needs a tested WebView bridge and own OHLCV tooltip/time mapping.
- Advanced Charts: https://www.tradingview.com/charting-library-docs/latest/getting_started/ — proprietary access/licensing and custom datafeed integration, not the same product as widgets or Lightweight Charts.

## Project audit evidence

The planning session inspected actual backend/frontend/workflow sources and retained AMD history. Cross-day context was missing even where historical indicator arithmetic was correct. This design addresses persistent reasoning, not just daily prompt wording. Scratch audit attachments are not required by the orchestrator package and must not become production dependencies.

No UI implementation, new renderer install, forecast calibration, mobile build or production rollout was performed by writing these documents.
