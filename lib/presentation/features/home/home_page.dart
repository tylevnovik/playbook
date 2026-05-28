import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/entities/chat.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../common/widgets/desktop_chat_sidebar.dart';
import '../../common/widgets/responsive_layout.dart';
import 'bloc/home_bloc.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobileBody: _HomeMobileView(),
      desktopBody: _HomeDesktopView(),
    );
  }
}

class _HomeMobileView extends StatefulWidget {
  const _HomeMobileView();

  @override
  State<_HomeMobileView> createState() => _HomeMobileViewState();
}

class _HomeMobileViewState extends State<_HomeMobileView> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.get('chats')),
      ),
      body: Column(
        children: [
          // 搜索框
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: loc.get('searchChats'),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),
          
          Expanded(
            child: BlocBuilder<HomeBloc, HomeState>(
              builder: (context, state) {
                if (state is HomeLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is HomeError) {
                  return Center(child: Text(state.message));
                }
                if (state is HomeLoaded) {
                  final allChats = state.chats;

                  // 过滤会话
                  final chats = allChats.where((chat) {
                    if (_searchQuery.trim().isEmpty) return true;
                    final chatCharacters = state.characters
                        .where((c) => chat.characterIds.contains(c.id))
                        .toList();
                    final nameMatch = chatCharacters.any((c) => c.name
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()));
                    final summaryMatch = chat.summary != null &&
                        chat.summary!
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase());
                    return nameMatch || summaryMatch;
                  }).toList();

                  if (chats.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty ? '暂无会话' : '未匹配到会话',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          if (_searchQuery.isEmpty)
                            Text(
                              '点击右下方按钮发起新对话',
                              style: theme.textTheme.bodyMedium,
                            ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: chats.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final chat = chats[index];
                      final chatCharacters = state.characters
                          .where((c) => chat.characterIds.contains(c.id))
                          .toList();

                      String displayName = '未命名会话';
                      String? displayAvatar;
                      if (chatCharacters.isNotEmpty) {
                        if (chatCharacters.length == 1) {
                          displayName = chatCharacters.first.name;
                          displayAvatar = chatCharacters.first.avatarPath;
                        } else {
                          displayName = chatCharacters.map((c) => c.name).join(', ');
                          displayAvatar = chatCharacters.first.avatarPath;
                        }
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            backgroundImage: displayAvatar != null && displayAvatar.isNotEmpty
                                ? NetworkImage(displayAvatar)
                                : null,
                            child: displayAvatar == null || displayAvatar.isEmpty
                                ? Text(
                                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                    style: TextStyle(
                                      color: theme.colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            chat.summary ??
                                (chatCharacters.length > 1
                                    ? '群聊 (${chatCharacters.length}个角色)'
                                    : (chatCharacters.isNotEmpty
                                        ? chatCharacters.first.description
                                        : '无参与角色')),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => context.push('/chat/${chat.id}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _confirmDelete(context, chat, displayName),
                          ),
                        ),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateChatDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateChatDialog(BuildContext context) {
    final homeState = context.read<HomeBloc>().state;
    if (homeState is! HomeLoaded) return;

    final loc = AppLocalizations.of(context)!;
    final characters = homeState.characters;

    if (characters.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(loc.get('createChat')),
          content: Text(loc.get('noCharactersToChat')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(loc.get('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/characters');
              },
              child: Text(loc.get('characters')),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return CharacterSelectDialog(
          characters: characters,
          onSelected: (selectedIds) async {
            final result = await getIt<ChatRepository>().createChat(
              characterIds: selectedIds,
            );
            if (!context.mounted) return;
            result.fold(
              (failure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('创建会话失败: ${failure.message}')),
                );
              },
              (chat) {
                context.read<HomeBloc>().add(LoadCharacters());
                context.push('/chat/${chat.id}');
              },
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, Chat chat, String name) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.get('deleteChat')),
        content: Text(loc.get('confirmDeleteChat')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.get('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await getIt<ChatRepository>().deleteChat(chat.id);
              result.fold(
                (failure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('删除会话失败: ${failure.message}')),
                  );
                },
                (_) {
                  context.read<HomeBloc>().add(LoadCharacters());
                },
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(loc.get('delete')),
          ),
        ],
      ),
    );
  }
}

class _HomeDesktopView extends StatelessWidget {
  const _HomeDesktopView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Row(
      children: [
        const DesktopChatSidebar(),
        Expanded(
          child: Container(
            color: theme.colorScheme.surfaceContainerHigh,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.forum_outlined,
                      size: 80,
                      color: theme.colorScheme.primary.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    loc.get('welcomeTitle'),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '选择左侧会话开始聊天，或者点击下方按钮发起新对话。',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_comment),
                    label: Text(loc.get('createChat')),
                    onPressed: () => _showCreateChatDialog(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showCreateChatDialog(BuildContext context) {
    final homeState = context.read<HomeBloc>().state;
    if (homeState is! HomeLoaded) return;

    final loc = AppLocalizations.of(context)!;
    final characters = homeState.characters;

    if (characters.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(loc.get('createChat')),
          content: Text(loc.get('noCharactersToChat')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(loc.get('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/characters');
              },
              child: Text(loc.get('characters')),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return CharacterSelectDialog(
          characters: characters,
          onSelected: (selectedIds) async {
            final result = await getIt<ChatRepository>().createChat(
              characterIds: selectedIds,
            );
            if (!context.mounted) return;
            result.fold(
              (failure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('创建会话失败: ${failure.message}')),
                );
              },
              (chat) {
                context.read<HomeBloc>().add(LoadCharacters());
                context.go('/chat/${chat.id}');
              },
            );
          },
        );
      },
    );
  }
}
