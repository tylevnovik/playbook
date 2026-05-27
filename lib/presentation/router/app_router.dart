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
