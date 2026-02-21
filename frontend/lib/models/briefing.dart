import 'package:freezed_annotation/freezed_annotation.dart';

part 'briefing.freezed.dart';
part 'briefing.g.dart';

@freezed
abstract class BriefingCategory with _$BriefingCategory {
  const factory BriefingCategory({
    @JsonKey(name: 'sentiment_score') required double sentimentScore,
    required String summary,
    required List<BriefingItem> items,
  }) = _BriefingCategory;

  factory BriefingCategory.fromJson(Map<String, dynamic> json) =>
      _$BriefingCategoryFromJson(json);
}

@freezed
abstract class BriefingItem with _$BriefingItem {
  const factory BriefingItem({
    String? ticker,
    String? name,
    double? price,
    double? change,
    double? sentiment,
    String? analysis,
    String? title,
    String? l,
    String? img,
    String? takeaway,
    String? source,
    String? timestamp,
  }) = _BriefingItem;

  factory BriefingItem.fromJson(Map<String, dynamic> json) =>
      _$BriefingItemFromJson(json);
}
