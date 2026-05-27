# Multi-Platform Role-Playing LLM App — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a cross-platform (Web/Windows/Android) role-playing LLM application with Flutter, featuring character cards, world books, tree-structured dialogues, and multi-provider LLM support.

**Architecture:** Clean Architecture + BLoC. Domain layer is pure Dart with zero Flutter dependency. Data layer handles SQLite persistence and LLM API calls. Presentation layer uses BLoC for state management.

**Tech Stack:** Flutter 3.x, Dart, BLoC, GetIt+injectable, sqflite, dio, json_serializable, go_router, flutter_markdown

---

## Phase 1: Project Scaffolding & Core

### Task 1: Create Flutter Project & Configure Dependencies

**Files:**
- Create: `pubspec.yaml`
- Create: `lib/app.dart`
- Create: `lib/main.dart`

- [ ] **Step 1: Create Flutter project**

```bash
flutter create --org com.playbook --project-name playbook --platforms web,windows,android .
```

- [ ] **Step 2: Add dependencies to pubspec.yaml**

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^8.1.3
  get_it: ^7.6.4
  injectable: ^2.3.2
  sqflite: ^2.3.0
  sqflite_common_ffi: ^2.3.0+4
  sqflite_common_ffi_web: ^0.4.0
  dio: ^5.4.0
  json_annotation: ^4.8.1
  go_router: ^13.0.0
  flutter_markdown: ^0.6.18
  image_picker: ^1.0.7
  file_picker: ^6.1.1
  path_provider: ^2.1.1
  uuid: ^4.2.1
  google_fonts: ^6.1.0
  dynamic_color: ^1.7.0
  shared_preferences: ^2.2.2
  equatable: ^2.0.5
  dartz: ^0.10.1
  freezed_annotation: ^2.4.1
  collection: ^1.18.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.7
  json_serializable: ^6.7.1
  injectable_generator: ^2.4.1
  freezed: ^2.4.5
  bloc_test: ^9.1.5
  mocktail: ^1.0.1
  flutter_lints: ^3.0.1
```

- [ ] **Step 3: Run flutter pub get**

```bash
flutter pub get
```

- [ ] **Step 4: Create minimal app.dart**

```dart
import 'package:flutter/material.dart';

class PlaybookApp extends StatelessWidget {
  const PlaybookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Playbook',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(child: Text('Playbook')),
      ),
    );
  }
}
```

- [ ] **Step 5: Create main.dart**

```dart
import 'package:flutter/material.dart';
import 'app.dart';

void main() {
  runApp(const PlaybookApp());
}
```

- [ ] **Step 6: Verify build**

```bash
flutter build windows --debug
```

- [ ] **Step 7: Commit**

```bash
git init
git add .
git commit -m "feat: scaffold Flutter project with dependencies"
```

---

### Task 2: Core Layer — Theme System

**Files:**
- Create: `lib/core/theme/app_theme.dart`
- Create: `lib/core/theme/app_colors.dart`

- [ ] **Step 1: Create app_colors.dart**

```dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryLight = Color(0xFF6750A4);
  static const Color primaryDark = Color(0xFFD0BCFF);
  static const Color surfaceLight = Color(0xFFFFFBFE);
  static const Color surfaceDark = Color(0xFF1C1B1F);
  static const Color errorLight = Color(0xFFB3261E);
  static const Color errorDark = Color(0xFFF2B8B5);
  
  // Chat bubble colors
  static const Color userBubbleLight = Color(0xFFE8DEF8);
  static const Color userBubbleDark = Color(0xFF4F378B);
  static const Color assistantBubbleLight = Color(0xFFE7E0EC);
  static const Color assistantBubbleDark = Color(0xFF2D2D3D);
}
```

- [ ] **Step 2: Create app_theme.dart**

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

enum AppThemeMode { light, dark, system, custom }

class AppTheme {
  static ThemeData light({Color? seedColor}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor ?? AppColors.primaryLight,
      brightness: Brightness.light,
    );
    return _buildTheme(colorScheme);
  }

  static ThemeData dark({Color? seedColor}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor ?? AppColors.primaryDark,
      brightness: Brightness.dark,
    );
    return _buildTheme(colorScheme);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final textTheme = GoogleFonts.notoSansScTextTheme(
      ThemeData(colorScheme: colorScheme).textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/core/theme/
git commit -m "feat: add Material 3 theme system with light/dark/custom support"
```

---

### Task 3: Core Layer — Constants, Error Handling, Utils

**Files:**
- Create: `lib/core/constants/app_constants.dart`
- Create: `lib/core/error/failures.dart`
- Create: `lib/core/error/exceptions.dart`
- Create: `lib/core/utils/id_generator.dart`
- Create: `lib/core/utils/token_estimator.dart`

- [ ] **Step 1: Create app_constants.dart**

```dart
class AppConstants {
  static const String appName = 'Playbook';
  static const String dbName = 'playbook.db';
  static const int dbVersion = 1;
  
  // Token limits (default, overridable per model)
  static const int defaultMaxContextTokens = 8000;
  static const int defaultMaxResponseTokens = 1000;
  static const int defaultSummaryThreshold = 20; // messages before summarization
  static const int defaultRecentMessages = 20;
  
  // Storage keys
  static const String keyThemeMode = 'theme_mode';
  static const String keyPrimaryColor = 'primary_color';
  static const String keyUsername = 'username';
  static const String keyDefaultProvider = 'default_provider';
  static const String keyOpenaiApiKey = 'openai_api_key';
  static const String keyOpenaiBaseUrl = 'openai_base_url';
  static const String keyOpenaiModel = 'openai_model';
  static const String keyAnthropicApiKey = 'anthropic_api_key';
  static const String keyAnthropicModel = 'anthropic_model';
  static const String keyGeminiApiKey = 'gemini_api_key';
  static const String keyGeminiModel = 'gemini_model';
}
```

- [ ] **Step 2: Create failures.dart**

```dart
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

class ApiFailure extends Failure {
  final int? statusCode;
  const ApiFailure(super.message, {this.statusCode});
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class FileFailure extends Failure {
  const FileFailure(super.message);
}
```

- [ ] **Step 3: Create exceptions.dart**

```dart
class DatabaseException implements Exception {
  final String message;
  const DatabaseException(this.message);
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});
}

class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);
}
```

- [ ] **Step 4: Create id_generator.dart**

```dart
import 'package:uuid/uuid.dart';

class IdGenerator {
  static const _uuid = Uuid();
  
  static String generate() => _uuid.v4();
}
```

- [ ] **Step 5: Create token_estimator.dart**

```dart
class TokenEstimator {
  /// Rough estimation: ~4 chars per token for English, ~2 chars per token for CJK
  static int estimate(String text) {
    int count = 0;
    for (int i = 0; i < text.length; i++) {
      final char = text.codeUnitAt(i);
      // CJK characters
      if (char >= 0x4E00 && char <= 0x9FFF) {
        count += 1;
      } else {
        count += 1; // Will be divided by 4 later
      }
    }
    // Rough: 4 chars ≈ 1 token for ASCII, CJK already counted
    final asciiChars = text.runes.where((r) => r < 0x4E00 || r > 0x9FFF).length;
    final cjkChars = text.runes.length - asciiChars;
    return (asciiChars / 4).ceil() + cjkChars;
  }
}
```

- [ ] **Step 6: Commit**

```bash
git add lib/core/
git commit -m "feat: add core constants, error handling, and utilities"
```

---

### Task 4: Domain Layer — Entities

**Files:**
- Create: `lib/domain/entities/character.dart`
- Create: `lib/domain/entities/chat.dart`
- Create: `lib/domain/entities/message.dart`
- Create: `lib/domain/entities/world_book.dart`
- Create: `lib/domain/entities/llm_config.dart`

- [ ] **Step 1: Create character.dart**

```dart
import 'package:equatable/equatable.dart';

class Character extends Equatable {
  final String id;
  final String name;
  final String? avatarPath;
  final String description;
  final String greeting;
  final String? exampleMessages;
  final String? systemPrompt;
  final List<String> tags;
  final String? worldBookId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastChattedAt;

  const Character({
    required this.id,
    required this.name,
    this.avatarPath,
    required this.description,
    required this.greeting,
    this.exampleMessages,
    this.systemPrompt,
    this.tags = const [],
    this.worldBookId,
    required this.createdAt,
    required this.updatedAt,
    this.lastChattedAt,
  });

  Character copyWith({
    String? name,
    String? avatarPath,
    String? description,
    String? greeting,
    String? exampleMessages,
    String? systemPrompt,
    List<String>? tags,
    String? worldBookId,
    DateTime? lastChattedAt,
  }) {
    return Character(
      id: id,
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
      description: description ?? this.description,
      greeting: greeting ?? this.greeting,
      exampleMessages: exampleMessages ?? this.exampleMessages,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      tags: tags ?? this.tags,
      worldBookId: worldBookId ?? this.worldBookId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      lastChattedAt: lastChattedAt ?? this.lastChattedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, description, greeting];
}
```

