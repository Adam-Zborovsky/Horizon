// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'briefing_config_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BriefingConfig _$BriefingConfigFromJson(Map<String, dynamic> json) =>
    _BriefingConfig(
      topics:
          (json['topics'] as List<dynamic>?)
              ?.map((e) => Topic.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      tickers:
          (json['tickers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$BriefingConfigToJson(_BriefingConfig instance) =>
    <String, dynamic>{'topics': instance.topics, 'tickers': instance.tickers};

_Topic _$TopicFromJson(Map<String, dynamic> json) =>
    _Topic(name: json['name'] as String, enabled: json['enabled'] as bool);

Map<String, dynamic> _$TopicToJson(_Topic instance) => <String, dynamic>{
  'name': instance.name,
  'enabled': instance.enabled,
};
