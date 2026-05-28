import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/injection.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/file_saver/file_saver.dart';
import '../../../domain/entities/world_book.dart';
import '../../../domain/repositories/world_book_repository.dart';
import '../../common/widgets/responsive_layout.dart';
import 'bloc/world_book_bloc.dart';
import 'widgets/entry_card.dart';

class WorldBookPage extends StatefulWidget {
  final String? worldBookId;

  const WorldBookPage({super.key, this.worldBookId});

  @override
  State<WorldBookPage> createState() => _WorldBookPageState();
}

class _WorldBookPageState extends State<WorldBookPage> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  final _entryNameController = TextEditingController();
  final _entryKeywordsController = TextEditingController();
  final _entryContentController = TextEditingController();
  final _entryCategoryController = TextEditingController();
  final _entryPriorityController = TextEditingController();

  bool _mobileShowEntries = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _entryNameController.dispose();
    _entryKeywordsController.dispose();
    _entryContentController.dispose();
    _entryCategoryController.dispose();
    _entryPriorityController.dispose();
    super.dispose();
  }

  void _showAddWorldBookDialog(BuildContext context, WorldBookBloc bloc) {
    final loc = AppLocalizations.of(context)!;
    _nameController.clear();
    _descController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.get('addWorldBook')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: loc.get('requiredName')),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              decoration: InputDecoration(labelText: loc.get('description')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.get('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              final name = _nameController.text.trim();
              if (name.isNotEmpty) {
                bloc.add(
                  CreateWorldBookEvent(
                    name: name,
                    description: _descController.text.trim(),
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: Text(loc.get('add')),
          ),
        ],
      ),
    );
  }

  Future<void> _importWorldBook(
    BuildContext context,
    WorldBookBloc bloc,
  ) async {
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

      final importResult = await getIt<WorldBookRepository>().importWorldBook(
        content,
      );
      if (!context.mounted) return;

      importResult.fold(
        (failure) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${loc.get('importWorldBookFailed')}: ${failure.message}',
            ),
          ),
        ),
        (_) {
          bloc.add(LoadWorldBooks());
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.get('importWorldBookSuccess'))),
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.get('importWorldBookFailed')}: $e')),
      );
    }
  }

  Future<void> _exportWorldBook(
    BuildContext context,
    String worldBookId,
  ) async {
    final loc = AppLocalizations.of(context)!;
    try {
      final result = await getIt<WorldBookRepository>().exportWorldBook(
        worldBookId,
      );
      if (!context.mounted) return;

      await result.fold(
        (failure) async {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${loc.get('exportWorldBookFailed')}: ${failure.message}',
              ),
            ),
          );
        },
        (jsonContent) async {
          final fileName =
              'playbook_world_book_${DateTime.now().millisecondsSinceEpoch}.json';
          await saveFileContent(jsonContent, fileName);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.get('exportWorldBookSuccess'))),
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.get('exportWorldBookFailed')}: $e')),
      );
    }
  }

  void _showEntryFormDialog(
    BuildContext context,
    WorldBookBloc bloc,
    String worldBookId, {
    WorldBookEntry? entry,
  }) {
    final loc = AppLocalizations.of(context)!;
    if (entry != null) {
      _entryNameController.text = entry.name;
      _entryKeywordsController.text = entry.keywords.join(', ');
      _entryContentController.text = entry.content;
      _entryCategoryController.text = entry.category;
      _entryPriorityController.text = entry.priority.toString();
    } else {
      _entryNameController.clear();
      _entryKeywordsController.clear();
      _entryContentController.clear();
      _entryCategoryController.text = 'general';
      _entryPriorityController.text = '0';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(entry == null ? loc.get('addEntry') : loc.get('editEntry')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _entryNameController,
                decoration: InputDecoration(labelText: loc.get('requiredName')),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _entryKeywordsController,
                decoration: InputDecoration(
                  labelText: loc.get('keywords'),
                  hintText: loc.get('keywordsHint'),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _entryContentController,
                maxLines: 5,
                decoration: InputDecoration(labelText: loc.get('content')),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _entryCategoryController,
                decoration: InputDecoration(labelText: loc.get('category')),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _entryPriorityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: loc.get('priority')),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.get('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              final name = _entryNameController.text.trim();
              final content = _entryContentController.text.trim();
              final keywords = _entryKeywordsController.text
                  .split(',')
                  .map((k) => k.trim())
                  .where((k) => k.isNotEmpty)
                  .toList();

              if (name.isNotEmpty &&
                  content.isNotEmpty &&
                  keywords.isNotEmpty) {
                final newEntry = WorldBookEntry(
                  id: entry?.id ?? '',
                  worldBookId: worldBookId,
                  name: name,
                  keywords: keywords,
                  content: content,
                  category: _entryCategoryController.text.trim().isEmpty
                      ? 'general'
                      : _entryCategoryController.text.trim(),
                  priority: int.tryParse(_entryPriorityController.text) ?? 0,
                  enabled: entry?.enabled ?? true,
                  createdAt: entry?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                bloc.add(SaveEntryEvent(newEntry));
                Navigator.pop(context);
              }
            },
            child: Text(loc.get('save')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return BlocProvider(
      create: (_) =>
          WorldBookBloc(getIt<WorldBookRepository>())..add(LoadWorldBooks()),
      child: BlocBuilder<WorldBookBloc, WorldBookState>(
        builder: (context, state) {
          final theme = Theme.of(context);
          final bloc = context.read<WorldBookBloc>();

          if (state is WorldBookLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (state is WorldBookError) {
            return Scaffold(
              appBar: AppBar(title: Text(loc.get('worldBooks'))),
              body: Center(
                child: Text(
                  state.message,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            );
          }

          if (state is WorldBookLoaded) {
            return ResponsiveLayout(
              mobileBody: _buildMobileBody(context, state, bloc, theme),
              desktopBody: _buildDesktopBody(context, state, bloc, theme),
            );
          }

          return Scaffold(body: Center(child: Text(loc.get('loading'))));
        },
      ),
    );
  }

  Widget _buildMobileBody(
    BuildContext context,
    WorldBookLoaded state,
    WorldBookBloc bloc,
    ThemeData theme,
  ) {
    final loc = AppLocalizations.of(context)!;
    final books = state.worldBooks;
    final selectedId = state.selectedWorldBookId;
    final entries = state.entries;

    if (books.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(loc.get('worldBooks')),
          actions: [
            IconButton(
              icon: const Icon(Icons.psychology_outlined),
              tooltip: 'AI 设定提取',
              onPressed: () => context.go('/extractor'),
            ),
            IconButton(
              icon: const Icon(Icons.upload_file_outlined),
              tooltip: loc.get('importWorldBook'),
              onPressed: () => _importWorldBook(context, bloc),
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_off_outlined,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(loc.get('noWorldBooks'), style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                loc.get('tapToCreateBook'),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.auto_awesome_outlined),
                label: Text(loc.get('addExampleWorldBooks')),
                onPressed: () {
                  bloc.add(CreateExampleWorldBooks());
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.get('examplesAdded'))),
                  );
                },
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddWorldBookDialog(context, bloc),
          child: const Icon(Icons.add),
        ),
      );
    }

    if (_mobileShowEntries && selectedId != null) {
      final selectedBook = books.firstWhere(
        (b) => b.id == selectedId,
        orElse: () => books.first,
      );
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                _mobileShowEntries = false;
              });
            },
          ),
          title: Text(selectedBook.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.download_outlined),
              tooltip: loc.get('exportWorldBook'),
              onPressed: () => _exportWorldBook(context, selectedBook.id),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: loc.get('delete'),
              onPressed: () {
                setState(() {
                  _mobileShowEntries = false;
                });
                bloc.add(DeleteWorldBookEvent(selectedBook.id));
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text(
                    '${loc.get('entries')} (${entries.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(loc.get('addEntry')),
                    onPressed: () =>
                        _showEntryFormDialog(context, bloc, selectedId),
                  ),
                ],
              ),
            ),
            Expanded(
              child: entries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.auto_stories_outlined,
                            size: 48,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            loc.get('noEntries'),
                            style: theme.textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            loc.get('clickToAddEntry'),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return EntryCard(
                          entry: entry,
                          onEdit: () => _showEntryFormDialog(
                            context,
                            bloc,
                            selectedId,
                            entry: entry,
                          ),
                          onDelete: () {
                            bloc.add(DeleteEntryEvent(entry.id, selectedId));
                          },
                          onToggleEnabled: (val) {
                            final toggled = WorldBookEntry(
                              id: entry.id,
                              worldBookId: entry.worldBookId,
                              name: entry.name,
                              keywords: entry.keywords,
                              content: entry.content,
                              category: entry.category,
                              priority: entry.priority,
                              enabled: val,
                              createdAt: entry.createdAt,
                              updatedAt: DateTime.now(),
                            );
                            bloc.add(SaveEntryEvent(toggled));
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.get('worldBooks')),
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology_outlined),
            tooltip: 'AI 设定提取',
            onPressed: () => context.go('/extractor'),
          ),
          IconButton(
            icon: const Icon(Icons.upload_file_outlined),
            tooltip: loc.get('importWorldBook'),
            onPressed: () => _importWorldBook(context, bloc),
          ),
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            tooltip: loc.get('newWorldBook'),
            onPressed: () => _showAddWorldBookDialog(context, bloc),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return ListTile(
            leading: const Icon(Icons.book_outlined),
            title: Text(book.name),
            subtitle: book.description != null
                ? Text(
                    book.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              bloc.add(LoadEntriesEvent(book.id));
              setState(() {
                _mobileShowEntries = true;
              });
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddWorldBookDialog(context, bloc),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDesktopBody(
    BuildContext context,
    WorldBookLoaded state,
    WorldBookBloc bloc,
    ThemeData theme,
  ) {
    final loc = AppLocalizations.of(context)!;
    final books = state.worldBooks;
    final selectedId = state.selectedWorldBookId;
    final entries = state.entries;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.get('worldBooks')),
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology_outlined),
            tooltip: 'AI 设定提取',
            onPressed: () => context.go('/extractor'),
          ),
          IconButton(
            icon: const Icon(Icons.upload_file_outlined),
            tooltip: loc.get('importWorldBook'),
            onPressed: () => _importWorldBook(context, bloc),
          ),
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            tooltip: loc.get('newWorldBook'),
            onPressed: () => _showAddWorldBookDialog(context, bloc),
          ),
        ],
      ),
      body: books.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_off_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loc.get('noWorldBooks'),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.get('tapToCreateBook'),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: Text(loc.get('addExampleWorldBooks')),
                    onPressed: () {
                      bloc.add(CreateExampleWorldBooks());
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(loc.get('examplesAdded'))),
                      );
                    },
                  ),
                ],
              ),
            )
          : Row(
              children: [
                Container(
                  width: 280,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  child: ListView.builder(
                    itemCount: books.length,
                    itemBuilder: (context, index) {
                      final book = books[index];
                      final isSelected = book.id == selectedId;
                      return ListTile(
                        title: Text(
                          book.name,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: book.description != null
                            ? Text(
                                book.description!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        selected: isSelected,
                        selectedTileColor: theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.3),
                        trailing: isSelected
                            ? IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                ),
                                tooltip: loc.get('delete'),
                                onPressed: () {
                                  bloc.add(DeleteWorldBookEvent(book.id));
                                },
                              )
                            : null,
                        onTap: () {
                          bloc.add(LoadEntriesEvent(book.id));
                        },
                      );
                    },
                  ),
                ),
                Expanded(
                  child: selectedId == null
                      ? Center(child: Text(loc.get('selectWorldBook')))
                      : Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Text(
                                    '${loc.get('entries')} (${entries.length})',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.download_outlined),
                                    label: Text(loc.get('exportWorldBook')),
                                    onPressed: () =>
                                        _exportWorldBook(context, selectedId),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.add),
                                    label: Text(loc.get('addEntry')),
                                    onPressed: () => _showEntryFormDialog(
                                      context,
                                      bloc,
                                      selectedId,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: entries.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.auto_stories_outlined,
                                            size: 48,
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            loc.get('noEntries'),
                                            style: theme.textTheme.bodyLarge,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            loc.get('clickToAddEntry'),
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      itemCount: entries.length,
                                      itemBuilder: (context, index) {
                                        final entry = entries[index];
                                        return EntryCard(
                                          entry: entry,
                                          onEdit: () => _showEntryFormDialog(
                                            context,
                                            bloc,
                                            selectedId,
                                            entry: entry,
                                          ),
                                          onDelete: () {
                                            bloc.add(
                                              DeleteEntryEvent(
                                                entry.id,
                                                selectedId,
                                              ),
                                            );
                                          },
                                          onToggleEnabled: (val) {
                                            final toggled = WorldBookEntry(
                                              id: entry.id,
                                              worldBookId: entry.worldBookId,
                                              name: entry.name,
                                              keywords: entry.keywords,
                                              content: entry.content,
                                              category: entry.category,
                                              priority: entry.priority,
                                              enabled: val,
                                              createdAt: entry.createdAt,
                                              updatedAt: DateTime.now(),
                                            );
                                            bloc.add(SaveEntryEvent(toggled));
                                          },
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
    );
  }
}
