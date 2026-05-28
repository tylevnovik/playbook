import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../common/widgets/desktop_scaffold.dart';
import '../common/widgets/offline_banner.dart';
import '../common/widgets/responsive_layout.dart';
import '../features/home/home_page.dart';
import '../features/character/character_edit_page.dart';
import '../features/character/character_list_page.dart';
import '../features/chat/chat_page.dart';
import '../features/worldbook/world_book_page.dart';
import '../features/settings/settings_page.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          final body = OfflineBanner(child: child);
          if (!ResponsiveLayout.isMobile(context)) {
            return DesktopScaffold(
              selectedIndex: _selectedIndexFor(state.matchedLocation),
              body: body,
            );
          }

          return Scaffold(body: body);
        },
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomePage()),
          GoRoute(
            path: '/characters',
            builder: (context, state) => const CharacterListPage(),
          ),
          GoRoute(
            path: '/character/new',
            builder: (context, state) => const CharacterEditPage(),
          ),
          GoRoute(
            path: '/character/:id',
            builder: (context, state) =>
                CharacterEditPage(characterId: state.pathParameters['id']),
          ),
          GoRoute(
            path: '/chat/:chatId',
            builder: (context, state) {
              final chatId = state.pathParameters['chatId']!;
              return ChatPage(
                key: ValueKey(chatId),
                chatId: chatId,
              );
            },
          ),
          GoRoute(
            path: '/worldbook',
            builder: (context, state) => const WorldBookPage(),
          ),
          GoRoute(
            path: '/worldbook/:id',
            builder: (context, state) =>
                WorldBookPage(worldBookId: state.pathParameters['id']),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    ],
  );

  static int _selectedIndexFor(String location) {
    if (location.startsWith('/characters')) return 1;
    if (location.startsWith('/worldbook')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }
}
