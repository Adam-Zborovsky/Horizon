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
      await http.put(
        Uri.parse(ApiConfig.briefingConfigEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tickers': state.toList(),
        }),
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      // Silent fail for now, or log
    }
  }
}
