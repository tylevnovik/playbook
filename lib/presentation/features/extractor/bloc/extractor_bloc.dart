import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collection/collection.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../domain/entities/character.dart';
import '../../../../domain/entities/chat.dart';
import '../../../../domain/entities/message.dart';
import '../../../../domain/entities/world_book.dart';
import '../../../../domain/repositories/character_repository.dart';
import '../../../../domain/repositories/chat_repository.dart';
import '../../../../domain/repositories/world_book_repository.dart';
import '../../../../domain/repositories/settings_repository.dart';
import '../../../../domain/repositories/llm_repository.dart';
import 'extractor_event.dart';
import 'extractor_state.dart';

class ExtractorBloc extends Bloc<ExtractorEvent, ExtractorState> {
  final CharacterRepository characterRepository;
  final WorldBookRepository worldBookRepository;
  final ChatRepository chatRepository;
  final SettingsRepository settingsRepository;
  final LlmRepository llmRepository;

  ExtractorBloc({
    required this.characterRepository,
    required this.worldBookRepository,
    required this.chatRepository,
    required this.settingsRepository,
    required this.llmRepository,
  }) : super(const ExtractorState()) {
    on<LoadExtractorInitialData>(_onLoadExtractorInitialData);
    on<ExtractFromTextEvent>(_onExtractFromText);
    on<ExtractFromChatEvent>(_onExtractFromChat);
    on<ImportSelectedEntitiesEvent>(_onImportSelectedEntities);
  }

  Future<void> _onLoadExtractorInitialData(
    LoadExtractorInitialData event,
    Emitter<ExtractorState> emit,
  ) async {
    emit(state.copyWith(status: ExtractorStatus.loading));

    final booksResult = await worldBookRepository.getAllWorldBooks();
    final chatsResult = await chatRepository.getAllChats();
    final charsResult = await characterRepository.getAllCharacters();

    final books = booksResult.fold((_) => <WorldBook>[], (list) => list);
    final chats = chatsResult.fold((_) => <Chat>[], (list) => list);
    final chars = charsResult.fold((_) => <Character>[], (list) => list);

    emit(state.copyWith(
      status: ExtractorStatus.initial,
      worldBooks: books,
      chats: chats,
      allCharacters: chars,
      errorMessage: null,
      extractionProgressMessage: null,
    ));
  }

  String _cleanJsonContent(String content) {
    String cleaned = content.trim();
    if (cleaned.startsWith('```')) {
      final lines = cleaned.split('\n');
      if (lines.first.startsWith('```')) {
        lines.removeAt(0);
      }
      if (lines.isNotEmpty && lines.last.startsWith('```')) {
        lines.removeLast();
      }
      cleaned = lines.join('\n').trim();
    }
    return cleaned;
  }

