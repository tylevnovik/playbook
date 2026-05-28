// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:playbook/core/di/modules.dart' as _i878;
import 'package:playbook/data/datasources/local/character_dao.dart' as _i673;
import 'package:playbook/data/datasources/local/chat_dao.dart' as _i119;
import 'package:playbook/data/datasources/local/export_service.dart' as _i952;
import 'package:playbook/data/datasources/local/message_dao.dart' as _i420;
import 'package:playbook/data/datasources/local/story_state_dao.dart' as _i102;
import 'package:playbook/data/datasources/local/world_book_dao.dart' as _i652;
import 'package:playbook/data/datasources/remote/anthropic_provider.dart'
    as _i380;
import 'package:playbook/data/datasources/remote/gemini_provider.dart' as _i15;
import 'package:playbook/data/datasources/remote/openai_provider.dart' as _i650;
import 'package:playbook/domain/repositories/character_repository.dart'
    as _i142;
import 'package:playbook/domain/repositories/chat_repository.dart' as _i972;
import 'package:playbook/domain/repositories/llm_repository.dart' as _i952;
import 'package:playbook/domain/repositories/settings_repository.dart' as _i706;
import 'package:playbook/domain/repositories/story_state_repository.dart'
    as _i75;
import 'package:playbook/domain/repositories/world_book_repository.dart'
    as _i376;
import 'package:playbook/domain/usecases/build_prompt.dart' as _i443;
import 'package:playbook/domain/usecases/load_character.dart' as _i255;
import 'package:playbook/domain/usecases/manage_chat.dart' as _i584;
import 'package:playbook/domain/usecases/send_message.dart' as _i759;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final appModule = _$AppModule();
    gh.singleton<_i673.CharacterDao>(() => appModule.characterDao);
    gh.singleton<_i119.ChatDao>(() => appModule.chatDao);
    gh.singleton<_i420.MessageDao>(() => appModule.messageDao);
    gh.singleton<_i652.WorldBookDao>(() => appModule.worldBookDao);
    gh.singleton<_i102.StoryStateDao>(() => appModule.storyStateDao);
    gh.singleton<_i650.OpenAiProvider>(() => appModule.openaiProvider);
    gh.singleton<_i380.AnthropicProvider>(() => appModule.anthropicProvider);
    gh.singleton<_i15.GeminiProvider>(() => appModule.geminiProvider);
    await gh.singletonAsync<_i460.SharedPreferences>(
      () => appModule.sharedPreferences,
      preResolve: true,
    );
    gh.lazySingleton<_i952.ExportService>(() => _i952.ExportService());
    gh.singleton<_i972.ChatRepository>(
      () =>
          appModule.chatRepository(gh<_i119.ChatDao>(), gh<_i420.MessageDao>()),
    );
    gh.factory<_i584.ManageChat>(
      () => appModule.manageChat(gh<_i972.ChatRepository>()),
    );
    gh.singleton<_i376.WorldBookRepository>(
      () => appModule.worldBookRepository(gh<_i652.WorldBookDao>()),
    );
    gh.singleton<_i952.LlmRepository>(
      () => appModule.llmRepository(
        gh<_i650.OpenAiProvider>(),
        gh<_i380.AnthropicProvider>(),
        gh<_i15.GeminiProvider>(),
      ),
    );
    gh.singleton<_i142.CharacterRepository>(
      () => appModule.characterRepository(gh<_i673.CharacterDao>()),
    );
    gh.singleton<_i706.SettingsRepository>(
      () => appModule.settingsRepository(gh<_i460.SharedPreferences>()),
    );
    gh.singleton<_i75.StoryStateRepository>(
      () => appModule.storyStateRepository(gh<_i102.StoryStateDao>()),
    );
    gh.factory<_i255.LoadCharacter>(
      () => appModule.loadCharacter(
        gh<_i142.CharacterRepository>(),
        gh<_i972.ChatRepository>(),
      ),
    );
    gh.factory<_i443.BuildPrompt>(
      () => appModule.buildPrompt(
        gh<_i376.WorldBookRepository>(),
        gh<_i75.StoryStateRepository>(),
      ),
    );
    gh.factory<_i759.SendMessage>(
      () => appModule.sendMessage(
        gh<_i952.LlmRepository>(),
        gh<_i972.ChatRepository>(),
        gh<_i706.SettingsRepository>(),
        gh<_i142.CharacterRepository>(),
        gh<_i443.BuildPrompt>(),
      ),
    );
    return this;
  }
}

class _$AppModule extends _i878.AppModule {}
