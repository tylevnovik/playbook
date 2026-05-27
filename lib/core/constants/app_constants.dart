class AppConstants {
  static const String appName = 'Playbook';
  static const String dbName = 'playbook.db';
  static const int dbVersion = 1;
  
  // Token limits (default, overridable per model)
  static const int defaultMaxContextTokens = 8000;
  static const int defaultMaxResponseTokens = 1000;
  static const int defaultSummaryThreshold = 20; // messages before summarization
  static const int defaultRecentMessages = 20;
  
  // Storage keys
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguage = 'language';
  static const String keyPrimaryColor = 'primary_color';
  static const String keyUsername = 'username';
  static const String keyDefaultProvider = 'default_provider';
  static const String keyOpenaiApiKey = 'openai_api_key';
  static const String keyOpenaiBaseUrl = 'openai_base_url';
  static const String keyOpenaiModel = 'openai_model';
  static const String keyAnthropicApiKey = 'anthropic_api_key';
  static const String keyAnthropicModel = 'anthropic_model';
  static const String keyGeminiApiKey = 'gemini_api_key';
  static const String keyGeminiModel = 'gemini_model';
}
