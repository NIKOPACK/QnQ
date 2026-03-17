class AppConstants {
  AppConstants._();

  static const String appName = 'QnQ';
  static const String appVersion = '1.0.0';

  // Default LLM parameters
  static const double defaultTemperature = 0.7;
  static const int defaultMaxTokens = 4096;
  static const double defaultTopP = 1.0;

  // Plugin system
  static const String pluginManifestFile = 'plugin.json';
  static const String pluginEntryFile = 'main.lua';
  static const int pluginExecutionTimeoutMs = 30000;

  // MCP
  static const int mcpConnectionTimeoutMs = 10000;
  static const int mcpRequestTimeoutMs = 30000;

  // UI
  static const double cardBorderRadius = 16.0;
  static const double inputBorderRadius = 12.0;
  static const int maxConversationHistory = 50;
}
