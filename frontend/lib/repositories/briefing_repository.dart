import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:horizon/models/briefing.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'briefing_repository.g.dart';

@riverpod
class BriefingRepository extends _$BriefingRepository {
  // Replace with your actual n8n or intelligence API endpoint
  static const String _apiEndpoint = 'http://homeserver:3001/api/v1/briefing';

  @override
  Future<Map<String, BriefingCategory>> build() async {
    try {
      // Attempt to fetch live data
      print('📡 Fetching briefing from: $_apiEndpoint');
      final response = await http.get(Uri.parse(_apiEndpoint)).timeout(
        const Duration(seconds: 15),
      );

      print('📡 Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        
        // Check if the response follows the { success: true, data: { ... } } format
        if (body.containsKey('success') && body.containsKey('data')) {
          final data = body['data'];
          if (data is Map<String, dynamic> && data.isNotEmpty) {
            print('✅ Live data fetched and unwrapped successfully');
            return _parseData(data);
          } else {
            print('⚠️ Backend returned success but data is empty or malformed');
          }
        } else {
          // Fallback for direct data access if the wrapper is missing
          print('ℹ️ Response wrapper missing, attempting direct parse');
          return _parseData(body);
        }
      }
    } catch (e) {
      print('❌ Live data fetch failed: $e');
    }

    // Fallback to local asset data if live fetch fails or returns empty
    print('📂 Falling back to local example_output.json');
    final String assetResponse = await rootBundle.loadString('assets/example_output.json');
    final localData = json.decode(assetResponse) as Map<String, dynamic>;
    return _parseData(localData);
  }

  Map<String, BriefingCategory> _parseData(Map<String, dynamic> data) {
    return data.map((key, value) => MapEntry(
          key,
          BriefingCategory.fromJson(value as Map<String, dynamic>),
        ));
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }
}
