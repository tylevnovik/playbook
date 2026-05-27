import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/injection.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/entities/character.dart';
import '../../../domain/repositories/character_repository.dart';
import '../../features/home/bloc/home_bloc.dart';

class DesktopCharacterSidebar extends StatelessWidget {
  final String? selectedCharacterId;

  const DesktopCharacterSidebar({super.key, this.selectedCharacterId});

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
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () => context.push('/character/new'),
                  tooltip: loc.get('createCharacter'),
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
                  final characters = state.characters;
                  if (characters.isEmpty) {
                    return Center(
                      child: Text(
                        loc.get('noCharacters'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: characters.length,
                    itemBuilder: (context, index) {
                      final char = characters[index];
                      final isSelected = char.id == selectedCharacterId;

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 4.0,
                        ),
                        child: InkWell(
                          onTap: () => context.go('/chat/${char.id}'),
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
                                      char.avatarPath != null &&
                                          char.avatarPath!.isNotEmpty
                                      ? NetworkImage(char.avatarPath!)
                                      : null,
                                  child:
                                      char.avatarPath == null ||
                                          char.avatarPath!.isEmpty
                                      ? Text(
                                          char.name.isNotEmpty
                                              ? char.name[0].toUpperCase()
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
                                        char.name,
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
                                        char.description,
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
                                    if (value == 'edit') {
                                      context.push('/character/${char.id}');
                                    } else if (value == 'delete') {
                                      _confirmDelete(context, char);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text(loc.get('edit')),
                                    ),
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

  void _confirmDelete(BuildContext context, Character character) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.get('deleteCharacter')),
        content: Text(loc.get('deleteConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.get('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<HomeBloc>().add(DeleteCharacter(character.id));
              context.go('/');
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
