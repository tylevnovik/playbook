import 'package:dartz/dartz.dart';
import '../../core/constants/app_constants.dart';
import '../../core/error/failures.dart';
import '../entities/message.dart';
import '../entities/character.dart';
import '../repositories/llm_repository.dart';
import '../repositories/chat_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/character_repository.dart';
import 'build_prompt.dart';

class SendMessage {
  final LlmRepository llmRepository;
  final ChatRepository chatRepository;
  final SettingsRepository settingsRepository;
  final CharacterRepository characterRepository;
  final BuildPrompt buildPrompt;

  SendMessage({
    required this.llmRepository,
    required this.chatRepository,
    required this.settingsRepository,
    required this.characterRepository,
    required this.buildPrompt,
  });

  Future<Either<Failure, Message>> call({
    required String chatId,
    required String content,
    String? senderId,
    List<MessageAttachment>? attachments,
  }) async {
    final chatResult = await chatRepository.getChat(chatId);
    return await chatResult.fold((failure) async => Left(failure), (chat) async {
      if (chat.characterIds.isEmpty) {
        return const Left(ValidationFailure('No characters linked to this chat.'));
      }

      final activeId = (senderId != null && chat.characterIds.contains(senderId))
          ? senderId
          : chat.characterIds.first;
      
      final activeCharResult = await characterRepository.getCharacter(activeId);
      return await activeCharResult.fold((failure) async => Left(failure), (activeCharacter) async {
        final List<Character> allCharacters = [];
        for (final charId in chat.characterIds) {
          final charResult = await characterRepository.getCharacter(charId);
          charResult.fold((_) => null, (char) => allCharacters.add(char));
        }

        final configResult = await settingsRepository.getDefaultLlmConfig();
        return await configResult.fold((failure) async => Left(failure), (config) async {
          final usernameResult = await settingsRepository.getString(AppConstants.keyUsername);
          final username = usernameResult.fold(
            (_) => 'User',
            (val) => val ?? 'User',
          );

          final messagesResult = await chatRepository.getMessages(chatId);
          return await messagesResult.fold((failure) async => Left(failure), (messages) async {
            final userMessage = Message(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              chatId: chatId,
              role: MessageRole.user,
              content: content,
              attachments: attachments,
              createdAt: DateTime.now(),
            );
            final saveUserResult = await chatRepository.saveMessage(userMessage);
            return await saveUserResult.fold((failure) async => Left(failure), (_) async {
              
              final promptMessagesResult = await buildPrompt(
                activeCharacter: activeCharacter,
                allCharacters: allCharacters,
                worldBookIds: chat.worldBookIds,
                messages: [...messages, userMessage],
                config: config,
                username: username,
                summary: null,
              );

              return await promptMessagesResult.fold((failure) async => Left(failure), (promptMessages) async {
                final responseResult = await llmRepository.sendMessage(
                  messages: promptMessages,
                  config: config,
                  attachments: attachments,
                );

                return await responseResult.fold((failure) async => Left(failure), (responseContent) async {
                  final assistantMessage = Message(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    chatId: chatId,
                    role: MessageRole.assistant,
                    content: responseContent,
                    createdAt: DateTime.now(),
                    senderId: activeCharacter.id,
                  );
                  return await chatRepository.saveMessage(assistantMessage);
                });
              });
            });
          });
        });
      });
    });
  }
}
