import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/utils/token_estimator.dart';
import '../entities/character.dart';
import '../entities/message.dart';
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
