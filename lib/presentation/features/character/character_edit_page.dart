import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/di/injection.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/file_saver/file_saver.dart';
import '../../../domain/entities/character.dart';
import '../../../domain/entities/world_book.dart';
import '../../../domain/repositories/character_repository.dart';
import '../../../domain/repositories/world_book_repository.dart';
import 'bloc/character_edit_bloc.dart';

class CharacterEditPage extends StatefulWidget {
  final String? characterId;

  const CharacterEditPage({super.key, this.characterId});

  @override
  State<CharacterEditPage> createState() => _CharacterEditPageState();
}

class _CharacterEditPageState extends State<CharacterEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _greetingController = TextEditingController();
  final _exampleController = TextEditingController();
  final _promptController = TextEditingController();
  final _tagController = TextEditingController();

  String? _avatarPath;
  List<String> _selectedWorldBookIds = [];
  List<String> _tags = [];
  List<WorldBook> _worldBooks = [];
  bool _isLoadingWorldBooks = true;

  @override
  void initState() {
    super.initState();
    _loadWorldBooks();
  }

  Future<void> _loadWorldBooks() async {
    final result = await getIt<WorldBookRepository>().getAllWorldBooks();
    result.fold((failure) => null, (books) {
      if (mounted) {
        setState(() {
          _worldBooks = books;
          _isLoadingWorldBooks = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _greetingController.dispose();
    _exampleController.dispose();
    _promptController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _avatarPath = image.path;
      });
    }
  }

  void _addTag(String value) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty && !_tags.contains(trimmed)) {
      setState(() {
        _tags.add(trimmed);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = CharacterEditBloc(getIt<CharacterRepository>());
        if (widget.characterId != null) {
          bloc.add(LoadCharacterForEdit(widget.characterId!));
        }
        return bloc;
      },
      child: BlocConsumer<CharacterEditBloc, CharacterEditState>(
        listener: (context, state) {
          final loc = AppLocalizations.of(context)!;
          if (state is CharacterEditSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(loc.get('characterSaveSuccess'))),
            );
            context.pop();
          }
          if (state is CharacterEditError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
          if (state is CharacterEditLoaded && state.character != null) {
            final char = state.character!;
            _nameController.text = char.name;
            _descController.text = char.description;
            _greetingController.text = char.greeting;
            _exampleController.text = char.exampleMessages ?? '';
            _promptController.text = char.systemPrompt ?? '';
            _avatarPath = char.avatarPath;
            _selectedWorldBookIds = List.from(char.worldBookIds);
            _tags = List.from(char.tags);
          }
        },
        builder: (context, state) {
          final loc = AppLocalizations.of(context)!;
          final isSaving = state is CharacterEditLoading;

          return Scaffold(
            appBar: AppBar(
              title: Text(
                widget.characterId == null
                    ? loc.get('newCharacterTitle')
                    : loc.get('editCharacterTitle'),
              ),
              actions: [
                if (widget.characterId != null)
                  IconButton(
                    icon: const Icon(Icons.share),
                    tooltip: loc.get('exportCharacter'),
                    onPressed: () => _exportJson(context),
                  ),
              ],
            ),
            body: isSaving
                ? const Center(child: CircularProgressIndicator())
                : Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        // Avatar picker
                        Center(
                          child: GestureDetector(
                            onTap: _pickAvatar,
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              backgroundImage: _avatarPath != null
                                  ? NetworkImage(_avatarPath!)
                                  : null,
                              child: _avatarPath == null
                                  ? Icon(
                                      Icons.camera_alt,
                                      size: 32,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            loc.get('tapToChangeAvatar'),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Name field
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: loc.get('characterNameRequired'),
                            hintText: loc.get('characterNameHint'),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty
                              ? loc.get('nameRequired')
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Description field
                        TextFormField(
                          controller: _descController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: loc.get('characterDescriptionRequired'),
                            hintText: loc.get('characterDescriptionHint'),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty
                              ? loc.get('descriptionRequired')
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Greeting field
                        TextFormField(
                          controller: _greetingController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: loc.get('greetingRequired'),
                            hintText: loc.get('greetingHint'),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty
                              ? loc.get('greetingRequiredError')
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // System prompt override
                        TextFormField(
                          controller: _promptController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: loc.get('systemPromptOverride'),
                            hintText: loc.get('systemPromptOverrideHint'),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Example messages
                        TextFormField(
                          controller: _exampleController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: loc.get('exampleMessages'),
                            hintText: loc.get('exampleMessagesHint'),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // World Books
                        _isLoadingWorldBooks
                            ? const Center(child: CircularProgressIndicator())
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    loc.get('worldBook'),
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: () => _showWorldBookSelectionDialog(context),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Theme.of(context).colorScheme.outlineVariant,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: _selectedWorldBookIds.isEmpty
                                          ? Row(
                                              children: [
                                                Icon(
                                                  Icons.book_outlined,
                                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  loc.get('selectWorldBookToLink'),
                                                  style: TextStyle(
                                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Wrap(
                                              spacing: 8.0,
                                              runSpacing: 4.0,
                                              crossAxisAlignment: WrapCrossAlignment.center,
                                              children: [
                                                ..._selectedWorldBookIds.map((id) {
                                                  final book = _worldBooks.firstWhere(
                                                    (b) => b.id == id,
                                                    orElse: () => WorldBook(
                                                      id: id,
                                                      name: '未知世界书',
                                                      description: '',
                                                      createdAt: DateTime.now(),
                                                      updatedAt: DateTime.now(),
                                                    ),
                                                  );
                                                  return Chip(
                                                    label: Text(book.name),
                                                    onDeleted: () {
                                                      setState(() {
                                                        _selectedWorldBookIds.remove(id);
                                                      });
                                                    },
                                                  );
                                                }),
                                                IconButton(
                                                  icon: const Icon(Icons.add_circle_outline, size: 24),
                                                  onPressed: () => _showWorldBookSelectionDialog(context),
                                                  color: Theme.of(context).colorScheme.primary,
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                        const SizedBox(height: 16),

                        // Tags
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _tagController,
                                decoration: InputDecoration(
                                  labelText: loc.get('addTag'),
                                  hintText: loc.get('addTagHint'),
                                ),
                                onFieldSubmitted: _addTag,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              icon: const Icon(Icons.add),
                              onPressed: () => _addTag(_tagController.text),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0,
                          children: _tags
                              .map(
                                (t) => Chip(
                                  label: Text(t),
                                  onDeleted: () => _removeTag(t),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 24),

                        // Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => context.pop(),
                              child: Text(loc.get('cancel')),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  final char = Character(
                                    id: widget.characterId ?? '',
                                    name: _nameController.text.trim(),
                                    avatarPath: _avatarPath,
                                    description: _descController.text.trim(),
                                    greeting: _greetingController.text.trim(),
                                    exampleMessages:
                                        _exampleController.text.trim().isEmpty
                                        ? null
                                        : _exampleController.text.trim(),
                                    systemPrompt:
                                        _promptController.text.trim().isEmpty
                                        ? null
                                        : _promptController.text.trim(),
                                    tags: _tags,
                                    worldBookIds: _selectedWorldBookIds,
                                    createdAt: DateTime.now(),
                                    updatedAt: DateTime.now(),
                                  );
                                  context.read<CharacterEditBloc>().add(
                                    SaveCharacter(char),
                                  );
                                }
                              },
                              child: Text(loc.get('save')),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  void _showWorldBookSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final loc = AppLocalizations.of(context)!;
            return AlertDialog(
              title: Text(loc.get('selectWorldBooks')),
              content: _worldBooks.isEmpty
                  ? Text(loc.get('noWorldBooksAvailable'))
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: _worldBooks.map((book) {
                          final isSelected = _selectedWorldBookIds.contains(book.id);
                          return CheckboxListTile(
                            title: Text(book.name),
                            subtitle: (book.description != null && book.description!.isNotEmpty)
                                ? Text(
                                    book.description!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            value: isSelected,
                            onChanged: (checked) {
                              setDialogState(() {
                                if (checked == true) {
                                  _selectedWorldBookIds.add(book.id);
                                } else {
                                  _selectedWorldBookIds.remove(book.id);
                                }
                              });
                              setState(() {});
                            },
                          );
                        }).toList(),
                      ),
                    ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(loc.get('ok')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _exportJson(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    final result = await getIt<CharacterRepository>().exportCharacter(
      widget.characterId!,
    );
    if (!context.mounted) return;
    await result.fold(
      (failure) async {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${loc.get('exportCharacterFailed')}: ${failure.message}',
            ),
          ),
        );
      },
      (jsonStr) async {
        final fileName =
            'playbook_character_${DateTime.now().millisecondsSinceEpoch}.json';
        await saveFileContent(jsonStr, fileName);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.get('exportCharacterSuccess'))),
        );
      },
    );
  }
}
