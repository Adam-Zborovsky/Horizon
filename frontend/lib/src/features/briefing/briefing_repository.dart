import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/api/api_config.dart';
import 'briefing_model.dart';

part 'briefing_repository.g.dart';

@riverpod
class BriefingRepository extends _$BriefingRepository {
  @override
  Future<BriefingData> build() async {
    final response = await http.get(Uri.parse(ApiConfig.briefingEndpoint));
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      
      // Handle case where 'data' might be returned as a string (common with n8n/webhook integrations)
      if (jsonResponse['data'] is String) {
        try {
          jsonResponse['data'] = jsonDecode(jsonResponse['data']);
        } catch (e) {
          // If it's not JSON, we'll let fromJson handle the error or provide an empty map
          jsonResponse['data'] = <String, dynamic>{};
        }
      }
      
      // Ensure data is a Map
      if (jsonResponse['data'] == null) {
        jsonResponse['data'] = <String, dynamic>{};
      }

      return BriefingData.fromJson(jsonResponse);
    } else {
      throw Exception('Failed to load briefing from ${ApiConfig.briefingEndpoint}: Status ${response.statusCode}');
    }
  }
}
