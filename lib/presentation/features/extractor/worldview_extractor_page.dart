import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collection/collection.dart';

import '../../../core/di/injection.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/repositories/character_repository.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../../domain/repositories/world_book_repository.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/repositories/llm_repository.dart';
import 'bloc/extractor_bloc.dart';
import 'bloc/extractor_event.dart';
import 'bloc/extractor_state.dart';

class WorldviewExtractorPage extends StatefulWidget {
  final String? initialChatId;

  const WorldviewExtractorPage({super.key, this.initialChatId});

  @override
  State<WorldviewExtractorPage> createState() => _WorldviewExtractorPageState();
}

class _WorldviewExtractorPageState extends State<WorldviewExtractorPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _textController = TextEditingController();
  
  String? _selectedChatId;
  String? _destinationWorldBookId;
  final _newWorldBookNameController = TextEditingController();
  bool _createNewWorldBook = false;

  // 临时存储提取后被用户修改的值
  final List<TextEditingController> _charNameControllers = [];
  final List<TextEditingController> _charDescControllers = [];
  final List<TextEditingController> _charGreetingControllers = [];
  final List<bool> _selectedCharacters = [];

  final List<TextEditingController> _entryNameControllers = [];
  final List<TextEditingController> _entryKeywordsControllers = [];
  final List<TextEditingController> _entryContentControllers = [];
  final List<String> _entryCategories = [];
  final List<bool> _selectedEntries = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedChatId = widget.initialChatId;
    if (_selectedChatId != null) {
      _tabController.index = 1; // 默认选中“从聊天提取”
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    _newWorldBookNameController.dispose();
    _disposeExtractedControllers();
    super.dispose();
  }

  void _disposeExtractedControllers() {
    for (var c in _charNameControllers) {
      c.dispose();
    }
    for (var c in _charDescControllers) {
      c.dispose();
    }
    for (var c in _charGreetingControllers) {
      c.dispose();
    }
    for (var c in _entryNameControllers) {
      c.dispose();
    }
    for (var c in _entryKeywordsControllers) {
      c.dispose();
    }
    for (var c in _entryContentControllers) {
      c.dispose();
    }
    _charNameControllers.clear();
    _charDescControllers.clear();
    _charGreetingControllers.clear();
    _selectedCharacters.clear();
    _entryNameControllers.clear();
    _entryKeywordsControllers.clear();
    _entryContentControllers.clear();
    _entryCategories.clear();
    _selectedEntries.clear();
  }

  void _setupExtractedControllers(List<Map<String, String>> chars, List<Map<String, dynamic>> entries) {
    _disposeExtractedControllers();

    for (final char in chars) {
      _charNameControllers.add(TextEditingController(text: char['name'] ?? ''));
      _charDescControllers.add(TextEditingController(text: char['description'] ?? ''));
      _charGreetingControllers.add(TextEditingController(text: char['greeting'] ?? ''));
      _selectedCharacters.add(true);
    }

    for (final entry in entries) {
      _entryNameControllers.add(TextEditingController(text: entry['name'] ?? ''));
      _entryKeywordsControllers.add(TextEditingController(text: (entry['keywords'] as List<dynamic>?)?.join(', ') ?? ''));
      _entryContentControllers.add(TextEditingController(text: entry['content'] ?? ''));
      _entryCategories.add(entry['category'] ?? 'general');
      _selectedEntries.add(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return BlocProvider(
      create: (context) => ExtractorBloc(
        characterRepository: getIt<CharacterRepository>(),
        worldBookRepository: getIt<WorldBookRepository>(),
        chatRepository: getIt<ChatRepository>(),
        settingsRepository: getIt<SettingsRepository>(),
        llmRepository: getIt<LlmRepository>(),
      )..add(LoadExtractorInitialData()),
      child: BlocConsumer<ExtractorBloc, ExtractorState>(
        listener: (context, state) {
          if (state.status == ExtractorStatus.success) {
            _setupExtractedControllers(state.extractedCharacters, state.extractedEntries);
            if (state.worldBooks.isNotEmpty && _destinationWorldBookId == null) {
              _destinationWorldBookId = state.worldBooks.first.id;
            }
          } else if (state.status == ExtractorStatus.importSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('设定与角色卡已成功导入数据库！'),
                backgroundColor: Colors.green,
              ),
            );
            _disposeExtractedControllers();
          } else if (state.status == ExtractorStatus.error && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final isDesktop = MediaQuery.of(context).size.width >= 1100;

          return Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  Icon(Icons.psychology, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(loc.get('aiExtractor')),
                ],
              ),
            ),
            body: state.status == ExtractorStatus.loading && state.extractedCharacters.isEmpty
                ? _buildLoadingScreen(theme, state)
                : isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 4,
                            child: _buildInputPanel(context, state, theme),
                          ),
                          VerticalDivider(
                            width: 1,
                            thickness: 1,
                            color: theme.colorScheme.outlineVariant,
                          ),
                          Expanded(
                            flex: 6,
                            child: _buildResultPanel(context, state, theme),
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            SizedBox(
                              height: 450,
                              child: _buildInputPanel(context, state, theme),
                            ),
                            const Divider(height: 1),
                            SizedBox(
                              height: 600,
                              child: _buildResultPanel(context, state, theme),
                            ),
                          ],
                        ),
                      ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingScreen(ThemeData theme, ExtractorState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            state.extractionProgressMessage ?? 'AI 正在为您解析设定...',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '提取角色背景人设和世界设定百科中，请稍候。',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInputPanel(BuildContext context, ExtractorState state, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.paste_outlined), text: '手动粘贴文本'),
                Tab(icon: Icon(Icons.chat_bubble_outline), text: '从聊天提取'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 手动粘贴
                  _buildTextInputTab(theme),
                  // 从聊天选择
                  _buildChatSelectTab(state, theme),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_tabController.index == 0) {
                    context.read<ExtractorBloc>().add(
                          ExtractFromTextEvent(_textController.text),
                        );
                  } else {
                    if (_selectedChatId != null) {
                      context.read<ExtractorBloc>().add(
                            ExtractFromChatEvent(_selectedChatId!),
                          );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('请先选择一个聊天会话')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.auto_awesome),
                label: Text(
                  _tabController.index == 0 ? '开始分析提取' : '从该会话中提取设定',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextInputTab(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '直接粘贴大段背景故事、大纲人设或设定百科：',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: TextField(
            controller: _textController,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              hintText: '例：在阿瓦隆大陆上，魔法是依赖星能的。星能分为赤、碧、金三色，分别由不同神祇执掌...\n阿斯蒙德是一名身披黑色长袍的亡灵巫师，生性孤僻且热爱研究古籍...',
              hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerLow,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatSelectTab(ExtractorState state, ThemeData theme) {
    if (state.chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            const Text('暂无历史会话记录'),
          ],
        ),
      );
    }

    final selectedChat = state.chats.firstWhereOrNull((c) => c.id == _selectedChatId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '选择一个现有的角色聊天，分析对话提炼世界设定：',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _selectedChatId,
          hint: const Text('选择会话...'),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: state.chats.map((chat) {
            final chatChars = state.allCharacters
                .where((c) => chat.characterIds.contains(c.id))
                .toList();
            String chatTitle = '未命名会话';
            if (chatChars.isNotEmpty) {
              chatTitle = chatChars.map((c) => c.name).join(', ');
            }
            if (chat.summary != null && chat.summary!.isNotEmpty) {
              chatTitle += ' (${chat.summary})';
            }
            return DropdownMenuItem(
              value: chat.id,
              child: Text(
                chatTitle,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedChatId = val;
            });
          },
        ),
        const SizedBox(height: 16),
        if (selectedChat != null) ...[
          Text(
            '会话摘要与背景：',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              selectedChat.summary ?? '此会话暂无摘要。',
              style: theme.textTheme.bodyMedium,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ] else
          const Expanded(
            child: Center(
              child: Text('选择一个会话以预览其属性'),
            ),
          ),
      ],
    );
  }

  Widget _buildResultPanel(BuildContext context, ExtractorState state, ThemeData theme) {
    if (state.status == ExtractorStatus.initial ||
        (state.status == ExtractorStatus.loading && state.extractedCharacters.isEmpty)) {
      return Center(
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
                Icons.psychology,
                size: 64,
                color: theme.colorScheme.primary.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '等待设定分析...',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '在左侧配置提取源，点击“开始分析提取”后此处将显示分析结果',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    if (state.extractedCharacters.isEmpty && state.extractedEntries.isEmpty) {
      return const Center(
        child: Text('没有检测到任何设定或角色，请尝试更换输入文本。'),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 提取到的角色
              if (_charNameControllers.isNotEmpty) ...[
                Text(
                  'AI 识别的角色卡设定',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...List.generate(_charNameControllers.length, (idx) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _selectedCharacters[idx]
                            ? theme.colorScheme.primary.withValues(alpha: 0.3)
                            : theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('导入此角色卡', style: TextStyle(fontWeight: FontWeight.bold)),
                            value: _selectedCharacters[idx],
                            onChanged: (val) {
                              setState(() {
                                _selectedCharacters[idx] = val ?? false;
                              });
                            },
                          ),
                          const Divider(),
                          TextField(
                            controller: _charNameControllers[idx],
                            decoration: const InputDecoration(labelText: '角色名称'),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _charDescControllers[idx],
                            maxLines: 3,
                            decoration: const InputDecoration(labelText: '性格背景人设描述'),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _charGreetingControllers[idx],
                            decoration: const InputDecoration(labelText: '初始开场白'),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const Divider(),
                const SizedBox(height: 16),
              ],

              // 提取到的百科设定
              if (_entryNameControllers.isNotEmpty) ...[
                Text(
                  'AI 识别的世界观百科条目',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...List.generate(_entryNameControllers.length, (idx) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _selectedEntries[idx]
                            ? theme.colorScheme.primary.withValues(alpha: 0.3)
                            : theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('导入此词条', style: TextStyle(fontWeight: FontWeight.bold)),
                            value: _selectedEntries[idx],
                            onChanged: (val) {
                              setState(() {
                                _selectedEntries[idx] = val ?? false;
                              });
                            },
                          ),
                          const Divider(),
                          TextField(
                            controller: _entryNameControllers[idx],
                            decoration: const InputDecoration(labelText: '词条名称'),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _entryKeywordsControllers[idx],
                            decoration: const InputDecoration(
                              labelText: '触发关键字 (逗号分隔)',
                              hintText: '例：星能, 赤碧金',
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _entryContentControllers[idx],
                            maxLines: 4,
                            decoration: const InputDecoration(labelText: '设定百科详情'),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _entryCategories[idx],
                            decoration: const InputDecoration(labelText: '设定分类'),
                            items: const [
                              DropdownMenuItem(value: 'general', child: Text('常规设定')),
                              DropdownMenuItem(value: 'character', child: Text('角色状态')),
                              DropdownMenuItem(value: 'location', child: Text('地点环境')),
                              DropdownMenuItem(value: 'event', child: Text('事件伏笔')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _entryCategories[idx] = val;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
        _buildImportOptionsFooter(context, state, theme),
      ],
    );
  }

  Widget _buildImportOptionsFooter(BuildContext context, ExtractorState state, ThemeData theme) {
    final hasSelectedEntries = _selectedEntries.contains(true);
    final hasSelectedChars = _selectedCharacters.contains(true);

    if (!hasSelectedEntries && !hasSelectedChars) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
        ),
        child: const Center(
          child: Text('请先勾选需要导入的角色或世界观条目'),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasSelectedEntries) ...[
            SwitchListTile(
              title: const Text('为此提取新建世界书'),
              subtitle: Text(_createNewWorldBook ? '导入至新创建的世界书' : '导入至现有的世界书'),
              value: _createNewWorldBook,
              onChanged: (val) {
                setState(() {
                  _createNewWorldBook = val;
                });
              },
            ),
            const SizedBox(height: 8),
            if (_createNewWorldBook)
              TextField(
                controller: _newWorldBookNameController,
                decoration: const InputDecoration(
                  labelText: '新建世界书名称 *',
                  hintText: '输入新书的名字，例：阿瓦隆世界设定',
                  isDense: true,
                ),
              )
            else
              DropdownButtonFormField<String>(
                initialValue: _destinationWorldBookId,
                hint: const Text('选择目标世界书...'),
                decoration: const InputDecoration(
                  labelText: '选择世界书',
                  isDense: true,
                ),
                items: state.worldBooks.map((wb) {
                  return DropdownMenuItem(value: wb.id, child: Text(wb.name));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _destinationWorldBookId = val;
                  });
                },
              ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                final List<Map<String, String>> finalChars = [];
                for (int i = 0; i < _charNameControllers.length; i++) {
                  if (_selectedCharacters[i]) {
                    finalChars.add({
                      'name': _charNameControllers[i].text.trim(),
                      'description': _charDescControllers[i].text.trim(),
                      'greeting': _charGreetingControllers[i].text.trim(),
                    });
                  }
                }

                final List<Map<String, dynamic>> finalEntries = [];
                for (int i = 0; i < _entryNameControllers.length; i++) {
                  if (_selectedEntries[i]) {
                    final kwList = _entryKeywordsControllers[i]
                        .text
                        .split(',')
                        .map((k) => k.trim())
                        .where((k) => k.isNotEmpty)
                        .toList();

                    finalEntries.add({
                      'name': _entryNameControllers[i].text.trim(),
                      'keywords': kwList,
                      'content': _entryContentControllers[i].text.trim(),
                      'category': _entryCategories[i],
                    });
                  }
                }

                final destinationBookName = _createNewWorldBook 
                    ? _newWorldBookNameController.text.trim()
                    : null;

                if (_createNewWorldBook && (destinationBookName == null || destinationBookName.isEmpty)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请输入新建世界书名称')),
                  );
                  return;
                }

                if (!_createNewWorldBook && hasSelectedEntries && _destinationWorldBookId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请选择已有世界书进行导入')),
                  );
                  return;
                }

                context.read<ExtractorBloc>().add(
                      ImportSelectedEntitiesEvent(
                        characters: finalChars,
                        entries: finalEntries,
                        destinationWorldBookId: _createNewWorldBook ? null : _destinationWorldBookId,
                        newWorldBookName: destinationBookName,
                      ),
                    );
              },
              icon: const Icon(Icons.file_download_outlined),
              label: const Text('导入所选角色与设定百科'),
            ),
          ),
        ],
      ),
    );
  }
}
