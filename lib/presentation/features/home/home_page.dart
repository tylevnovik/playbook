import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/repositories/character_repository.dart';
import '../../common/widgets/desktop_character_sidebar.dart';
import '../../common/widgets/responsive_layout.dart';
import 'bloc/home_bloc.dart';
import 'widgets/character_card.dart';

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

class _HomeMobileView extends StatelessWidget {
  const _HomeMobileView();

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.get('appName')),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_outlined),
            tooltip: loc.get('importCharacter'),
            onPressed: () => _importCharacter(context),
          ),
          IconButton(
            icon: const Icon(Icons.book_outlined),
            tooltip: loc.get('worldBooks'),
            onPressed: () => context.push('/worldbook'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: loc.get('settings'),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is HomeError) {
            return Center(child: Text(state.message));
          }
          if (state is HomeLoaded) {
            if (state.characters.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      loc.get('noCharacters'),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.get('tapToCreate'),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: state.characters.length,
              itemBuilder: (context, index) {
                final character = state.characters[index];
                return CharacterCard(
                  character: character,
                  onTap: () => context.push('/chat/${character.id}'),
                  onDelete: () {
                    context.read<HomeBloc>().add(DeleteCharacter(character.id));
                  },
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/character/new'),
        child: const Icon(Icons.add),
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
        const DesktopCharacterSidebar(),
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
                    loc.get('welcomeSubtitle'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(loc.get('createCharacter')),
                    onPressed: () => context.push('/character/new'),
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
}
