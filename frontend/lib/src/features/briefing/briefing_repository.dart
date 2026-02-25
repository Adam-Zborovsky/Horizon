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
  double? _parseSentiment(dynamic s) {
    if (s == null) return null;
    if (s is num) return s.toDouble();
    if (s is String) {
      final lowerS = s.toLowerCase().trim();
      final parsed = double.tryParse(lowerS);
      if (parsed != null) return parsed;
      
      // Standard descriptive sentiments
      if (lowerS.contains('very bullish') || lowerS.contains('strong buy')) return 0.95;
      if (lowerS.contains('bullish') || lowerS.contains('buy') || lowerS.contains('positive')) return 0.75;
      if (lowerS.contains('neutral') || lowerS.contains('hold') || lowerS.contains('mixed')) return 0.0;
      if (lowerS.contains('bearish') || lowerS.contains('sell') || lowerS.contains('negative')) return -0.75;
      if (lowerS.contains('very bearish') || lowerS.contains('strong sell')) return -0.95;
      
      // Additional keywords
      if (lowerS.contains('volatile')) return 0.1;
      if (lowerS.contains('conflict') || lowerS.contains('danger')) return -0.5;
      if (lowerS.contains('growth') || lowerS.contains('expansion')) return 0.5;
    }
    return null;
  }

  String _formatCategory(String key) {
    if (key == 'news_intel') return 'Strategic News Intel';
    if (key == 'market_analyst' || key == 'market_analysis') return 'Market Analysis';
    if (key == 'opportunity_scout' || key == 'opportunities' || key == 'high_signal_divergent') return 'Alpha Opportunities';
    
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
      
      // Extract specific fields if they exist in the analysis map
      final outlook = analysis['outlook']?.toString() ?? analysis['outlook_1_3_months']?.toString();
      final catalysts = analysis['catalysts'];
      final risks = analysis['risks'];
      final priceAction = analysis['potential_price_action']?.toString() ?? analysis['price_action_projection']?.toString();

      if (result['takeaway'] == null && outlook != null) result['takeaway'] = outlook;
      if (result['catalysts'] == null && catalysts != null) result['catalysts'] = catalysts;
      if (result['risks'] == null && risks != null) result['risks'] = risks;
      if (result['potential_price_action'] == null && priceAction != null) result['potential_price_action'] = priceAction;

      // Convert the main analysis field to a readable string if it's still a Map
      // Prefer outlook, or join all values
      result['analysis'] = outlook ?? analysis.values.where((v) => v is String).join('\n');
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

    // Handle analysis if it's still not a string
    if (result['analysis'] != null && result['analysis'] is! String) {
      result['analysis'] = result['analysis'].toString();
    }

    // Ensure catalysts and risks are List<String>
    final listStringFields = ['catalysts', 'risks'];
    for (final field in listStringFields) {
      if (result[field] != null) {
        if (result[field] is List) {
          result[field] = (result[field] as List).map((e) => e.toString()).toList();
        } else if (result[field] is String) {
          // If it's a string, try to split it or put it in a list
          final String val = result[field];
          if (val.contains(',')) {
            result[field] = val.split(',').map((e) => e.trim()).toList();
          } else {
            result[field] = [val];
          }
        } else {
          result[field] = [result[field].toString()];
        }
      }
    }

    // Ensure history is List<double>
    if (result['history'] != null) {
      if (result['history'] is List) {
        result['history'] = (result['history'] as List).map((e) {
          if (e is num) return e.toDouble();
          if (e is String) return double.tryParse(e) ?? 0.0;
          return 0.0;
        }).toList();
      } else {
        result.remove('history'); // Remove if it's not a list to avoid crash
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
                        final score = _parseSentiment(item.sentiment ?? item.sentimentScore);
                        if (score != null) {
                          totalSentiment += score;
                          count++;
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
                    final score = _parseSentiment(item.sentimentScore ?? item.sentiment);
                    if (score != null) {
                      totalSentiment += score;
                      count++;
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
                    final score = _parseSentiment(item.sentimentScore ?? item.sentiment);
                    if (score != null) {
                      totalSentiment += score;
                      count++;
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

          // 4. Handle any other top-level categories (Generic Support)
          decodedContent.forEach((key, value) {
            final String categoryName = _formatCategory(key);
            // Skip already processed standard containers
            if (newsContainers.contains(key) || 
                marketContainers.contains(key) || 
                opportunityContainers.contains(key)) return;

            if (value is Map<String, dynamic>) {
              try {
                categoriesMap[categoryName] = CategoryData.fromJson(value);
              } catch (e) {
                debugPrint('BriefingRepository: Failed to parse generic category map $categoryName: $e');
              }
            } else if (value is List) {
              try {
                final List<BriefingItem> items = value.map((i) => BriefingItem.fromJson(_normalizeItem(i as Map<String, dynamic>))).toList();
                
                double totalSentiment = 0;
                int count = 0;
                for (final item in items) {
                  final score = _parseSentiment(item.sentiment ?? item.sentimentScore);
                  if (score != null) {
                    totalSentiment += score;
                    count++;
                  }
                }

                categoriesMap[categoryName] = CategoryData(
                  sentimentScore: count > 0 ? totalSentiment / count : 0.0,
                  summary: 'Direct item list feed.',
                  items: items,
                );
              } catch (e) {
                debugPrint('BriefingRepository: Failed to parse generic list $categoryName: $e');
              }
            }
          });
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
