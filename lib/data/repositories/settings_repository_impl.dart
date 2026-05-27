import 'package:dartz/dartz.dart';
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
  Future<Either<Failure, LlmConfig>> getLlmConfig(LlmProviderType providerType) async {
    try {
      switch (providerType) {
        case LlmProviderType.openai:
          final apiKey = _prefs.getString(AppConstants.keyOpenaiApiKey) ?? '';
          final baseUrl = _prefs.getString(AppConstants.keyOpenaiBaseUrl);
          final model = _prefs.getString(AppConstants.keyOpenaiModel) ?? 'gpt-4o-mini';
          return Right(LlmConfig(
            providerType: LlmProviderType.openai,
            apiKey: apiKey,
            baseUrl: baseUrl,
            model: model,
            contextWindow: AppConstants.defaultMaxContextTokens,
            maxTokens: AppConstants.defaultMaxResponseTokens,
          ));
        case LlmProviderType.anthropic:
          final apiKey = _prefs.getString(AppConstants.keyAnthropicApiKey) ?? '';
          final model = _prefs.getString(AppConstants.keyAnthropicModel) ?? 'claude-3-5-sonnet-latest';
          return Right(LlmConfig(
            providerType: LlmProviderType.anthropic,
            apiKey: apiKey,
            model: model,
            contextWindow: AppConstants.defaultMaxContextTokens,
            maxTokens: AppConstants.defaultMaxResponseTokens,
          ));
        case LlmProviderType.gemini:
          final apiKey = _prefs.getString(AppConstants.keyGeminiApiKey) ?? '';
          final model = _prefs.getString(AppConstants.keyGeminiModel) ?? 'gemini-1.5-flash';
          return Right(LlmConfig(
            providerType: LlmProviderType.gemini,
            apiKey: apiKey,
            model: model,
            contextWindow: AppConstants.defaultMaxContextTokens,
            maxTokens: AppConstants.defaultMaxResponseTokens,
          ));
      }
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, LlmProviderType>> getDefaultProvider() async {
    try {
      final value = _prefs.getString(AppConstants.keyDefaultProvider) ?? LlmProviderType.openai.name;
      final type = LlmProviderType.values.firstWhere((e) => e.name == value, orElse: () => LlmProviderType.openai);
      return Right(type);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
