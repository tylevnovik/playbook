import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:playbook/domain/usecases/build_prompt.dart';
import 'package:playbook/domain/repositories/world_book_repository.dart';
import 'package:playbook/domain/repositories/story_state_repository.dart';
import 'package:playbook/domain/entities/character.dart';
import 'package:playbook/domain/entities/message.dart';
import 'package:playbook/domain/entities/llm_config.dart';
import 'package:playbook/domain/entities/story_state.dart';
import 'package:playbook/domain/entities/world_book.dart';

class MockWorldBookRepository extends Mock implements WorldBookRepository {}
class MockStoryStateRepository extends Mock implements StoryStateRepository {}

void main() {
  late BuildPrompt buildPrompt;
  late MockWorldBookRepository mockWorldBookRepository;
  late MockStoryStateRepository mockStoryStateRepository;

  setUp(() {
    mockWorldBookRepository = MockWorldBookRepository();
    mockStoryStateRepository = MockStoryStateRepository();
    buildPrompt = BuildPrompt(
      worldBookRepository: mockWorldBookRepository,
      storyStateRepository: mockStoryStateRepository,
    );
  });

  test('buildPrompt includes system prompt, matched world book entries, active story states, and recent messages', () async {
    final activeCharacter = Character(
      id: 'char1',
      name: 'Test Character',
      avatarPath: '',
      description: 'A helpful test character.',
      greeting: 'Hello!',
      tags: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final config = LlmConfig(
      providerType: LlmProviderType.openai,
      apiKey: 'api-key',
      baseUrl: 'base-url',
      model: 'model',
      contextWindow: 4000,
      maxTokens: 1000,
      temperature: 0.7,
    );

    final worldBookEntry = WorldBookEntry(
      id: 'entry1',
      worldBookId: 'wb1',
      name: 'Magic Magic',
      keywords: const ['magic'],
      content: 'Magic is real in this world.',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final storyState = StoryState(
      id: 'state1',
      chatId: 'chat1',
      category: StoryStateCategory.taboo,
      content: 'Never mention purple elephants.',
      isActive: true,
      updatedAt: DateTime.now(),
    );

    final message = Message(
      id: 'msg1',
      chatId: 'chat1',
      role: MessageRole.user,
      content: 'Is there magic in this world?',
      createdAt: DateTime.now(),
    );

    when(() => mockWorldBookRepository.matchEntries('wb1', any()))
        .thenAnswer((_) async => Right([worldBookEntry]));

    when(() => mockStoryStateRepository.getActiveStoryStates('chat1'))
        .thenAnswer((_) async => Right([storyState]));

    final result = await buildPrompt(
      chatId: 'chat1',
      activeCharacter: activeCharacter,
      allCharacters: [activeCharacter],
      worldBookIds: const ['wb1'],
      messages: [message],
      config: config,
    );

    expect(result.isRight(), isTrue);
    result.fold(
      (failure) => fail('Should not return failure'),
      (promptMessages) {
        expect(promptMessages.length, 4); // system + world_context + story_states_context + msg1
        
        final systemMsg = promptMessages.firstWhere((m) => m.id == 'system');
        expect(systemMsg.content, contains('Test Character'));
        expect(systemMsg.content, contains('A helpful test character.'));

        final worldCtxMsg = promptMessages.firstWhere((m) => m.id == 'world_context');
        expect(worldCtxMsg.content, contains('Magic is real'));

        final storyStatesMsg = promptMessages.firstWhere((m) => m.id == 'story_states_context');
        expect(storyStatesMsg.content, contains('Never mention purple elephants'));

        final userMsg = promptMessages.firstWhere((m) => m.id == 'msg1');
        expect(userMsg.content, contains('Is there magic'));
      },
    );
  });

  test('buildPrompt includes player configuration in system prompt when username and userDescription are provided', () async {
    final activeCharacter = Character(
      id: 'char1',
      name: 'Test Character',
      avatarPath: '',
      description: 'A helpful test character.',
      greeting: 'Hello!',
      tags: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final config = LlmConfig(
      providerType: LlmProviderType.openai,
      apiKey: 'api-key',
      baseUrl: 'base-url',
      model: 'model',
      contextWindow: 4000,
      maxTokens: 1000,
      temperature: 0.7,
    );

    when(() => mockWorldBookRepository.matchEntries(any(), any()))
        .thenAnswer((_) async => const Right([]));

    when(() => mockStoryStateRepository.getActiveStoryStates(any()))
        .thenAnswer((_) async => const Right([]));

    final result = await buildPrompt(
      chatId: 'chat1',
      activeCharacter: activeCharacter,
      allCharacters: [activeCharacter],
      worldBookIds: const [],
      messages: [],
      config: config,
      username: 'Alice',
      userDescription: 'A brave adventurer looking for gold.',
    );

    expect(result.isRight(), isTrue);
    result.fold(
      (failure) => fail('Should not return failure'),
      (promptMessages) {
        final systemMsg = promptMessages.firstWhere((m) => m.id == 'system');
        expect(systemMsg.content, contains("The user is named Alice"));
        expect(systemMsg.content, contains("The user's description/role is: A brave adventurer looking for gold."));
      },
    );
  });
}
