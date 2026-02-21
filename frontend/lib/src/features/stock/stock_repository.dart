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
  }) = _StockData;

  factory StockData.fromJson(Map<String, dynamic> json) => _$StockDataFromJson(json);
}

@riverpod
class StockRepository extends _$StockRepository {
  @override
  Future<List<StockData>> build() async {
    final briefing = await ref.watch(briefingRepositoryProvider.future);
    
    final List<StockData> stocks = [];
    
    for (final category in briefing.data.values) {
      for (final item in category.items) {
        if (item.ticker != null) {
          // Convert BriefingItem to StockData
          stocks.add(StockData(
            ticker: item.ticker!,
            name: item.name ?? item.ticker!,
            currentPrice: double.tryParse(item.price?.replaceAll(RegExp(r'[^\d.]'), '') ?? '0') ?? 0.0,
            changePercent: double.tryParse(item.change?.replaceAll(RegExp(r'[^\d.+-]'), '') ?? '0') ?? 0.0,
            history: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0], // Placeholder for sparklines
            sentiment: item.sentiment ?? 0.0,
            analysis: item.analysis,
          ));
        }
      }
    }
    
    // Remove duplicates by ticker
    final seen = <String>{};
    return stocks.where((s) => seen.add(s.ticker)).toList();
  }
}
