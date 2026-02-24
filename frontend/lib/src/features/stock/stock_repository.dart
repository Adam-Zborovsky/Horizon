import 'dart:math';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../briefing/briefing_repository.dart';
import '../briefing/briefing_config_repository.dart';

part 'stock_repository.freezed.dart';
part 'stock_repository.g.dart';

@freezed
abstract class StockData with _$StockData {
  const factory StockData({
    required String ticker,
    required String name,
    required double currentPrice,
    required double changePercent,
    required List<double> history, 
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
  double _extractPrice(String? text) {
    if (text == null || text.isEmpty) return 0.0;
    // Prioritize patterns with $ sign
    final regexDollar = RegExp(r'\$\s*(\d+(?:\.\d+)?)');
    final matchDollar = regexDollar.firstMatch(text);
    if (matchDollar != null) {
      return double.tryParse(matchDollar.group(1) ?? '0') ?? 0.0;
    }
    // Then look for numbers that look like stock prices (XX.XX or XXX.XX)
    final regexNum = RegExp(r'\b(\d{1,4}\.\d{2})\b');
    final matchNum = regexNum.firstMatch(text);
    if (matchNum != null) {
      return double.tryParse(matchNum.group(1) ?? '0') ?? 0.0;
    }
    return 0.0;
  }

  double _extractChange(String? text) {
    if (text == null || text.isEmpty) return 0.0;
    final regexPercent = RegExp(r'([+-]?\d+(?:\.\d+)?)\s*%');
    final matchPercent = regexPercent.firstMatch(text);
    if (matchPercent != null) {
      return double.tryParse(matchPercent.group(1) ?? '0') ?? 0.0;
    }
    return 0.0;
  }

  @override
  Future<List<StockData>> build() async {
    final briefing = await ref.watch(briefingRepositoryProvider.future);
    final config = await ref.watch(briefingConfigRepositoryProvider.future);
    
    final List<StockData> stocks = [];
    final random = Random();
    final seen = <String>{};
    
    final now = DateTime.now().toUtc();
    bool isMarketClosed = now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
    if (now.weekday == DateTime.monday && (now.hour < 14 || (now.hour == 14 && now.minute < 30))) {
      isMarketClosed = true;
    }

    // 1. Process items from briefing
    for (final category in briefing.data.values) {
      for (final item in category.items) {
        if (item.ticker != null) {
          final ticker = item.ticker!.toUpperCase();
          if (seen.contains(ticker)) continue;

          // Price extraction
          double price = double.tryParse(item.price?.replaceAll(RegExp(r'[^\d.]'), '') ?? '0') ?? 0.0;
          if (price == 0) {
            price = _extractPrice(item.potentialPriceAction);
            if (price == 0) price = _extractPrice(item.explanation);
            if (price == 0) price = _extractPrice(item.takeaway);
            if (price == 0) price = _extractPrice(item.analysis?.toString());
          }

          // Change extraction
          double change = double.tryParse(item.change?.replaceAll(RegExp(r'[^\d.+-]'), '') ?? '0') ?? 0.0;
          if (change == 0) {
            change = _extractChange(item.potentialPriceAction);
            if (change == 0) change = _extractChange(item.explanation);
            if (change == 0) change = _extractChange(item.takeaway);
          }
          
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
          
          final List<double> history = item.history ?? _generateHistory(price > 0 ? price : 100.0, change, sentiment, random, isMarketClosed);
          final finalPrice = price > 0 ? price : (history.isNotEmpty ? history.last : 100.0);

          stocks.add(StockData(
            ticker: ticker,
            name: item.name ?? ticker,
            currentPrice: finalPrice,
            changePercent: change,
            history: history,
            sentiment: sentiment,
            analysis: item.analysis is String ? item.analysis : (item.analysis is Map ? item.takeaway : null),
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
        final double price = 100.0; 
        final List<double> history = _generateHistory(price, 0.0, 0.0, random, isMarketClosed);
        
        stocks.add(StockData(
          ticker: upperTicker,
          name: upperTicker,
          currentPrice: price,
          changePercent: 0.0,
          history: history,
          sentiment: 0.0,
        ));
        seen.add(upperTicker);
      }
    }

    return stocks;
  }

  List<double> _generateHistory(double currentPrice, double changePercent, double sentiment, Random random, bool isWeekend) {
    if (currentPrice <= 0) return List.filled(15, 10.0);
    final List<double> points = [];
    double lastVal = currentPrice;
    points.add(currentPrice);
    final effectiveChange = changePercent == 0 ? (random.nextDouble() - 0.5) * 0.5 : changePercent;
    for (int i = 0; i < 14; i++) {
      final volatility = currentPrice * 0.012; 
      final bias = (effectiveChange / 100) * (currentPrice / 10);
      final noise = (random.nextDouble() - 0.5) * volatility;
      final sentimentInfluence = sentiment * (currentPrice * 0.002);
      lastVal = lastVal - bias + noise - sentimentInfluence;
      if (lastVal < currentPrice * 0.7) lastVal = currentPrice * 0.7 + (random.nextDouble() * 5);
      points.insert(0, lastVal);
    }
    return points;
  }
}
