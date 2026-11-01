// H11 — authenticated observed-market-history repository.
//
// Requests GET /market/instruments/:instrumentId/history (mounted by the H15A
// slice under `${ApiConfig.baseUrl}/market`), always authenticated via the
// existing JWT bearer convention. Responses are parsed into strictly validated
// HistoryResponse models; unavailable/partial/stale states are preserved, and
// nothing in this lane invents or repairs market data. Query parameters are
// validated enums; an invalid range cannot be sent.
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/api/api_config.dart';
import '../auth/auth_repository.dart';
import '../positions/position_repository.dart';
import 'market_models.dart';

part 'market_repository.g.dart';

class MarketRepository {
  MarketRepository({http.Client? client, AuthTokenProvider? tokenProvider})
      : _client = client ?? http.Client(),
        _tokenProvider = tokenProvider ?? _defaultTokenProvider;

  final http.Client _client;
  final AuthTokenProvider _tokenProvider;

  static Future<String?> _defaultTokenProvider() => AuthRepository().getToken();

  /// Fetches observed history for one instrument and semantic range. Pass
  /// [resolution] to request a specific resolution and [snapshotId] to pin an
  /// immutable assessment snapshot.
  Future<HistoryResponse> getHistory({
    required String instrumentId,
    required MarketRange range,
    String? resolution,
    String? snapshotId,
  }) async {
    final url =
        Uri.parse('${ApiConfig.baseUrl}/market/instruments/$instrumentId/history')
            .replace(queryParameters: {
      'range': range.wireValue,
      if (resolution != null) 'resolution': resolution,
      if (snapshotId != null) 'snapshot_id': snapshotId,
    });

    final token = await _tokenProvider();
    final request = http.Request('GET', url);
    request.headers['Accept'] = 'application/json';
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    final response =
        await http.Response.fromStream(await _client.send(request));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException.fromResponse(response.statusCode, response.body);
    }
    return HistoryResponse.fromJson(_decodeJsonObject(response.body));
  }

  Map<String, dynamic> _decodeJsonObject(String body) {
    final decoded = body.isEmpty ? null : _safeDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw ContractFormatException(
          'market history response: expected an object');
    }
    return decoded;
  }

  dynamic _safeDecode(String body) {
    try {
      return jsonDecode(body);
    } on FormatException {
      throw ContractFormatException(
          'market history response: expected JSON');
    }
  }

  /// Cancels in-flight requests and releases the client.
  void close() => _client.close();
}

@riverpod
MarketRepository marketRepository(Ref ref) {
  return MarketRepository(
    tokenProvider: () async {
      final auth = ref.read(authRepositoryProvider);
      return auth.getToken();
    },
  );
}
