import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/file_saver/file_saver.dart';
import '../../../domain/entities/character.dart';
import '../../../domain/entities/world_book.dart';
import '../../../domain/repositories/character_repository.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../../domain/repositories/world_book_repository.dart';
import '../home/bloc/home_bloc.dart';

class CharacterListPage extends StatefulWidget {
  const CharacterListPage({super.key});

  @override
  State<CharacterListPage> createState() => _CharacterListPageState();
}

class _CharacterListPageState extends State<CharacterListPage> {
  String _searchQuery = '';
  Character? _selectedCharacter;
  List<WorldBook> _worldBooks = [];
  bool _isLoadingWorldBooks = true;

  @override
  void initState() {
    super.initState();
    _loadWorldBooks();
    // 确保列表是最新的
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeBloc>().add(LoadCharacters());
    });
  }

  Future<void> _loadWorldBooks() async {
    final result = await getIt<WorldBookRepository>().getAllWorldBooks();
    result.fold(
      (failure) {
        if (mounted) setState(() => _isLoadingWorldBooks = false);
      },
      (books) {
        if (mounted) {
          setState(() {
            _worldBooks = books;
            _isLoadingWorldBooks = false;
          });
        }
      },
    );
  }

  Future<void> _importCharacter() async {
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
      if (!mounted) return;

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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.get('importCharacterFailed')}: $e')),
      );
    }
  }

  Future<void> _exportCharacter(String characterId) async {
    final loc = AppLocalizations.of(context)!;
    final result = await getIt<CharacterRepository>().exportCharacter(
      characterId,
    );
    if (!mounted) return;
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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.get('exportCharacterSuccess'))),
        );
      },
    );
  }

  void _startChat(Character character) async {
    final result = await getIt<ChatRepository>().createChat(
      characterIds: [character.id],
    );
    if (!mounted) return;
    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发起对话失败: ${failure.message}')),
        );
      },
      (chat) {
        context.read<HomeBloc>().add(LoadCharacters());
        context.go('/chat/${chat.id}');
      },
    );
  }

  void _confirmDelete(Character character) {
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
            onPressed: () async {
              Navigator.pop(ctx);
              context.read<HomeBloc>().add(DeleteCharacter(character.id));
              setState(() {
                if (_selectedCharacter?.id == character.id) {
                  _selectedCharacter = null;
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('角色删除成功')),
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isDesktop = MediaQuery.of(context).size.width >= 1000;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.get('characters')),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_outlined),
            tooltip: loc.get('importCharacter'),
            onPressed: _importCharacter,
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome_outlined),
            tooltip: loc.get('addExampleCharacters'),
            onPressed: () {
              context.read<HomeBloc>().add(CreateExampleCharacters());
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(loc.get('examplesAdded'))),
              );
            },
          ),
          if (!isDesktop)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: loc.get('createCharacter'),
              onPressed: () async {
                await context.push('/character/new');
                if (mounted) {
                  context.read<HomeBloc>().add(LoadCharacters());
                }
              },
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
            // 本地搜索过滤
            final characters = state.characters.where((c) {
              if (_searchQuery.trim().isEmpty) return true;
              final nameMatch =
                  c.name.toLowerCase().contains(_searchQuery.toLowerCase());
              final descMatch = c.description
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase());
              final tagMatch = c.tags.any(
                  (t) => t.toLowerCase().contains(_searchQuery.toLowerCase()));
              return nameMatch || descMatch || tagMatch;
            }).toList();

            if (isDesktop) {
              return _buildDesktopLayout(characters);
            } else {
              return _buildMobileLayout(characters);
            }
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: !isDesktop
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                await context.push('/character/new');
                if (mounted) {
                  context.read<HomeBloc>().add(LoadCharacters());
                }
              },
              icon: const Icon(Icons.add),
              label: Text(loc.get('createCharacter')),
            ),
    );
  }

  // 桌面端布局
  Widget _buildDesktopLayout(List<Character> characters) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    // 纠正已选择的角色的最新状态
    Character? currentSelected;
    if (_selectedCharacter != null) {
      final index = characters.indexWhere((c) => c.id == _selectedCharacter!.id);
      if (index != -1) {
        currentSelected = characters[index];
      }
    }

    return Row(
      children: [
        // 左侧角色列表
        Container(
          width: 320,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: loc.get('searchCharacters'),
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
                child: characters.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty ? '暂无角色' : '未找到匹配角色',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: characters.length,
                        itemBuilder: (context, index) {
                          final char = characters[index];
                          final isSelected = currentSelected?.id == char.id;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primaryContainer,
                              backgroundImage: char.avatarPath != null &&
                                      char.avatarPath!.isNotEmpty
                                  ? NetworkImage(char.avatarPath!)
                                  : null,
                              child: char.avatarPath == null ||
                                      char.avatarPath!.isEmpty
                                  ? Text(
                                      char.name.isNotEmpty
                                          ? char.name[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        color: theme.colorScheme.onPrimaryContainer,
                                      ),
                                    )
                                  : null,
                            ),
                            title: Text(
                              char.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              char.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            selected: isSelected,
                            selectedTileColor: theme.colorScheme.secondaryContainer,
                            onTap: () {
                              setState(() {
                                _selectedCharacter = char;
                              });
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        // 右侧角色详情预览
        Expanded(
          child: currentSelected == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 80,
                        color: theme.colorScheme.primary.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        loc.get('selectCharacterToView'),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : _buildCharacterDetailView(currentSelected),
        ),
      ],
    );
  }

  // 移动端布局
  Widget _buildMobileLayout(List<Character> characters) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Column(
      children: [
        // 搜索栏
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: loc.get('searchCharacters'),
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
          child: characters.isEmpty
              ? Center(
                  child: Text(
                    _searchQuery.isEmpty ? '暂无角色' : '未找到匹配角色',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    childAspectRatio: 0.78,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: characters.length,
                  itemBuilder: (context, index) {
                    final char = characters[index];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _showMobileCharacterDetails(char),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Container(
                                color: theme.colorScheme.primaryContainer,
                                child: char.avatarPath != null &&
                                        char.avatarPath!.isNotEmpty
                                    ? Image.network(char.avatarPath!,
                                        fit: BoxFit.cover)
                                    : Center(
                                        child: Text(
                                          char.name.isNotEmpty
                                              ? char.name[0].toUpperCase()
                                              : '?',
                                          style: theme.textTheme.displayMedium
                                              ?.copyWith(
                                            color: theme.colorScheme
                                                .onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      char.name,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      char.description,
                                      style: theme.textTheme.bodySmall,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // 角色详细预览区域
  Widget _buildCharacterDetailView(Character char) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    // 查找绑定的世界书名字
    final linkedBooks = _worldBooks
        .where((book) => char.worldBookIds.contains(book.id))
        .map((b) => b.name)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部个人资料
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: theme.colorScheme.primaryContainer,
                backgroundImage: char.avatarPath != null && char.avatarPath!.isNotEmpty
                    ? NetworkImage(char.avatarPath!)
                    : null,
                child: char.avatarPath == null || char.avatarPath!.isEmpty
                    ? Text(
                        char.name.isNotEmpty ? char.name[0].toUpperCase() : '?',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      char.name,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (char.tags.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: char.tags
                            .map((tag) => Chip(
                                  label: Text(tag, style: const TextStyle(fontSize: 12)),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  padding: EdgeInsets.zero,
                                ))
                            .toList(),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // 核心信息列表
          _buildInfoSection('人物描述', char.description, Icons.description_outlined),
          _buildInfoSection('开场白设定', char.greeting, Icons.chat_bubble_outline),
          
          if (char.systemPrompt != null && char.systemPrompt!.isNotEmpty)
            _buildInfoSection('系统覆盖指令', char.systemPrompt!, Icons.psychology_outlined),

          if (char.exampleMessages != null && char.exampleMessages!.isNotEmpty)
            _buildInfoSection('对话示例', char.exampleMessages!, Icons.history_edu_outlined),

          // 关联的世界书
          _buildInfoSection(
            '关联的世界书',
            linkedBooks.isEmpty ? '无关联的世界书' : linkedBooks.join('、'),
            Icons.auto_stories_outlined,
          ),

          const SizedBox(height: 32),

          // 操作动作栏
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.chat_bubble),
                label: Text(loc.get('startChatWithChar')),
                onPressed: () => _startChat(char),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.edit_outlined),
                label: Text(loc.get('edit')),
                onPressed: () async {
                  await context.push('/character/${char.id}');
                  if (mounted) {
                    context.read<HomeBloc>().add(LoadCharacters());
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.download_outlined),
                label: Text(loc.get('exportCharacter')),
                onPressed: () => _exportCharacter(char.id),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline),
                label: Text(loc.get('delete')),
                onPressed: () => _confirmDelete(char),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, String content, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              content,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // 手机端展示角色详情的弹窗
  void _showMobileCharacterDetails(Character char) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final linkedBooks = _worldBooks
        .where((book) => char.worldBookIds.contains(book.id))
        .map((b) => b.name)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 1.0,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        backgroundImage: char.avatarPath != null && char.avatarPath!.isNotEmpty
                            ? NetworkImage(char.avatarPath!)
                            : null,
                        child: char.avatarPath == null || char.avatarPath!.isEmpty
                            ? Text(
                                char.name.isNotEmpty ? char.name[0].toUpperCase() : '?',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              char.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (char.tags.isNotEmpty)
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: char.tags
                                    .map((t) => Chip(
                                          label: Text(t, style: const TextStyle(fontSize: 11)),
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          padding: EdgeInsets.zero,
                                        ))
                                    .toList(),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),

                  _buildInfoSection('人物描述', char.description, Icons.description_outlined),
                  _buildInfoSection('开场白设定', char.greeting, Icons.chat_bubble_outline),
                  
                  if (char.systemPrompt != null && char.systemPrompt!.isNotEmpty)
                    _buildInfoSection('系统覆盖指令', char.systemPrompt!, Icons.psychology_outlined),

                  _buildInfoSection(
                    '关联的世界书',
                    linkedBooks.isEmpty ? '无关联的世界书' : linkedBooks.join('、'),
                    Icons.auto_stories_outlined,
                  ),

                  const SizedBox(height: 24),

                  // 操作按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.chat_bubble),
                      label: Text(loc.get('startChatWithChar')),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _startChat(char);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.edit_outlined),
                          label: Text(loc.get('edit')),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await context.push('/character/${char.id}');
                            if (mounted) {
                              context.read<HomeBloc>().add(LoadCharacters());
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.download_outlined),
                          label: Text(loc.get('exportCharacter')),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _exportCharacter(char.id);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete_outline),
                      label: Text(loc.get('delete')),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _confirmDelete(char);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(color: theme.colorScheme.error),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