- [ ] **Step 2: Create message.dart**

```dart
import 'package:equatable/equatable.dart';

enum MessageRole { user, assistant, system }

class MessageAttachment {
  final String path; // local file path or base64
  final String mimeType;
  
  const MessageAttachment({required this.path, required this.mimeType});
}

class Message extends Equatable {
  final String id;
  final String chatId;
  final String? parentId; // null = root, otherwise points to parent for tree structure
  final MessageRole role;
  final String content;
  final List<MessageAttachment>? attachments;
  final int? tokensUsed;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.chatId,
    this.parentId,
    required this.role,
    required this.content,
    this.attachments,
    this.tokensUsed,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, chatId, parentId, role, content];
}
```

- [ ] **Step 3: Create chat.dart**

```dart
import 'package:equatable/equatable.dart';

class Chat extends Equatable {
  final String id;
  final String characterId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Chat({
    required this.id,
    required this.characterId,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, characterId];
}
```

- [ ] **Step 4: Create world_book.dart**

```dart
import 'package:equatable/equatable.dart';

class WorldBook extends Equatable {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WorldBook({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, name];
}

class WorldBookEntry extends Equatable {
  final String id;
  final String worldBookId;
  final String name;
  final List<String> keywords;
  final String content;
  final String category;
  final int priority;
  final bool enabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WorldBookEntry({
    required this.id,
    required this.worldBookId,
    required this.name,
    required this.keywords,
    required this.content,
    this.category = 'general',
    this.priority = 0,
    this.enabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, worldBookId, name, keywords];
}
```

- [ ] **Step 5: Create llm_config.dart**

```dart
import 'package:equatable/equatable.dart';

enum LlmProviderType { openai, anthropic, gemini }

class LlmConfig extends Equatable {
  final LlmProviderType providerType;
  final String apiKey;
  final String? baseUrl;
  final String model;
  final double temperature;
  final int maxTokens;
  final int contextWindow;

  const LlmConfig({
    required this.providerType,
    required this.apiKey,
    this.baseUrl,
    required this.model,
    this.temperature = 0.7,
    this.maxTokens = 1000,
    this.contextWindow = 8000,
  });

  @override
  List<Object?> get props => [providerType, model];
}
```

- [ ] **Step 6: Commit**

```bash
git add lib/domain/entities/
git commit -m "feat: add domain entities (Character, Chat, Message, WorldBook, LlmConfig)"
```

---

### Task 5: Domain Layer — Repository Interfaces

**Files:**
- Create: `lib/domain/repositories/character_repository.dart`
- Create: `lib/domain/repositories/chat_repository.dart`
- Create: `lib/domain/repositories/world_book_repository.dart`
- Create: `lib/domain/repositories/settings_repository.dart`
- Create: `lib/domain/repositories/llm_repository.dart`

- [ ] **Step 1: Create character_repository.dart**

```dart
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/character.dart';

abstract class CharacterRepository {
  Future<Either<Failure, List<Character>>> getAllCharacters();
  Future<Either<Failure, Character>> getCharacter(String id);
  Future<Either<Failure, Character>> createCharacter(Character character);
  Future<Either<Failure, Character>> updateCharacter(Character character);
  Future<Either<Failure, void>> deleteCharacter(String id);
  Future<Either<Failure, List<Character>>> searchCharacters(String query);
  Future<Either<Failure, void>> importCharacter(String jsonContent);
  Future<Either<Failure, String>> exportCharacter(String id);
}
```

- [ ] **Step 2: Create chat_repository.dart**

```dart
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/chat.dart';
import '../entities/message.dart';

abstract class ChatRepository {
  Future<Either<Failure, List<Chat>>> getChatsForCharacter(String characterId);
  Future<Either<Failure, Chat>> createChat(String characterId);
  Future<Either<Failure, void>> deleteChat(String id);
  Future<Either<Failure, List<Message>>> getMessages(String chatId);
  Future<Either<Failure, Message>> getMessage(String id);
  Future<Either<Failure, Message>> saveMessage(Message message);
  Future<Either<Failure, List<Message>>> getBranchMessages(String chatId, String? leafMessageId);
  Future<Either<Failure, List<Message>>> getMessageBranches(String chatId, String parentId);
}
```

- [ ] **Step 3: Create world_book_repository.dart**

```dart
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/world_book.dart';

abstract class WorldBookRepository {
  Future<Either<Failure, List<WorldBook>>> getAllWorldBooks();
  Future<Either<Failure, WorldBook>> getWorldBook(String id);
  Future<Either<Failure, WorldBook>> createWorldBook(WorldBook worldBook);
  Future<Either<Failure, WorldBook>> updateWorldBook(WorldBook worldBook);
  Future<Either<Failure, void>> deleteWorldBook(String id);
  Future<Either<Failure, List<WorldBookEntry>>> getEntries(String worldBookId);
  Future<Either<Failure, WorldBookEntry>> createEntry(WorldBookEntry entry);
  Future<Either<Failure, WorldBookEntry>> updateEntry(WorldBookEntry entry);
  Future<Either<Failure, void>> deleteEntry(String entryId);
  Future<Either<Failure, List<WorldBookEntry>>> matchEntries(String worldBookId, String text);
}
```

- [ ] **Step 4: Create settings_repository.dart**

```dart
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/llm_config.dart';

abstract class SettingsRepository {
  Future<Either<Failure, String?>> getString(String key);
  Future<Either<Failure, void>> setString(String key, String value);
  Future<Either<Failure, int?>> getInt(String key);
  Future<Either<Failure, void>> setInt(String key, int value);
  Future<Either<Failure, double?>> getDouble(String key);
  Future<Either<Failure, void>> setDouble(String key, double value);
  Future<Either<Failure, bool?>> getBool(String key);
  Future<Either<Failure, void>> setBool(String key, bool value);
  Future<Either<Failure, LlmConfig>> getLlmConfig(LlmProviderType providerType);
  Future<Either<Failure, LlmProviderType>> getDefaultProvider();
}
```

- [ ] **Step 5: Create llm_repository.dart**

```dart
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/message.dart';
import '../entities/llm_config.dart';

abstract class LlmRepository {
  Future<Either<Failure, String>> sendMessage({
    required List<Message> messages,
    required LlmConfig config,
    List<MessageAttachment>? attachments,
  });

  Stream<Either<Failure, String>> streamMessage({
    required List<Message> messages,
    required LlmConfig config,
    List<MessageAttachment>? attachments,
  });

  Future<Either<Failure, String>> summarize({
    required List<Message> messages,
    required LlmConfig config,
  });
}
```

- [ ] **Step 6: Commit**

```bash
git add lib/domain/repositories/
git commit -m "feat: add domain repository interfaces"
```

---

### Task 6: Domain Layer — Use Cases

**Files:**
- Create: `lib/domain/usecases/send_message.dart`
- Create: `lib/domain/usecases/load_character.dart`
- Create: `lib/domain/usecases/manage_chat.dart`
- Create: `lib/domain/usecases/build_prompt.dart`

- [ ] **Step 1: Create send_message.dart**

```dart
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/message.dart';
import '../entities/llm_config.dart';
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
```

- [ ] **Step 2: Create load_character.dart**

```dart
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/character.dart';
import '../entities/chat.dart';
import '../repositories/character_repository.dart';
import '../repositories/chat_repository.dart';

class LoadCharacter {
  final CharacterRepository characterRepository;
  final ChatRepository chatRepository;

  LoadCharacter({
    required this.characterRepository,
    required this.chatRepository,
  });

  Future<Either<Failure, (Character, List<Chat>)>> call(String characterId) async {
    final charResult = await characterRepository.getCharacter(characterId);
    return charResult.fold(
      (failure) => Left(failure),
      (character) async {
        final chatsResult = await chatRepository.getChatsForCharacter(characterId);
        return chatsResult.fold(
          (failure) => Left(failure),
          (chats) => Right((character, chats)),
        );
      },
    );
  }
}
```

- [ ] **Step 3: Create manage_chat.dart**