  Future<void> _onExtractFromText(
    ExtractFromTextEvent event,
    Emitter<ExtractorState> emit,
  ) async {
    final text = event.text.trim();
    if (text.isEmpty) return;

    emit(state.copyWith(
      status: ExtractorStatus.loading,
      errorMessage: null,
      extractionProgressMessage: '正在分析文本，识别设定实体与角色卡名称...',
    ));

    try {
      final configResult = await settingsRepository.getDefaultLlmConfig();
      await configResult.fold(
        (failure) async {
          emit(state.copyWith(
            status: ExtractorStatus.error,
            errorMessage: '获取大模型配置失败: ${failure.message}',
          ));
        },
        (config) async {
          // --- 第一阶段：识别实体名称 ---
          const identifierPrompt = '''You are a world-building entity identifier.
Your task is to read the provided setting text and identify all the character profiles and worldview/lore entries mentioned.
Extract at most 5 key characters and at most 8 key worldview entries that are the most important.
For each item, output only its name and a very short 1-sentence summary.

Respond ONLY with a valid JSON in this format:
{
  "characters": [
    {
      "name": "Character Name",
      "summary": "1-sentence summary"
    }
  ],
  "world_book_entries": [
    {
      "name": "Entry Name (e.g. magic system name, city name, key concept)",
      "summary": "1-sentence summary"
    }
  ]
}
Return ONLY valid JSON. Do not include any markdown fences or conversational explanations.''';

          final identificationResult = await llmRepository.sendMessage(
            messages: [
              Message(
                id: 'system',
                chatId: '',
                role: MessageRole.system,
                content: identifierPrompt,
                createdAt: DateTime.now(),
              ),
              Message(
                id: 'user',
                chatId: '',
                role: MessageRole.user,
                content: text,
                createdAt: DateTime.now(),
              ),
            ],
            config: config,
          );

          await identificationResult.fold(
            (failure) async {
              emit(state.copyWith(
                status: ExtractorStatus.error,
                errorMessage: '实体识别失败: ${failure.message}',
              ));
            },
            (responseContent) async {
              try {
                final cleaned = _cleanJsonContent(responseContent);
                final Map<String, dynamic> parsed = jsonDecode(cleaned);
                
                final List<dynamic> charsList = parsed['characters'] ?? [];
                final List<dynamic> entriesList = parsed['world_book_entries'] ?? [];

                if (charsList.isEmpty && entriesList.isEmpty) {
                  emit(state.copyWith(
                    status: ExtractorStatus.error,
                    errorMessage: '未能从文本中识别出任何设定实体或角色名称，请换用更详细的文本重试。',
                  ));
                  return;
                }

                final List<Map<String, String>> finalCharacters = [];
                final List<Map<String, dynamic>> finalEntries = [];

                final totalItems = charsList.length + entriesList.length;
                int currentItemIdx = 0;

                // --- 第二阶段：靶向对每个实体提取高细节内容 ---
                // 1. 靶向提取角色卡
                for (final item in charsList) {
                  final String charName = (item['name'] ?? '').toString().trim();
                  if (charName.isEmpty) continue;

                  currentItemIdx++;
                  emit(state.copyWith(
                    extractionProgressMessage: '正在提取角色设定: $charName ($currentItemIdx / $totalItems)',
                  ));

                  final extractedChar = await _extractTargetedCharacter(charName, text, config);
                  if (extractedChar != null) {
                    finalCharacters.add(extractedChar);
                  }
                }

                // 2. 靶向提取世界设定百科词条
                for (final item in entriesList) {
                  final String entryName = (item['name'] ?? '').toString().trim();
                  if (entryName.isEmpty) continue;

                  currentItemIdx++;
                  emit(state.copyWith(
                    extractionProgressMessage: '正在提取词条百科: $entryName ($currentItemIdx / $totalItems)',
                  ));

                  final extractedEntry = await _extractTargetedEntry(entryName, text, config);
                  if (extractedEntry != null) {
                    finalEntries.add(extractedEntry);
                  }
                }

                emit(state.copyWith(
                  status: ExtractorStatus.success,
                  extractedCharacters: finalCharacters,
                  extractedEntries: finalEntries,
                  extractionProgressMessage: null,
                ));
              } catch (e) {
                emit(state.copyWith(
                  status: ExtractorStatus.error,
                  errorMessage: '解析实体识别结果 JSON 失败：$e\n原始结果：$responseContent',
                ));
              }
            },
          );
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: ExtractorStatus.error,
        errorMessage: '提取时发生未知错误: $e',
      ));
    }
  }

