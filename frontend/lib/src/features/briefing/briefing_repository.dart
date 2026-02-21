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
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> topLevel = jsonDecode(response.body);
        
        // 1. Get the first element of the 'data' list
        final dynamic dataList = topLevel['data'];
        if (dataList == null || dataList is! List || dataList.isEmpty) {
          return const BriefingData(data: {}, success: true, message: 'No briefing data found.');
        }
        
        final Map<String, dynamic> firstBriefing = dataList.first as Map<String, dynamic>;
        
        // 2. Extract and clean the nested 'data' string which contains Markdown-wrapped JSON
        String rawContent = firstBriefing['data'] as String? ?? '';
        
        // Use regex to extract the first JSON block found in the string
        final RegExp jsonRegex = RegExp(r'\{[\s\S]*\}');
        final match = jsonRegex.firstMatch(rawContent);
        
        if (match != null) {
          rawContent = match.group(0)!;
        } else {
          // Fallback to simple cleaning if regex fails
          rawContent = rawContent.replaceAll('```json', '').replaceAll('```', '').trim();
        }
        
        if (rawContent.isEmpty) {
          return const BriefingData(data: {}, success: true, message: 'Empty briefing content.');
        }

        // 3. Decode the actual intelligence content
        Map<String, dynamic> decodedContent;
        try {
          decodedContent = jsonDecode(rawContent);
        } catch (e) {
          return const BriefingData(data: {}, success: true, message: 'JSON Decode failed on nested data.');
        }

        final List<dynamic> categoriesList = decodedContent['categories'] as List? ?? [];

        // 4. Map the list of category objects into our expected Map structure for the UI
        final Map<String, CategoryData> categoriesMap = {};
        
        for (final catJson in categoriesList) {
          if (catJson is Map<String, dynamic>) {
            final String name = catJson['category'] as String? ?? 'General Intelligence';
            
            try {
              // Ensure numbers are doubles even if they arrive as ints
              final sentiment = catJson['sentiment_score'];
              final List<dynamic> items = catJson['items'] as List? ?? [];
              
              categoriesMap[name] = CategoryData(
                sentimentScore: (sentiment is num) ? sentiment.toDouble() : 0.0,
                summary: catJson['summary'] as String? ?? 'No summary.',
                items: items.whereType<Map<String, dynamic>>().map((i) {
                  // Pre-process item numbers to avoid type errors
                  final itemSentiment = i['sentiment'];
                  final processedItem = Map<String, dynamic>.from(i);
                  if (itemSentiment is num) {
                    processedItem['sentiment'] = itemSentiment.toDouble();
                  }
                  return BriefingItem.fromJson(processedItem);
                }).toList(),
              );
            } catch (e) {
              // Log or skip broken categories
            }
          }
        }

        return BriefingData(
          data: categoriesMap,
          success: topLevel['success'] as bool? ?? true,
          message: firstBriefing['message'] as String?,
        );
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      // Re-throw to let Riverpod handle the error state in the UI
      rethrow;
    }
  }
}
