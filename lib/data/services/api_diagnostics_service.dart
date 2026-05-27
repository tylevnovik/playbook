import 'package:dio/dio.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/llm_config.dart';

class ApiDiagnosticsResult {
  final bool success;
  final String message;
  final List<String> models;

  const ApiDiagnosticsResult({
    required this.success,
    required this.message,
    this.models = const [],
  });
}

class ApiDiagnosticsService {
  final Dio _dio;

  ApiDiagnosticsService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 12),
              validateStatus: (status) => status != null && status < 500,
            ),
          );

  Future<ApiDiagnosticsResult> testConnection({
    required LlmProviderType providerType,
    required String apiKey,
    required String baseUrl,
    required String model,
  }) async {
    if (apiKey.trim().isEmpty) {
      return const ApiDiagnosticsResult(
        success: false,
        message: 'API Key is required.',
      );
    }
    if (model.trim().isEmpty) {
      return const ApiDiagnosticsResult(
        success: false,
        message: 'Model name is required.',
      );
    }

    try {
      final response = switch (providerType) {
        LlmProviderType.openai => await _dio.get(
          _joinVersionedPath(
            baseUrl,
            '/v1/models/${Uri.encodeComponent(model)}',
          ),
          options: Options(headers: _openAiHeaders(apiKey)),
        ),
        LlmProviderType.anthropic => await _dio.get(
          _joinVersionedPath(
            baseUrl,
            '/v1/models/${Uri.encodeComponent(model)}',
          ),
          options: Options(headers: _anthropicHeaders(apiKey)),
        ),
        LlmProviderType.gemini => await _dio.get(
          _joinPath(
            baseUrl,
            '/${_geminiModelPath(model)}?key=${Uri.encodeComponent(apiKey)}',
          ),
        ),
      };

      if ((response.statusCode ?? 0) >= 200 &&
          (response.statusCode ?? 0) < 300) {
        return const ApiDiagnosticsResult(
          success: true,
          message: 'Connection OK.',
        );
      }

      return ApiDiagnosticsResult(
        success: false,
        message: _responseMessage(response),
      );
    } on DioException catch (e) {
      return ApiDiagnosticsResult(success: false, message: _dioMessage(e));
    } catch (e) {
      return ApiDiagnosticsResult(success: false, message: e.toString());
    }
  }

  Future<ApiDiagnosticsResult> discoverModels({
    required LlmProviderType providerType,
    required String apiKey,
    required String baseUrl,
  }) async {
    if (apiKey.trim().isEmpty) {
      return const ApiDiagnosticsResult(
        success: false,
        message: 'API Key is required.',
      );
    }

    try {
      final response = switch (providerType) {
        LlmProviderType.openai => await _dio.get(
          _joinVersionedPath(baseUrl, '/v1/models'),
          options: Options(headers: _openAiHeaders(apiKey)),
        ),
        LlmProviderType.anthropic => await _dio.get(
          _joinVersionedPath(baseUrl, '/v1/models'),
          options: Options(headers: _anthropicHeaders(apiKey)),
        ),
        LlmProviderType.gemini => await _dio.get(
          _joinPath(
            baseUrl,
            '/models?key=${Uri.encodeComponent(apiKey)}&pageSize=1000',
          ),
        ),
      };

      if ((response.statusCode ?? 0) < 200 ||
          (response.statusCode ?? 0) >= 300) {
        return ApiDiagnosticsResult(
          success: false,
          message: _responseMessage(response),
        );
      }

      final models = switch (providerType) {
        LlmProviderType.openai => _parseOpenAiModels(response.data),
        LlmProviderType.anthropic => _parseAnthropicModels(response.data),
        LlmProviderType.gemini => _parseGeminiModels(response.data),
      };

      if (models.isEmpty) {
        return const ApiDiagnosticsResult(
          success: false,
          message: 'No compatible text models were returned.',
        );
      }

      return ApiDiagnosticsResult(
        success: true,
        message: 'Models discovered.',
        models: models,
      );
    } on DioException catch (e) {
      return ApiDiagnosticsResult(success: false, message: _dioMessage(e));
    } catch (e) {
      return ApiDiagnosticsResult(success: false, message: e.toString());
    }
  }

  static String fallbackBaseUrl(LlmProviderType providerType) {
    return switch (providerType) {
      LlmProviderType.openai => AppConstants.defaultOpenaiBaseUrl,
      LlmProviderType.anthropic => AppConstants.defaultAnthropicBaseUrl,
      LlmProviderType.gemini => AppConstants.defaultGeminiBaseUrl,
    };
  }

  static String fallbackModel(LlmProviderType providerType) {
    return switch (providerType) {
      LlmProviderType.openai => AppConstants.defaultOpenaiModel,
      LlmProviderType.anthropic => AppConstants.defaultAnthropicModel,
      LlmProviderType.gemini => AppConstants.defaultGeminiModel,
    };
  }

  static int fallbackContextTokens(LlmProviderType providerType) {
    return switch (providerType) {
      LlmProviderType.openai => AppConstants.defaultOpenaiContextTokens,
      LlmProviderType.anthropic => AppConstants.defaultAnthropicContextTokens,
      LlmProviderType.gemini => AppConstants.defaultGeminiContextTokens,
    };
  }

  static int fallbackResponseTokens(LlmProviderType providerType) {
    return switch (providerType) {
      LlmProviderType.openai => AppConstants.defaultOpenaiMaxResponseTokens,
      LlmProviderType.anthropic =>
        AppConstants.defaultAnthropicMaxResponseTokens,
      LlmProviderType.gemini => AppConstants.defaultGeminiMaxResponseTokens,
    };
  }

  static String _joinVersionedPath(String baseUrl, String path) {
    final normalized = _withoutTrailingSlash(baseUrl);
    if (normalized.endsWith('/v1') && path.startsWith('/v1/')) {
      return '$normalized${path.substring(3)}';
    }
    return _joinPath(normalized, path);
  }

  static String _joinPath(String baseUrl, String path) {
    final normalized = _withoutTrailingSlash(baseUrl);
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$normalized$normalizedPath';
  }

  static String _withoutTrailingSlash(String value) {
    final trimmed = value.trim();
    return trimmed.endsWith('/')
        ? trimmed.replaceFirst(RegExp(r'/+$'), '')
        : trimmed;
  }

  static String _geminiModelPath(String model) {
    final trimmed = model.trim();
    return trimmed.startsWith('models/') ? trimmed : 'models/$trimmed';
  }

  static Map<String, String> _openAiHeaders(String apiKey) => {
    'Authorization': 'Bearer $apiKey',
    'Content-Type': 'application/json',
  };

  static Map<String, String> _anthropicHeaders(String apiKey) => {
    'x-api-key': apiKey,
    'anthropic-version': '2023-06-01',
    'Content-Type': 'application/json',
  };

  static List<String> _parseOpenAiModels(dynamic data) {
    if (data is! Map || data['data'] is! List) return const [];
    return (data['data'] as List)
        .whereType<Map>()
        .map((model) => model['id'])
        .whereType<String>()
        .where((id) => id.trim().isNotEmpty)
        .toSet()
        .toList();
  }

  static List<String> _parseAnthropicModels(dynamic data) {
    if (data is! Map || data['data'] is! List) return const [];
    return (data['data'] as List)
        .whereType<Map>()
        .map((model) => model['id'])
        .whereType<String>()
        .where((id) => id.trim().isNotEmpty)
        .toSet()
        .toList();
  }

  static List<String> _parseGeminiModels(dynamic data) {
    if (data is! Map || data['models'] is! List) return const [];
    return (data['models'] as List)
        .whereType<Map>()
        .where((model) {
          final methods = model['supportedGenerationMethods'];
          return methods is List && methods.contains('generateContent');
        })
        .map((model) => model['baseModelId'] ?? model['name'])
        .whereType<String>()
        .map((id) => id.replaceFirst('models/', ''))
        .where((id) => id.trim().isNotEmpty)
        .toSet()
        .toList();
  }

  static String _responseMessage(Response<dynamic> response) {
    final status = response.statusCode ?? 0;
    final data = response.data;
    if (data is Map) {
      final error = data['error'];
      if (error is Map && error['message'] is String) {
        return 'HTTP $status: ${error['message']}';
      }
      if (data['message'] is String) {
        return 'HTTP $status: ${data['message']}';
      }
    }
    return 'HTTP $status';
  }

  static String _dioMessage(DioException error) {
    if (error.response != null) {
      return _responseMessage(error.response!);
    }
    return error.message ?? error.type.name;
  }
}
