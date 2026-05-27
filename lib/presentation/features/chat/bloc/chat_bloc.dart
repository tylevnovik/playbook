import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collection/collection.dart';
import '../../../../domain/entities/character.dart';
import '../../../../domain/entities/chat.dart';
import '../../../../domain/entities/message.dart';
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
  }

  Future<void> _onLoadChat(LoadChat event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    final charResult = await loadCharacter(event.characterId);
    await charResult.fold((failure) async => emit(ChatError(failure.message)), (
      data,
    ) async {
      final character = data.$1;
      final chats = data.$2;

      Chat chat;
      if (event.chatId != null) {
        chat =
            chats.firstWhereOrNull((c) => c.id == event.chatId) ??
            (chats.isNotEmpty
                ? chats.first
                : await _createNewChat(character.id));
      } else if (chats.isNotEmpty) {
        chat = chats.first;
      } else {
        chat = await _createNewChat(character.id);
      }

      await _loadMessagesAndBranches(character, chat, null, emit);
    });
  }

  Future<Chat> _createNewChat(String characterId) async {
    final result = await manageChat.createChat(characterId);
    return result.fold(
      (failure) => throw Exception(failure.message),
      (chat) => chat,
    );
  }

  Future<void> _loadMessagesAndBranches(
    Character character,
    Chat chat,
    String? leafId,
    Emitter<ChatState> emit,
  ) async {
    // 1. Get messages for the branch
    final messagesResult = await manageChat.switchBranch(chat.id, leafId);
    await messagesResult.fold(
      (failure) async => emit(ChatError(failure.message)),
      (messages) async {
        // If there are no messages, create the greeting message from the character
        if (messages.isEmpty) {
          final greetingMsg = Message(
            id: 'greeting_${DateTime.now().millisecondsSinceEpoch}',
            chatId: chat.id,
            parentId: null,
            role: MessageRole.assistant,
            content: character.greeting,
            createdAt: DateTime.now(),
          );
          // Save greeting message to DB
          await manageChat.repository.saveMessage(greetingMsg);
          messages.add(greetingMsg);
        }

        // 2. Fetch all messages in the chat to construct the branch map
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
          // Sort branches by creation date
          branches.forEach((key, list) {
            list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          });

          emit(
            ChatLoaded(
              character: character,
              chat: chat,
              messages: List.from(messages),
              branches: branches,
              currentLeafMessageId: messages.isNotEmpty
                  ? messages.last.id
                  : null,
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

      // Append user message locally for quick UI feedback
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

      // Emit sending state with optimistic update
      emit(
        currentState.copyWith(
          messages: updatedMessages,
          currentLeafMessageId: userMessage.id,
        ),
      );

      // Trigger SendMessage usecase which will handle saving the user message & calling API
      final result = await sendMessage(
        chatId: currentState.chat.id,
        content: event.content,
        attachments: event.attachments,
      );

      await result.fold((failure) async => emit(ChatError(failure.message)), (
        savedAssistantMsg,
      ) async {
        // Re-link assistant message with parentId = userMessage.id
        final linkedAssistantMsg = Message(
          id: savedAssistantMsg.id,
          chatId: savedAssistantMsg.chatId,
          parentId: userMessage.id,
          role: savedAssistantMsg.role,
          content: savedAssistantMsg.content,
          attachments: savedAssistantMsg.attachments,
          tokensUsed: savedAssistantMsg.tokensUsed,
          createdAt: savedAssistantMsg.createdAt,
        );
        // Overwrite with parentId linking in DB
        await manageChat.repository.saveMessage(linkedAssistantMsg);

        // Reload messages and branch mappings
        await _loadMessagesAndBranches(
          currentState.character,
          currentState.chat,
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
        currentState.character,
        currentState.chat,
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
      // Find parent of this message
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
              // Switch branch starting from this sibling's leaf
              // To find the leaf, we traverse down using branches
              String leafId = targetSibling.id;
              while (currentState.branches[leafId] != null &&
                  currentState.branches[leafId]!.isNotEmpty) {
                leafId = currentState.branches[leafId]!.first.id;
              }
              await _loadMessagesAndBranches(
                currentState.character,
                currentState.chat,
                leafId,
                emit,
              );
            }
          }
        }
      }
    }
  }
}