```dart
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/chat.dart';
import '../entities/message.dart';
import '../repositories/chat_repository.dart';

class ManageChat {
  final ChatRepository repository;

  ManageChat({required this.repository});

  Future<Either<Failure, Chat>> createChat(String characterId) {
    return repository.createChat(characterId);
  }

  Future<Either<Failure, void>> deleteChat(String id) {
    return repository.deleteChat(id);
  }

  Future<Either<Failure, List<Message>>> getMessages(String chatId) {
    return repository.getMessages(chatId);
  }

  Future<Either<Failure, List<Message>>> switchBranch(String chatId, String? leafMessageId) {
    return repository.getBranchMessages(chatId, leafMessageId);
  }

  Future<Either<Failure, List<Message>>> getBranches(String chatId, String parentId) {
    return repository.getMessageBranches(chatId, parentId);
  }
}
```

- [ ] **Step 4: Create build_prompt.dart**

```dart
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/utils/token_estimator.dart';
import '../entities/character.dart';
import '../entities/message.dart';
import '../entities/world_book.dart';
import '../entities/llm_config.dart';
import '../repositories/world_book_repository.dart';

class BuildPrompt {
  final WorldBookRepository worldBookRepository;

  BuildPrompt({required this.worldBookRepository});

  Future<Either<Failure, List<Message>>> call({
    required Character character,
    required List<Message> messages,
    required LlmConfig config,
    String? username,
    String? summary,
  }) async {
    final promptMessages = <Message>[];
    int tokenBudget = config.contextWindow - config.maxTokens;

    // 1. System prompt
    final systemPrompt = _buildSystemPrompt(character, username);
    promptMessages.add(Message(
      id: 'system',
      chatId: '',
      role: MessageRole.system,
      content: systemPrompt,
      createdAt: DateTime.now(),
    ));
    tokenBudget -= TokenEstimator.estimate(systemPrompt);

    // 2. World book entries (if linked)
    if (character.worldBookId != null) {
      final entriesResult = await worldBookRepository.matchEntries(
        character.worldBookId!,
        messages.map((m) => m.content).join(' '),
      );
      entriesResult.fold(
        (failure) => null, // Skip on error
        (entries) {
          if (entries.isNotEmpty) {
            final worldContext = entries.map((e) => e.content).join('\n\n');
            tokenBudget -= TokenEstimator.estimate(worldContext);
            if (tokenBudget > 0) {
              promptMessages.add(Message(
                id: 'world_context',
                chatId: '',
                role: MessageRole.system,
                content: '## World Context\n$worldContext',
                createdAt: DateTime.now(),
              ));
            }
          }
        },
      );
    }

    // 3. Summary (if exists)
    if (summary != null && summary.isNotEmpty) {
      tokenBudget -= TokenEstimator.estimate(summary);
      if (tokenBudget > 0) {
        promptMessages.add(Message(
          id: 'summary',
          chatId: '',
          role: MessageRole.system,
          content: '## Previous Conversation Summary\n$summary',
          createdAt: DateTime.now(),
        ));
      }
    }

    // 4. Recent messages (fit as many as budget allows)
    final recentMessages = messages.reversed.take(config.contextWindow ~/ 200).toList().reversed;
    for (final msg in recentMessages) {
      final msgTokens = TokenEstimator.estimate(msg.content);
      if (tokenBudget - msgTokens < 0) break;
      tokenBudget -= msgTokens;
      promptMessages.add(msg);
    }

    return Right(promptMessages);
  }

  String _buildSystemPrompt(Character character, String? username) {
    final userName = username ?? 'User';
    final customPrompt = character.systemPrompt ?? '';
    
    return '''You are ${character.name}. Stay in character at all times.

## Character Description
${character.description}

$customPrompt

## Rules
- Never break character
- Never refer to yourself as an AI or language model
- Respond as ${character.name} would, based on the character description
- Use * for actions, " for dialogue
- Keep responses engaging and in-character
- The user's name is $userName''';
  }
}
```

- [ ] **Step 5: Commit**

```bash
git add lib/domain/usecases/
git commit -m "feat: add domain use cases (SendMessage, LoadCharacter, ManageChat, BuildPrompt)"
```

---

## Phase 2: Data Layer & LLM Integration

### Task 7: Data Layer — Database Setup

**Files:**
- Create: `lib/data/datasources/local/database_service.dart`
- Create: `lib/data/datasources/local/character_dao.dart`
- Create: `lib/data/datasources/local/chat_dao.dart`
- Create: `lib/data/datasources/local/message_dao.dart`
- Create: `lib/data/datasources/local/world_book_dao.dart`

- [ ] **Step 1: Create database_service.dart**

```dart
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_constants.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    if (kIsWeb) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfiWeb;
    }
    
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE characters (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        avatar_path TEXT,
        description TEXT NOT NULL,
        greeting TEXT NOT NULL,
        example_messages TEXT,
        system_prompt TEXT,
        tags TEXT DEFAULT '[]',
        world_book_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_chatted_at TEXT,
        FOREIGN KEY (world_book_id) REFERENCES world_books(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE chats (
        id TEXT PRIMARY KEY,
        character_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (character_id) REFERENCES characters(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        chat_id TEXT NOT NULL,
        parent_id TEXT,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        attachments TEXT,
        tokens_used INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE,
        FOREIGN KEY (parent_id) REFERENCES messages(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE world_books (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE world_book_entries (
        id TEXT PRIMARY KEY,
        world_book_id TEXT NOT NULL,
        name TEXT NOT NULL,
        keywords TEXT NOT NULL,
        content TEXT NOT NULL,
        category TEXT DEFAULT 'general',
        priority INTEGER DEFAULT 0,
        enabled INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (world_book_id) REFERENCES world_books(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Indexes
    await db.execute('CREATE INDEX idx_chats_character ON chats(character_id)');
    await db.execute('CREATE INDEX idx_messages_chat ON messages(chat_id)');
    await db.execute('CREATE INDEX idx_messages_parent ON messages(parent_id)');
    await db.execute('CREATE INDEX idx_entries_worldbook ON world_book_entries(world_book_id)');
  }

  static Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
```

- [ ] **Step 2: Create character_dao.dart**

```dart
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';

class CharacterDao {
  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await DatabaseService.database;
    return await db.query('characters', orderBy: 'last_chatted_at DESC');
  }

  Future<Map<String, dynamic>?> getById(String id) async {
    final db = await DatabaseService.database;
    final results = await db.query('characters', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> insert(Map<String, dynamic> data) async {
    final db = await DatabaseService.database;
    await db.insert('characters', data);
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    final db = await DatabaseService.database;
    await db.update('characters', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(String id) async {
    final db = await DatabaseService.database;
    await db.delete('characters', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> search(String query) async {
    final db = await DatabaseService.database;
    return await db.query(
      'characters',
      where: 'name LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
  }
}
```

- [ ] **Step 3: Create chat_dao.dart**

```dart
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';

class ChatDao {
  Future<List<Map<String, dynamic>>> getByCharacterId(String characterId) async {
    final db = await DatabaseService.database;
    return await db.query(
      'chats',
      where: 'character_id = ?',
      whereArgs: [characterId],
      orderBy: 'updated_at DESC',
    );
  }

  Future<Map<String, dynamic>?> getById(String id) async {
    final db = await DatabaseService.database;
    final results = await db.query('chats', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> insert(Map<String, dynamic> data) async {
    final db = await DatabaseService.database;
    await db.insert('chats', data);
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    final db = await DatabaseService.database;
    await db.update('chats', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(String id) async {
    final db = await DatabaseService.database;
    await db.delete('chats', where: 'id = ?', whereArgs: [id]);
  }
}
```

- [ ] **Step 4: Create message_dao.dart**

