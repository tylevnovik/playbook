import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/local/character_dao.dart';
import '../../data/datasources/local/chat_dao.dart';
import '../../data/datasources/local/message_dao.dart';
import '../../data/datasources/local/world_book_dao.dart';
import '../../data/datasources/local/story_state_dao.dart';
import '../../data/datasources/remote/openai_provider.dart';
import '../../data/datasources/remote/anthropic_provider.dart';
import '../../data/datasources/remote/gemini_provider.dart';
import '../../domain/repositories/character_repository.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/world_book_repository.dart';
import '../../domain/repositories/story_state_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/llm_repository.dart';
import '../../data/repositories/character_repository_impl.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../data/repositories/world_book_repository_impl.dart';
import '../../data/repositories/story_state_repository_impl.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../data/repositories/llm_repository_impl.dart';
import '../../domain/usecases/send_message.dart';
import '../../domain/usecases/load_character.dart';
import '../../domain/usecases/manage_chat.dart';
import '../../domain/usecases/build_prompt.dart';

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
  StoryStateDao get storyStateDao => StoryStateDao();
  
  @singleton
  OpenAiProvider get openaiProvider => OpenAiProvider();
  
  @singleton
  AnthropicProvider get anthropicProvider => AnthropicProvider();
  
  @singleton
  GeminiProvider get geminiProvider => GeminiProvider();

  @preResolve
  @singleton
  Future<SharedPreferences> get sharedPreferences => SharedPreferences.getInstance();

  // Repositories
  @singleton
  CharacterRepository characterRepository(CharacterDao dao) => CharacterRepositoryImpl(dao);

  @singleton
  ChatRepository chatRepository(ChatDao chatDao, MessageDao messageDao) => ChatRepositoryImpl(chatDao, messageDao);

  @singleton
  WorldBookRepository worldBookRepository(WorldBookDao dao) => WorldBookRepositoryImpl(dao);

  @singleton
  StoryStateRepository storyStateRepository(StoryStateDao dao) => StoryStateRepositoryImpl(dao);

  @singleton
  SettingsRepository settingsRepository(SharedPreferences prefs) => SettingsRepositoryImpl(prefs);

  @singleton
  LlmRepository llmRepository(OpenAiProvider op, AnthropicProvider ap, GeminiProvider gp) => LlmRepositoryImpl(op, ap, gp);

  // Use cases
  @injectable
  SendMessage sendMessage(LlmRepository lr, ChatRepository cr, SettingsRepository sr, CharacterRepository chr, BuildPrompt bp) => SendMessage(llmRepository: lr, chatRepository: cr, settingsRepository: sr, characterRepository: chr, buildPrompt: bp);

  @injectable
  LoadCharacter loadCharacter(CharacterRepository cr, ChatRepository chr) => LoadCharacter(characterRepository: cr, chatRepository: chr);

  @injectable
  ManageChat manageChat(ChatRepository cr) => ManageChat(repository: cr);

  @injectable
  BuildPrompt buildPrompt(WorldBookRepository wbr, StoryStateRepository ssr) =>
      BuildPrompt(worldBookRepository: wbr, storyStateRepository: ssr);
}
