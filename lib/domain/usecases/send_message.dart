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
    return await providerResult.fold(
      (failure) async => Left(failure),
      (providerType) async {
        final configResult = await settingsRepository.getLlmConfig(providerType);
        return await configResult.fold(
          (failure) async => Left(failure),
          (config) async {
            // 2. Load recent messages
            final messagesResult = await chatRepository.getMessages(chatId);
            return await messagesResult.fold(
              (failure) async => Left(failure),
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
                final saveUserResult = await chatRepository.saveMessage(userMessage);
                return await saveUserResult.fold(
                  (failure) async => Left(failure),
                  (_) async {
                    // 4. Send to LLM
                    final responseResult = await llmRepository.sendMessage(
                      messages: [...messages, userMessage],
                      config: config,
                      attachments: attachments,
                    );
                    return await responseResult.fold(
                      (failure) async => Left(failure),
                      (responseContent) async {
                        // 5. Save assistant message
                        final assistantMessage = Message(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          chatId: chatId,
                          role: MessageRole.assistant,
                          content: responseContent,
                          createdAt: DateTime.now(),
                        );
                        return await chatRepository.saveMessage(assistantMessage);
                      },
                    );
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
