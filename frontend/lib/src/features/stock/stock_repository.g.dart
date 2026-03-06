// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_repository.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StockData _$StockDataFromJson(Map<String, dynamic> json) => _StockData(
  ticker: json['ticker'] as String,
  name: json['name'] as String,
  currentPrice: (json['currentPrice'] as num).toDouble(),
  changePercent: (json['changePercent'] as num).toDouble(),
  history: (json['history'] as List<dynamic>)
      .map((e) => (e as num).toDouble())
      .toList(),
  sentiment: (json['sentiment'] as num).toDouble(),
  source: $enumDecode(_$StockSourceEnumMap, json['source']),
  analysis: json['analysis'] as String?,
  direction: json['direction'] as String?,
  horizon: json['horizon'] as String?,
  catalysts: (json['catalysts'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  risks: (json['risks'] as List<dynamic>?)?.map((e) => e as String).toList(),
  potentialPriceAction: json['potentialPriceAction'] as String?,
);

Map<String, dynamic> _$StockDataToJson(_StockData instance) =>
    <String, dynamic>{
      'ticker': instance.ticker,
      'name': instance.name,
      'currentPrice': instance.currentPrice,
      'changePercent': instance.changePercent,
      'history': instance.history,
      'sentiment': instance.sentiment,
      'source': _$StockSourceEnumMap[instance.source]!,
      'analysis': instance.analysis,
      'direction': instance.direction,
      'horizon': instance.horizon,
      'catalysts': instance.catalysts,
      'risks': instance.risks,
      'potentialPriceAction': instance.potentialPriceAction,
    };

const _$StockSourceEnumMap = {
  StockSource.watchlist: 'watchlist',
  StockSource.opportunity: 'opportunity',
};

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(StockRepository)
final stockRepositoryProvider = StockRepositoryProvider._();

final class StockRepositoryProvider
    extends $AsyncNotifierProvider<StockRepository, List<StockData>> {
  StockRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'stockRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$stockRepositoryHash();

  @$internal
  @override
  StockRepository create() => StockRepository();
}

String _$stockRepositoryHash() => r'ba122da78ee140d443eef1b5f343f6e40617566b';

abstract class _$StockRepository extends $AsyncNotifier<List<StockData>> {
  FutureOr<List<StockData>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<StockData>>, List<StockData>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<StockData>>, List<StockData>>,
              AsyncValue<List<StockData>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
