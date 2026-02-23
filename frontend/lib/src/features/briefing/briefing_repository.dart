import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/api/api_config.dart';
import 'briefing_model.dart';

part 'briefing_repository.g.dart';

@riverpod
class BriefingRepository extends _$BriefingRepository {
  @override
  Future<BriefingData> build() async {
    // Watch for config changes so that the dashboard updates its filtered state
    ref.watch(briefingConfigRepositoryProvider);
    
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.briefingEndpoint))
          .timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          return const BriefingData(data: {}, success: true, message: 'Empty response from server.');
        }

        final dynamic decodedBody;
        try {
          decodedBody = jsonDecode(response.body);
        } catch (e) {
          throw Exception('Failed to parse server response: $e\nBody: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...');
        }
        
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
        } else if (rawData == null) {
          return const BriefingData(data: {}, success: true, message: 'Briefing data is empty.');
        } else {
          rawContent = jsonEncode(firstBriefing);
        }
        
        // Clean Markdown or unwanted wrapper if present
        // Use a more careful approach than just a greedy regex
        if (rawContent.contains('```')) {
          final RegExp jsonBlockRegex = RegExp(r'```(?:json)?\s*(\{[\s\S]*\})\s*```');
          final match = jsonBlockRegex.firstMatch(rawContent);
          if (match != null) {
            rawContent = match.group(1)!;
          }
        }

        // 3. Decode content
        if (rawContent.trim().isEmpty) {
           return const BriefingData(data: {}, success: true, message: 'Empty briefing content.');
        }

        final dynamic decodedContent;
        try {
          decodedContent = jsonDecode(rawContent);
        } catch (e) {
          throw Exception('Failed to parse briefing content: $e\nContent starts with: ${rawContent.substring(0, rawContent.length > 100 ? 100 : rawContent.length)}');
        }

        final Map<String, CategoryData> categoriesMap = {};

        if (decodedContent is Map<String, dynamic>) {
          // Handle the new structure: news_categories, market_analysis, opportunities
          if (decodedContent.containsKey('news_categories')) {
            final Map<String, dynamic> newsCats = decodedContent['news_categories'];
            newsCats.forEach((key, value) {
              if (value is List) {
                try {
                  categoriesMap[key] = CategoryData(
                    sentimentScore: 0.0, // Default for now
                    summary: 'Strategic news analysis for $key.',
                    items: value.map((i) => BriefingItem.fromJson(i as Map<String, dynamic>)).toList(),
                  );
                } catch (e) {
                  debugPrint('BriefingRepository: Failed to parse news category $key: $e');
                }
              }
            });
          }

          if (decodedContent.containsKey('market_analysis')) {
             final List<dynamic> marketAnalysis = decodedContent['market_analysis'];
             try {
                categoriesMap['Market Analysis'] = CategoryData(
                  sentimentScore: 0.8, // Example default
                  summary: 'Deep dive analysis of key tickers at technical and fundamental inflection points.',
                  items: marketAnalysis.map((i) => BriefingItem.fromJson(i as Map<String, dynamic>)).toList(),
                );
             } catch (e) {
               debugPrint('BriefingRepository: Failed to parse market_analysis: $e');
             }
          }

          if (decodedContent.containsKey('opportunities')) {
             final List<dynamic> opportunities = decodedContent['opportunities'];
             try {
                categoriesMap['Opportunities'] = CategoryData(
                  sentimentScore: 0.9,
                  summary: 'High-signal tactical opportunities across diverse market sectors.',
                  items: opportunities.map((i) => BriefingItem.fromJson(i as Map<String, dynamic>)).toList(),
                );
             } catch (e) {
               debugPrint('BriefingRepository: Failed to parse opportunities: $e');
             }
          }

          // Legacy support (if no news_categories, market_analysis, or opportunities found)
          if (categoriesMap.isEmpty) {
            // Pattern A: categories list
            if (decodedContent.containsKey('categories') && decodedContent['categories'] is List) {
              final List<dynamic> list = decodedContent['categories'];
              for (final item in list) {
                if (item is Map<String, dynamic>) {
                  final String name = item['category'] ?? item['name'] ?? 'General';
                  try {
                    categoriesMap[name] = CategoryData.fromJson(item);
                  } catch (e) {
                    debugPrint('BriefingRepository: Failed to parse category $name: $e');
                  }
                }
              }
            } 
            // Pattern B: direct map (keys are category names)
            else {
              decodedContent.forEach((key, value) {
                if (value is Map<String, dynamic>) {
                  if (value.containsKey('items') || value.containsKey('sentiment_score') || value.containsKey('summary')) {
                    try {
                      categoriesMap[key] = CategoryData.fromJson(value);
                    } catch (e) {
                      debugPrint('BriefingRepository: Failed to parse category $key: $e');
                    }
                  }
                } else if (value is List) {
                  try {
                    categoriesMap[key] = CategoryData(
                      sentimentScore: 0.0,
                      summary: 'Direct item list',
                      items: value.map((i) => BriefingItem.fromJson(i as Map<String, dynamic>)).toList(),
                    );
                  } catch (e) {
                    debugPrint('BriefingRepository: Failed to parse list category $key: $e');
                  }
                }
              });
            }
          }
        }

        if (categoriesMap.isEmpty) {
          debugPrint('BriefingRepository: No categories found in decoded content. Keys found: ${decodedContent.keys.join(', ')}');
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

  Future<void> triggerBriefing() async {
    final response = await http.post(Uri.parse(ApiConfig.briefingTriggerEndpoint));
    if (response.statusCode != 200) {
      throw Exception('Failed to trigger briefing: ${response.statusCode}');
    }
  }
}
