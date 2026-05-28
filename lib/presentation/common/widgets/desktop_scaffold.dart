import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_localizations.dart';

class DesktopScaffold extends StatelessWidget {
  final Widget body;
  final int selectedIndex;

  const DesktopScaffold({
    super.key,
    required this.body,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final isWide = MediaQuery.of(context).size.width >= 1200;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: isWide,
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              if (index == selectedIndex) return;
              switch (index) {
                case 0:
                  context.go('/');
                  break;
                case 1:
                  context.go('/characters');
                  break;
                case 2:
                  context.go('/worldbook');
                  break;
                case 3:
                  context.go('/extractor');
                  break;
                case 4:
                  context.go('/settings');
                  break;
              }
            },
            minWidth: 72,
            minExtendedWidth: 200,
            backgroundColor: theme.colorScheme.surfaceContainerLow,
            indicatorColor: theme.colorScheme.primaryContainer,
            selectedIconTheme: IconThemeData(
              color: theme.colorScheme.onPrimaryContainer,
            ),
            unselectedIconTheme: IconThemeData(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            selectedLabelTextStyle: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelTextStyle: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            leading: Column(
              children: [
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.bubble_chart,
                    size: 32,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (isWide) ...[
                  const SizedBox(height: 8),
                  Text(
                    'PLAYBOOK',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
            destinations: [
              NavigationRailDestination(
                icon: const Icon(Icons.chat_bubble_outline),
                selectedIcon: const Icon(Icons.chat_bubble),
                label: Text(loc.get('chats')),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.people_outline),
                selectedIcon: const Icon(Icons.people),
                label: Text(loc.get('characters')),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.auto_stories_outlined),
                selectedIcon: const Icon(Icons.auto_stories),
                label: Text(loc.get('worldBooks')),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.psychology_outlined),
                selectedIcon: const Icon(Icons.psychology),
                label: Text(loc.get('aiExtractor')),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: Text(loc.get('settings')),
              ),
            ],
          ),          VerticalDivider(
            thickness: 1,
            width: 1,
            color: theme.colorScheme.outlineVariant,
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
