import 'package:dartz/dartz.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/error/failures.dart';
import '../../../domain/entities/llm_config.dart';
import '../../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SharedPreferences _prefs;

  SettingsRepositoryImpl(this._prefs);

  @override
  Future<Either<Failure, String?>> getString(String key) async {
    try {
      return Right(_prefs.getString(key));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setString(String key, String value) async {
    try {
      await _prefs.setString(key, value);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int?>> getInt(String key) async {
    try {
      return Right(_prefs.getInt(key));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setInt(String key, int value) async {
    try {
      await _prefs.setInt(key, value);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, double?>> getDouble(String key) async {
    try {
      return Right(_prefs.getDouble(key));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setDouble(String key, double value) async {
    try {
      await _prefs.setDouble(key, value);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool?>> getBool(String key) async {
    try {
      return Right(_prefs.getBool(key));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setBool(String key, bool value) async {
    try {
      await _prefs.setBool(key, value);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, LlmConfig>> getLlmConfig(
    LlmProviderType providerType,
  ) async {
    try {
      final profiles = _loadProfiles();
      final profile = profiles.firstWhere(
        (item) => item.providerType == providerType,
        orElse: () => _defaultProfileFor(providerType),
      );
      return Right(profile.toConfig());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, LlmConfig>> getDefaultLlmConfig() async {
    try {
      final profiles = _loadProfiles();
      final defaultId = _defaultProfileId(profiles);
      final profile = profiles.firstWhere(
        (item) => item.id == defaultId,
        orElse: () => profiles.first,
      );
      return Right(profile.toConfig());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<LlmProviderProfile>>>
  getProviderProfiles() async {
    try {
      return Right(_loadProfiles());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveProviderProfiles(
    List<LlmProviderProfile> profiles,
  ) async {
    try {
      final normalized = profiles.isEmpty ? _defaultProfiles() : profiles;
      await _prefs.setString(
        AppConstants.keyProviderProfiles,
        jsonEncode(normalized.map((profile) => profile.toJson()).toList()),
      );

      final defaultId = _defaultProfileId(normalized);
      if (!normalized.any((profile) => profile.id == defaultId)) {
        await _prefs.setString(
          AppConstants.keyDefaultProviderProfileId,
          normalized.first.id,
        );
      }
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> getDefaultProviderProfileId() async {
    try {
      return Right(_defaultProfileId(_loadProfiles()));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setDefaultProviderProfileId(String id) async {
    try {
      await _prefs.setString(AppConstants.keyDefaultProviderProfileId, id);
      final profiles = _loadProfiles();
      final selected = profiles.firstWhere(
        (profile) => profile.id == id,
        orElse: () => profiles.first,
      );
      await _prefs.setString(
        AppConstants.keyDefaultProvider,
        selected.providerType.name,
      );
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, LlmProviderType>> getDefaultProvider() async {
    try {
      final profiles = _loadProfiles();
      final defaultId = _defaultProfileId(profiles);
      final selected = profiles.firstWhere(
        (profile) => profile.id == defaultId,
        orElse: () => profiles.first,
      );
      return Right(selected.providerType);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  String _stringOrDefault(String key, String fallback) {
    final value = _prefs.getString(key);
    if (value == null || value.trim().isEmpty) return fallback;
    return value.trim();
  }

  List<LlmProviderProfile> _loadProfiles() {
    final encoded = _prefs.getString(AppConstants.keyProviderProfiles);
    if (encoded == null || encoded.trim().isEmpty) {
      return _defaultProfiles();
    }

    final decoded = jsonDecode(encoded);
    if (decoded is! List) return _defaultProfiles();
    final profiles = decoded
        .whereType<Map>()
        .map(
          (item) =>
              LlmProviderProfile.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
    if (profiles.isEmpty) return _defaultProfiles();

    final builtInIds = profiles.map((profile) => profile.id).toSet();
    for (final builtIn in _defaultProfiles()) {
      if (!builtInIds.contains(builtIn.id)) {
        profiles.add(builtIn);
      }
    }
    return profiles;
  }

  List<LlmProviderProfile> _defaultProfiles() {
    return [
      LlmProviderProfile(
        id: AppConstants.profileOpenaiOfficial,
        name: 'OpenAI',
        providerType: LlmProviderType.openai,
        apiKey: _prefs.getString(AppConstants.keyOpenaiApiKey) ?? '',
        baseUrl: _stringOrDefault(
          AppConstants.keyOpenaiBaseUrl,
          AppConstants.defaultOpenaiBaseUrl,
        ),
        model: _stringOrDefault(
          AppConstants.keyOpenaiModel,
          AppConstants.defaultOpenaiModel,
        ),
        contextWindow: AppConstants.defaultOpenaiContextTokens,
        maxTokens: AppConstants.defaultOpenaiMaxResponseTokens,
        isBuiltIn: true,
      ),
      LlmProviderProfile(
        id: AppConstants.profileAnthropicOfficial,
        name: 'Anthropic',
        providerType: LlmProviderType.anthropic,
        apiKey: _prefs.getString(AppConstants.keyAnthropicApiKey) ?? '',
        baseUrl: _stringOrDefault(
          AppConstants.keyAnthropicBaseUrl,
          AppConstants.defaultAnthropicBaseUrl,
        ),
        model: _stringOrDefault(
          AppConstants.keyAnthropicModel,
          AppConstants.defaultAnthropicModel,
        ),
        contextWindow: AppConstants.defaultAnthropicContextTokens,
        maxTokens: AppConstants.defaultAnthropicMaxResponseTokens,
        isBuiltIn: true,
      ),
      LlmProviderProfile(
        id: AppConstants.profileGeminiOfficial,
        name: 'Google Gemini',
        providerType: LlmProviderType.gemini,
        apiKey: _prefs.getString(AppConstants.keyGeminiApiKey) ?? '',
        baseUrl: _stringOrDefault(
          AppConstants.keyGeminiBaseUrl,
          AppConstants.defaultGeminiBaseUrl,
        ),
        model: _stringOrDefault(
          AppConstants.keyGeminiModel,
          AppConstants.defaultGeminiModel,
        ),
        contextWindow: AppConstants.defaultGeminiContextTokens,
        maxTokens: AppConstants.defaultGeminiMaxResponseTokens,
        isBuiltIn: true,
      ),
      LlmProviderProfile(
        id: AppConstants.profileMimoOfficial,
        name: 'Xiaomi Mimo',
        providerType: LlmProviderType.mimo,
        apiKey: _prefs.getString(AppConstants.keyMimoApiKey) ?? '',
        baseUrl: _stringOrDefault(
          AppConstants.keyMimoBaseUrl,
          AppConstants.defaultMimoBaseUrl,
        ),
        model: _stringOrDefault(
          AppConstants.keyMimoModel,
          AppConstants.defaultMimoModel,
        ),
        contextWindow: AppConstants.defaultMimoContextTokens,
        maxTokens: AppConstants.defaultMimoMaxResponseTokens,
        isBuiltIn: true,
      ),
      LlmProviderProfile(
        id: AppConstants.profileTokenPlanOfficial,
        name: 'Xiaomi Token Plan',
        providerType: LlmProviderType.tokenPlan,
        apiKey: _prefs.getString(AppConstants.keyTokenPlanApiKey) ?? '',
        baseUrl: _stringOrDefault(
          AppConstants.keyTokenPlanBaseUrl,
          AppConstants.defaultTokenPlanBaseUrl,
        ),
        model: _stringOrDefault(
          AppConstants.keyTokenPlanModel,
          AppConstants.defaultTokenPlanModel,
        ),
        contextWindow: AppConstants.defaultTokenPlanContextTokens,
        maxTokens: AppConstants.defaultTokenPlanMaxResponseTokens,
        isBuiltIn: true,
      ),
      LlmProviderProfile(
        id: AppConstants.profileDeepseekOfficial,
        name: 'DeepSeek',
        providerType: LlmProviderType.deepseek,
        apiKey: _prefs.getString(AppConstants.keyDeepseekApiKey) ?? '',
        baseUrl: _stringOrDefault(
          AppConstants.keyDeepseekBaseUrl,
          AppConstants.defaultDeepseekBaseUrl,
        ),
        model: _stringOrDefault(
          AppConstants.keyDeepseekModel,
          AppConstants.defaultDeepseekModel,
        ),
        contextWindow: AppConstants.defaultDeepseekContextTokens,
        maxTokens: AppConstants.defaultDeepseekMaxResponseTokens,
        isBuiltIn: true,
      ),
    ];
  }

  LlmProviderProfile _defaultProfileFor(LlmProviderType type) {
    return _defaultProfiles().firstWhere(
      (profile) => profile.providerType == type,
      orElse: () => _defaultProfiles().first,
    );
  }

  String _defaultProfileId(List<LlmProviderProfile> profiles) {
    final stored = _prefs.getString(AppConstants.keyDefaultProviderProfileId);
    if (stored != null && profiles.any((profile) => profile.id == stored)) {
      return stored;
    }

    final legacy = _prefs.getString(AppConstants.keyDefaultProvider);
    final legacyType = LlmProviderType.values.firstWhere(
      (type) => type.name == legacy,
      orElse: () => LlmProviderType.openai,
    );
    return profiles
        .firstWhere(
          (profile) => profile.providerType == legacyType,
          orElse: () => profiles.first,
        )
        .id;
  }
}
