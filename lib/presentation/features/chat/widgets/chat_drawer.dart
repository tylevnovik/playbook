import 'package:flutter/material.dart';
import '../../../../domain/entities/character.dart';
import '../../../../domain/entities/world_book.dart';

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
          ],
        ),
      ),
    );
  }
}
