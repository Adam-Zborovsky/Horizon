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
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.briefingEndpoint))
          .timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final dynamic decodedBody = jsonDecode(response.body);
        Map<String, dynamic> firstBriefing;

        // 1. Handle top-level list or map
        if (decodedBody is List) {
          if (decodedBody.isEmpty) {
            return const BriefingData(data: {}, success: true, message: 'No briefing data found.');
          }
          firstBriefing = decodedBody.first as Map<String, dynamic>;
        } else if (decodedBody is Map<String, dynamic>) {
          if (decodedBody['data'] is List && (decodedBody['data'] as List).isNotEmpty) {
            firstBriefing = (decodedBody['data'] as List).first as Map<String, dynamic>;
          } else {
            firstBriefing = decodedBody;
          }
        } else {
          throw Exception('Unexpected response format');
        }
        
        // 2. Extract and clean the nested 'data' content
        dynamic rawData = firstBriefing['data'];
        String rawContent = '';

        if (rawData is String) {
          rawContent = rawData;
        } else if (rawData is Map) {
          rawContent = jsonEncode(rawData);
        } else {
          rawContent = jsonEncode(firstBriefing);
        }
        
        // Clean Markdown if present
        final RegExp jsonRegex = RegExp(r'\{[\s\S]*\}');
        final match = jsonRegex.firstMatch(rawContent);
        if (match != null) {
          rawContent = match.group(0)!;
        }

        // 3. Decode content
        final dynamic decodedContent = jsonDecode(rawContent);
        final Map<String, CategoryData> categoriesMap = {};

        if (decodedContent is Map<String, dynamic>) {
          // Pattern A: categories list
          if (decodedContent.containsKey('categories') && decodedContent['categories'] is List) {
            final List<dynamic> list = decodedContent['categories'];
            for (final item in list) {
              if (item is Map<String, dynamic>) {
                final String name = item['category'] ?? item['name'] ?? 'General';
                categoriesMap[name] = CategoryData.fromJson(item);
              }
            }
          } 
          // Pattern B: direct map
          else {
            decodedContent.forEach((key, value) {
              if (value is Map<String, dynamic> && (value.containsKey('items') || value.containsKey('sentiment_score'))) {
                try {
                  categoriesMap[key] = CategoryData.fromJson(value);
                } catch (e) {
                  // Skip
                }
              }
            });
          }
        }

        return BriefingData(
          data: categoriesMap,
          success: firstBriefing['success'] as bool? ?? true,
          message: firstBriefing['message'] as String?,
        );
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
