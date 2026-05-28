import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../domain/entities/message.dart';
import '../../../../domain/repositories/settings_repository.dart';
import '../../../../domain/repositories/llm_repository.dart';
import '../../../../core/di/injection.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';

class WorldviewExtractorDialog extends StatefulWidget {
  final ChatLoaded chatState;
  final ChatBloc chatBloc;

  const WorldviewExtractorDialog({
    super.key,
    required this.chatState,
    required this.chatBloc,
  });

  @override
  State<WorldviewExtractorDialog> createState() => _WorldviewExtractorDialogState();
}

class _WorldviewExtractorDialogState extends State<WorldviewExtractorDialog> {
  final _textController = TextEditingController();
  bool _isLoading = false;
  bool _isAnalyzed = false;

  List<Map<String, String>> _extractedCharacters = [];
  List<Map<String, dynamic>> _extractedEntries = [];

  List<bool> _selectedCharacters = [];
  List<bool> _selectedEntries = [];

  String? _errorMessage;

  Future<void> _runExtraction() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isAnalyzed = false;
    });

    try {
      final configResult = await getIt<SettingsRepository>().getDefaultLlmConfig();
      await configResult.fold(
        (failure) {
          setState(() {
            _isLoading = false;
            _errorMessage = '获取大模型配置失败: ${failure.message}';
          });
        },
        (config) async {
          final systemPrompt = '''You are a world-building assistant. Your task is to analyze the provided background settings text and extract key character profiles and world book entry settings.
Return the result in a valid JSON format.
JSON Schema:
{
  "characters": [
    {
      "name": "Character Name",
      "description": "Short description of character background, personality, and appearance",
      "greeting": "A starting greeting message in-character"
    }
  ],
  "world_book_entries": [
    {
      "name": "Entry Name (e.g. magic system name, city name, key concept)",
      "keywords": ["keyword1", "keyword2"],
      "content": "Detailed explanation of this setting",
      "category": "general|character|location|event"
    }
  ]
}
Return ONLY valid JSON. Do not include any markdown fences or conversational explanations.''';

          final responseResult = await getIt<LlmRepository>().sendMessage(
            messages: [
              Message(
                id: 'system',
                chatId: '',
                role: MessageRole.system,
                content: systemPrompt,
                createdAt: DateTime.now(),
              ),
              Message(
                id: 'user',
                chatId: '',
                role: MessageRole.user,
                content: text,
                createdAt: DateTime.now(),
              ),
            ],
            config: config,
          );

          responseResult.fold(
            (failure) {
              setState(() {
                _isLoading = false;
                _errorMessage = '提取失败: ${failure.message}';
              });
            },
            (responseContent) {
              try {
                String cleaned = responseContent.trim();
                if (cleaned.startsWith('```')) {
                  final lines = cleaned.split('\n');
                  if (lines.first.startsWith('```')) {
                    lines.removeAt(0);
                  }
                  if (lines.isNotEmpty && lines.last.startsWith('```')) {
                    lines.removeLast();
                  }
                  cleaned = lines.join('\n').trim();
                }

                final Map<String, dynamic> parsed = jsonDecode(cleaned);
                final List<dynamic> charsList = parsed['characters'] ?? [];
                final List<dynamic> entriesList = parsed['world_book_entries'] ?? [];

                final characters = charsList.map((item) {
                  return {
                    'name': (item['name'] ?? '').toString(),
                    'description': (item['description'] ?? '').toString(),
                    'greeting': (item['greeting'] ?? '').toString(),
                  };
                }).toList();

                final entries = entriesList.map((item) {
                  return {
                    'name': (item['name'] ?? '').toString(),
                    'keywords': List<String>.from(item['keywords'] ?? []),
                    'content': (item['content'] ?? '').toString(),
                    'category': (item['category'] ?? 'general').toString(),
                  };
                }).toList();

                setState(() {
                  _isLoading = false;
                  _isAnalyzed = true;
                  _extractedCharacters = characters;
                  _extractedEntries = entries;
                  _selectedCharacters = List.filled(characters.length, true);
                  _selectedEntries = List.filled(entries.length, true);
                });
              } catch (e) {
                setState(() {
                  _isLoading = false;
                  _errorMessage = '解析 JSON 响应失败，请重试。原始响应：\n$responseContent';
                });
              }
            },
          );
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '提取时发生未知错误: $e';
      });
    }
  }

  void _importSelected() {
    final List<Map<String, String>> finalCharacters = [];
    for (int i = 0; i < _extractedCharacters.length; i++) {
      if (_selectedCharacters[i]) {
        finalCharacters.add(_extractedCharacters[i]);
      }
    }

    final List<Map<String, dynamic>> finalEntries = [];
    for (int i = 0; i < _extractedEntries.length; i++) {
      if (_selectedEntries[i]) {
        finalEntries.add(_extractedEntries[i]);
      }
    }

    if (finalCharacters.isEmpty && finalEntries.isEmpty) {
      Navigator.pop(context);
      return;
    }

    widget.chatBloc.add(
      ImportExtractedEntities(
        characters: finalCharacters,
        entries: finalEntries,
      ),
    );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('成功导入 ${finalCharacters.length} 个角色和 ${finalEntries.length} 条世界书设定！'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.psychology, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('AI 自动提取设定'),
        ],
      ),
      content: SizedBox(
        width: 600,
        height: 500,
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('AI 正在分析文本并提取实体...'),
                  ],
                ),
              )
            : _isAnalyzed
                ? _buildPreviewScreen(theme)
                : _buildInputScreen(theme),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        if (_isAnalyzed) ...[
          TextButton(
            onPressed: () {
              setState(() {
                _isAnalyzed = false;
              });
            },
            child: const Text('重新输入'),
          ),
          ElevatedButton(
            onPressed: _importSelected,
            child: const Text('导入所选'),
          ),
        ] else
          ElevatedButton(
            onPressed: _runExtraction,
            child: const Text('开始分析'),
          ),
      ],
    );
  }

  Widget _buildInputScreen(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '请在下方粘贴大段故事背景、世界观、人物设定等文字，AI 将自动从中识别提取角色卡及世界书词条。',
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: TextField(
            controller: _textController,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              hintText: '在这里粘贴背景文本...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerLow,
            ),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildPreviewScreen(ThemeData theme) {
    return ListView(
      children: [
        if (_extractedCharacters.isNotEmpty) ...[
          Text('检测到的角色', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _extractedCharacters.length,
            itemBuilder: (context, idx) {
              final char = _extractedCharacters[idx];
              return CheckboxListTile(
                value: _selectedCharacters[idx],
                title: Text(char['name'] ?? ''),
                subtitle: Text(char['description'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                onChanged: (val) {
                  setState(() {
                    _selectedCharacters[idx] = val ?? false;
                  });
                },
              );
            },
          ),
          const Divider(),
        ],
        if (_extractedEntries.isNotEmpty) ...[
          Text('检测到的世界设定', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _extractedEntries.length,
            itemBuilder: (context, idx) {
              final entry = _extractedEntries[idx];
              return CheckboxListTile(
                value: _selectedEntries[idx],
                title: Text(entry['name'] ?? ''),
                subtitle: Text(entry['content'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                onChanged: (val) {
                  setState(() {
                    _selectedEntries[idx] = val ?? false;
                  });
                },
              );
            },
          ),
        ],
        if (_extractedCharacters.isEmpty && _extractedEntries.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text('没有检测到任何设定或角色，请尝试更换输入文本。'),
            ),
          ),
      ],
    );
  }
}
