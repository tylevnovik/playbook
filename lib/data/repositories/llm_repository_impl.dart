import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../core/error/failures.dart';
import '../../../domain/entities/llm_config.dart';
import '../../../domain/entities/message.dart';
import '../../../domain/repositories/llm_repository.dart';
import '../datasources/remote/llm_provider.dart';
import '../datasources/remote/openai_provider.dart';
import '../datasources/remote/anthropic_provider.dart';
import '../datasources/remote/gemini_provider.dart';

class LlmRepositoryImpl implements LlmRepository {
  final OpenAiProvider _openAiProvider;
  final AnthropicProvider _anthropicProvider;
  final GeminiProvider _geminiProvider;

  LlmRepositoryImpl(
    this._openAiProvider,
    this._anthropicProvider,
    this._geminiProvider,
  );

  LlmProvider _getProvider(LlmProviderType type) {
    switch (type) {
      case LlmProviderType.openai:
      case LlmProviderType.mimo:
      case LlmProviderType.tokenPlan:
      case LlmProviderType.deepseek:
        return _openAiProvider;
      case LlmProviderType.anthropic:
        return _anthropicProvider;
      case LlmProviderType.gemini:
        return _geminiProvider;
    }
  }

  @override
  Future<Either<Failure, String>> sendMessage({
    required List<Message> messages,
    required LlmConfig config,
    List<MessageAttachment>? attachments,
  }) async {
    try {
      final provider = _getProvider(config.providerType);
      final response = await provider.sendMessage(
        messages: messages,
        config: config,
        attachments: attachments,
      );
      return Right(response.content);
    } catch (e) {
      final failure = await _handleError(e);
      return Left(failure);
    }
  }

  @override
  Stream<Either<Failure, String>> streamMessage({
    required List<Message> messages,
    required LlmConfig config,
    List<MessageAttachment>? attachments,
  }) async* {
    try {
      final provider = _getProvider(config.providerType);
      await for (final chunk in provider.streamMessage(
        messages: messages,
        config: config,
        attachments: attachments,
      )) {
        if (chunk.content.isNotEmpty) {
          yield Right(chunk.content);
        }
      }
    } catch (e) {
      final failure = await _handleError(e);
      yield Left(failure);
    }
  }

  @override
  Future<Either<Failure, String>> summarize({
    required List<Message> messages,
    required LlmConfig config,
  }) async {
    try {
      final provider = _getProvider(config.providerType);
      final summaryPrompt = Message(
        id: 'summary_prompt',
        chatId: '',
        role: MessageRole.user,
        content: 'Please summarize the key events, facts, relationships and themes of the conversation so far in about 200 words. Keep it structured and bulleted.',
        createdAt: DateTime.now(),
      );
      final response = await provider.sendMessage(
        messages: [...messages, summaryPrompt],
        config: config,
      );
      return Right(response.content);
    } catch (e) {
      final failure = await _handleError(e);
      return Left(failure);
    }
  }

  Future<Failure> _handleError(Object error) async {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;
      String message = error.message ?? error.toString();

      if (data is Map) {
        final errorObj = data['error'];
        if (errorObj is Map && errorObj['message'] is String) {
          message = errorObj['message'] as String;
        } else if (data['message'] is String) {
          message = data['message'] as String;
        }
      } else if (data is ResponseBody) {
        try {
          final List<int> bytes = [];
          await for (final chunk in data.stream) {
            bytes.addAll(chunk);
          }
          if (bytes.isNotEmpty) {
            final jsonStr = utf8.decode(bytes);
            final decoded = jsonDecode(jsonStr);
            if (decoded is Map) {
              final errorObj = decoded['error'];
              if (errorObj is Map && errorObj['message'] is String) {
                message = errorObj['message'] as String;
              } else if (decoded['message'] is String) {
                message = decoded['message'] as String;
              }
            }
          }
        } catch (_) {}
      } else if (data is String) {
        try {
          final decoded = jsonDecode(data);
          if (decoded is Map) {
            final errorObj = decoded['error'];
            if (errorObj is Map && errorObj['message'] is String) {
              message = errorObj['message'] as String;
            } else if (decoded['message'] is String) {
              message = decoded['message'] as String;
            }
          }
        } catch (_) {
          if (data.trim().isNotEmpty) {
            message = data;
          }
        }
      }
      return ApiFailure(message, statusCode: statusCode);
    }
    return ApiFailure(error.toString());
  }
}