```dart
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';

class MessageDao {
  Future<List<Map<String, dynamic>>> getByChatId(String chatId) async {
    final db = await DatabaseService.database;
    return await db.query(
      'messages',
      where: 'chat_id = ?',
      whereArgs: [chatId],
      orderBy: 'created_at ASC',
    );
  }

  Future<Map<String, dynamic>?> getById(String id) async {
    final db = await DatabaseService.database;
    final results = await db.query('messages', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> getChildren(String parentId) async {
    final db = await DatabaseService.database;
    return await db.query(
      'messages',
      where: 'parent_id = ?',
      whereArgs: [parentId],
      orderBy: 'created_at ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getBranch(String chatId, String? leafId) async {
    final db = await DatabaseService.database;
    final messages = <Map<String, dynamic>>[];
    
    String? currentId = leafId;
    while (currentId != null) {
      final msg = await getById(currentId);
      if (msg == null) break;
      messages.insert(0, msg);
      currentId = msg['parent_id'] as String?;
    }
    
    // If no leaf specified, get the first/root branch
    if (leafId == null) {
      final roots = await db.query(
        'messages',
        where: 'chat_id = ? AND parent_id IS NULL',
        whereArgs: [chatId],
        orderBy: 'created_at ASC',
      );
      if (roots.isNotEmpty) {
        return await _buildBranch(chatId, roots.first['id'] as String);
      }
    }
    
    return messages;
  }

  Future<List<Map<String, dynamic>>> _buildBranch(String chatId, String rootId) async {
    final messages = <Map<String, dynamic>>[];
    String? currentId = rootId;
    
    while (currentId != null) {
      final msg = await getById(currentId);
      if (msg == null) break;
      messages.add(msg);
      
      final children = await getChildren(currentId);
      currentId = children.isNotEmpty ? children.first['id'] as String? : null;
    }
    
    return messages;
  }

  Future<void> insert(Map<String, dynamic> data) async {
    final db = await DatabaseService.database;
    await db.insert('messages', data);
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    final db = await DatabaseService.database;
    await db.update('messages', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(String id) async {
    final db = await DatabaseService.database;
    await db.delete('messages', where: 'id = ?', whereArgs: [id]);
  }
}
```

- [ ] **Step 5: Create world_book_dao.dart**

```dart
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';

class WorldBookDao {
  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await DatabaseService.database;
    return await db.query('world_books', orderBy: 'name ASC');
  }

  Future<Map<String, dynamic>?> getById(String id) async {
    final db = await DatabaseService.database;
    final results = await db.query('world_books', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> insert(Map<String, dynamic> data) async {
    final db = await DatabaseService.database;
    await db.insert('world_books', data);
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    final db = await DatabaseService.database;
    await db.update('world_books', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(String id) async {
    final db = await DatabaseService.database;
    await db.delete('world_books', where: 'id = ?', whereArgs: [id]);
  }

  // Entries
  Future<List<Map<String, dynamic>>> getEntries(String worldBookId) async {
    final db = await DatabaseService.database;
    return await db.query(
      'world_book_entries',
      where: 'world_book_id = ?',
      whereArgs: [worldBookId],
      orderBy: 'priority ASC',
    );
  }

  Future<void> insertEntry(Map<String, dynamic> data) async {
    final db = await DatabaseService.database;
    await db.insert('world_book_entries', data);
  }

  Future<void> updateEntry(String id, Map<String, dynamic> data) async {
    final db = await DatabaseService.database;
    await db.update('world_book_entries', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteEntry(String id) async {
    final db = await DatabaseService.database;
    await db.delete('world_book_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> matchEntries(String worldBookId, String text) async {
    final db = await DatabaseService.database;
    final entries = await db.query(
      'world_book_entries',
      where: 'world_book_id = ? AND enabled = 1',
      whereArgs: [worldBookId],
    );
    
    return entries.where((entry) {
      final keywords = (entry['keywords'] as String).split(',');
      return keywords.any((k) => text.toLowerCase().contains(k.trim().toLowerCase()));
    }).toList();
  }
}
```

- [ ] **Step 6: Commit**

```bash
git add lib/data/datasources/local/
git commit -m "feat: add SQLite database service and DAOs"
```

---

### Task 8: Data Layer — Models

**Files:**
- Create: `lib/data/models/character_model.dart`
- Create: `lib/data/models/chat_model.dart`
- Create: `lib/data/models/message_model.dart`
- Create: `lib/data/models/world_book_model.dart`
- Create: `lib/data/models/llm_config_model.dart`

- [ ] **Step 1: Create character_model.dart**

```dart
import 'dart:convert';
import '../../domain/entities/character.dart';

class CharacterModel {
  static Character fromMap(Map<String, dynamic> map) {
    return Character(
      id: map['id'] as String,
      name: map['name'] as String,
      avatarPath: map['avatar_path'] as String?,
      description: map['description'] as String,
      greeting: map['greeting'] as String,
      exampleMessages: map['example_messages'] as String?,
      systemPrompt: map['system_prompt'] as String?,
      tags: List<String>.from(jsonDecode(map['tags'] as String? ?? '[]')),
      worldBookId: map['world_book_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      lastChattedAt: map['last_chatted_at'] != null
          ? DateTime.parse(map['last_chatted_at'] as String)
          : null,
    );
  }

  static Map<String, dynamic> toMap(Character character) {
    return {
      'id': character.id,
      'name': character.name,
      'avatar_path': character.avatarPath,
      'description': character.description,
      'greeting': character.greeting,
      'example_messages': character.exampleMessages,
      'system_prompt': character.systemPrompt,
      'tags': jsonEncode(character.tags),
      'world_book_id': character.worldBookId,
      'created_at': character.createdAt.toIso8601String(),
      'updated_at': character.updatedAt.toIso8601String(),
      'last_chatted_at': character.lastChattedAt?.toIso8601String(),
    };
  }

  static String toJson(Character character) => jsonEncode(toMap(character));
  
  static Character fromJson(String json) => fromMap(jsonDecode(json));
}
```

- [ ] **Step 2: Create chat_model.dart**

```dart
import '../../domain/entities/chat.dart';

class ChatModel {
  static Chat fromMap(Map<String, dynamic> map) {
    return Chat(
      id: map['id'] as String,
      characterId: map['character_id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  static Map<String, dynamic> toMap(Chat chat) {
    return {
      'id': chat.id,
      'character_id': chat.characterId,
      'created_at': chat.createdAt.toIso8601String(),
      'updated_at': chat.updatedAt.toIso8601String(),
    };
  }
}
```

- [ ] **Step 3: Create message_model.dart**

```dart
import 'dart:convert';
import '../../domain/entities/message.dart';

class MessageModel {
  static Message fromMap(Map<String, dynamic> map) {
    List<MessageAttachment>? attachments;
    if (map['attachments'] != null) {
      final List<dynamic> list = jsonDecode(map['attachments'] as String);
      attachments = list.map((a) => MessageAttachment(
        path: a['path'] as String,
        mimeType: a['mime_type'] as String,
      )).toList();
    }

    return Message(
      id: map['id'] as String,
      chatId: map['chat_id'] as String,
      parentId: map['parent_id'] as String?,
      role: MessageRole.values.firstWhere((r) => r.name == map['role']),
      content: map['content'] as String,
      attachments: attachments,
      tokensUsed: map['tokens_used'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  static Map<String, dynamic> toMap(Message message) {
    return {
      'id': message.id,
      'chat_id': message.chatId,
      'parent_id': message.parentId,
      'role': message.role.name,
      'content': message.content,
      'attachments': message.attachments != null
          ? jsonEncode(message.attachments!.map((a) => {
              'path': a.path,
              'mime_type': a.mimeType,
            }).toList())
          : null,
      'tokens_used': message.tokensUsed,
      'created_at': message.createdAt.toIso8601String(),
    };
  }
}
```

- [ ] **Step 4: Create world_book_model.dart**

```dart
import 'dart:convert';
import '../../domain/entities/world_book.dart';

class WorldBookModel {
  static WorldBook fromMap(Map<String, dynamic> map) {
    return WorldBook(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  static Map<String, dynamic> toMap(WorldBook worldBook) {
    return {
      'id': worldBook.id,
      'name': worldBook.name,
      'description': worldBook.description,
      'created_at': worldBook.createdAt.toIso8601String(),
      'updated_at': worldBook.updatedAt.toIso8601String(),
    };
  }
}

class WorldBookEntryModel {
  static WorldBookEntry fromMap(Map<String, dynamic> map) {
    return WorldBookEntry(
      id: map['id'] as String,
      worldBookId: map['world_book_id'] as String,
      name: map['name'] as String,
      keywords: (map['keywords'] as String).split(',').map((k) => k.trim()).toList(),
      content: map['content'] as String,
      category: map['category'] as String? ?? 'general',
      priority: map['priority'] as int? ?? 0,
      enabled: (map['enabled'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  static Map<String, dynamic> toMap(WorldBookEntry entry) {
    return {
      'id': entry.id,
      'world_book_id': entry.worldBookId,
      'name': entry.name,
      'keywords': entry.keywords.join(','),
      'content': entry.content,
      'category': entry.category,
      'priority': entry.priority,
      'enabled': entry.enabled ? 1 : 0,
      'created_at': entry.createdAt.toIso8601String(),
      'updated_at': entry.updatedAt.toIso8601String(),
    };
  }
}
```

