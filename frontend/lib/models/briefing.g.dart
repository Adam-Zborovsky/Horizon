// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'briefing.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BriefingCategory _$BriefingCategoryFromJson(Map<String, dynamic> json) =>
    _BriefingCategory(
      sentimentScore: (json['sentiment_score'] as num).toDouble(),
      summary: json['summary'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => BriefingItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BriefingCategoryToJson(_BriefingCategory instance) =>
    <String, dynamic>{
      'sentiment_score': instance.sentimentScore,
      'summary': instance.summary,
      'items': instance.items,
    };

_BriefingItem _$BriefingItemFromJson(Map<String, dynamic> json) =>
    _BriefingItem(
      ticker: json['ticker'] as String?,
      name: json['name'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      change: (json['change'] as num?)?.toDouble(),
      sentiment: (json['sentiment'] as num?)?.toDouble(),
      analysis: json['analysis'] as String?,
      title: json['title'] as String?,
      l: json['l'] as String?,
      img: json['img'] as String?,
      takeaway: json['takeaway'] as String?,
      source: json['source'] as String?,
      timestamp: json['timestamp'] as String?,
    );

Map<String, dynamic> _$BriefingItemToJson(_BriefingItem instance) =>
    <String, dynamic>{
      'ticker': instance.ticker,
      'name': instance.name,
      'price': instance.price,
      'change': instance.change,
      'sentiment': instance.sentiment,
      'analysis': instance.analysis,
      'title': instance.title,
      'l': instance.l,
      'img': instance.img,
      'takeaway': instance.takeaway,
      'source': instance.source,
      'timestamp': instance.timestamp,
    };