  Future<Map<String, String>?> _extractTargetedCharacter(
    String name,
    String sourceText,
    dynamic config,
  ) async {
    final systemPrompt = '''You are an expert character setting extractor.
Your task is to locate all descriptions and background settings about the character named "$name" from the provided source text.
Extract the detailed description of their background, personality, and appearance.
Preserve the original setting text and detailed explanations word-for-word or in high detail from the source text. Do NOT summarize, shorten, or generalize. Keep the sentences and structure as close to the original text as possible.

Respond ONLY with a valid JSON in this format:
{
  "name": "$name",
  "description": "Preserve the original description of character background, personality, and appearance in full detail.",
  "greeting": "A starting greeting message in-character based on their background"
}
Return ONLY valid JSON. Do not include any markdown fences or conversational explanations.
Important: The JSON values must be written in the same language as the source text (e.g. if source is in Chinese, return Chinese).''';

    try {
      final responseResult = await llmRepository.sendMessage(
        messages: [
          Message(
            id: 'system',
            chatId: '',
            role: MessageRole.system,
            content: systemPrompt,
            createdAt: DateTime.now(),
          ),
          Message(
            id: 'user',
            chatId: '',
            role: MessageRole.user,
            content: sourceText,
            createdAt: DateTime.now(),
          ),
        ],
        config: config,
      );

      return responseResult.fold(
        (_) => null,
        (responseContent) {
          try {
            final cleaned = _cleanJsonContent(responseContent);
            final Map<String, dynamic> parsed = jsonDecode(cleaned);
            return {
              'name': (parsed['name'] ?? name).toString(),
              'description': (parsed['description'] ?? '').toString(),
              'greeting': (parsed['greeting'] ?? '').toString(),
            };
          } catch (e) {
            return null;
          }
        },
      );
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _extractTargetedEntry(
    String name,
    String sourceText,
    dynamic config,
  ) async {
    final systemPrompt = '''You are an expert worldview setting extractor.
Your task is to locate all explanations and descriptions about the entry/setting named "$name" from the provided source text.
Extract the detailed explanation of this setting.
Preserve the original setting text and explanations word-for-word or in high detail from the source text. Do NOT summarize, shorten, or generalize. Keep the sentences, details, and structure as close to the original text as possible.

Respond ONLY with a valid JSON in this format:
{
  "name": "$name",
  "keywords": ["keyword1", "keyword2"],
  "content": "Preserve the original detailed explanation of this setting in full detail.",
  "category": "general|character|location|event"
}
Return ONLY valid JSON. Do not include any markdown fences or conversational explanations.
Important: The JSON values must be written in the same language as the source text (e.g. if source is in Chinese, return Chinese).''';

    try {
      final responseResult = await llmRepository.sendMessage(
        messages: [
          Message(
            id: 'system',
            chatId: '',
            role: MessageRole.system,
            content: systemPrompt,
            createdAt: DateTime.now(),
          ),
          Message(
            id: 'user',
            chatId: '',
            role: MessageRole.user,
            content: sourceText,
            createdAt: DateTime.now(),
          ),
        ],
        config: config,
      );

      return responseResult.fold(
        (_) => null,
        (responseContent) {
          try {
            final cleaned = _cleanJsonContent(responseContent);
            final Map<String, dynamic> parsed = jsonDecode(cleaned);
            return {
              'name': (parsed['name'] ?? name).toString(),
              'keywords': List<String>.from(parsed['keywords'] ?? []),
              'content': (parsed['content'] ?? '').toString(),
              'category': (parsed['category'] ?? 'general').toString(),
            };
          } catch (e) {
            return null;
          }
        },
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _onExtractFromChat(
    ExtractFromChatEvent event,
    Emitter<ExtractorState> emit,
  ) async {
    emit(state.copyWith(status: ExtractorStatus.loading, errorMessage: null));

    try {
      final messagesResult = await chatRepository.getMessages(event.chatId);
      await messagesResult.fold(
        (failure) async {
          emit(state.copyWith(
            status: ExtractorStatus.error,
            errorMessage: '获取聊天消息失败: ${failure.message}',
          ));
        },
        (messages) async {
          if (messages.isEmpty) {
            emit(state.copyWith(
              status: ExtractorStatus.error,
              errorMessage: '当前聊天会话没有消息历史，无法提取。',
            ));
            return;
          }

          // 仅获取最后 50 条消息以避免上下文超限
          final recentMessages = messages.length > 50 
              ? messages.sublist(messages.length - 50) 
              : messages;

          final StringBuffer chatTranscript = StringBuffer();
          for (final msg in recentMessages) {
            String senderName = '未知';
            if (msg.role == MessageRole.user) {
              senderName = '用户';
            } else {
              final character = state.allCharacters.firstWhereOrNull((c) => c.id == msg.senderId);
              senderName = character?.name ?? 'AI角色';
            }
            chatTranscript.writeln('$senderName: ${msg.content}');
          }

          final systemPromptText = '以下是一段角色扮演或故事创作的聊天历史记录。请分析该对话，提取其中涉及的重要角色设定卡以及世界观百科背景设定。\n\n对话记录：\n${chatTranscript.toString()}';
          add(ExtractFromTextEvent(systemPromptText));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: ExtractorStatus.error,
        errorMessage: '获取聊天数据时发生错误: $e',
      ));
    }
  }

  Future<void> _onImportSelectedEntities(
    ImportSelectedEntitiesEvent event,
    Emitter<ExtractorState> emit,
  ) async {
    emit(state.copyWith(status: ExtractorStatus.loading, errorMessage: null));

    try {
      // 1. 导入角色
      for (final charMap in event.characters) {
        final char = Character(
          id: IdGenerator.generate(),
          name: charMap['name'] ?? '未命名角色',
          avatarPath: '',
          description: charMap['description'] ?? '',
          greeting: charMap['greeting'] ?? '',
          tags: const [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await characterRepository.createCharacter(char);
      }

      // 2. 导入世界设定
      if (event.entries.isNotEmpty) {
        String? targetWbId = event.destinationWorldBookId;

        // 如果是新建世界书
        if (event.newWorldBookName != null && event.newWorldBookName!.trim().isNotEmpty) {
          final newWb = WorldBook(
            id: IdGenerator.generate(),
            name: event.newWorldBookName!.trim(),
            description: '自动从设定提取页面创建',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          final createWbResult = await worldBookRepository.createWorldBook(newWb);
          createWbResult.fold(
            (failure) => throw Exception('创建世界书失败: ${failure.message}'),
            (wb) => targetWbId = wb.id,
          );
        }

        if (targetWbId == null) {
          throw Exception('未指定或创建世界书，无法保存词条。');
        }

        for (final entryMap in event.entries) {
          final entry = WorldBookEntry(
            id: IdGenerator.generate(),
            worldBookId: targetWbId!,
            name: entryMap['name'] ?? '未命名设定',
            keywords: List<String>.from(entryMap['keywords'] ?? []),
            content: entryMap['content'] ?? '',
            category: entryMap['category'] ?? 'general',
            priority: 0,
            enabled: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await worldBookRepository.createEntry(entry);
        }
      }

      emit(state.copyWith(status: ExtractorStatus.importSuccess));
      // 重新加载初始数据（刷新列表）
      add(LoadExtractorInitialData());
    } catch (e) {
      emit(state.copyWith(
        status: ExtractorStatus.error,
        errorMessage: '导入过程中发生错误: $e',
      ));
    }
  }
}
