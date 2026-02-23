import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/api/api_config.dart';
import 'package:horizon/src/features/briefing/briefing_config_repository.dart';
import 'briefing_model.dart';

part 'briefing_repository.g.dart';

  String _formatCategory(String key) {
    if (key == 'news_intel') return 'Strategic News Intel';
    if (key == 'market_analyst') return 'Market Analysis';
    if (key == 'opportunity_scout') return 'Alpha Opportunities';
    
    return key.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return '';
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).join(' ');
  }

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
          // 1. Handle explicit news containers (Nested Pattern)
          final newsContainers = ['news', 'news_intel', 'news_categories'];
          for (final containerKey in newsContainers) {
            if (decodedContent.containsKey(containerKey)) {
              final dynamic container = decodedContent[containerKey];
              if (container is Map<String, dynamic>) {
                container.forEach((key, value) {
                  if (value is List) {
                    try {
                      final String categoryName = _formatCategory(key);
                      categoriesMap[categoryName] = CategoryData(
                        sentimentScore: 0.0,
                        summary: 'Strategic analysis for $categoryName.',
                        items: value.map((i) => BriefingItem.fromJson(i as Map<String, dynamic>)).toList(),
                      );
                    } catch (e) {
                      debugPrint('BriefingRepository: Failed to parse nested category $key in $containerKey: $e');
                    }
                  }
                });
              }
            }
          }

          // 2. Handle market analysis containers
          final marketContainers = ['market', 'market_analyst', 'market_analysis'];
          for (final containerKey in marketContainers) {
            if (decodedContent.containsKey(containerKey)) {
              final dynamic container = decodedContent[containerKey];
              if (container is List) {
                try {
                  categoriesMap['Market Analysis'] = CategoryData(
                    sentimentScore: 0.8,
                    summary: 'Deep dive analysis of key tickers at technical and fundamental inflection points.',
                    items: container.map((i) {
                      final map = i as Map<String, dynamic>;
                      // Flatten 'analysis' if it's nested (from market_analyst)
                      if (map.containsKey('analysis') && map['analysis'] is Map<String, dynamic>) {
                        final analysis = map['analysis'] as Map<String, dynamic>;
                        return BriefingItem.fromJson({...map, ...analysis});
                      }
                      return BriefingItem.fromJson(map);
                    }).toList(),
                  );
                } catch (e) {
                  debugPrint('BriefingRepository: Failed to parse $containerKey: $e');
                }
              }
            }
          }

          // 3. Handle opportunities containers
          final opportunityContainers = ['opportunities', 'opportunity_scout'];
          for (final containerKey in opportunityContainers) {
            if (decodedContent.containsKey(containerKey)) {
              final dynamic container = decodedContent[containerKey];
              if (container is List) {
                try {
                  categoriesMap['Alpha Opportunities'] = CategoryData(
                    sentimentScore: 0.9,
                    summary: 'High-signal tactical opportunities across diverse market sectors.',
                    items: container.map((i) => BriefingItem.fromJson(i as Map<String, dynamic>)).toList(),
                  );
                } catch (e) {
                  debugPrint('BriefingRepository: Failed to parse $containerKey: $e');
                }
              }
            }
          }

          // Legacy support (if no categories found yet)
          if (categoriesMap.isEmpty) {
            // Pattern A: categories list
            if (decodedContent.containsKey('categories') && decodedContent['categories'] is List) {
              final List<dynamic> list = decodedContent['categories'];
              for (final item in list) {
                if (item is Map<String, dynamic>) {
                  final String name = _formatCategory(item['category'] ?? item['name'] ?? 'General');
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
                final String categoryName = _formatCategory(key);
                if (value is Map<String, dynamic>) {
                  if (value.containsKey('items') || value.containsKey('sentiment_score') || value.containsKey('summary')) {
                    try {
                      categoriesMap[categoryName] = CategoryData.fromJson(value);
                    } catch (e) {
                      debugPrint('BriefingRepository: Failed to parse category $categoryName: $e');
                    }
                  }
                } else if (value is List) {
                  try {
                    categoriesMap[categoryName] = CategoryData(
                      sentimentScore: 0.0,
                      summary: 'Direct item list',
                      items: value.map((i) => BriefingItem.fromJson(i as Map<String, dynamic>)).toList(),
                    );
                  } catch (e) {
                    debugPrint('BriefingRepository: Failed to parse list category $categoryName: $e');
                  }
                }
              });
            }
          }
        }
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
