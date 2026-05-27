import 'package:dartz/dartz.dart';
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
      return Left(ApiFailure(e.toString()));
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
      yield Left(ApiFailure(e.toString()));
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
      return Left(ApiFailure(e.toString()));
    }
  }
}
