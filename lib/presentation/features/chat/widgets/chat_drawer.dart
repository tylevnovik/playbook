import 'package:flutter/material.dart';
import '../../../../domain/entities/character.dart';
import '../../../../domain/entities/world_book.dart';
import '../../../../domain/entities/story_state.dart';

class ChatDrawer extends StatefulWidget {
  final double initialTemperature;
  final int initialMaxTokens;
  final String? initialSystemPrompt;
  final Function(double, int, String?) onSettingsChanged;
  
  final List<String> selectedCharacterIds;
  final List<Character> allAvailableCharacters;
  final Function(List<String>) onCharactersChanged;

  final List<String> selectedWorldBookIds;
  final List<WorldBook> allAvailableWorldBooks;
  final Function(List<String>) onWorldBooksChanged;

  final List<StoryState> storyStates;
  final Function(StoryStateCategory, String) onAddStoryState;
  final Function(StoryState) onUpdateStoryState;
  final Function(String) onDeleteStoryState;

  const ChatDrawer({
    super.key,
    required this.initialTemperature,
    required this.initialMaxTokens,
    this.initialSystemPrompt,
    required this.onSettingsChanged,
    required this.selectedCharacterIds,
    required this.allAvailableCharacters,
    required this.onCharactersChanged,
    required this.selectedWorldBookIds,
    required this.allAvailableWorldBooks,
    required this.onWorldBooksChanged,
    required this.storyStates,
    required this.onAddStoryState,
    required this.onUpdateStoryState,
    required this.onDeleteStoryState,
  });

  @override
  State<ChatDrawer> createState() => _ChatDrawerState();
}

class _ChatDrawerState extends State<ChatDrawer> {
  late double _temperature;
  late int _maxTokens;
  final _promptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _temperature = widget.initialTemperature;
    _maxTokens = widget.initialMaxTokens;
    _promptController.text = widget.initialSystemPrompt ?? '';
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _triggerChanged() {
    widget.onSettingsChanged(_temperature, _maxTokens, _promptController.text.trim().isEmpty ? null : _promptController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Text(
              'Session Configuration',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Temperature slider
            Text(
              'Temperature: ${_temperature.toStringAsFixed(1)}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Slider(
              value: _temperature,
              min: 0.0,
              max: 2.0,
              divisions: 20,
              label: _temperature.toStringAsFixed(1),
              onChanged: (val) {
                setState(() {
                  _temperature = val;
                });
                _triggerChanged();
              },
            ),
            Text(
              'Lower values are more focused/deterministic, higher values are more creative/random.',
              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),

            // Max Tokens
            Text(
              'Max Response Tokens: $_maxTokens',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _maxTokens.toDouble(),
                    min: 100,
                    max: 4000,
                    divisions: 39,
                    label: '$_maxTokens',
                    onChanged: (val) {
                      setState(() {
                        _maxTokens = val.toInt();
                      });
                      _triggerChanged();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // System prompt override
            Text(
              'System Instruction Override',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _promptController,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'e.g. Speak like a pirate...',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _triggerChanged(),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),

            // Select characters
            Text(
              '会话参与角色',
              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...widget.allAvailableCharacters.map((char) {
              final isSelected = widget.selectedCharacterIds.contains(char.id);
              return CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(char.name),
                value: isSelected,
                secondary: CircleAvatar(
                  radius: 16,
                  backgroundImage: char.avatarPath != null && char.avatarPath!.isNotEmpty
                      ? NetworkImage(char.avatarPath!)
                      : null,
                  child: char.avatarPath == null || char.avatarPath!.isEmpty
                      ? Text(char.name.isNotEmpty ? char.name[0].toUpperCase() : '?')
                      : null,
                ),
                onChanged: (val) {
                  final newIds = List<String>.from(widget.selectedCharacterIds);
                  if (val == true) {
                    newIds.add(char.id);
                  } else {
                    // 确保至少保留一个角色（可选，如果可以空就不限制）
                    newIds.remove(char.id);
                  }
                  widget.onCharactersChanged(newIds);
                },
              );
            }),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),

            // Select world books
            Text(
              '会话关联世界书',
              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            widget.allAvailableWorldBooks.isEmpty
                ? Text(
                    '无可用世界书',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  )
                : Column(
                    children: widget.allAvailableWorldBooks.map((wb) {
                      final isSelected = widget.selectedWorldBookIds.contains(wb.id);
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(wb.name),
                        subtitle: wb.description != null && wb.description!.isNotEmpty
                            ? Text(wb.description!, maxLines: 1, overflow: TextOverflow.ellipsis)
                            : null,
                        value: isSelected,
                        onChanged: (val) {
                          final newIds = List<String>.from(widget.selectedWorldBookIds);
                          if (val == true) {
                            newIds.add(wb.id);
                          } else {
                            newIds.remove(wb.id);
                          }
                          widget.onWorldBooksChanged(newIds);
                        },
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '故事状态与追踪',
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: '添加故事状态',
                  onPressed: () => _showAddStoryStateDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            widget.storyStates.isEmpty
                ? Text(
                    '暂无故事状态/约束设定',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  )
                : Column(
                    children: widget.storyStates.map((state) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Chip(
                                    label: Text(
                                      _categoryLabel(state.category),
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  const Spacer(),
                                  Switch(
                                    value: state.isActive,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    onChanged: (val) {
                                      widget.onUpdateStoryState(state.copyWith(isActive: val));
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 16),
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => _showEditStoryStateDialog(context, state),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 16),
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => widget.onDeleteStoryState(state.id),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
                                child: Text(
                                  state.content,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    decoration: state.isActive ? null : TextDecoration.lineThrough,
                                    color: state.isActive ? null : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  String _categoryLabel(StoryStateCategory cat) {
    switch (cat) {
      case StoryStateCategory.character:
        return '人物状态';
      case StoryStateCategory.location:
        return '地点状态';
      case StoryStateCategory.event:
        return '事件/伏笔';
      case StoryStateCategory.relationship:
        return '角色关系';
      case StoryStateCategory.taboo:
        return '写作禁忌';
      case StoryStateCategory.style:
        return '风格约束';
    }
  }

  void _showAddStoryStateDialog(BuildContext context) {
    StoryStateCategory selectedCategory = StoryStateCategory.event;
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('添加故事状态/线索'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<StoryStateCategory>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(labelText: '状态类别'),
                    items: StoryStateCategory.values.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(_categoryLabel(cat)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedCategory = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: '状态描述 / 规则约束',
                      border: OutlineInputBorder(),
                      hintText: '描述具体线索、角色现状、伏笔、或 AI 生成时的写作禁忌。',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () {
                    final text = contentController.text.trim();
                    if (text.isNotEmpty) {
                      widget.onAddStoryState(selectedCategory, text);
                    }
                    Navigator.pop(ctx);
                  },
                  child: const Text('添加'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditStoryStateDialog(BuildContext context, StoryState state) {
    StoryStateCategory selectedCategory = state.category;
    final contentController = TextEditingController(text: state.content);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('编辑故事状态/线索'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<StoryStateCategory>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(labelText: '状态类别'),
                    items: StoryStateCategory.values.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(_categoryLabel(cat)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedCategory = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: '状态描述 / 规则约束',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () {
                    final text = contentController.text.trim();
                    if (text.isNotEmpty) {
                      widget.onUpdateStoryState(
                        state.copyWith(
                          category: selectedCategory,
                          content: text,
                        ),
                      );
                    }
                    Navigator.pop(ctx);
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
