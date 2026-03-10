import 'package:flutter/foundation.dart';

class ApiConfig {
  // Use absolute URL for mobile, relative for web
  // For local mobile development, you can use 'http://10.0.2.2:8181' (Android) 
  // or your machine's local IP address.
  static const String _host = kIsWeb ? '' : 'https://horizon.adamzborovsky.com';
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
  static String opportunityStatsEndpoint(String ticker) => '$baseUrl/briefing/opportunity-stats/$ticker';
  
  // N8N Webhook for configuration updates
  static const String configWebhookEndpoint = '$baseUrl/briefing/config';
}
