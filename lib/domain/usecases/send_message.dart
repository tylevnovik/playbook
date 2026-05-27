import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/message.dart';
import '../repositories/llm_repository.dart';
import '../repositories/chat_repository.dart';
import '../repositories/settings_repository.dart';

class SendMessage {
  final LlmRepository llmRepository;
  final ChatRepository chatRepository;
  final SettingsRepository settingsRepository;

  SendMessage({
    required this.llmRepository,
    required this.chatRepository,
    required this.settingsRepository,
  });

  Future<Either<Failure, Message>> call({
    required String chatId,
    required String content,
    List<MessageAttachment>? attachments,
  }) async {
    // 1. Get LLM config
    final providerResult = await settingsRepository.getDefaultProvider();
    return providerResult.fold(
      (failure) => Left(failure),
      (providerType) async {
        final configResult = await settingsRepository.getLlmConfig(providerType);
        return configResult.fold(
          (failure) => Left(failure),
          (config) async {
            // 2. Load recent messages
            final messagesResult = await chatRepository.getMessages(chatId);
            return messagesResult.fold(
              (failure) => Left(failure),
              (messages) async {
                // 3. Save user message
                final userMessage = Message(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  chatId: chatId,
                  role: MessageRole.user,
                  content: content,
                  attachments: attachments,
                  createdAt: DateTime.now(),
                );
                await chatRepository.saveMessage(userMessage);

                // 4. Send to LLM
                final responseResult = await llmRepository.sendMessage(
                  messages: [...messages, userMessage],
                  config: config,
                  attachments: attachments,
                );
                return responseResult.fold(
                  (failure) => Left(failure),
                  (responseContent) async {
                    // 5. Save assistant message
                    final assistantMessage = Message(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      chatId: chatId,
                      role: MessageRole.assistant,
                      content: responseContent,
                      createdAt: DateTime.now(),
                    );
                    return Right(await chatRepository.saveMessage(assistantMessage));
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
