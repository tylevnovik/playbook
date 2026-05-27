import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/injection.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/entities/chat.dart';
import '../../../domain/repositories/character_repository.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../features/home/bloc/home_bloc.dart';

class DesktopCharacterSidebar extends StatelessWidget {
  final String? selectedChatId;

  const DesktopCharacterSidebar({super.key, this.selectedChatId});

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
                      hintText: loc.get('searchCharacters'),
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
                      context.read<HomeBloc>().add(SearchCharacters(query));
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: const Icon(Icons.add_comment, size: 20),
                  onPressed: () => _createNewChat(context),
                  tooltip: '新建会话',
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: const Icon(Icons.upload_file_outlined, size: 20),
                  onPressed: () => _importCharacter(context),
                  tooltip: loc.get('importCharacter'),
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
                  final chats = state.chats;
                  if (chats.isEmpty) {
                    return Center(
                      child: Text(
                        '暂无会话',
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
                      final isSelected = chat.id == selectedChatId;

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
                                        chatCharacters.length > 1
                                            ? '群聊 (${chatCharacters.length}个角色)'
                                            : (chatCharacters.isNotEmpty
                                                ? chatCharacters.first.description
                                                : '无参与角色'),
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

  void _createNewChat(BuildContext context) async {
    final result = await getIt<ChatRepository>().createChat(characterIds: []);
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
  }

  void _confirmDelete(BuildContext context, Chat chat, String name) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除会话'),
        content: Text('你确定要删除与 "$name" 的聊天会话吗？历史消息将被彻底删除，此操作不可撤销。'),
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

  Future<void> _importCharacter(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final content = file.bytes != null
          ? utf8.decode(file.bytes!)
          : file.path != null
          ? await File(file.path!).readAsString()
          : throw Exception(loc.get('fileReadFailed'));

      final importResult = await getIt<CharacterRepository>().importCharacter(
        content,
      );
      if (!context.mounted) return;

      importResult.fold(
        (failure) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${loc.get('importCharacterFailed')}: ${failure.message}',
            ),
          ),
        ),
        (_) {
          context.read<HomeBloc>().add(LoadCharacters());
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.get('importCharacterSuccess'))),
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.get('importCharacterFailed')}: $e')),
      );
    }
  }
}
