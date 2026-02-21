import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/api/api_config.dart';

part 'watchlist_provider.g.dart';

@riverpod
class Watchlist extends _$Watchlist {
  @override
  Set<String> build() {
    return {'MU', 'STX', 'RXT', 'BTC-USD'};
  }

  Future<void> add(String ticker) async {
    state = {...state, ticker.toUpperCase()};
    await _syncWithN8N();
  }

  Future<void> remove(String ticker) async {
    state = {...state}..remove(ticker.toUpperCase());
    await _syncWithN8N();
  }

  bool contains(String ticker) => state.contains(ticker.toUpperCase());

  Future<void> _syncWithN8N() async {
    try {
      final topics = ref.read(followedTopicsProvider);
      await http.post(
        Uri.parse(ApiConfig.configWebhookEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'data': {
            'topics': topics.toList(),
            'tickers': state.toList(),
          }
        }),
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      // Silent fail for now, or log
    }
  }
}

@riverpod
class FollowedTopics extends _$FollowedTopics {
  @override
  Set<String> build() {
    return {
      'Artificial Intelligence',
      'Market Trends',
      'Semiconductors',
      'Israel Geopolitics',
      'Israel General News',
      'Positive News',
    };
  }

  Future<void> toggle(String topic) async {
    if (state.contains(topic)) {
      state = {...state}..remove(topic);
    } else {
      state = {...state, topic};
    }
    await _syncWithN8N();
  }

  Future<void> _syncWithN8N() async {
    try {
      final tickers = ref.read(watchlistProvider);
      await http.post(
        Uri.parse(ApiConfig.configWebhookEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'data': {
            'topics': state.toList(),
            'tickers': tickers.toList(),
          }
        }),
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      // Silent fail
    }
  }
}
