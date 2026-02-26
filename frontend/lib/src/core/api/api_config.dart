class ApiConfig {
  static const String baseUrl = 'https://alpha-horizon-backend.adamzborovsky.com/api/v1';
  static const String authEndpoint = '$baseUrl/auth';
  static const String loginEndpoint = '$authEndpoint/login';
  static const String registerEndpoint = '$authEndpoint/register';
  static const String meEndpoint = '$authEndpoint/me';
  
  static const String briefingEndpoint = '$baseUrl/briefing';
  static const String briefingTriggerEndpoint = '$baseUrl/briefing/trigger';
  static const String briefingConfigEndpoint = '$baseUrl/briefing/config';
  static const String briefingSearchEndpoint = '$baseUrl/briefing/search';
  static String opportunityStatsEndpoint(String ticker) => '$baseUrl/briefing/opportunity-stats/$ticker';
  
  // N8N Webhook for configuration updates
  // Adjusting to common N8N webhook pattern based on backend domain
  static const String configWebhookEndpoint = '$baseUrl/briefing/config';
  
  // You can add more endpoints here as the backend grows
  // static const String stockEndpoint = '$baseUrl/stocks';
}
