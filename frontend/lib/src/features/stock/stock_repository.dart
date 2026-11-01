import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../briefing/briefing_repository.dart';
import '../briefing/briefing_config_repository.dart';

part 'stock_repository.freezed.dart';
part 'stock_repository.g.dart';

enum StockSource { watchlist, opportunity }

@freezed
abstract class StockData with _$StockData {
  const factory StockData({
    required String ticker,
    required String name,
    required double currentPrice,
    required double changePercent,
    required List<double> history, 
    required double sentiment,
    required StockSource source,
    String? analysis,
    String? direction, // "long" or "short" for opportunities
    String? horizon,
    List<String>? catalysts,
    List<String>? risks,
    String? potentialPriceAction,
  }) = _StockData;

  factory StockData.fromJson(Map<String, dynamic> json) => _$StockDataFromJson(json);
}

@riverpod
class StockRepository extends _$StockRepository {
  // H15: authoritative prices are NEVER extracted from prose. No regex
  // scraping of explanation/takeaway/analysis/potential_price_action — the
  // only accepted sources are the model-reported structured fields
  // (item.price, item.change, item.history). Anything else stays
  // "unavailable" (price 0.0 / empty history) and renders truthfully
  // downstream; the detail and Wear surfaces carry the unavailable state.

  double _parseStructuredPrice(String? raw) {
    if (raw == null || raw.isEmpty) return 0.0;
    return double.tryParse(raw.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
  }

  double _parseStructuredChange(String? raw) {
    if (raw == null || raw.isEmpty) return 0.0;
    return double.tryParse(raw.replaceAll(RegExp(r'[^\d.+-]'), '')) ?? 0.0;
  }

  @override
  Future<List<StockData>> build() async {
    final briefing = await ref.watch(briefingRepositoryProvider.future);
    final config = await ref.watch(briefingConfigRepositoryProvider.future);
    
    final List<StockData> stocks = [];
    final seen = <String>{};
    
    // 1. Process items from briefing
    for (final entry in briefing.data.entries) {
      final categoryName = entry.key.toLowerCase();
      final category = entry.value;
      
      final isOpportunityCategory = categoryName.contains('opportunit') || categoryName.contains('scout');

      for (final item in category.items) {
        if (item.ticker != null) {
          final ticker = item.ticker!.toUpperCase();
          
          // If already seen, we might want to update it if the new one is an "opportunity"
          // but for now let's just keep the first one found (usually market_analysis is first)
          if (seen.contains(ticker)) continue;

          // H15: price comes only from the structured model-reported field;
          // prose fields are never scraped. No value → 0.0 ("unavailable").
          final price = _parseStructuredPrice(item.price);

          // H15: change comes only from the structured model-reported field.
          final change = _parseStructuredChange(item.change);
          
          final double sentiment = item.sentimentScore ?? 
              (() {
                final s = item.sentiment;
                if (s is num) return s.toDouble();
                if (s is String) {
                  final lowerS = s.toLowerCase();
                  final parsed = double.tryParse(s);
                  if (parsed != null) return parsed;
                  if (lowerS.contains('very bullish') || lowerS.contains('strong buy')) return 0.9;
                  if (lowerS.contains('bullish') || lowerS.contains('buy')) return 0.7;
                  if (lowerS.contains('neutral') || lowerS.contains('hold')) return 0.0;
                  if (lowerS.contains('bearish') || lowerS.contains('sell')) return -0.7;
                  if (lowerS.contains('very bearish') || lowerS.contains('strong sell')) return -0.9;
                }
                return 0.0;
              })();
          
          // H15B: no synthetic history fallback — only a model-reported
          // history is carried. Missing history stays empty and the detail
          // screen renders a truthful unavailable chart slot.
          final List<double> history = item.history ?? const <double>[];
          final finalPrice = price > 0 ? price : (history.isNotEmpty ? history.last : 0.0);

          // Analysis mapping logic
          String? analysisText;
          if (item.analysis is String) {
            analysisText = item.analysis;
          } else if (item.analysis is Map) {
            // Check for market_outlook or similar nested fields
            final map = item.analysis as Map<String, dynamic>;
            analysisText = map['market_outlook'] ?? map['summary'] ?? item.takeaway;
          } else {
            analysisText = item.explanation ?? item.takeaway;
          }

          stocks.add(StockData(
            ticker: ticker,
            name: item.name ?? ticker,
            currentPrice: finalPrice,
            changePercent: change,
            history: history,
            sentiment: sentiment,
            source: isOpportunityCategory ? StockSource.opportunity : StockSource.watchlist,
            analysis: analysisText,
            direction: item.direction,
            horizon: item.horizon,
            catalysts: item.catalysts,
            risks: item.risks,
            potentialPriceAction: item.potentialPriceAction,
          ));
          seen.add(ticker);
        }
      }
    }
    
    // 2. Add remaining watchlist tickers
    for (final ticker in config.tickers) {
      final upperTicker = ticker.toUpperCase();
      if (!seen.contains(upperTicker)) {
        // H15B: no invented placeholder price/history for watchlist tickers
        // without briefing data — price 0.0 and empty history mean
        // "unavailable", rendered truthfully downstream.
        stocks.add(StockData(
          ticker: upperTicker,
          name: upperTicker,
          currentPrice: 0.0,
          changePercent: 0.0,
          history: const <double>[],
          sentiment: 0.0,
          source: StockSource.watchlist,
        ));
        seen.add(upperTicker);
      }
    }

    return stocks;
  }


}
