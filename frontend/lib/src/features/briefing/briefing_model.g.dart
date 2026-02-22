// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'briefing_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BriefingData _$BriefingDataFromJson(Map<String, dynamic> json) =>
    _BriefingData(
      data: (json['data'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, CategoryData.fromJson(e as Map<String, dynamic>)),
      ),
      message: json['message'] as String?,
      success: json['success'] as bool,
    );

Map<String, dynamic> _$BriefingDataToJson(_BriefingData instance) =>
    <String, dynamic>{
      'data': instance.data,
      'message': instance.message,
      'success': instance.success,
    };

_CategoryData _$CategoryDataFromJson(Map<String, dynamic> json) =>
    _CategoryData(
      sentimentScore: (json['sentiment_score'] as num?)?.toDouble() ?? 0.0,
      summary: json['summary'] as String? ?? '',
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => BriefingItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$CategoryDataToJson(_CategoryData instance) =>
    <String, dynamic>{
      'sentiment_score': instance.sentimentScore,
      'summary': instance.summary,
      'items': instance.items,
    };

_BriefingItem _$BriefingItemFromJson(Map<String, dynamic> json) =>
    _BriefingItem(
      title: json['title'] as String?,
      l: json['l'] as String?,
      sentiment: (json['sentiment'] as num?)?.toDouble(),
      img: json['img'] as String?,
      takeaway: json['takeaway'] as String?,
      ticker: json['ticker'] as String?,
      name: json['name'] as String?,
      price: json['price'] as String?,
      change: json['change'] as String?,
      analysis: json['analysis'] as String?,
      explanation: json['explanation'] as String?,
      horizon: json['horizon'] as String?,
    );

Map<String, dynamic> _$BriefingItemToJson(_BriefingItem instance) =>
    <String, dynamic>{
      'title': instance.title,
      'l': instance.l,
      'sentiment': instance.sentiment,
      'img': instance.img,
      'takeaway': instance.takeaway,
      'ticker': instance.ticker,
      'name': instance.name,
      'price': instance.price,
      'change': instance.change,
      'analysis': instance.analysis,
      'explanation': instance.explanation,
      'horizon': instance.horizon,
    };
