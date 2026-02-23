import 'package:freezed_annotation/freezed_annotation.dart';

part 'briefing_model.freezed.dart';
part 'briefing_model.g.dart';

@freezed
abstract class BriefingData with _$BriefingData {
  const factory BriefingData({
    required Map<String, CategoryData> data,
    String? message,
    required bool success,
  }) = _BriefingData;

  factory BriefingData.fromJson(Map<String, dynamic> json) => _$BriefingDataFromJson(json);
}

@freezed
abstract class CategoryData with _$CategoryData {
  const factory CategoryData({
    @JsonKey(name: 'sentiment_score') @Default(0.0) double sentimentScore,
    @Default('') String summary,
    @Default([]) List<BriefingItem> items,
  }) = _CategoryData;

  factory CategoryData.fromJson(Map<String, dynamic> json) => _$CategoryDataFromJson(json);
}

@freezed
abstract class BriefingItem with _$BriefingItem {
  const factory BriefingItem({
    String? title,
    String? l,
    dynamic sentiment, // Changed to dynamic to handle both double and String
    String? img,
    String? takeaway,
    String? ticker,
    String? name,
    String? price,
    String? change,
    String? analysis,
    String? explanation,
    String? horizon,
    // New fields from market_analysis
    List<String>? catalysts,
    List<String>? risks,
    @JsonKey(name: 'potential_price_action') String? potentialPriceAction,
    @JsonKey(name: 'sentiment_score') double? sentimentScore,
  }) = _BriefingItem;

  factory BriefingItem.fromJson(Map<String, dynamic> json) => _$BriefingItemFromJson(json);
}
