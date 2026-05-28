import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collection/collection.dart';
import '../../../../domain/entities/character.dart';
import '../../../../domain/entities/chat.dart';
import '../../../../domain/entities/message.dart';
import '../../../../domain/entities/world_book.dart';
import '../../../../domain/entities/story_state.dart';
import '../../../../domain/repositories/world_book_repository.dart';
import '../../../../domain/repositories/story_state_repository.dart';
import '../../../../domain/repositories/settings_repository.dart';
import '../../../../domain/repositories/llm_repository.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../domain/usecases/load_character.dart';
import '../../../../domain/usecases/manage_chat.dart';
import '../../../../domain/usecases/send_message.dart';
import '../../../../domain/usecases/build_prompt.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final LoadCharacter loadCharacter;
  final ManageChat manageChat;
  final SendMessage sendMessage;
  final StoryStateRepository storyStateRepository;

  ChatBloc({
    required this.loadCharacter,
    required this.manageChat,
    required this.sendMessage,
    required this.storyStateRepository,
  }) : super(ChatInitial()) {
    on<LoadChat>(_onLoadChat);
    on<SendChatMessage>(_onSendChatMessage);
    on<SwitchChatBranch>(_onSwitchBranch);
    on<SwitchToSiblingBranch>(_onSwitchToSiblingBranch);
    on<UpdateChatCharacters>(_onUpdateChatCharacters);
    on<UpdateChatWorldBooks>(_onUpdateChatWorldBooks);
    on<SetActiveCharacter>(_onSetActiveCharacter);
    on<AddStoryState>(_onAddStoryState);
    on<UpdateStoryStateEvent>(_onUpdateStoryState);
    on<DeleteStoryStateEvent>(_onDeleteStoryState);
    on<ToggleMessageCanon>(_onToggleMessageCanon);
    on<EditMessage>(_onEditMessage);
    on<RewriteMessage>(_onRewriteMessage);
    on<ImportExtractedEntities>(_onImportExtractedEntities);
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

        final storyStatesResult = await storyStateRepository.getStoryStates(chat.id);
        final storyStates = storyStatesResult.fold((_) => <StoryState>[], (list) => list);

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
              storyStates: storyStates,
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

      final configResult = await getIt<SettingsRepository>().getDefaultLlmConfig();
      final config = configResult.fold((_) => null, (c) => c);
      if (config == null) {
        emit(ChatError('无法获取 LLM 配置，请检查设置。'));
        return;
      }

      final activeId = (activeCharId != null && currentState.chat.characterIds.contains(activeCharId))
          ? activeCharId
          : currentState.chat.characterIds.first;
      final activeChar = currentState.characters.firstWhereOrNull((c) => c.id == activeId);
      if (activeChar == null) {
        emit(ChatError('无法获取当前角色。'));
        return;
      }

      final usernameResult = await getIt<SettingsRepository>().getString(AppConstants.keyUsername);
      final username = usernameResult.fold((_) => 'User', (val) => val ?? 'User');

      final userDescResult = await getIt<SettingsRepository>().getString(AppConstants.keyUserDescription);
      final userDescription = userDescResult.fold((_) => '', (val) => val ?? '');

      final userMsgId = DateTime.now().millisecondsSinceEpoch.toString();
      final userMessage = Message(
        id: userMsgId,
        chatId: currentState.chat.id,
        parentId: currentLeaf,
        role: MessageRole.user,
        content: event.content,
        attachments: event.attachments,
        createdAt: DateTime.now(),
      );
      await manageChat.repository.saveMessage(userMessage);

      final List<Message> messagesWithUser = List.from(currentState.messages)..add(userMessage);
      emit(
        currentState.copyWith(
          messages: messagesWithUser,
          currentLeafMessageId: userMsgId,
        ),
      );

      String? currentSummary = currentState.chat.summary;
      if (messagesWithUser.length >= AppConstants.defaultSummaryThreshold &&
          (currentSummary == null || currentSummary.trim().isEmpty)) {
        final summarizeResult = await getIt<LlmRepository>().summarize(
          messages: messagesWithUser,
          config: config,
        );
        await summarizeResult.fold(
          (_) async => null,
          (newSummary) async {
            currentSummary = newSummary;
            final updatedChat = currentState.chat.copyWith(summary: newSummary);
            await manageChat.repository.updateChat(updatedChat);
          },
        );
      }

      final promptMessagesResult = await getIt<BuildPrompt>().call(
        chatId: currentState.chat.id,
        activeCharacter: activeChar,
        allCharacters: currentState.characters,
        worldBookIds: currentState.chat.worldBookIds,
        messages: messagesWithUser,
        config: config,
        username: username,
        userDescription: userDescription,
        summary: currentSummary,
      );

      await promptMessagesResult.fold(
        (failure) async => emit(ChatError(failure.message)),
        (promptMessages) async {
          final assistantMsgId = (DateTime.now().millisecondsSinceEpoch + 1).toString();
          Message assistantMessage = Message(
            id: assistantMsgId,
            chatId: currentState.chat.id,
            parentId: userMsgId,
            role: MessageRole.assistant,
            content: '',
            createdAt: DateTime.now(),
            senderId: activeChar.id,
          );

          final List<Message> messagesWithAssistant = List.from(messagesWithUser)..add(assistantMessage);
          emit(
            currentState.copyWith(
              messages: messagesWithAssistant,
              currentLeafMessageId: assistantMsgId,
            ),
          );

          final stream = getIt<LlmRepository>().streamMessage(
            messages: promptMessages,
            config: config,
            attachments: event.attachments,
          );

          final contentBuffer = StringBuffer();
          bool hasError = false;
          String? errorMessage;

          await for (final chunkResult in stream) {
            await chunkResult.fold(
              (failure) async {
                hasError = true;
                errorMessage = failure.message;
              },
              (chunkText) async {
                contentBuffer.write(chunkText);
                assistantMessage = assistantMessage.copyWith(content: contentBuffer.toString());
                
                final updatedList = messagesWithAssistant.map((m) {
                  return m.id == assistantMsgId ? assistantMessage : m;
                }).toList();

                emit(
                  currentState.copyWith(
                    messages: updatedList,
                  ),
                );
              },
            );
            if (hasError) break;
          }

          if (hasError) {
            emit(ChatError(errorMessage ?? '生成失败。'));
          } else {
            await manageChat.repository.saveMessage(assistantMessage);

            await _loadMessagesAndBranches(
              currentState.characters,
              currentState.chat,
              activeId,
              assistantMsgId,
              emit,
            );
          }
        },
      );
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

  Future<void> _onAddStoryState(
    AddStoryState event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is ChatLoaded) {
      final newState = StoryState(
        id: IdGenerator.generate(),
        chatId: currentState.chat.id,
        category: event.category,
        targetId: event.targetId,
        content: event.content,
        isActive: true,
        updatedAt: DateTime.now(),
      );
      final result = await storyStateRepository.addStoryState(newState);
      await result.fold(
        (failure) async => emit(ChatError(failure.message)),
        (_) async {
          await _loadMessagesAndBranches(
            currentState.characters,
            currentState.chat,
            currentState.activeCharacterId,
            currentState.currentLeafMessageId,
            emit,
          );
        },
      );
    }
  }

  Future<void> _onUpdateStoryState(
    UpdateStoryStateEvent event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is ChatLoaded) {
      final updated = event.state.copyWith(updatedAt: DateTime.now());
      final result = await storyStateRepository.updateStoryState(updated);
      await result.fold(
        (failure) async => emit(ChatError(failure.message)),
        (_) async {
          await _loadMessagesAndBranches(
            currentState.characters,
            currentState.chat,
            currentState.activeCharacterId,
            currentState.currentLeafMessageId,
            emit,
          );
        },
      );
    }
  }

  Future<void> _onDeleteStoryState(
    DeleteStoryStateEvent event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is ChatLoaded) {
      final result = await storyStateRepository.deleteStoryState(event.id);
      await result.fold(
        (failure) async => emit(ChatError(failure.message)),
        (_) async {
          await _loadMessagesAndBranches(
            currentState.characters,
            currentState.chat,
            currentState.activeCharacterId,
            currentState.currentLeafMessageId,
            emit,
          );
        },
      );
    }
  }

  Future<void> _onToggleMessageCanon(
    ToggleMessageCanon event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is ChatLoaded) {
      final result = await manageChat.repository.toggleMessageCanon(event.messageId, event.isCanon);
      await result.fold(
        (failure) async => emit(ChatError(failure.message)),
        (_) async {
          await _loadMessagesAndBranches(
            currentState.characters,
            currentState.chat,
            currentState.activeCharacterId,
            currentState.currentLeafMessageId,
            emit,
          );
        },
      );
    }
  }

  Future<void> _onEditMessage(
    EditMessage event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is ChatLoaded) {
      final oldMsgResult = await manageChat.repository.getMessage(event.messageId);
      await oldMsgResult.fold(
        (failure) async => emit(ChatError(failure.message)),
        (oldMsg) async {
          final newMsg = Message(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            chatId: oldMsg.chatId,
            parentId: oldMsg.parentId,
            role: oldMsg.role,
            content: event.newContent,
            attachments: oldMsg.attachments,
            createdAt: DateTime.now(),
            senderId: oldMsg.senderId,
          );
          final saveResult = await manageChat.repository.saveMessage(newMsg);
          await saveResult.fold(
            (failure) async => emit(ChatError(failure.message)),
            (savedMsg) async {
              await _loadMessagesAndBranches(
                currentState.characters,
                currentState.chat,
                currentState.activeCharacterId,
                savedMsg.id,
                emit,
              );
            },
          );
        },
      );
    }
  }

  Future<void> _onRewriteMessage(
    RewriteMessage event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is ChatLoaded) {
      emit(ChatLoading());
      
      final oldMsgResult = await manageChat.repository.getMessage(event.messageId);
      await oldMsgResult.fold(
        (failure) async => emit(ChatError(failure.message)),
        (oldMsg) async {
          final configResult = await getIt<SettingsRepository>().getDefaultLlmConfig();
          await configResult.fold(
            (failure) async => emit(ChatError(failure.message)),
            (config) async {
              final systemPrompt = '''You are a helper that rewrites or continues a selected portion of text in a story.
Return ONLY the rewritten or continued text. Do not add any conversational filler, explanations, or quotes around the output.
Instruction: ${event.instruction}
Selected Text to replace or continue: "${event.selectedText}"''';

              final messages = [
                Message(
                  id: 'system',
                  chatId: '',
                  role: MessageRole.system,
                  content: systemPrompt,
                  createdAt: DateTime.now(),
                ),
                Message(
                  id: 'context',
                  chatId: '',
                  role: MessageRole.user,
                  content: 'Here is the message context:\n${oldMsg.content}',
                  createdAt: DateTime.now(),
                ),
              ];

              final responseResult = await getIt<LlmRepository>().sendMessage(
                messages: messages,
                config: config,
              );

              await responseResult.fold(
                (failure) async => emit(ChatError(failure.message)),
                (rewrittenText) async {
                  String newContent;
                  if (event.instruction == '续写') {
                    final index = oldMsg.content.indexOf(event.selectedText);
                    if (index != -1) {
                      newContent = '${oldMsg.content.substring(0, index + event.selectedText.length)}\n$rewrittenText${oldMsg.content.substring(index + event.selectedText.length)}';
                    } else {
                      newContent = '${oldMsg.content}\n$rewrittenText';
                    }
                  } else {
                    newContent = oldMsg.content.replaceAll(event.selectedText, rewrittenText);
                  }

                  final newMsg = Message(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    chatId: oldMsg.chatId,
                    parentId: oldMsg.parentId,
                    role: oldMsg.role,
                    content: newContent,
                    attachments: oldMsg.attachments,
                    createdAt: DateTime.now(),
                    senderId: event.senderId ?? oldMsg.senderId,
                  );

                  final saveResult = await manageChat.repository.saveMessage(newMsg);
                  await saveResult.fold(
                    (failure) async => emit(ChatError(failure.message)),
                    (savedMsg) async {
                      await _loadMessagesAndBranches(
                        currentState.characters,
                        currentState.chat,
                        currentState.activeCharacterId,
                        savedMsg.id,
                        emit,
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

  Future<void> _onImportExtractedEntities(
    ImportExtractedEntities event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is ChatLoaded) {
      emit(ChatLoading());
      
      try {
        final List<String> newCharIds = List.from(currentState.chat.characterIds);
        for (final charMap in event.characters) {
          final char = Character(
            id: IdGenerator.generate(),
            name: charMap['name'] ?? 'AI Character',
            avatarPath: '',
            description: charMap['description'] ?? '',
            greeting: charMap['greeting'] ?? '',
            tags: const [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await loadCharacter.characterRepository.createCharacter(char);
          newCharIds.add(char.id);
        }

        String worldBookId;
        final List<String> newWbIds = List.from(currentState.chat.worldBookIds);
        if (newWbIds.isNotEmpty) {
          worldBookId = newWbIds.first;
        } else {
          final firstCharName = currentState.characters.isNotEmpty ? currentState.characters.first.name : 'Chat';
          final newWb = WorldBook(
            id: IdGenerator.generate(),
            name: '$firstCharName World Book',
            description: 'Auto-extracted from background settings',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await getIt<WorldBookRepository>().createWorldBook(newWb);
          newWbIds.add(newWb.id);
          worldBookId = newWb.id;
        }

        for (final entryMap in event.entries) {
          final entry = WorldBookEntry(
            id: IdGenerator.generate(),
            worldBookId: worldBookId,
            name: entryMap['name'] ?? 'Entry',
            keywords: List<String>.from(entryMap['keywords'] ?? []),
            content: entryMap['content'] ?? '',
            category: entryMap['category'] ?? 'general',
            priority: entryMap['priority'] ?? 0,
            enabled: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await getIt<WorldBookRepository>().createEntry(entry);
        }

        final updatedChat = currentState.chat.copyWith(
          characterIds: newCharIds,
          worldBookIds: newWbIds,
          updatedAt: DateTime.now(),
        );
        await manageChat.repository.updateChat(updatedChat);

        final List<Character> newCharacters = [];
        for (final charId in newCharIds) {
          final charRes = await loadCharacter.characterRepository.getCharacter(charId);
          charRes.fold((_) => null, (c) => newCharacters.add(c));
        }

        await _loadMessagesAndBranches(
          newCharacters,
          updatedChat,
          currentState.activeCharacterId ?? (newCharIds.isNotEmpty ? newCharIds.first : null),
          currentState.currentLeafMessageId,
          emit,
        );
      } catch (e) {
        emit(ChatError(e.toString()));
      }
    }
  }
}
