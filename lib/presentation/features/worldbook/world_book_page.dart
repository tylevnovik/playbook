import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../domain/entities/world_book.dart';
import '../../../../domain/repositories/world_book_repository.dart';
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
    _nameController.clear();
    _descController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add World Book'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name *'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = _nameController.text.trim();
              if (name.isNotEmpty) {
                bloc.add(CreateWorldBookEvent(name: name, description: _descController.text.trim()));
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEntryFormDialog(BuildContext context, WorldBookBloc bloc, String worldBookId, {WorldBookEntry? entry}) {
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
        title: Text(entry == null ? 'Add Entry' : 'Edit Entry'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _entryNameController,
                decoration: const InputDecoration(labelText: 'Name *'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _entryKeywordsController,
                decoration: const InputDecoration(
                  labelText: 'Keywords *',
                  hintText: 'e.g. apple, tree, fruit (comma separated)',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _entryContentController,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Content *'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _entryCategoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _entryPriorityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Priority (higher is evaluated first)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
              
              if (name.isNotEmpty && content.isNotEmpty && keywords.isNotEmpty) {
                final newEntry = WorldBookEntry(
                  id: entry?.id ?? '',
                  worldBookId: worldBookId,
                  name: name,
                  keywords: keywords,
                  content: content,
                  category: _entryCategoryController.text.trim().isEmpty ? 'general' : _entryCategoryController.text.trim(),
                  priority: int.tryParse(_entryPriorityController.text) ?? 0,
                  enabled: entry?.enabled ?? true,
                  createdAt: entry?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                bloc.add(SaveEntryEvent(newEntry));
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WorldBookBloc(getIt<WorldBookRepository>())..add(LoadWorldBooks()),
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
              appBar: AppBar(title: const Text('World Books')),
              body: Center(child: Text(state.message, style: TextStyle(color: theme.colorScheme.error))),
            );
          }

          if (state is WorldBookLoaded) {
            final books = state.worldBooks;
            final selectedId = state.selectedWorldBookId;
            final entries = state.entries;

            return Scaffold(
              appBar: AppBar(
                title: const Text('World Books'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.create_new_folder_outlined),
                    tooltip: 'New World Book',
                    onPressed: () => _showAddWorldBookDialog(context, bloc),
                  ),
                ],
              ),
              body: books.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_off_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(height: 16),
                          Text('No World Books yet', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text('Tap the icon above to create one.', style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    )
                  : Row(
                      children: [
                        // Left sidebar
                        Container(
                          width: 250,
                          decoration: BoxDecoration(
                            border: Border(right: BorderSide(color: theme.colorScheme.outlineVariant)),
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
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                subtitle: book.description != null ? Text(book.description!, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
                                selected: isSelected,
                                selectedTileColor: theme.colorScheme.primaryContainer.withOpacity(0.3),
                                trailing: isSelected
                                    ? IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 20),
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

                        // Right main area
                        Expanded(
                          child: selectedId == null
                              ? const Center(child: Text('Select a World Book to manage entries.'))
                              : Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        children: [
                                          Text(
                                            'Entries (${entries.length})',
                                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                          ),
                                          const Spacer(),
                                          ElevatedButton.icon(
                                            icon: const Icon(Icons.add),
                                            label: const Text('Add Entry'),
                                            onPressed: () => _showEntryFormDialog(context, bloc, selectedId),
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
                                                  Icon(Icons.auto_stories_outlined, size: 48, color: theme.colorScheme.onSurfaceVariant),
                                                  const SizedBox(height: 16),
                                                  Text('No entries in this World Book', style: theme.textTheme.bodyLarge),
                                                  const SizedBox(height: 8),
                                                  Text('Click Add Entry to document facts.', style: theme.textTheme.bodyMedium),
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
                                                  onEdit: () => _showEntryFormDialog(context, bloc, selectedId, entry: entry),
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
                        ),
                      ],
                    ),
            );
          }

          return const Scaffold(
            body: Center(child: Text('Initial')),
          );
        },
      ),
    );
  }
}
