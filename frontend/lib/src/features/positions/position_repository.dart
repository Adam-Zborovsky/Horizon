// H11 — authenticated position repository for the contract-version-1 API.
//
// Conventions traced from the existing codebase before implementation
// (per the H11 execution steps — no new shared api_client.dart is invented):
// - Token storage/lookup: AuthRepository (SharedPreferences, `auth_token` key)
//   in frontend/lib/src/features/auth/auth_repository.dart.
// - Request style: per-repository `package:http` calls attaching
//   `Authorization: Bearer <token>` only when a token exists, as in
//   briefing_config_repository.dart.
// - Provider wiring: plain class + `@riverpod` factory function as in
//   auth_repository.dart.
// - Base URL: ApiConfig.baseUrl (api_config.dart is a shared file owned by
//   another lane; it is imported, never edited here).
//
// An http.Client can be injected for tests; closing the repository cancels
// in-flight requests by closing the client, and the resulting ClientException
// is surfaced, never swallowed. Owner identity is server-derived from the JWT
// and never placed into write payloads (CONTRACTS §2/§9).
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/api/api_config.dart';
import '../auth/auth_repository.dart';
import 'position_models.dart';

part 'position_repository.g.dart';

/// A typed, safe API error. `code`/`message` come from the global error
/// envelope `{success, error: {message, code}}` or the position routes' flat
/// forwarded envelope `{code, message}`; raw upstream payloads or tokens are
/// never included.
class ApiException implements Exception {
  ApiException(this.statusCode, {required this.code, this.message});

  final int statusCode;
  final String code;
  final String? message;

  static ApiException fromResponse(int statusCode, String body) {
    String code = 'HTTP_$statusCode';
    String? message;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic>) {
          final errorCode = error['code'];
          if (errorCode is String && errorCode.isNotEmpty) code = errorCode;
          final errorMessage = error['message'];
          if (errorMessage is String && errorMessage.isNotEmpty) {
            message = errorMessage;
          }
        } else {
          // Position routes forward typed service errors as a flat
          // {code, message} body (position.routes.js error forwarding),
          // e.g. REVISION_CONFLICT / DUPLICATE_POSITION.
          final flatCode = decoded['code'];
          if (flatCode is String && flatCode.isNotEmpty) code = flatCode;
          final flatMessage = decoded['message'];
          if (flatMessage is String && flatMessage.isNotEmpty) {
            message = flatMessage;
          }
        }
      }
    } on FormatException {
      // Non-JSON error body: keep the synthetic status code.
    }
    return ApiException(statusCode, code: code, message: message);
  }

  @override
  String toString() =>
      'ApiException($statusCode, $code${message == null ? '' : ': $message'})';
}

typedef AuthTokenProvider = Future<String?> Function();

class PositionRepository {
  PositionRepository({http.Client? client, AuthTokenProvider? tokenProvider})
      : _client = client ?? http.Client(),
        _tokenProvider = tokenProvider ?? _defaultTokenProvider;

  final http.Client _client;
  final AuthTokenProvider _tokenProvider;

  static Future<String?> _defaultTokenProvider() => AuthRepository().getToken();

  Uri _uri(String path, [Map<String, String>? queryParameters]) =>
      Uri.parse('${ApiConfig.baseUrl}$path')
          .replace(queryParameters: queryParameters);

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
    return jsonDecode(response.body);
  }

  /// Owner's tracked positions. The backend always answers
  /// `{positions: [...]}` (position.routes.js:43); any other shape is a
  /// contract drift and throws rather than being repaired.
  Future<List<Position>> getPositions() async {
    final decoded = await _sendJson('GET', _uri('/positions'));
    final List<dynamic> items = switch (decoded) {
      {'positions': final List items} => items,
      _ => throw ContractFormatException(
          'GET /positions: expected a {positions: [...]} envelope'),
    };
    return items.map((entry) => entry is Map<String, dynamic>
        ? Position.fromJson(entry)
        : throw ContractFormatException(
            'GET /positions: expected position objects')).toList();
  }

  /// Adds a validated position. Duplicate active identity is a 409 conflict.
  /// The backend answers 201 with the serialized position object directly.
  Future<Position> addPosition(PositionWrite write) async {
    final decoded = await _sendJson('POST', _uri('/positions'),
        body: write.toJson());
    return Position.fromJson(_requirePositionObject(decoded));
  }

  /// Applies explicit changed fields with optimistic concurrency. The body
  /// mirrors position.routes.js:60 / position.service.js:356-361:
  /// `{expected_revision, changes: {...}}`, where `changes` carries
  /// ALLOWED_FIELDS names (e.g. `instrument`, never `instrument_id`).
  /// Revision conflicts surface as [ApiException] with statusCode 409.
  Future<Position> patchPosition(String id, PositionWrite patch) async {
    if (patch.expectedRevision == null) {
      throw ArgumentError.value(
          patch.expectedRevision,
          'expectedRevision',
          'PATCH /positions/:id requires expected_revision for optimistic '
          'concurrency');
    }
    final decoded = await _sendJson('PATCH', _uri('/positions/$id'), body: {
      'expected_revision': patch.expectedRevision,
      'changes': patch.toJson(),
    });
    return Position.fromJson(_requirePositionObject(decoded));
  }

  /// POST and PATCH answers carry the serialized position object directly
  /// (no envelope); anything else is a contract drift.
  Map<String, dynamic> _requirePositionObject(Object? decoded) {
    if (decoded is Map<String, dynamic>) return decoded;
    throw ContractFormatException('expected a position object');
  }

  /// Cancels in-flight requests and releases the client.
  void close() => _client.close();
}

@riverpod
PositionRepository positionRepository(Ref ref) {
  return PositionRepository(
    tokenProvider: () async {
      final auth = ref.read(authRepositoryProvider);
      return auth.getToken();
    },
  );
}
