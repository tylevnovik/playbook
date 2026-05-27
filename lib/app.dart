import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'core/localization/app_localizations.dart';
import 'core/constants/app_constants.dart';
import 'domain/repositories/character_repository.dart';
import 'domain/repositories/settings_repository.dart';
import 'presentation/features/home/bloc/home_bloc.dart';
import 'presentation/features/settings/bloc/settings_bloc.dart';
import 'presentation/router/app_router.dart';

class PlaybookApp extends StatelessWidget {
  const PlaybookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              HomeBloc(getIt<CharacterRepository>())..add(LoadCharacters()),
        ),
        BlocProvider(
          create: (_) =>
              SettingsBloc(getIt<SettingsRepository>())..add(LoadSettings()),
        ),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          Locale locale = const Locale('zh', 'CN'); // Default to Chinese
          var themeMode = ThemeMode.system;
          if (settingsState is SettingsLoaded) {
            final langCode = settingsState.values[AppConstants.keyLanguage];
            if (langCode != null && langCode.isNotEmpty) {
              if (langCode == 'en') {
                locale = const Locale('en', 'US');
              } else {
                locale = const Locale('zh', 'CN');
              }
            }

            themeMode =
                switch (settingsState.values[AppConstants.keyThemeMode]) {
                  'light' => ThemeMode.light,
                  'dark' => ThemeMode.dark,
                  _ => ThemeMode.system,
                };
          }

          return DynamicColorBuilder(
            builder: (lightDynamic, darkDynamic) {
              return MaterialApp.router(
                title: 'Playbook',
                locale: locale,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [
                  Locale('zh', 'CN'),
                  Locale('en', 'US'),
                ],
                theme: AppTheme.light(seedColor: lightDynamic?.primary),
                darkTheme: AppTheme.dark(seedColor: darkDynamic?.primary),
                themeMode: themeMode,
                routerConfig: AppRouter.router,
                debugShowCheckedModeBanner: false,
              );
            },
          );
        },
      ),
    );
  }
}
