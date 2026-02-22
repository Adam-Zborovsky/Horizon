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
    @JsonKey(name: 'sentiment_score') required double sentimentScore,
    required String summary,
    required List<BriefingItem> items,
  }) = _CategoryData;

  factory CategoryData.fromJson(Map<String, dynamic> json) => _$CategoryDataFromJson(json);
}

@freezed
abstract class BriefingItem with _$BriefingItem {
  const factory BriefingItem({
    String? title,
    String? l,
    double? sentiment,
    String? img,
    String? takeaway,
    String? ticker,
    String? name,
    String? price,
    String? change,
    String? analysis,
    String? explanation,
    String? horizon,
  }) = _BriefingItem;

  factory BriefingItem.fromJson(Map<String, dynamic> json) => _$BriefingItemFromJson(json);
}
