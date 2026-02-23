import 'dart:math';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../briefing/briefing_repository.dart';

part 'stock_repository.freezed.dart';
part 'stock_repository.g.dart';

@freezed
abstract class StockData with _$StockData {
  const factory StockData({
    required String ticker,
    required String name,
    required double currentPrice,
    required double changePercent,
    required List<double> history, // Last 24 hours/points for sparkline
    required double sentiment,
    String? analysis,
    List<String>? catalysts,
    List<String>? risks,
    String? potentialPriceAction,
  }) = _StockData;

  factory StockData.fromJson(Map<String, dynamic> json) => _$StockDataFromJson(json);
}

@riverpod
class StockRepository extends _$StockRepository {
  @override
  Future<List<StockData>> build() async {
    final briefing = await ref.watch(briefingRepositoryProvider.future);
    
    final List<StockData> stocks = [];
    final random = Random();
    
    // Check if it's the weekend or Monday morning before market open (9:30 AM ET / 14:30 UTC)
    final now = DateTime.now().toUtc();
    bool isMarketClosed = now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
    
    // Monday pre-market check (before 14:30 UTC)
    if (now.weekday == DateTime.monday && (now.hour < 14 || (now.hour == 14 && now.minute < 30))) {
      isMarketClosed = true;
    }

    for (final category in briefing.data.values) {
      for (final item in category.items) {
        if (item.ticker != null) {
          final double initialPrice = double.tryParse(item.price?.replaceAll(RegExp(r'[^\d.]'), '') ?? '0') ?? 0.0;
          final double change = double.tryParse(item.change?.replaceAll(RegExp(r'[^\d.+-]'), '') ?? '0') ?? 0.0;
          
          // Use sentiment score or fallback to sentiment string/double
          final double sentiment = item.sentimentScore ?? 
              (item.sentiment is double ? item.sentiment as double : 0.0);
          
          // Use history from backend if available, otherwise simulate
          final List<double> history = item.history ?? _generateHistory(initialPrice, change, sentiment, random, isMarketClosed);

          // If price is missing from direct field but present in history, use the latest point
          final double price = initialPrice > 0 ? initialPrice : (history.isNotEmpty ? history.last : 100.0);

          stocks.add(StockData(
            ticker: item.ticker!,
            name: item.name ?? item.ticker!,
            currentPrice: price,
            changePercent: change,
            history: history,
            sentiment: sentiment,
            analysis: item.analysis,
            catalysts: item.catalysts,
            risks: item.risks,
            potentialPriceAction: item.potentialPriceAction,
          ));
        }
      }
    }
    
    // Remove duplicates by ticker
    final seen = <String>{};
    return stocks.where((s) => seen.add(s.ticker)).toList();
  }

  List<double> _generateHistory(double currentPrice, double changePercent, double sentiment, Random random, bool isWeekend) {
    // If price is missing, we can't generate a meaningful chart
    if (currentPrice <= 0) return List.filled(15, 10.0); // Minimal baseline
    
    final List<double> points = [];
    double lastVal = currentPrice;
    
    // We go backwards from the "current" price (which on weekends is the Friday close)
    points.add(currentPrice);
    
    // If change is 0, we add a tiny bit of "noise" so it's not a perfectly flat line
    final effectiveChange = changePercent == 0 ? (random.nextDouble() - 0.5) * 0.5 : changePercent;

    for (int i = 0; i < 14; i++) {
      // Volatility based on current price
      final volatility = currentPrice * 0.012; 
      
      // Bias: if the day was very positive (large change), the price likely trended up
      // So going backwards, it should trend down.
      final bias = (effectiveChange / 100) * (currentPrice / 10);
      
      // Add randomness + sentiment influence + trend bias
      final noise = (random.nextDouble() - 0.5) * volatility;
      final sentimentInfluence = sentiment * (currentPrice * 0.002);
      
      lastVal = lastVal - bias + noise - sentimentInfluence;
      
      // Floor it to 70% of current price to avoid deep dives
      if (lastVal < currentPrice * 0.7) lastVal = currentPrice * 0.7 + (random.nextDouble() * 5);
      
      points.insert(0, lastVal);
    }
    
    return points;
  }
}
