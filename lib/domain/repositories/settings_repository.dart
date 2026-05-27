import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/llm_config.dart';

abstract class SettingsRepository {
  Future<Either<Failure, String?>> getString(String key);
  Future<Either<Failure, void>> setString(String key, String value);
  Future<Either<Failure, int?>> getInt(String key);
  Future<Either<Failure, void>> setInt(String key, int value);
  Future<Either<Failure, double?>> getDouble(String key);
  Future<Either<Failure, void>> setDouble(String key, double value);
  Future<Either<Failure, bool?>> getBool(String key);
  Future<Either<Failure, void>> setBool(String key, bool value);
  Future<Either<Failure, LlmConfig>> getLlmConfig(LlmProviderType providerType);
  Future<Either<Failure, LlmProviderType>> getDefaultProvider();
}
