class AppConstants {
  static const String appName = 'Playbook';
  static const String dbName = 'playbook.db';
  static const int dbVersion = 3;

  // Token limits (default, overridable per model)
  static const int defaultMaxContextTokens = 8000;
  static const int defaultMaxResponseTokens = 1000;
  static const int defaultSummaryThreshold =
      20; // messages before summarization
  static const int defaultRecentMessages = 20;

  // Provider defaults
  static const String defaultOpenaiBaseUrl = 'https://api.openai.com/v1';
  static const String defaultOpenaiModel = 'gpt-5.5';
  static const int defaultOpenaiContextTokens = 1050000;
  static const int defaultOpenaiMaxResponseTokens = 1000;

  static const String defaultAnthropicBaseUrl = 'https://api.anthropic.com/v1';
  static const String defaultAnthropicModel = 'claude-opus-4-7';
  static const int defaultAnthropicContextTokens = 1000000;
  static const int defaultAnthropicMaxResponseTokens = 1000;

  static const String defaultGeminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';
  static const String defaultGeminiOpenAiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/openai';
  static const String defaultGeminiModel = 'gemini-3.5-flash';
  static const int defaultGeminiContextTokens = 1048576;
  static const int defaultGeminiMaxResponseTokens = 1000;

  static const String defaultMimoBaseUrl = 'https://api.xiaomimimo.com';
  static const String defaultMimoModel = 'mimo-v2.5-pro';
  static const int defaultMimoContextTokens = 1000000;
  static const int defaultMimoMaxResponseTokens = 4096;

  static const String defaultTokenPlanBaseUrl =
      'https://token-plan-cn.xiaomimimo.com/v1';
  static const String defaultTokenPlanModel = 'mimo-v2.5-pro';
  static const int defaultTokenPlanContextTokens = 1000000;
  static const int defaultTokenPlanMaxResponseTokens = 4096;

  static const String defaultDeepseekBaseUrl = 'https://api.deepseek.com';
  static const String defaultDeepseekModel = 'deepseek-v4-pro';
  static const int defaultDeepseekContextTokens = 1000000;
  static const int defaultDeepseekMaxResponseTokens = 4096;

  static const String profileOpenaiOfficial = 'official_openai';
  static const String profileAnthropicOfficial = 'official_anthropic';
  static const String profileGeminiOfficial = 'official_gemini';
  static const String profileMimoOfficial = 'official_mimo';
  static const String profileTokenPlanOfficial = 'official_token_plan';
  static const String profileDeepseekOfficial = 'official_deepseek';

  // Storage keys
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguage = 'language';
  static const String keyPrimaryColor = 'primary_color';
  static const String keyUsername = 'username';
  static const String keyDefaultProvider = 'default_provider';
  static const String keyProviderProfiles = 'provider_profiles';
  static const String keyDefaultProviderProfileId =
      'default_provider_profile_id';
  static const String keyOpenaiApiKey = 'openai_api_key';
  static const String keyOpenaiBaseUrl = 'openai_base_url';
  static const String keyOpenaiModel = 'openai_model';
  static const String keyAnthropicApiKey = 'anthropic_api_key';
  static const String keyAnthropicBaseUrl = 'anthropic_base_url';
  static const String keyAnthropicModel = 'anthropic_model';
  static const String keyGeminiApiKey = 'gemini_api_key';
  static const String keyGeminiBaseUrl = 'gemini_base_url';
  static const String keyGeminiModel = 'gemini_model';
  static const String keyMimoApiKey = 'mimo_api_key';
  static const String keyMimoBaseUrl = 'mimo_base_url';
  static const String keyMimoModel = 'mimo_model';
  static const String keyTokenPlanApiKey = 'token_plan_api_key';
  static const String keyTokenPlanBaseUrl = 'token_plan_base_url';
  static const String keyTokenPlanModel = 'token_plan_model';
  static const String keyDeepseekApiKey = 'deepseek_api_key';
  static const String keyDeepseekBaseUrl = 'deepseek_base_url';
  static const String keyDeepseekModel = 'deepseek_model';
}
