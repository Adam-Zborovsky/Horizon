import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../api/api_config.dart';
import '../../features/auth/auth_repository.dart';
import '../../features/briefing/briefing_repository.dart';
import 'notification_service.dart';

part 'data_polling_service.g.dart';

/// Periodically polls the backend for new briefing data.
/// When a newer timestamp is detected, fires a notification and
/// invalidates the briefing provider so the UI auto-refreshes.
@Riverpod(keepAlive: true)
class DataPollingService extends _$DataPollingService {
  Timer? _timer;
  String? _lastKnownTimestamp;

  static const _pollInterval = Duration(minutes: 2);

  @override
  void build() {
    _startPolling();
    ref.onDispose(_stopPolling);
  }

  void _startPolling() {
    _stopPolling();
    // Do an initial check after a short delay to let the app settle
    _timer = Timer.periodic(_pollInterval, (_) => _checkForNewData());
    // Also run once shortly after startup
    Future.delayed(const Duration(seconds: 10), _checkForNewData);
  }

  void _stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _checkForNewData() async {
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final token = await authRepo.getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse(ApiConfig.briefingStatusEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final latestTimestamp = body['latestTimestamp'] as String?;

      if (latestTimestamp == null) return;

      if (_lastKnownTimestamp == null) {
        // First check — just record the current timestamp, don't notify
        _lastKnownTimestamp = latestTimestamp;
        return;
      }

      if (latestTimestamp != _lastKnownTimestamp) {
        _lastKnownTimestamp = latestTimestamp;

        // New data available — fire notification
        await NotificationService.showRefreshNotification(
          'New intelligence data is available.',
        );

        // Invalidate the briefing provider to trigger UI auto-refresh
        ref.invalidate(briefingRepositoryProvider);
      }
    } catch (_) {
      // Silently ignore polling errors to avoid disrupting the user
    }
  }
}