- [ ] **Step 5: Commit**

```bash
git add lib/data/models/
git commit -m "feat: add data models for database mapping"
```

---

### Task 9: LLM Integration — Provider Implementations

**Files:**
- Create: `lib/data/datasources/remote/llm_provider.dart`
- Create: `lib/data/datasources/remote/openai_provider.dart`
- Create: `lib/data/datasources/remote/anthropic_provider.dart`
- Create: `lib/data/datasources/remote/gemini_provider.dart`

- [ ] **Step 1: Create llm_provider.dart**

```dart
import '../../../domain/entities/message.dart';
import '../../../domain/entities/llm_config.dart';

class ChatResponse {
  final String content;
  final int? tokensUsed;
  
  const ChatResponse({required this.content, this.tokensUsed});
}

class ChatChunk {
  final String content;
  final bool isDone;
  
  const ChatChunk({required this.content, this.isDone = false});
}

abstract class LlmProvider {
  Future<ChatResponse> sendMessage({
    required List<Message> messages,
    required LlmConfig config,
    List<MessageAttachment>? attachments,
  });

  Stream<ChatChunk> streamMessage({
    required List<Message> messages,
    required LlmConfig config,
    List<MessageAttachment>? attachments,
  });
}
```

- [ ] **Step 2: Create openai_provider.dart**

```dart
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../domain/entities/message.dart';
import '../../../domain/entities/llm_config.dart';
import 'llm_provider.dart';

class OpenAiProvider implements LlmProvider {
  final Dio _dio;

  OpenAiProvider({Dio? dio}) : _dio = dio ?? Dio();

  @override
  Future<ChatResponse> sendMessage({
    required List<Message> messages,
    required LlmConfig config,
    List<MessageAttachment>? attachments,
  }) async {
    final response = await _dio.post(
      '${config.baseUrl ?? "https://api.openai.com"}/v1/chat/completions',
      options: Options(
        headers: {
          'Authorization': 'Bearer ${config.apiKey}',
          'Content-Type': 'application/json',
        },
      ),
      data: jsonEncode({
        'model': config.model,
        'messages': _formatMessages(messages, attachments),
        'temperature': config.temperature,
        'max_tokens': config.maxTokens,
      }),
    );

    final data = response.data;
    return ChatResponse(
      content: data['choices'][0]['message']['content'] as String,
      tokensUsed: data['usage']?['total_tokens'] as int?,
    );
  }

  @override
  Stream<ChatChunk> streamMessage({
    required List<Message> messages,
    required LlmConfig config,
    List<MessageAttachment>? attachments,
  }) async* {
    final response = await _dio.post(
      '${config.baseUrl ?? "https://api.openai.com"}/v1/chat/completions',
      options: Options(
        headers: {
          'Authorization': 'Bearer ${config.apiKey}',
          'Content-Type': 'application/json',
        },
        responseType: ResponseType.stream,
      ),
      data: jsonEncode({
        'model': config.model,
        'messages': _formatMessages(messages, attachments),
        'temperature': config.temperature,
        'max_tokens': config.maxTokens,
        'stream': true,
      }),
    );

    final stream = response.data.stream as Stream<List<int>>;
    String buffer = '';

    await for (final chunk in stream) {
      buffer += utf8.decode(chunk);
      final lines = buffer.split('\n');
      buffer = lines.removeLast();

      for (final line in lines) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6).trim();
          if (data == '[DONE]') {
            yield const ChatChunk(content: '', isDone: true);
            return;
          }
          try {
            final json = jsonDecode(data);
            final delta = json['choices'][0]['delta'];
            if (delta != null && delta['content'] != null) {
              yield ChatChunk(content: delta['content'] as String);
            }
          } catch (_) {}
        }
      }
    }
  }

  List<Map<String, dynamic>> _formatMessages(
    List<Message> messages,
    List<MessageAttachment>? attachments,
  ) {
    return messages.map((m) {
      final msg = <String, dynamic>{
        'role': m.role.name,
        'content': m.role == MessageRole.user && attachments != null && attachments.isNotEmpty
            ? [
                {'type': 'text', 'text': m.content},
                ...attachments.map((a) => {
                  'type': 'image_url',
                  'image_url': {'url': 'data:${a.mimeType};base64,${a.path}'},
                }),
              ]
            : m.content,
      };
      return msg;
    }).toList();
  }
}
```

- [ ] **Step 3: Create anthropic_provider.dart**

```dart
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../domain/entities/message.dart';
import '../../../domain/entities/llm_config.dart';
import 'llm_provider.dart';

class AnthropicProvider implements LlmProvider {
  final Dio _dio;

  AnthropicProvider({Dio? dio}) : _dio = dio ?? Dio();

  @override
  Future<ChatResponse> sendMessage({
    required List<Message> messages,
    required LlmConfig config,
    List<MessageAttachment>? attachments,
  }) async {
    final formatted = _formatMessages(messages, attachments);
    
    final response = await _dio.post(
      'https://api.anthropic.com/v1/messages',
      options: Options(
        headers: {
          'x-api-key': config.apiKey,
          'anthropic-version': '2023-06-01',
          'Content-Type': 'application/json',
        },
      ),
      data: jsonEncode({
        'model': config.model,
        'max_tokens': config.maxTokens,
        'system': formatted.systemPrompt,
        'messages': formatted.messages,
      }),
    );

    final data = response.data;
    return ChatResponse(
      content: data['content'][0]['text'] as String,
      tokensUsed: (data['usage']?['input_tokens'] as int? ?? 0) +
          (data['usage']?['output_tokens'] as int? ?? 0),
    );
  }

  @override
  Stream<ChatChunk> streamMessage({
    required List<Message> messages,
    required LlmConfig config,
    List<MessageAttachment>? attachments,
  }) async* {
    final formatted = _formatMessages(messages, attachments);
    
    final response = await _dio.post(
      'https://api.anthropic.com/v1/messages',
      options: Options(
        headers: {
          'x-api-key': config.apiKey,
          'anthropic-version': '2023-06-01',
          'Content-Type': 'application/json',
        },
        responseType: ResponseType.stream,
      ),
      data: jsonEncode({
        'model': config.model,
        'max_tokens': config.maxTokens,
        'system': formatted.systemPrompt,
        'messages': formatted.messages,
        'stream': true,
      }),
    );

    final stream = response.data.stream as Stream<List<int>>;
    String buffer = '';

    await for (final chunk in stream) {
      buffer += utf8.decode(chunk);
      final lines = buffer.split('\n');
      buffer = lines.removeLast();

      for (final line in lines) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6).trim();
          try {
            final json = jsonDecode(data);
            if (json['type'] == 'content_block_delta') {
              yield ChatChunk(content: json['delta']['text'] as String);
            } else if (json['type'] == 'message_stop') {
              yield const ChatChunk(content: '', isDone: true);
              return;
            }
          } catch (_) {}
        }
      }
    }
  }

  _FormattedMessages _formatMessages(
    List<Message> messages,
    List<MessageAttachment>? attachments,
  ) {
    String? systemPrompt;
    final List<Map<String, dynamic>> formattedMessages = [];

    for (final msg in messages) {
      if (msg.role == MessageRole.system) {
        systemPrompt = msg.content;
      } else {
        formattedMessages.add({
          'role': msg.role.name,
          'content': msg.role == MessageRole.user && attachments != null && attachments.isNotEmpty
              ? [
                  {'type': 'text', 'text': msg.content},
                  ...attachments.map((a) => {
                    'type': 'image',
                    'source': {
                      'type': 'base64',
                      'media_type': a.mimeType,
                      'data': a.path,
                    },
                  }),
                ]
              : msg.content,
        });
      }
    }

    return _FormattedMessages(
      systemPrompt: systemPrompt ?? '',
      messages: formattedMessages,
    );
  }
}

class _FormattedMessages {
  final String systemPrompt;
  final List<Map<String, dynamic>> messages;
  
  const _FormattedMessages({required this.systemPrompt, required this.messages});
}
```

- [ ] **Step 4: Create gemini_provider.dart**

