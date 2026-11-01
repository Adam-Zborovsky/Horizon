import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/api/api_config.dart';
import '../auth/auth_repository.dart';
import 'briefing_config_model.dart';

part 'briefing_config_repository.g.dart';

/// H15: typed, bounded refusal surfaced by the accepted backend contract
/// (CONTRACTS §10 / SPEC §5): a stale tickers-only PUT that would remove
/// tickers backing active positions is refused with `409
/// POSITION_TICKER_CONFLICT` — never a destructive replacement. The wire
/// carries `{success: false, error: {message, code}}`; when the backend
/// includes `error.details.blocked_removals` it is parsed through, but the
/// message is the guaranteed bounded copy (never invented client-side).
class PositionTickerConflictException implements Exception {
  final String code;
  final String message;

  /// `{ticker, active_position_ids}` pairs when the backend exposes them.
  final List<Map<String, dynamic>> blockedRemovals;

  const PositionTickerConflictException({
    this.code = 'POSITION_TICKER_CONFLICT',
    required this.message,
    this.blockedRemovals = const <Map<String, dynamic>>[],
  });

  @override
  String toString() => 'PositionTickerConflictException: $message';
}

/// Generic non-2xx API failure with the status preserved for callers that
/// need to distinguish (e.g. 401 re-auth) from conflicts.
class BriefingConfigApiException implements Exception {
  final int statusCode;
  final String message;
  const BriefingConfigApiException(this.statusCode, this.message);

  @override
  String toString() => 'BriefingConfigApiException($statusCode): $message';
}

@riverpod
class BriefingConfigRepository extends _$BriefingConfigRepository {
  /// Injectable transport seam (accepted H15B ResearchWire pattern): the
  /// production path uses the default `http.Client()`; tests subclass and
  /// return a mock. No new dependency, no generated file.
  http.Client createClient() => http.Client();

  @override
  Future<BriefingConfig> build() async {
    return await getConfig();
  }

  /// Parses the wire body: the backend answers the config directly or
  /// wrapped in `{data: ...}`.
  BriefingConfig _parseConfigBody(String body) {
    final dynamic responseBody = json.decode(body);
    final data = responseBody is Map && responseBody.containsKey('topics')
        ? responseBody
        : responseBody['data'];
    if (data == null) return const BriefingConfig();
    return BriefingConfig.fromJson(data as Map<String, dynamic>);
  }

  /// Maps a non-2xx response to the typed bounded exceptions: 409
  /// POSITION_TICKER_CONFLICT keeps the server message verbatim (the
  /// bounded/explicit refusal copy), everything else is a generic API
  /// failure with the status preserved. Nothing is retried silently.
  Never _throwForResponse(http.Response response) {
    String message = 'Failed (HTTP ${response.statusCode}).';
    List<Map<String, dynamic>> blockedRemovals =
        const <Map<String, dynamic>>[];
    String code = 'HTTP_${response.statusCode}';
    try {
      final dynamic decoded = json.decode(response.body);
      if (decoded is Map && decoded['error'] is Map) {
        final error = decoded['error'] as Map;
        if (error['message'] is String && (error['message'] as String).isNotEmpty) {
          message = error['message'] as String;
        }
        if (error['code'] is String) code = error['code'] as String;
        final details = error['details'];
        if (details is List) {
          blockedRemovals = details
              .whereType<Map>()
              .map((entry) => Map<String, dynamic>.from(entry))
              .toList();
        }
      }
    } catch (_) {
      // Malformed error body: fall back to the generic message; never
      // fabricate conflict details client-side.
    }
    if (response.statusCode == 409 && code == 'POSITION_TICKER_CONFLICT') {
      throw PositionTickerConflictException(
        code: code,
        message: message,
        blockedRemovals: blockedRemovals,
      );
    }
    throw BriefingConfigApiException(response.statusCode, message);
  }

  Future<Map<String, String>> _getHeaders() async {
    final authRepo = ref.read(authRepositoryProvider);
    final token = await authRepo.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<BriefingConfig> getConfig() async {
    final headers = await _getHeaders();
    final client = createClient();
    final response = await client.get(
      Uri.parse(ApiConfig.briefingConfigEndpoint),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return _parseConfigBody(response.body);
    }
    _throwForResponse(response);
  }

  Future<void> updateConfig(BriefingConfig config) async {
    final headers = await _getHeaders();
    final client = createClient();
    final response = await client.put(
      Uri.parse(ApiConfig.briefingConfigEndpoint),
      headers: headers,
      body: json.encode(config.toJson()),
    );
    if (response.statusCode == 200) {
      state = AsyncData(_parseConfigBody(response.body));
      return;
    }
    _throwForResponse(response);
  }

  Future<void> toggleTopic(String topicName, bool enabled) async {
    final headers = await _getHeaders();
    final client = createClient();
    final response = await client.put(
      Uri.parse('${ApiConfig.briefingConfigEndpoint}/topic/${Uri.encodeComponent(topicName)}'),
      headers: headers,
      body: json.encode({'enabled': enabled}),
    );
    if (response.statusCode == 200) {
      state = AsyncData(_parseConfigBody(response.body));
      return;
    }
    _throwForResponse(response);
  }

  Future<void> removeTopic(String topicName) async {
    final headers = await _getHeaders();
    final client = createClient();
    final response = await client.delete(
      Uri.parse('${ApiConfig.briefingConfigEndpoint}/topic/${Uri.encodeComponent(topicName)}'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      state = AsyncData(_parseConfigBody(response.body));
      return;
    }
    _throwForResponse(response);
  }
}

@riverpod
Future<List<String>> recommendedTopics(Ref ref) async {
  final authRepo = ref.read(authRepositoryProvider);
  final token = await authRepo.getToken();
  final response = await http.get(
    Uri.parse('${ApiConfig.briefingConfigEndpoint}/recommended'),
    headers: {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    },
  );
  if (response.statusCode == 200) {
    final dynamic responseBody = json.decode(response.body);
    // Backend returns directly or wrapped in { data: ... }
    final dynamic rawData = responseBody is List ? responseBody : responseBody['data'];
    final List<dynamic> data = rawData ?? [];
    return data.map((e) => e.toString()).toList();
  } else {
    throw Exception('Failed to load recommended topics: ${response.statusCode}');
  }
}
