import 'package:dartz/dartz.dart';
import 'package:collection/collection.dart';
import '../../core/error/failures.dart';
import '../../core/utils/token_estimator.dart';
import '../entities/character.dart';
import '../entities/message.dart';
import '../entities/llm_config.dart';
import '../entities/story_state.dart';
import '../repositories/world_book_repository.dart';
import '../repositories/story_state_repository.dart';

class BuildPrompt {
  final WorldBookRepository worldBookRepository;
  final StoryStateRepository storyStateRepository;

  BuildPrompt({
    required this.worldBookRepository,
    required this.storyStateRepository,
  });

  Future<Either<Failure, List<Message>>> call({
    required String chatId,
    required Character activeCharacter,
    required List<Character> allCharacters,
    required List<String> worldBookIds,
    required List<Message> messages,
    required LlmConfig config,
    String? username,
    String? userDescription,
    String? summary,
    List<Character> allAvailableCharacters = const [],
  }) async {
    final promptMessages = <Message>[];
    int tokenBudget = config.contextWindow - config.maxTokens;

    // 1. System prompt
    final systemPrompt = _buildSystemPrompt(activeCharacter, allCharacters, username, userDescription);
    promptMessages.add(Message(
      id: 'system',
      chatId: '',
      role: MessageRole.system,
      content: systemPrompt,
      createdAt: DateTime.now(),
    ));
    tokenBudget -= TokenEstimator.estimate(systemPrompt);

    // 2. World book entries (if linked)
    if (worldBookIds.isNotEmpty) {
      final allMatchedEntries = <dynamic>[];
      final recentText = messages.reversed.take(5).map((m) => m.content).join(' ');
      for (final wbId in worldBookIds) {
        final entriesResult = await worldBookRepository.matchEntries(
          wbId,
          recentText,
        );
        entriesResult.fold(
          (failure) => null,
          (entries) => allMatchedEntries.addAll(entries),
        );
      }

      if (allMatchedEntries.isNotEmpty) {
        final uniqueEntries = <String, dynamic>{};
        for (final entry in allMatchedEntries) {
          final existing = uniqueEntries[entry.id];
          if (existing == null || entry.priority > existing.priority) {
            uniqueEntries[entry.id] = entry;
          }
        }
        final sortedEntries = uniqueEntries.values.toList()
          ..sort((a, b) => b.priority.compareTo(a.priority));

        final limitedEntries = sortedEntries.take(5).toList();

        final worldContext = limitedEntries.map((e) => e.content).join('\n\n');
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
    }

    // 2.5 Dynamic Story States
    final storyStatesResult = await storyStateRepository.getActiveStoryStates(chatId);
    final activeStates = storyStatesResult.fold((_) => <StoryState>[], (list) => list);
    if (activeStates.isNotEmpty) {
      final characterStates = activeStates.where((s) => s.category == StoryStateCategory.character);
      final locationStates = activeStates.where((s) => s.category == StoryStateCategory.location);
      final eventStates = activeStates.where((s) => s.category == StoryStateCategory.event);
      final relationshipStates = activeStates.where((s) => s.category == StoryStateCategory.relationship);
      final tabooStates = activeStates.where((s) => s.category == StoryStateCategory.taboo);
      final styleStates = activeStates.where((s) => s.category == StoryStateCategory.style);

      final stateBuffer = StringBuffer();
      stateBuffer.writeln('## Current Story & World States');

      if (characterStates.isNotEmpty) {
        stateBuffer.writeln('\n### Character States');
        for (final s in characterStates) {
          stateBuffer.writeln('- ${s.content}');
        }
      }
      if (locationStates.isNotEmpty) {
        stateBuffer.writeln('\n### Location States');
        for (final s in locationStates) {
          stateBuffer.writeln('- ${s.content}');
        }
      }
      if (relationshipStates.isNotEmpty) {
        stateBuffer.writeln('\n### Character Relationships');
        for (final s in relationshipStates) {
          stateBuffer.writeln('- ${s.content}');
        }
      }
      if (eventStates.isNotEmpty) {
        stateBuffer.writeln('\n### Event States & Foreshadowing');
        for (final s in eventStates) {
          stateBuffer.writeln('- ${s.content}');
        }
      }
      if (tabooStates.isNotEmpty) {
        stateBuffer.writeln('\n### Taboos (Never do these)');
        for (final s in tabooStates) {
          stateBuffer.writeln('- ${s.content}');
        }
      }
      if (styleStates.isNotEmpty) {
        stateBuffer.writeln('\n### Style Constraints');
        for (final s in styleStates) {
          stateBuffer.writeln('- ${s.content}');
        }
      }

      final statesContext = stateBuffer.toString();
      tokenBudget -= TokenEstimator.estimate(statesContext);
      if (tokenBudget > 0) {
        promptMessages.add(Message(
          id: 'story_states_context',
          chatId: '',
          role: MessageRole.system,
          content: statesContext,
          createdAt: DateTime.now(),
        ));
      }
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
    final userName = username ?? 'User';
    for (final msg in recentMessages) {
      final msgTokens = TokenEstimator.estimate(msg.content);
      if (tokenBudget - msgTokens < 0) break;
      tokenBudget -= msgTokens;

      // Format with speaker prefix so the LLM knows who is speaking
      String prefix = '';
      if (msg.senderId == 'dm') {
        prefix = '[DM]';
      } else if (msg.senderId != null) {
        final char = allCharacters.firstWhereOrNull((c) => c.id == msg.senderId) ??
            allAvailableCharacters.firstWhereOrNull((c) => c.id == msg.senderId);
        if (char != null) {
          prefix = '[${char.name}]';
        } else {
          prefix = '[Character]';
        }
      } else {
        prefix = '[$userName]';
      }

      final formattedContent = msg.content.trim().startsWith('[') ? msg.content : '$prefix: ${msg.content}';
      promptMessages.add(msg.copyWith(content: formattedContent));
    }

    return Right(promptMessages);
  }

  String _buildSystemPrompt(
    Character activeCharacter,
    List<Character> allCharacters,
    String? username,
    String? userDescription,
  ) {
    final userName = username ?? 'User';
    final userDesc = userDescription ?? '';
    final customPrompt = activeCharacter.systemPrompt ?? '';
    
    final otherChars = allCharacters.where((c) => c.id != activeCharacter.id);
    final otherCharsPrompt = otherChars.isNotEmpty
        ? '\n## Other Characters in this Group Chat\n${otherChars.map((c) => '- Name: ${c.name}\n  Description: ${c.description}').join('\n')}'
        : '';
    
    return '''You are a group chat roleplay orchestrator and narrator (DM).
Stay in character at all times. You can write narrations or describe scenes as [DM], and speak/act as any of the characters in the group chat:
- Name: ${activeCharacter.name} (Primary character)
  Description: ${activeCharacter.description}
$otherCharsPrompt

$customPrompt

## Critical Multi-Character / DM Rules
1. When generating a response, you can output dialogue/actions for characters, or scene narration as [DM].
2. Every block of content you output MUST start with a speaker label in brackets at the beginning of a line:
   - Use `[DM]: narration` for environment/scene description or action outcome.
   - Use `[Character Name]: content` for character dialogue and actions (e.g. `[${activeCharacter.name}]: ...`).
   Example:
   [DM]: Carter nods slowly.
   [${activeCharacter.name}]: "Who goes there?"
3. Not all characters must speak in every turn. Only generate output for characters who have something meaningful to say or react to in this context. If no character needs to speak, just use [DM] to describe the scene.
4. The user is named $userName. The user can also roleplay/speak as characters or as [DM]. Pay attention to who is speaking based on their `[Name]:` prefix in the history.
5. Do not include any meta-commentary, explanations, or quotes around the whole block. Only output the speaker-prefixed lines. Keep the tone engaging and atmospheric.

The user's description/role is: $userDesc''';
  }
}
