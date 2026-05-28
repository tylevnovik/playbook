import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/injection.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/entities/chat.dart';
import '../../../domain/entities/character.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../features/home/bloc/home_bloc.dart';

class DesktopChatSidebar extends StatefulWidget {
  final String? selectedChatId;

  const DesktopChatSidebar({super.key, this.selectedChatId});

  @override
  State<DesktopChatSidebar> createState() => _DesktopChatSidebarState();
}

class _DesktopChatSidebarState extends State<DesktopChatSidebar> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        border: Border(
          right: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: loc.get('searchChats'),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (query) {
                      setState(() {
                        _searchQuery = query;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: const Icon(Icons.add_comment, size: 20),
                  onPressed: () => _showCreateChatDialog(context),
                  tooltip: loc.get('createChat'),
                ),
              ],
            ),
          ),

          Expanded(
            child: BlocBuilder<HomeBloc, HomeState>(
              builder: (context, state) {
                if (state is HomeLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is HomeError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        state.message,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  );
                }
                if (state is HomeLoaded) {
                  final allChats = state.chats;
                  
                  // 本地过滤会话
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
                      child: Text(
                        _searchQuery.isEmpty ? '暂无会话' : '未匹配到会话',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      final chat = chats[index];
                      final isSelected = chat.id == widget.selectedChatId;

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

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 4.0,
                        ),
                        child: InkWell(
                          onTap: () => context.go('/chat/${chat.id}'),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.secondaryContainer
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary.withValues(
                                        alpha: 0.2,
                                      )
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor:
                                      theme.colorScheme.primaryContainer,
                                  backgroundImage:
                                      displayAvatar != null &&
                                              displayAvatar.isNotEmpty
                                          ? NetworkImage(displayAvatar)
                                          : null,
                                  child:
                                      displayAvatar == null ||
                                              displayAvatar.isEmpty
                                          ? Text(
                                              displayName.isNotEmpty
                                                  ? displayName[0].toUpperCase()
                                                  : '?',
                                              style: TextStyle(
                                                color: theme
                                                    .colorScheme
                                                    .onPrimaryContainer,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayName,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        chat.summary ??
                                            (chatCharacters.length > 1
                                                ? '群聊 (${chatCharacters.length}个角色)'
                                                : (chatCharacters.isNotEmpty
                                                    ? chatCharacters.first.description
                                                    : '无参与角色')),
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 18),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onSelected: (value) {
                                    if (value == 'delete') {
                                      _confirmDelete(context, chat, displayName);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text(loc.get('delete')),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
                  context.go('/');
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

class CharacterSelectDialog extends StatefulWidget {
  final List<Character> characters;
  final Function(List<String>) onSelected;

  const CharacterSelectDialog({
    super.key,
    required this.characters,
    required this.onSelected,
  });

  @override
  State<CharacterSelectDialog> createState() => _CharacterSelectDialogState();
}

class _CharacterSelectDialogState extends State<CharacterSelectDialog> {
  final List<String> _selectedIds = [];

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(loc.get('selectCharactersToChat')),
      content: SizedBox(
        width: 400,
        height: 300,
        child: ListView.builder(
          itemCount: widget.characters.length,
          itemBuilder: (context, index) {
            final char = widget.characters[index];
            final isChecked = _selectedIds.contains(char.id);

            return CheckboxListTile(
              title: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: char.avatarPath != null && char.avatarPath!.isNotEmpty
                        ? NetworkImage(char.avatarPath!)
                        : null,
                    child: char.avatarPath == null || char.avatarPath!.isEmpty
                        ? Text(char.name.isNotEmpty ? char.name[0].toUpperCase() : '?')
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      char.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                char.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              value: isChecked,
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _selectedIds.add(char.id);
                  } else {
                    _selectedIds.remove(char.id);
                  }
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.get('cancel')),
        ),
        ElevatedButton(
          onPressed: _selectedIds.isEmpty
              ? null
              : () {
                  Navigator.pop(context);
                  widget.onSelected(_selectedIds);
                },
          child: Text(loc.get('ok')),
        ),
      ],
    );
  }
}
