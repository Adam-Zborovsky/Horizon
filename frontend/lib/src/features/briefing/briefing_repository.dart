import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/api/api_config.dart';
import 'package:horizon/src/features/briefing/briefing_config_repository.dart';
import 'briefing_model.dart';

part 'briefing_repository.g.dart';

@riverpod
class BriefingRepository extends _$BriefingRepository {
  String _formatCategory(String key) {
    if (key == 'news_intel') return 'Strategic News Intel';
    if (key == 'market_analyst' || key == 'market_analysis') return 'Market Analysis';
    if (key == 'opportunity_scout' || key == 'opportunities') return 'Alpha Opportunities';
    
    return key.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return '';
      final upperWord = word.toUpperCase();
      if (upperWord == 'AI') return 'AI';
      if (upperWord == 'IPO') return 'IPO';
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).join(' ').trim();
  }

  Map<String, dynamic> _normalizeItem(Map<String, dynamic> map) {
    final result = Map<String, dynamic>.from(map);
    
    // Normalize field variations from different agents
    if (result['outlook_1_3_months'] != null && result['analysis'] == null) {
      result['analysis'] = result['outlook_1_3_months'];
    }
    if (result['price_action_projection'] != null && result['potential_price_action'] == null) {
      result['potential_price_action'] = result['price_action_projection'];
    }
    
    // Flatten nested analysis if present
    if (result['analysis'] is Map<String, dynamic>) {
      final analysis = result['analysis'] as Map<String, dynamic>;
      analysis.forEach((key, value) {
        if (result[key] == null) {
          result[key] = value;
        }
      });
      // Ensure outlook or primary text is mapped to takeaway for display
      final String? outlook = analysis['outlook']?.toString() ?? analysis['outlook_1_3_months']?.toString();
      if (outlook != null) {
        result['takeaway'] = outlook;
      }
    }
    
    // Safety: ensure fields expected by json_serializable as String? are actually strings
    final stringFields = [
      'title', 'takeaway', 'ticker', 'name', 'price', 'change', 
      'explanation', 'horizon', 'potential_price_action'
    ];
    
    for (final field in stringFields) {
      if (result[field] != null && result[field] is! String) {
        result[field] = result[field].toString();
      }
    }
    
    return result;
  }

  @override
  Future<BriefingData> build() async {
    // Watch for config changes
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
          throw Exception('Failed to parse server response: $e');
        }
        
        Map<String, dynamic> firstBriefing;
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
        
        if (rawContent.contains('```')) {
          final RegExp jsonBlockRegex = RegExp(r'```(?:json)?\s*(\{[\s\S]*\})\s*```');
          final match = jsonBlockRegex.firstMatch(rawContent);
          if (match != null) rawContent = match.group(1)!;
        }

        if (rawContent.trim().isEmpty) {
           return const BriefingData(data: {}, success: true, message: 'Empty briefing content.');
        }

        final dynamic decodedContent;
        try {
          decodedContent = jsonDecode(rawContent);
        } catch (e) {
          throw Exception('Failed to parse briefing content: $e');
        }

        final Map<String, CategoryData> categoriesMap = {};

        if (decodedContent is Map<String, dynamic>) {
          // 1. Handle News Containers
          final newsContainers = ['news', 'news_intel', 'news_categories'];
          for (final containerKey in newsContainers) {
            if (decodedContent.containsKey(containerKey)) {
              final dynamic container = decodedContent[containerKey];
              if (container is Map<String, dynamic>) {
                container.forEach((key, value) {
                  if (value is List) {
                    try {
                      final String categoryName = _formatCategory(key);
                      final List<BriefingItem> items = value.map((i) => BriefingItem.fromJson(_normalizeItem(i as Map<String, dynamic>))).toList();
                      
                      double totalSentiment = 0;
                      int count = 0;
                      for (final item in items) {
                        final dynamic s = item.sentiment ?? item.sentimentScore;
                        if (s is num) {
                          totalSentiment += s.toDouble();
                          count++;
                        } else if (s is String) {
                          final lowerS = s.toLowerCase();
                          double? parsed = double.tryParse(s);
                          if (parsed != null) {
                            totalSentiment += parsed;
                            count++;
                          } else {
                            if (lowerS.contains('very bullish') || lowerS.contains('strong buy')) {
                              totalSentiment += 0.9; count++;
                            } else if (lowerS.contains('bullish') || lowerS.contains('buy')) {
                              totalSentiment += 0.7; count++;
                            } else if (lowerS.contains('neutral') || lowerS.contains('hold')) {
                              totalSentiment += 0.0; count++;
                            } else if (lowerS.contains('bearish') || lowerS.contains('sell')) {
                              totalSentiment += -0.7; count++;
                            } else if (lowerS.contains('very bearish') || lowerS.contains('strong sell')) {
                              totalSentiment += -0.9; count++;
                            }
                          }
                        }
                      }
                      categoriesMap[categoryName] = CategoryData(
                        sentimentScore: count > 0 ? totalSentiment / count : 0.0,
                        summary: 'Strategic analysis for $categoryName.',
                        items: items,
                      );
                    } catch (e) {
                      debugPrint('BriefingRepository: Failed to parse news category $key: $e');
                    }
                  }
                });
              }
            }
          }

          // 2. Handle Market Analysis
          final marketContainers = ['market', 'market_analyst', 'market_analysis'];
          for (final containerKey in marketContainers) {
            if (decodedContent.containsKey(containerKey)) {
              final dynamic container = decodedContent[containerKey];
              List<dynamic> itemsList = [];
              if (container is List) {
                itemsList = container;
              } else if (container is Map<String, dynamic>) {
                itemsList = container.values.toList();
              }

              if (itemsList.isNotEmpty) {
                try {
                  final List<BriefingItem> items = itemsList.map((i) => BriefingItem.fromJson(_normalizeItem(i as Map<String, dynamic>))).toList();
                  double totalSentiment = 0;
                  int count = 0;
                  for (final item in items) {
                    final dynamic s = item.sentimentScore ?? item.sentiment;
                    if (s is num) {
                      totalSentiment += s.toDouble();
                      count++;
                    } else if (s is String) {
                      final lowerS = s.toLowerCase();
                      final parsed = double.tryParse(s);
                      if (parsed != null) {
                        totalSentiment += parsed;
                        count++;
                      } else {
                        if (lowerS.contains('very bullish') || lowerS.contains('strong buy')) {
                          totalSentiment += 0.9; count++;
                        } else if (lowerS.contains('bullish') || lowerS.contains('buy')) {
                          totalSentiment += 0.7; count++;
                        } else if (lowerS.contains('neutral') || lowerS.contains('hold')) {
                          totalSentiment += 0.0; count++;
                        } else if (lowerS.contains('bearish') || lowerS.contains('sell')) {
                          totalSentiment += -0.7; count++;
                        } else if (lowerS.contains('very bearish') || lowerS.contains('strong sell')) {
                          totalSentiment += -0.9; count++;
                        }
                      }
                    }
                  }
                  categoriesMap['Market Analysis'] = CategoryData(
                    sentimentScore: count > 0 ? totalSentiment / count : 0.8,
                    summary: 'Technical and fundamental deep dive.',
                    items: items,
                  );
                } catch (e) {
                  debugPrint('BriefingRepository: Failed to parse $containerKey: $e');
                }
              }
            }
          }

          // 3. Handle Alpha Opportunities
          final opportunityContainers = ['opportunities', 'opportunity_scout'];
          for (final containerKey in opportunityContainers) {
            if (decodedContent.containsKey(containerKey)) {
              final dynamic container = decodedContent[containerKey];
              List<dynamic> itemsList = [];
              if (container is List) {
                itemsList = container;
              } else if (container is Map<String, dynamic>) {
                itemsList = container.values.toList();
              }

              if (itemsList.isNotEmpty) {
                try {
                  final List<BriefingItem> items = itemsList.map((i) => BriefingItem.fromJson(_normalizeItem(i as Map<String, dynamic>))).toList();
                  double totalSentiment = 0;
                  int count = 0;
                  for (final item in items) {
                    final dynamic s = item.sentimentScore ?? item.sentiment;
                    if (s is num) {
                      totalSentiment += s.toDouble();
                      count++;
                    } else if (s is String) {
                      final lowerS = s.toLowerCase();
                      final parsed = double.tryParse(s);
                      if (parsed != null) {
                        totalSentiment += parsed;
                        count++;
                      } else {
                        if (lowerS.contains('very bullish') || lowerS.contains('strong buy')) {
                          totalSentiment += 0.9; count++;
                        } else if (lowerS.contains('bullish') || lowerS.contains('buy')) {
                          totalSentiment += 0.7; count++;
                        } else if (lowerS.contains('neutral') || lowerS.contains('hold')) {
                          totalSentiment += 0.0; count++;
                        } else if (lowerS.contains('bearish') || lowerS.contains('sell')) {
                          totalSentiment += -0.7; count++;
                        } else if (lowerS.contains('very bearish') || lowerS.contains('strong sell')) {
                          totalSentiment += -0.9; count++;
                        }
                      }
                    }
                  }
                  categoriesMap['Alpha Opportunities'] = CategoryData(
                    sentimentScore: count > 0 ? totalSentiment / count : 0.9,
                    summary: 'High-signal tactical opportunities.',
                    items: items,
                  );
                } catch (e) {
                  debugPrint('BriefingRepository: Failed to parse $containerKey: $e');
                }
              }
            }
          }

          // Legacy / Generic Support
          if (categoriesMap.isEmpty) {
            decodedContent.forEach((key, value) {
              final String categoryName = _formatCategory(key);
              if (value is Map<String, dynamic>) {
                try {
                  categoriesMap[categoryName] = CategoryData.fromJson(value);
                } catch (e) {
                  debugPrint('BriefingRepository: Failed to parse generic category $categoryName: $e');
                }
              } else if (value is List) {
                try {
                  categoriesMap[categoryName] = CategoryData(
                    sentimentScore: 0.0,
                    summary: 'Direct list feed.',
                    items: value.map((i) => BriefingItem.fromJson(_normalizeItem(i as Map<String, dynamic>))).toList(),
                  );
                } catch (e) {
                  debugPrint('BriefingRepository: Failed to parse generic list $categoryName: $e');
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

  Future<void> triggerBriefing() async {
    final response = await http.post(Uri.parse(ApiConfig.briefingTriggerEndpoint));
    if (response.statusCode != 200) {
      throw Exception('Failed to trigger briefing: ${response.statusCode}');
    }
  }
}
