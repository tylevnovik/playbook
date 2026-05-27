import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/entities/character.dart';
import '../../../../domain/entities/chat.dart';
import '../../../../domain/entities/message.dart';
import '../../../../domain/entities/world_book.dart';
import '../../../../domain/repositories/world_book_repository.dart';
import '../../../../core/di/injection.dart';
import '../../../../domain/usecases/load_character.dart';
import '../../../../domain/usecases/manage_chat.dart';
import '../../../../domain/usecases/send_message.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final LoadCharacter loadCharacter;
  final ManageChat manageChat;
  final SendMessage sendMessage;

  ChatBloc({
    required this.loadCharacter,
    required this.manageChat,
    required this.sendMessage,
  }) : super(ChatInitial()) {
    on<LoadChat>(_onLoadChat);
    on<SendChatMessage>(_onSendChatMessage);
    on<SwitchChatBranch>(_onSwitchBranch);
    on<SwitchToSiblingBranch>(_onSwitchToSiblingBranch);
    on<UpdateChatCharacters>(_onUpdateChatCharacters);
    on<UpdateChatWorldBooks>(_onUpdateChatWorldBooks);
    on<SetActiveCharacter>(_onSetActiveCharacter);
  }

  Future<void> _onLoadChat(LoadChat event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    final result = await loadCharacter(event.chatId);
    await result.fold((failure) async => emit(ChatError(failure.message)), (
      data,
    ) async {
      final chat = data.$1;
      final characters = data.$2;

      final activeCharId = characters.isNotEmpty ? characters.first.id : null;

      await _loadMessagesAndBranches(characters, chat, activeCharId, null, emit);
    });
  }

  Future<void> _loadMessagesAndBranches(
    List<Character> characters,
    Chat chat,
    String? activeCharId,
    String? leafId,
    Emitter<ChatState> emit,
  ) async {
    final messagesResult = await manageChat.switchBranch(chat.id, leafId);
    await messagesResult.fold(
      (failure) async => emit(ChatError(failure.message)),
      (messages) async {
        if (messages.isEmpty && characters.isNotEmpty) {
          final firstChar = characters.first;
          final greetingMsg = Message(
            id: 'greeting_${DateTime.now().millisecondsSinceEpoch}',
            chatId: chat.id,
            parentId: null,
            role: MessageRole.assistant,
            content: firstChar.greeting,
            createdAt: DateTime.now(),
            senderId: firstChar.id,
          );
          await manageChat.repository.saveMessage(greetingMsg);
          messages.add(greetingMsg);
        }

        final allCharsResult = await loadCharacter.characterRepository.getAllCharacters();
        final allAvailableCharacters = allCharsResult.fold((_) => <Character>[], (list) => list);

        final allWbResult = await getIt<WorldBookRepository>().getAllWorldBooks();
        final allAvailableWorldBooks = allWbResult.fold((_) => <WorldBook>[], (list) => list);

        final List<WorldBook> worldBooks = [];
        for (final wbId in chat.worldBookIds) {
          final wbResult = await getIt<WorldBookRepository>().getWorldBook(wbId);
          wbResult.fold((_) => null, (wb) => worldBooks.add(wb));
        }

        final allMessagesResult = await manageChat.getMessages(chat.id);
        allMessagesResult.fold((failure) => emit(ChatError(failure.message)), (
          allMsgs,
        ) {
          final Map<String, List<Message>> branches = {};
          for (final msg in allMsgs) {
            if (msg.parentId != null) {
              branches.putIfAbsent(msg.parentId!, () => []).add(msg);
            }
          }
          branches.forEach((key, list) {
            list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          });

          emit(
            ChatLoaded(
              characters: characters,
              allAvailableCharacters: allAvailableCharacters,
              worldBooks: worldBooks,
              allAvailableWorldBooks: allAvailableWorldBooks,
              chat: chat,
              messages: List.from(messages),
              branches: branches,
              currentLeafMessageId: messages.isNotEmpty
                  ? messages.last.id
                  : null,
              activeCharacterId: activeCharId,
            ),
          );
        });
      },
    );
  }

  Future<void> _onSendChatMessage(
    SendChatMessage event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is ChatLoaded) {
      final currentLeaf = currentState.currentLeafMessageId;
      final activeCharId = currentState.activeCharacterId;

      final userMessage = Message(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        chatId: currentState.chat.id,
        parentId: currentLeaf,
        role: MessageRole.user,
        content: event.content,
        attachments: event.attachments,
        createdAt: DateTime.now(),
      );

      final List<Message> updatedMessages = List.from(currentState.messages)
        ..add(userMessage);

      emit(
        currentState.copyWith(
          messages: updatedMessages,
          currentLeafMessageId: userMessage.id,
        ),
      );

      final result = await sendMessage(
        chatId: currentState.chat.id,
        content: event.content,
        senderId: activeCharId,
        attachments: event.attachments,
      );

      await result.fold((failure) async => emit(ChatError(failure.message)), (
        savedAssistantMsg,
      ) async {
        final linkedAssistantMsg = Message(
          id: savedAssistantMsg.id,
          chatId: savedAssistantMsg.chatId,
          parentId: userMessage.id,
          role: savedAssistantMsg.role,
          content: savedAssistantMsg.content,
          attachments: savedAssistantMsg.attachments,
          tokensUsed: savedAssistantMsg.tokensUsed,
          createdAt: savedAssistantMsg.createdAt,
          senderId: savedAssistantMsg.senderId,
        );
        await manageChat.repository.saveMessage(linkedAssistantMsg);

        await _loadMessagesAndBranches(
          currentState.characters,
          currentState.chat,
          activeCharId,
          linkedAssistantMsg.id,
          emit,
        );
      });
    }
  }

  Future<void> _onSwitchBranch(
    SwitchChatBranch event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is ChatLoaded) {
      await _loadMessagesAndBranches(
        currentState.characters,
        currentState.chat,
        currentState.activeCharacterId,
        event.leafMessageId,
        emit,
      );
    }
  }

  Future<void> _onSwitchToSiblingBranch(
    SwitchToSiblingBranch event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is ChatLoaded) {
      final messageId = event.messageId;
      final msg = currentState.messages.firstWhere((m) => m.id == messageId);
      final parentId = msg.parentId;
      if (parentId != null) {
        final siblings = currentState.branches[parentId] ?? [];
        if (siblings.length > 1) {
          final index = siblings.indexWhere((m) => m.id == messageId);
          if (index != -1) {
            int targetIndex = event.next ? index + 1 : index - 1;
            if (targetIndex >= 0 && targetIndex < siblings.length) {
              final targetSibling = siblings[targetIndex];
              String leafId = targetSibling.id;
              while (currentState.branches[leafId] != null &&
                  currentState.branches[leafId]!.isNotEmpty) {
                leafId = currentState.branches[leafId]!.first.id;
              }
              await _loadMessagesAndBranches(
                currentState.characters,
                currentState.chat,
                currentState.activeCharacterId,
                leafId,
                emit,
              );
            }
          }
        }
      }
    }
  }

  Future<void> _onUpdateChatCharacters(
    UpdateChatCharacters event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is ChatLoaded) {
      final updatedChat = currentState.chat.copyWith(characterIds: event.characterIds);
      final updateResult = await manageChat.repository.updateChat(updatedChat);
      await updateResult.fold(
        (failure) async => emit(ChatError(failure.message)),
        (_) async {
          final List<Character> characters = [];
          for (final charId in event.characterIds) {
            final charResult = await loadCharacter.characterRepository.getCharacter(charId);
            charResult.fold((_) => null, (char) => characters.add(char));
          }
          
          String? newActiveCharId = currentState.activeCharacterId;
          if (newActiveCharId == null || !event.characterIds.contains(newActiveCharId)) {
            newActiveCharId = event.characterIds.isNotEmpty ? event.characterIds.first : null;
          }
          
          await _loadMessagesAndBranches(
            characters,
            updatedChat,
            newActiveCharId,
            currentState.currentLeafMessageId,
            emit,
          );
        },
      );
    }
  }

  Future<void> _onUpdateChatWorldBooks(
    UpdateChatWorldBooks event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is ChatLoaded) {
      final updatedChat = currentState.chat.copyWith(worldBookIds: event.worldBookIds);
      final updateResult = await manageChat.repository.updateChat(updatedChat);
      await updateResult.fold(
        (failure) async => emit(ChatError(failure.message)),
        (_) async {
          await _loadMessagesAndBranches(
            currentState.characters,
            updatedChat,
            currentState.activeCharacterId,
            currentState.currentLeafMessageId,
            emit,
          );
        },
      );
    }
  }

  Future<void> _onSetActiveCharacter(
    SetActiveCharacter event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is ChatLoaded) {
      emit(currentState.copyWith(activeCharacterId: event.characterId));
    }
  }
}