```dart
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../domain/entities/message.dart';
import '../../../domain/entities/llm_config.dart';
import 'llm_provider.dart';

class GeminiProvider implements LlmProvider {
  final Dio _dio;

  GeminiProvider({Dio? dio}) : _dio = dio ?? Dio();

  @override
  Future<ChatResponse> sendMessage({
    required List<Message> messages,
    required LlmConfig config,
    List<MessageAttachment>? attachments,
  }) async {
    final response = await _dio.post(
      'https://generativelanguage.googleapis.com/v1beta/models/${config.model}:generateContent?key=${config.apiKey}',
      options: Options(headers: {'Content-Type': 'application/json'}),
      data: jsonEncode(_buildRequest(messages, config, attachments)),
    );

    final data = response.data;
    return ChatResponse(
      content: data['candidates'][0]['content']['parts'][0]['text'] as String,
      tokensUsed: data['usageMetadata']?['totalTokenCount'] as int?,
    );
  }

  @override
  Stream<ChatChunk> streamMessage({
    required List<Message> messages,
    required LlmConfig config,
    List<MessageAttachment>? attachments,
  }) async* {
    final response = await _dio.post(
      'https://generativelanguage.googleapis.com/v1beta/models/${config.model}:streamGenerateContent?key=${config.apiKey}',
      options: Options(
        headers: {'Content-Type': 'application/json'},
        responseType: ResponseType.stream,
      ),
      data: jsonEncode(_buildRequest(messages, config, attachments)),
    );

    final stream = response.data.stream as Stream<List<int>>;
    String buffer = '';

    await for (final chunk in stream) {
      buffer += utf8.decode(chunk);
      // Gemini streams JSON arrays
      if (buffer.contains('}')) {
        try {
          final json = jsonDecode(buffer);
          buffer = '';
          if (json is List && json.isNotEmpty) {
            final text = json.last['candidates']?[0]?['content']?['parts']?[0]?['text'];
            if (text != null) {
              yield ChatChunk(content: text as String);
            }
          }
        } catch (_) {}
      }
    }
    yield const ChatChunk(content: '', isDone: true);
  }

  Map<String, dynamic> _buildRequest(
    List<Message> messages,
    LlmConfig config,
    List<MessageAttachment>? attachments,
  ) {
    final contents = <Map<String, dynamic>>[];
    String? systemInstruction;

    for (final msg in messages) {
      if (msg.role == MessageRole.system) {
        systemInstruction = msg.content;
      } else {
        final parts = <Map<String, dynamic>>[{'text': msg.content}];
        
        if (attachments != null && attachments.isNotEmpty && msg.role == MessageRole.user) {
          for (final a in attachments) {
            parts.add({
              'inline_data': {
                'mime_type': a.mimeType,
                'data': a.path,
              },
            });
          }
        }

        contents.add({
          'role': msg.role == MessageRole.user ? 'user' : 'model',
          'parts': parts,
        });
      }
    }

    final request = <String, dynamic>{
      'contents': contents,
      'generationConfig': {
        'temperature': config.temperature,
        'maxOutputTokens': config.maxTokens,
      },
    };

    if (systemInstruction != null) {
      request['systemInstruction'] = {'parts': [{'text': systemInstruction}]};
    }

    return request;
  }
}
```

- [ ] **Step 5: Commit**

```bash
git add lib/data/datasources/remote/
git commit -m "feat: add LLM provider implementations (OpenAI, Anthropic, Gemini)"
```

---

### Task 10: Data Layer — Repository Implementations

**Files:**
- Create: `lib/data/repositories/character_repository_impl.dart`
- Create: `lib/data/repositories/chat_repository_impl.dart`
- Create: `lib/data/repositories/world_book_repository_impl.dart`
- Create: `lib/data/repositories/settings_repository_impl.dart`
- Create: `lib/data/repositories/llm_repository_impl.dart`

- [ ] **Step 1: Create character_repository_impl.dart**

```dart
import 'dart:convert';
import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/utils/id_generator.dart';
import '../../../domain/entities/character.dart';
import '../../../domain/repositories/character_repository.dart';
import '../../datasources/local/character_dao.dart';
import '../../models/character_model.dart';

class CharacterRepositoryImpl implements CharacterRepository {
  final CharacterDao _dao;

  CharacterRepositoryImpl(this._dao);

  @override
  Future<Either<Failure, List<Character>>> getAllCharacters() async {
    try {
      final maps = await _dao.getAll();
      return Right(maps.map(CharacterModel.fromMap).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Character>> getCharacter(String id) async {
    try {
      final map = await _dao.getById(id);
      if (map == null) return const Left(DatabaseFailure('Character not found'));
      return Right(CharacterModel.fromMap(map));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Character>> createCharacter(Character character) async {
    try {
      final now = DateTime.now();
      final newChar = Character(
        id: IdGenerator.generate(),
        name: character.name,
        avatarPath: character.avatarPath,
        description: character.description,
        greeting: character.greeting,
        exampleMessages: character.exampleMessages,
        systemPrompt: character.systemPrompt,
        tags: character.tags,
        worldBookId: character.worldBookId,
        createdAt: now,
        updatedAt: now,
      );
      await _dao.insert(CharacterModel.toMap(newChar));
      return Right(newChar);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Character>> updateCharacter(Character character) async {
    try {
      await _dao.update(character.id, CharacterModel.toMap(character));
      return Right(character);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCharacter(String id) async {
    try {
      await _dao.delete(id);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Character>>> searchCharacters(String query) async {
    try {
      final maps = await _dao.search(query);
      return Right(maps.map(CharacterModel.fromMap).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> importCharacter(String jsonContent) async {
    try {
      final map = jsonDecode(jsonContent) as Map<String, dynamic>;
      final character = CharacterModel.fromJson(jsonContent);
      await _dao.insert(CharacterModel.toMap(character));
      return const Right(null);
    } catch (e) {
      return Left(ValidationFailure('Invalid character JSON: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> exportCharacter(String id) async {
    try {
      final map = await _dao.getById(id);
      if (map == null) return const Left(DatabaseFailure('Character not found'));
      final character = CharacterModel.fromMap(map);
      return Right(CharacterModel.toJson(character));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
```

- [ ] **Step 2: Create remaining repository implementations (similar pattern)**

Implement `ChatRepositoryImpl`, `WorldBookRepositoryImpl`, `SettingsRepositoryImpl`, `LlmRepositoryImpl` following the same pattern: wrap DAO calls in try-catch, return Either<Failure, T>.

Key points:
- `LlmRepositoryImpl` delegates to the appropriate `LlmProvider` based on config
- `SettingsRepositoryImpl` uses SharedPreferences for simple values, SQLite for complex ones
- `ChatRepositoryImpl` handles tree-structure queries via `MessageDao.getBranch()`

- [ ] **Step 3: Commit**

```bash
git add lib/data/repositories/
git commit -m "feat: add repository implementations"
```

---

## Phase 3: Presentation Layer

### Task 11: Dependency Injection Setup

**Files:**
- Create: `lib/core/di/injection.dart`
- Create: `lib/core/di/modules.dart`

- [ ] **Step 1: Create injection.dart**

```dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit()
void configureDependencies() => getIt.init();
```

- [ ] **Step 2: Create modules.dart for manual bindings**

```dart
import 'package:injectable/injectable.dart';
import '../../data/datasources/local/character_dao.dart';
import '../../data/datasources/local/chat_dao.dart';
import '../../data/datasources/local/message_dao.dart';
import '../../data/datasources/local/world_book_dao.dart';
import '../../data/datasources/remote/openai_provider.dart';
import '../../data/datasources/remote/anthropic_provider.dart';
import '../../data/datasources/remote/gemini_provider.dart';

@module
abstract class AppModule {
  @singleton
  CharacterDao get characterDao => CharacterDao();
  
  @singleton
  ChatDao get chatDao => ChatDao();
  
  @singleton
  MessageDao get messageDao => MessageDao();
  
  @singleton
  WorldBookDao get worldBookDao => WorldBookDao();
  
  @singleton
  OpenAiProvider get openaiProvider => OpenAiProvider();
  
  @singleton
  AnthropicProvider get anthropicProvider => AnthropicProvider();
  
  @singleton
  GeminiProvider get geminiProvider => GeminiProvider();
}
```

- [ ] **Step 3: Run build_runner**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 4: Commit**

```bash
git add lib/core/di/
git commit -m "feat: add dependency injection setup with GetIt"
```

---

### Task 12: Presentation — Router & App Shell

**Files:**
- Create: `lib/presentation/router/app_router.dart`
- Create: `lib/presentation/common/widgets/app_shell.dart`
- Modify: `lib/app.dart`

