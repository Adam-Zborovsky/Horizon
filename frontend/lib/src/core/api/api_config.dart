class ApiConfig {
  static const String baseUrl = 'https://alpha-horizon-backend.adamzborovsky.com/api/v1';
  static const String briefingEndpoint = '$baseUrl/briefing';
  
  // N8N Webhook for configuration updates
  // Adjusting to common N8N webhook pattern based on backend domain
  static const String configWebhookEndpoint = 'https://n8n.zborovsky.cloud/webhook/update-briefing-config';
  
  // You can add more endpoints here as the backend grows
  // static const String stockEndpoint = '$baseUrl/stocks';
}
