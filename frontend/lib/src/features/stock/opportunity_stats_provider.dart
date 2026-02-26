import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:http/http.dart' as http;
import '../../core/api/api_config.dart';
import '../auth/auth_repository.dart';

part 'opportunity_stats_provider.g.dart';

class OpportunityStats {
  final int totalLast30Days;
  final int consecutiveTradingDays;
  final DateTime? lastSeen;

  const OpportunityStats({
    required this.totalLast30Days,
    required this.consecutiveTradingDays,
    this.lastSeen,
  });

  factory OpportunityStats.fromJson(Map<String, dynamic> json) {
    return OpportunityStats(
      totalLast30Days: (json['totalLast30Days'] as num?)?.toInt() ?? 0,
      consecutiveTradingDays: (json['consecutiveTradingDays'] as num?)?.toInt() ?? 0,
      lastSeen: json['lastSeen'] != null ? DateTime.tryParse(json['lastSeen'] as String) : null,
    );
  }

  static const OpportunityStats empty = OpportunityStats(
    totalLast30Days: 0,
    consecutiveTradingDays: 0,
  );
}

@riverpod
Future<OpportunityStats> opportunityStats(Ref ref, String ticker) async {
  final authRepo = ref.watch(authRepositoryProvider);
  final token = await authRepo.getToken();

  final response = await http.get(
    Uri.parse(ApiConfig.opportunityStatsEndpoint(ticker)),
    headers: {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    },
  ).timeout(const Duration(seconds: 10));

  if (response.statusCode == 200) {
    return OpportunityStats.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
  return OpportunityStats.empty;
}
