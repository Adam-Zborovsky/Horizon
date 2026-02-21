import 'package:freezed_annotation/freezed_annotation.dart';

part 'briefing_config_model.freezed.dart';
part 'briefing_config_model.g.dart';

@freezed
abstract class BriefingConfig with _$BriefingConfig {
  const factory BriefingConfig({
    @Default([]) List<Topic> topics,
    @Default([]) List<String> tickers,
  }) = _BriefingConfig;

  factory BriefingConfig.fromJson(Map<String, dynamic> json) => _$BriefingConfigFromJson(json);
}

@freezed
abstract class Topic with _$Topic {
  const factory Topic({
    required String name,
    required bool enabled,
  }) = _Topic;

  factory Topic.fromJson(Map<String, dynamic> json) => _$TopicFromJson(json);
}
