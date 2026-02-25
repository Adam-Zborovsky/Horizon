import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/api/api_config.dart';
import '../auth/auth_repository.dart';
import 'briefing_config_model.dart';

part 'briefing_config_repository.g.dart';

@riverpod
class BriefingConfigRepository extends _$BriefingConfigRepository {
  @override
  Future<BriefingConfig> build() async {
    return await getConfig();
  }

  Future<Map<String, String>> _getHeaders() async {
    final authRepo = ref.read(authRepositoryProvider);
    final token = await authRepo.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<BriefingConfig> getConfig() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse(ApiConfig.briefingConfigEndpoint),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final dynamic responseBody = json.decode(response.body);
      // Backend might return the config directly or wrapped in { data: ... }
      final data = responseBody is Map && responseBody.containsKey('topics') ? responseBody : responseBody['data'];
      if (data == null) return const BriefingConfig();
      return BriefingConfig.fromJson(data as Map<String, dynamic>);
    } else {
      throw Exception('Failed to load briefing config: ${response.statusCode}');
    }
  }

  Future<void> updateConfig(BriefingConfig config) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse(ApiConfig.briefingConfigEndpoint),
      headers: headers,
      body: json.encode(config.toJson()),
    );
    if (response.statusCode == 200) {
      final dynamic responseBody = json.decode(response.body);
      final data = responseBody is Map && responseBody.containsKey('topics') ? responseBody : responseBody['data'];
      if (data != null) {
        state = AsyncData(BriefingConfig.fromJson(data as Map<String, dynamic>));
      }
    } else {
      throw Exception('Failed to update briefing config: ${response.statusCode}');
    }
  }

  Future<void> toggleTopic(String topicName, bool enabled) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('${ApiConfig.briefingConfigEndpoint}/topic/${Uri.encodeComponent(topicName)}'),
      headers: headers,
      body: json.encode({'enabled': enabled}),
    );
    if (response.statusCode == 200) {
      final dynamic responseBody = json.decode(response.body);
      final data = responseBody is Map && responseBody.containsKey('topics') ? responseBody : responseBody['data'];
      if (data != null) {
        state = AsyncData(BriefingConfig.fromJson(data as Map<String, dynamic>));
      }
    } else {
      throw Exception('Failed to toggle topic: ${response.statusCode}');
    }
  }

  Future<void> removeTopic(String topicName) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('${ApiConfig.briefingConfigEndpoint}/topic/${Uri.encodeComponent(topicName)}'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final dynamic responseBody = json.decode(response.body);
      final data = responseBody is Map && responseBody.containsKey('topics') ? responseBody : responseBody['data'];
      if (data != null) {
        state = AsyncData(BriefingConfig.fromJson(data as Map<String, dynamic>));
      }
    } else {
      throw Exception('Failed to remove topic: ${response.statusCode}');
    }
  }
}

@riverpod
Future<List<String>> recommendedTopics(Ref ref) async {
  final authRepo = ref.read(authRepositoryProvider);
  final token = await authRepo.getToken();
  final response = await http.get(
    Uri.parse('${ApiConfig.briefingConfigEndpoint}/recommended'),
    headers: {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    },
  );
  if (response.statusCode == 200) {
    final dynamic responseBody = json.decode(response.body);
    // Backend returns directly or wrapped in { data: ... }
    final dynamic rawData = responseBody is List ? responseBody : responseBody['data'];
    final List<dynamic> data = rawData ?? [];
    return data.map((e) => e.toString()).toList();
  } else {
    throw Exception('Failed to load recommended topics: ${response.statusCode}');
  }
}
