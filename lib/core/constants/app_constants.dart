class AppConstants {
  static const String appName = 'Playbook';
  static const String dbName = 'playbook.db';
  static const int dbVersion = 1;

  // Token limits (default, overridable per model)
  static const int defaultMaxContextTokens = 8000;
  static const int defaultMaxResponseTokens = 1000;
  static const int defaultSummaryThreshold =
      20; // messages before summarization
  static const int defaultRecentMessages = 20;

  // Provider defaults
  static const String defaultOpenaiBaseUrl = 'https://api.openai.com';
  static const String defaultOpenaiModel = 'gpt-4o-mini';
  static const int defaultOpenaiContextTokens = 128000;
  static const int defaultOpenaiMaxResponseTokens = 1000;

  static const String defaultAnthropicBaseUrl = 'https://api.anthropic.com';
  static const String defaultAnthropicModel = 'claude-3-5-sonnet-latest';
  static const int defaultAnthropicContextTokens = 200000;
  static const int defaultAnthropicMaxResponseTokens = 1000;

  static const String defaultGeminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';
  static const String defaultGeminiModel = 'gemini-1.5-flash';
  static const int defaultGeminiContextTokens = 1048576;
  static const int defaultGeminiMaxResponseTokens = 1000;

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
  static const String keyAnthropicBaseUrl = 'anthropic_base_url';
  static const String keyAnthropicModel = 'anthropic_model';
  static const String keyGeminiApiKey = 'gemini_api_key';
  static const String keyGeminiBaseUrl = 'gemini_base_url';
  static const String keyGeminiModel = 'gemini_model';
}
