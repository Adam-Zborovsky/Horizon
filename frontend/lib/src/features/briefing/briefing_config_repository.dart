import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/api/api_config.dart';
import 'briefing_config_model.dart';

part 'briefing_config_repository.g.dart';

@riverpod
class BriefingConfigRepository extends _$BriefingConfigRepository {
  @override
  Future<BriefingConfig> build() async {
    return await getConfig();
  }

  Future<BriefingConfig> getConfig() async {
    final response = await http.get(Uri.parse(ApiConfig.briefingConfigEndpoint));
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody = json.decode(response.body);
      return BriefingConfig.fromJson(responseBody['data']);
    } else {
      throw Exception('Failed to load briefing config: ${response.statusCode}');
    }
  }

  Future<BriefingConfig> updateConfig(BriefingConfig config) async {
    final response = await http.put(
      Uri.parse(ApiConfig.briefingConfigEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(config.toJson()),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody = json.decode(response.body);
      return BriefingConfig.fromJson(responseBody['data']);
    } else {
      throw Exception('Failed to update briefing config: ${response.statusCode}');
    }
  }

  Future<BriefingConfig> toggleTopic(String topicName, bool enabled) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.briefingConfigEndpoint}/topic/$topicName'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'enabled': enabled}),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody = json.decode(response.body);
      return BriefingConfig.fromJson(responseBody['data']);
    } else {
      throw Exception('Failed to toggle topic: ${response.statusCode}');
    }
  }
}