- [ ] **Step 1: Create app_router.dart**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/home/home_page.dart';
import '../features/character/character_edit_page.dart';
import '../features/chat/chat_page.dart';
import '../features/worldbook/world_book_page.dart';
import '../features/settings/settings_page.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/character/new',
        builder: (context, state) => const CharacterEditPage(),
      ),
      GoRoute(
        path: '/character/:id',
        builder: (context, state) => CharacterEditPage(
          characterId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: '/chat/:characterId',
        builder: (context, state) => ChatPage(
          characterId: state.pathParameters['characterId']!,
          chatId: state.uri.queryParameters['chatId'],
        ),
      ),
      GoRoute(
        path: '/worldbook',
        builder: (context, state) => const WorldBookPage(),
      ),
      GoRoute(
        path: '/worldbook/:id',
        builder: (context, state) => WorldBookPage(
          worldBookId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
}
```

- [ ] **Step 2: Update app.dart with router and theme**

```dart
import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'core/theme/app_theme.dart';
import 'core/di/injection.dart';
import 'presentation/router/app_router.dart';

class PlaybookApp extends StatelessWidget {
  const PlaybookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp.router(
          title: 'Playbook',
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.system,
          routerConfig: AppRouter.router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
```

- [ ] **Step 3: Update main.dart**

```dart
import 'package:flutter/material.dart';
import 'core/di/injection.dart';
import 'app.dart';

void main() {
  configureDependencies();
  runApp(const PlaybookApp());
}
```

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/router/ lib/app.dart lib/main.dart
git commit -m "feat: add GoRouter navigation and app shell"
```

---

### Task 13: Presentation — Home Page (Character List)

**Files:**
- Create: `lib/presentation/features/home/home_page.dart`
- Create: `lib/presentation/features/home/bloc/home_bloc.dart`
- Create: `lib/presentation/features/home/widgets/character_card.dart`

- [ ] **Step 1: Create home_bloc.dart**

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../domain/entities/character.dart';
import '../../../../domain/repositories/character_repository.dart';

// Events
abstract class HomeEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoadCharacters extends HomeEvent {}
class SearchCharacters extends HomeEvent {
  final String query;
  SearchCharacters(this.query);
  @override
  List<Object> get props => [query];
}
class DeleteCharacter extends HomeEvent {
  final String id;
  DeleteCharacter(this.id);
  @override
  List<Object> get props => [id];
}

// States
abstract class HomeState extends Equatable {
  @override
  List<Object> get props => [];
}

class HomeInitial extends HomeState {}
class HomeLoading extends HomeState {}
class HomeLoaded extends HomeState {
  final List<Character> characters;
  HomeLoaded(this.characters);
  @override
  List<Object> get props => [characters];
}
class HomeError extends HomeState {
  final String message;
  HomeError(this.message);
  @override
  List<Object> get props => [message];
}

// BLoC
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final CharacterRepository _repository;

  HomeBloc(this._repository) : super(HomeInitial()) {
    on<LoadCharacters>(_onLoad);
    on<SearchCharacters>(_onSearch);
    on<DeleteCharacter>(_onDelete);
  }

  Future<void> _onLoad(LoadCharacters event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    final result = await _repository.getAllCharacters();
    result.fold(
      (failure) => emit(HomeError(failure.message)),
      (characters) => emit(HomeLoaded(characters)),
    );
  }

  Future<void> _onSearch(SearchCharacters event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    final result = await _repository.searchCharacters(event.query);
    result.fold(
      (failure) => emit(HomeError(failure.message)),
      (characters) => emit(HomeLoaded(characters)),
    );
  }

  Future<void> _onDelete(DeleteCharacter event, Emitter<HomeState> emit) async {
    await _repository.deleteCharacter(event.id);
    add(LoadCharacters());
  }
}
```

- [ ] **Step 2: Create character_card.dart**

```dart
import 'package:flutter/material.dart';
import '../../../../domain/entities/character.dart';

class CharacterCard extends StatelessWidget {
  final Character character;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const CharacterCard({
    super.key,
    required this.character,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: () => _showContextMenu(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                color: theme.colorScheme.primaryContainer,
                child: character.avatarPath != null
                    ? Image.network(character.avatarPath!, fit: BoxFit.cover)
                    : Center(
                        child: Text(
                          character.name[0].toUpperCase(),
                          style: theme.textTheme.displayMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      character.name,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      character.description,
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (character.lastChattedAt != null) ...[
                      const Spacer(),
                      Text(
                        _formatDate(character.lastChattedAt!),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                onTap();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Duplicate'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Export'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
```

- [ ] **Step 3: Create home_page.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/di/injection.dart';
import '../../domain/repositories/character_repository.dart';
import 'bloc/home_bloc.dart';
import 'widgets/character_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeBloc(getIt<CharacterRepository>())..add(LoadCharacters()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Playbook'),
        actions: [
          IconButton(
            icon: const Icon(Icons.book),
            tooltip: 'World Books',
            onPressed: () => context.push('/worldbook'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is HomeError) {
            return Center(child: Text(state.message));
          }
          if (state is HomeLoaded) {
            if (state.characters.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(height: 16),
                    Text('No characters yet', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Tap + to create one', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: state.characters.length,
              itemBuilder: (context, index) {
                final character = state.characters[index];
                return CharacterCard(
                  character: character,
                  onTap: () => context.push('/chat/${character.id}'),
                  onDelete: () {
                    context.read<HomeBloc>().add(DeleteCharacter(character.id));
                  },
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/character/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/features/home/
git commit -m "feat: add home page with character grid and BLoC"
```

---

### Task 14: Presentation — Character Edit Page

**Files:**
- Create: `lib/presentation/features/character/character_edit_page.dart`
- Create: `lib/presentation/features/character/bloc/character_edit_bloc.dart`

- [ ] **Step 1: Create character_edit_bloc.dart**

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../domain/entities/character.dart';
import '../../../../domain/repositories/character_repository.dart';

// Events
abstract class CharacterEditEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoadCharacterForEdit extends CharacterEditEvent {
  final String id;
  LoadCharacterForEdit(this.id);
}

class SaveCharacter extends CharacterEditEvent {
  final Character character;
  SaveCharacter(this.character);
}

class ImportCharacterJson extends CharacterEditEvent {
  final String json;
  ImportCharacterJson(this.json);
}

// States
abstract class CharacterEditState extends Equatable {
  @override
  List<Object> get props => [];
}

class CharacterEditInitial extends CharacterEditState {}
class CharacterEditLoading extends CharacterEditState {}
class CharacterEditLoaded extends CharacterEditState {
  final Character? character;
  CharacterEditLoaded(this.character);
}
class CharacterEditSaved extends CharacterEditState {}
class CharacterEditError extends CharacterEditState {
  final String message;
  CharacterEditError(this.message);
}

// BLoC
class CharacterEditBloc extends Bloc<CharacterEditEvent, CharacterEditState> {
  final CharacterRepository _repository;

  CharacterEditBloc(this._repository) : super(CharacterEditInitial()) {
    on<LoadCharacterForEdit>(_onLoad);
    on<SaveCharacter>(_onSave);
    on<ImportCharacterJson>(_onImport);
  }

  Future<void> _onLoad(LoadCharacterForEdit event, Emitter<CharacterEditState> emit) async {
    emit(CharacterEditLoading());
    final result = await _repository.getCharacter(event.id);
    result.fold(
      (failure) => emit(CharacterEditError(failure.message)),
      (character) => emit(CharacterEditLoaded(character)),
    );
  }

  Future<void> _onSave(SaveCharacter event, Emitter<CharacterEditState> emit) async {
    emit(CharacterEditLoading());
    final result = event.character.id.isEmpty
        ? await _repository.createCharacter(event.character)
        : await _repository.updateCharacter(event.character);
    result.fold(
      (failure) => emit(CharacterEditError(failure.message)),
      (_) => emit(CharacterEditSaved()),
    );
  }

  Future<void> _onImport(ImportCharacterJson event, Emitter<CharacterEditState> emit) async {
    emit(CharacterEditLoading());
    final result = await _repository.importCharacter(event.json);
    result.fold(
      (failure) => emit(CharacterEditError(failure.message)),
      (_) => emit(CharacterEditSaved()),
    );
  }
}
```

- [ ] **Step 2: Create character_edit_page.dart (form with all fields)**

Key elements:
- Text fields for: name, description, greeting, example_messages, system_prompt
- Tag input widget
- Avatar picker (image_picker)
- World book dropdown selector
- Import/Export JSON buttons
- Save/Cancel buttons

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/features/character/
git commit -m "feat: add character edit page with form and BLoC"
```

---

### Task 15: Presentation — Chat Page

**Files:**
- Create: `lib/presentation/features/chat/chat_page.dart`
- Create: `lib/presentation/features/chat/bloc/chat_bloc.dart`
- Create: `lib/presentation/features/chat/widgets/chat_bubble.dart`
- Create: `lib/presentation/features/chat/widgets/chat_input.dart`
- Create: `lib/presentation/features/chat/widgets/chat_drawer.dart`

- [ ] **Step 1: Create chat_bloc.dart**

Events: LoadChat, SendMessage, RegenerateMessage, SwitchBranch, SummarizeChat
States: ChatLoading, ChatLoaded (messages, branches, currentLeaf), ChatSending, ChatError

Key logic:
- Load messages for current branch
- Send message → call SendMessage use case → append to messages
- Regenerate → create new branch from current point
- Switch branch → load different branch path
- Auto-summarize when message count exceeds threshold

- [ ] **Step 2: Create chat_bubble.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../domain/entities/message.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final String characterName;
  final String? characterAvatar;
  final int branchCount;
  final VoidCallback? onBranchSwitch;

  const ChatBubble({
    super.key,
    required this.message,
    required this.characterName,
    this.characterAvatar,
    this.branchCount = 1,
    this.onBranchSwitch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == MessageRole.user;
    final isSystem = message.role == MessageRole.system;

    if (isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.content,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: characterAvatar != null
                  ? ClipOval(child: Image.network(characterAvatar!, width: 32, height: 32, fit: BoxFit.cover))
                  : Text(characterName[0], style: theme.textTheme.labelMedium),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                  ),
                  child: MarkdownBody(
                    data: message.content,
                    styleSheet: MarkdownStyleSheet(
                      p: theme.textTheme.bodyMedium?.copyWith(
                        color: isUser
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                if (branchCount > 1 && onBranchSwitch != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: GestureDetector(
                      onTap: onBranchSwitch,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.swap_horiz, size: 14, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            'Branch 1/$branchCount',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.tertiaryContainer,
              child: Icon(Icons.person, size: 18, color: theme.colorScheme.onTertiaryContainer),
            ),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Create chat_input.dart**

Input box with:
- Multi-line text field
- Attachment button (image picker)
- Send button (disabled when empty)
- Streaming indicator when waiting for response

- [ ] **Step 4: Create chat_drawer.dart**

Right-side drawer with:
- Temperature slider (0.0 - 2.0)
- Max tokens input
- System prompt override text area
- Context window usage bar
- Model selector dropdown

- [ ] **Step 5: Create chat_page.dart**

Main chat page combining all widgets:
- AppBar with character name + settings/drawer toggle
- Scrollable message list with ChatBubbles
- Bottom ChatInput
- Right drawer for ChatDrawer
- Tree navigation (swipe gestures or branch indicator buttons)

- [ ] **Step 6: Commit**

```bash
git add lib/presentation/features/chat/
git commit -m "feat: add chat page with bubbles, input, drawer, and tree navigation"
```

---

### Task 16: Presentation — World Book Page

**Files:**
- Create: `lib/presentation/features/worldbook/world_book_page.dart`
- Create: `lib/presentation/features/worldbook/bloc/world_book_bloc.dart`
- Create: `lib/presentation/features/worldbook/widgets/entry_card.dart`

- [ ] **Step 1: Create world_book_bloc.dart**

Events: LoadWorldBooks, CreateWorldBook, DeleteWorldBook, LoadEntries, CreateEntry, UpdateEntry, DeleteEntry
States: WorldBookLoading, WorldBookLoaded, EntriesLoaded, WorldBookError

- [ ] **Step 2: Create entry_card.dart**

Card showing entry name, keywords (as chips), category badge, priority, enabled toggle

- [ ] **Step 3: Create world_book_page.dart**

Two-panel layout:
- Left: list of world books (sidebar on web/desktop, full screen on mobile)
- Right: entries for selected world book
- FAB to add new entry
- Each entry expandable to edit content

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/features/worldbook/
git commit -m "feat: add world book management page"
```

---

### Task 17: Presentation — Settings Page

**Files:**
- Create: `lib/presentation/features/settings/settings_page.dart`
- Create: `lib/presentation/features/settings/bloc/settings_bloc.dart`
- Create: `lib/presentation/features/settings/widgets/api_config_section.dart`
- Create: `lib/presentation/features/settings/widgets/theme_section.dart`
- Create: `lib/presentation/features/settings/widgets/data_section.dart`

- [ ] **Step 1: Create settings_bloc.dart**

Events: LoadSettings, UpdateApiKey, UpdateTheme, ExportData, ImportData, ClearData
States: SettingsLoading, SettingsLoaded, SettingsError

- [ ] **Step 2: Create api_config_section.dart**

Three expandable sections (OpenAI, Anthropic, Gemini) each with:
- API Key field (obscured)
- Base URL field (OpenAI only)
- Model dropdown

- [ ] **Step 3: Create theme_section.dart**

- Radio buttons: Light / Dark / System / Custom
- Color picker for custom theme (simple HSV picker)
- Font size slider

- [ ] **Step 4: Create data_section.dart**

- Export button (triggers JSON download/share)
- Import button (file picker)
- Clear All button (with confirmation dialog)

- [ ] **Step 5: Create settings_page.dart**

ListView with sections:
- API Configuration
- Appearance
- Profile (username input)
- Data Management
- About

- [ ] **Step 6: Commit**

```bash
git add lib/presentation/features/settings/
git commit -m "feat: add settings page with API config, theme, and data management"
```

---

## Phase 4: Polish & Testing

### Task 18: Responsive Layout & Platform Adaptations

**Files:**
- Create: `lib/presentation/common/widgets/responsive_layout.dart`
- Modify: various pages for responsive behavior

- [ ] **Step 1: Create responsive_layout.dart**

```dart
import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) return mobile;
        if (constraints.maxWidth < 1200) return tablet ?? desktop;
        return desktop;
      },
    );
  }
}
```

- [ ] **Step 2: Add responsive behavior to HomePage**

Desktop: 4-column grid + sidebar for search/filter
Mobile: 2-column grid + bottom search bar

- [ ] **Step 3: Add responsive behavior to ChatPage**

Desktop: Chat + drawer side-by-side
Mobile: Chat full screen, drawer as modal bottom sheet

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/common/
git commit -m "feat: add responsive layout for web/desktop/mobile"
```

---

### Task 19: Data Export/Import

**Files:**
- Create: `lib/data/datasources/local/export_service.dart`

- [ ] **Step 1: Create export_service.dart**

Export all data as single JSON:
```json
{
  "version": 1,
  "characters": [...],
  "chats": [...],
  "messages": [...],
  "world_books": [...],
  "world_book_entries": [...],
  "settings": {...}
}
```

Import: validate JSON structure, merge or replace data

- [ ] **Step 2: Commit**

```bash
git add lib/data/datasources/local/export_service.dart
git commit -m "feat: add data export/import service"
```

---

### Task 20: Error Handling & Offline Support

**Files:**
- Create: `lib/presentation/common/widgets/error_dialog.dart`
- Create: `lib/presentation/common/widgets/offline_banner.dart`

- [ ] **Step 1: Create error_dialog.dart**

Reusable error dialog with:
- Error message
- "Go to Settings" button (for API key issues)
- "Retry" button (for transient errors)
- "Copy Error" button

- [ ] **Step 2: Create offline_banner.dart**

MaterialBanner shown when no network:
- Yellow warning bar
- "Messages will be sent when online" text
- Auto-hide when back online

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/common/widgets/
git commit -m "feat: add error handling and offline support UI"
```

---

### Task 21: Splash Screen & App Icon

**Files:**
- Create: `lib/presentation/features/splash/splash_page.dart`

- [ ] **Step 1: Create splash_page.dart**

Animated splash with:
- App logo (generated via flutter_launcher_icons)
- Loading indicator
- Auto-navigate to home after 1.5s or when DB ready

- [ ] **Step 2: Configure flutter_launcher_icons**

```yaml
flutter_launcher_icons:
  android: true
  ios: false
  web: true
  windows: true
  image_path: "assets/icon/app_icon.png"
```

- [ ] **Step 3: Generate icons**

```bash
dart run flutter_launcher_icons
```

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/features/splash/ pubspec.yaml
git commit -m "feat: add splash screen and app icon"
```

---

## Final Task: Build & Verify

- [ ] **Step 1: Run build_runner**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 2: Run flutter analyze**

```bash
flutter analyze
```

- [ ] **Step 3: Run tests**

```bash
flutter test
```

- [ ] **Step 4: Build for all platforms**

```bash
flutter build web
flutter build windows
flutter build apk
```

- [ ] **Step 5: Commit**

```bash
git add .
git commit -m "chore: final build verification"
```
