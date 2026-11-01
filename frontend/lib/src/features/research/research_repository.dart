// H11 — authenticated research repository: latest assessment + run state,
// paginated immutable assessment history, run queueing and evidence retrieval.
//
// Endpoints follow CONTRACTS.md §9 under /research. Run queueing sends the
// required Idempotency-Key header. An injectable http.Client supports test
// doubles and cancellation; closing the repository cancels in-flight requests
// and the resulting ClientException is surfaced, never swallowed. Owner
// identity is server-derived from the JWT; no owner or credential value is
// ever written into request payloads.
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/api/api_config.dart';
import '../auth/auth_repository.dart';
import '../positions/position_models.dart';
import '../positions/position_repository.dart';
import 'research_models.dart';

part 'research_repository.g.dart';

class ResearchRepository {
  ResearchRepository({http.Client? client, AuthTokenProvider? tokenProvider})
      : _client = client ?? http.Client(),
        _tokenProvider = tokenProvider ?? _defaultTokenProvider;

  final http.Client _client;
  final AuthTokenProvider _tokenProvider;

  static Future<String?> _defaultTokenProvider() => AuthRepository().getToken();

  Future<dynamic> _sendJson(
    String method,
    Uri url, {
    Object? body,
    Map<String, String> extraHeaders = const {},
  }) async {
    final token = await _tokenProvider();
    final request = http.Request(method, url);
    request.headers['Accept'] = 'application/json';
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    extraHeaders.forEach((key, value) => request.headers[key] = value);
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    final response =
        await http.Response.fromStream(await _client.send(request));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException.fromResponse(response.statusCode, response.body);
    }
    if (response.body.isEmpty) return null;
    try {
      return jsonDecode(response.body);
    } on FormatException {
      throw ContractFormatException('research response: expected JSON');
    }
  }

  /// Latest research state for a position. The real wire is a TOP-LEVEL
  /// object (research.routes.js:67-74): position_id, nullable
  /// latest_assessment, and run_state {last_success, latest_attempt} as two
  /// SEPARATE projections (not full run views). Null assessment when no run
  /// has produced one yet (CONTRACTS §9).
  Future<ResearchLatest> getLatest(String positionId) async {
    final decoded = await _sendJson(
      'GET',
      Uri.parse('${ApiConfig.baseUrl}/research/positions/$positionId/latest'),
    );
    return ResearchLatest.fromJson(_requireObject(decoded, 'latest state'));
  }

  /// Cursor-paginated, owner-scoped immutable assessment history.
  Future<AssessmentPage> listAssessments(
    String positionId, {
    String? cursor,
  }) async {
    final decoded = await _sendJson(
      'GET',
      Uri.parse('${ApiConfig.baseUrl}/research/positions/$positionId/assessments')
          .replace(queryParameters: {
        if (cursor != null) 'cursor': cursor,
      }),
    );
    return AssessmentPage.fromJson(_requireObject(decoded, 'assessments'));
  }

  /// Queues a research run. The idempotency key is required by contract;
  /// duplicate keys return the persisted run, conflicting payloads a 409.
  Future<ResearchRun> queueRun(
    String positionId, {
    required String idempotencyKey,
  }) async {
    if (idempotencyKey.isEmpty || idempotencyKey.length > 255) {
      throw ArgumentError.value(
          idempotencyKey, 'idempotencyKey', 'must be 1-255 characters');
    }
    final decoded = await _sendJson(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/research/positions/$positionId/runs'),
      extraHeaders: {'Idempotency-Key': idempotencyKey},
    );
    return ResearchRun.fromJson(_requireObject(decoded, 'run'));
  }

  /// Owner-scoped run progress with freshness/error metadata.
  Future<ResearchRun> getRun(String runId) async {
    final decoded = await _sendJson(
      'GET',
      Uri.parse('${ApiConfig.baseUrl}/research/runs/$runId'),
    );
    return ResearchRun.fromJson(_requireObject(decoded, 'run'));
  }

  /// Authorized, source-linked evidence excerpt and metadata.
  Future<EvidenceItem> getEvidence(String evidenceId) async {
    final decoded = await _sendJson(
      'GET',
      Uri.parse('${ApiConfig.baseUrl}/research/evidence/$evidenceId'),
    );
    return EvidenceItem.fromJson(_requireObject(decoded, 'evidence'));
  }

  Map<String, dynamic> _requireObject(Object? decoded, String label) {
    if (decoded is! Map<String, dynamic>) {
      throw ContractFormatException('research $label: expected an object');
    }
    return decoded;
  }

  /// Cancels in-flight requests and releases the client.
  void close() => _client.close();
}

@riverpod
ResearchRepository researchRepository(Ref ref) {
  final auth = ref.watch(authRepositoryProvider);
  return ResearchRepository(
    tokenProvider: auth.getToken,
  );
}
