import 'package:flutter/foundation.dart';

class ApiConfig {
  // Web uses relative paths (served by the same origin's nginx proxy).
  // Mobile defaults to the production API through the Cloudflare tunnel
  // (per DEPLOYMENT.md). For local emulator dev, override at build time:
  //   flutter run --dart-define=HORIZON_API_HOST=http://10.0.2.2:8181
  static const String _host = kIsWeb
      ? ''
      : String.fromEnvironment(
          'HORIZON_API_HOST',
          defaultValue: 'https://horizon.adamzborovsky.com',
        );

  static const String baseUrl = '$_host/api/v1';

  static const String authEndpoint = '$baseUrl/auth';
  static const String loginEndpoint = '$authEndpoint/login';
  static const String registerEndpoint = '$authEndpoint/register';
  static const String meEndpoint = '$authEndpoint/me';

  static const String briefingEndpoint = '$baseUrl/briefing';
  static const String briefingTriggerEndpoint = '$baseUrl/briefing/trigger';
  static const String briefingConfigEndpoint = '$baseUrl/briefing/config';
  static const String briefingStatusEndpoint = '$baseUrl/briefing/status';
  static const String briefingSearchEndpoint = '$baseUrl/briefing/search';
  static String opportunityStatsEndpoint(String ticker) =>
      '$baseUrl/briefing/opportunity-stats/$ticker';

  // N8N Webhook for configuration updates
  static const String configWebhookEndpoint = '$baseUrl/briefing/config';
}
