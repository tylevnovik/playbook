import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:collection/collection.dart';
import '../../../../domain/entities/message.dart';
import '../../../../domain/entities/character.dart';

class ChatBubble extends StatefulWidget {
  final Message message;
  final String characterName;
  final String? characterAvatar;
  final int branchCount;
  final int currentBranchIndex;
  final VoidCallback? onPreviousBranch;
  final VoidCallback? onNextBranch;
  final VoidCallback? onToggleCanon;
  final Function(String newContent)? onEditMessage;
  final Function(String selectedText, String instruction, String? senderId)? onRewrite;
  final Function(String selectedText)? onExtractToWorldBook;
  final List<Character> availableCharacters;
  final String username;

  const ChatBubble({
    super.key,
    required this.message,
    required this.characterName,
    this.characterAvatar,
    this.branchCount = 1,
    this.currentBranchIndex = 0,
    this.onPreviousBranch,
    this.onNextBranch,
    this.onToggleCanon,
    this.onEditMessage,
    this.onRewrite,
    this.onExtractToWorldBook,
    this.availableCharacters = const [],
    this.username = 'User',
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  bool _isEditing = false;
  late TextEditingController _controller;
  String _selectedText = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.message.content);
  }

  @override
  void didUpdateWidget(covariant ChatBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.content != widget.message.content) {
      _controller.text = widget.message.content;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _showRewriteDialog(BuildContext context, String selectedText) {
    if (widget.availableCharacters.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('以特定角色视角重写'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: widget.availableCharacters.map((char) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: char.avatarPath != null && char.avatarPath!.isNotEmpty
                        ? NetworkImage(char.avatarPath!)
                        : null,
                    child: char.avatarPath == null || char.avatarPath!.isEmpty
                        ? Text(char.name.isNotEmpty ? char.name[0].toUpperCase() : '?')
                        : null,
                  ),
                  title: Text(char.name),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onRewrite?.call(
                      selectedText,
                      '以 ${char.name} 的视角重写这一段故事',
                      char.id,
                    );
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = widget.message.role == MessageRole.user;
    final isSystem = widget.message.role == MessageRole.system;
    final isDm = widget.message.senderId == 'dm';

    if (isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.message.content,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (isDm) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isEditing)
              _buildEditField(theme)
            else
              SelectionArea(
                onSelectionChanged: (value) {
                  setState(() {
                    _selectedText = value?.plainText ?? '';
                  });
                },
                contextMenuBuilder: _buildContextMenu,
                child: MarkdownBody(
                  data: widget.message.content,
                  styleSheet: MarkdownStyleSheet(
                    p: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                      fontStyle: FontStyle.italic,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.branchCount > 1) ...[
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.chevron_left, size: 14),
                      onPressed: widget.currentBranchIndex > 0 ? widget.onPreviousBranch : null,
                    ),
                    Text(
                      '${widget.currentBranchIndex + 1}/${widget.branchCount}',
                      style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                    ),
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.chevron_right, size: 14),
                      onPressed: widget.currentBranchIndex < widget.branchCount - 1 ? widget.onNextBranch : null,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    _formatTime(widget.message.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      widget.message.isCanon ? Icons.push_pin : Icons.push_pin_outlined,
                      size: 12,
                      color: widget.message.isCanon ? Colors.amber[700] : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    ),
                    onPressed: widget.onToggleCanon,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 12,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    ),
                    onPressed: () {
                      setState(() {
                        _isEditing = true;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final senderChar = widget.availableCharacters.firstWhereOrNull((c) => c.id == widget.message.senderId);
    final String displayName;
    final String? displayAvatar;
    final bool isUserImpersonating = isUser && widget.message.senderId != null;

    if (senderChar != null) {
      displayName = isUserImpersonating ? '${senderChar.name} (扮演)' : senderChar.name;
      displayAvatar = senderChar.avatarPath;
    } else {
      if (isUser) {
        displayName = widget.username;
        displayAvatar = null;
      } else {
        displayName = widget.characterName;
        displayAvatar = widget.characterAvatar;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage: displayAvatar != null && displayAvatar.isNotEmpty
                  ? NetworkImage(displayAvatar)
                  : null,
              child: displayAvatar == null || displayAvatar.isEmpty
                  ? Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                      style: theme.textTheme.labelMedium,
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 2, left: 4, right: 4),
                  child: Text(
                    displayName,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isUser
                          ? (isUserImpersonating ? theme.colorScheme.secondary : theme.colorScheme.tertiary)
                          : theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_isEditing)
                  _buildEditField(theme)
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? (isUserImpersonating ? theme.colorScheme.secondaryContainer : theme.colorScheme.primaryContainer)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SelectionArea(
                      onSelectionChanged: (value) {
                        setState(() {
                          _selectedText = value?.plainText ?? '';
                        });
                      },
                      contextMenuBuilder: _buildContextMenu,
                      child: MarkdownBody(
                        data: widget.message.content,
                        styleSheet: MarkdownStyleSheet(
                          p: theme.textTheme.bodyMedium?.copyWith(
                            color: isUser
                                ? (isUserImpersonating ? theme.colorScheme.onSecondaryContainer : theme.colorScheme.onPrimaryContainer)
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.branchCount > 1) ...[
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.chevron_left, size: 16),
                          onPressed: widget.currentBranchIndex > 0 ? widget.onPreviousBranch : null,
                        ),
                        Text(
                          '${widget.currentBranchIndex + 1}/${widget.branchCount}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.chevron_right, size: 16),
                          onPressed: widget.currentBranchIndex < widget.branchCount - 1 ? widget.onNextBranch : null,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        _formatTime(widget.message.createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          widget.message.isCanon ? Icons.push_pin : Icons.push_pin_outlined,
                          size: 14,
                          color: widget.message.isCanon ? Colors.amber[700] : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                        ),
                        tooltip: widget.message.isCanon ? '锁定为主线' : '锁定为主线',
                        onPressed: widget.onToggleCanon,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                        ),
                        tooltip: '编辑消息',
                        onPressed: () {
                          setState(() {
                            _isEditing = true;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: displayAvatar != null && displayAvatar.isNotEmpty
                  ? null
                  : theme.colorScheme.tertiaryContainer,
              backgroundImage: displayAvatar != null && displayAvatar.isNotEmpty
                  ? NetworkImage(displayAvatar)
                  : null,
              child: displayAvatar == null || displayAvatar.isEmpty
                  ? Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                    )
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditField(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: _controller,
            maxLines: null,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: '编辑消息...',
            ),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                    _controller.text = widget.message.content;
                  });
                },
                child: const Text('取消'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  if (_controller.text.trim().isNotEmpty) {
                    widget.onEditMessage?.call(_controller.text.trim());
                  }
                  setState(() {
                    _isEditing = false;
                  });
                },
                child: const Text('保存'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContextMenu(BuildContext context, SelectableRegionState regionState) {
    final buttonItems = regionState.contextMenuButtonItems;
    if (_selectedText.isEmpty) {
      return AdaptiveTextSelectionToolbar.buttonItems(
        anchors: regionState.contextMenuAnchors,
        buttonItems: buttonItems,
      );
    }
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: regionState.contextMenuAnchors,
      buttonItems: [
        ...buttonItems,
        if (widget.availableCharacters.isNotEmpty)
          ContextMenuButtonItem(
            label: '以视角重写',
            onPressed: () {
              ContextMenuController.removeAny();
              _showRewriteDialog(context, _selectedText);
            },
          ),
        ContextMenuButtonItem(
          label: '局部续写',
          onPressed: () {
            ContextMenuController.removeAny();
            widget.onRewrite?.call(_selectedText, '续写', null);
          },
        ),
        ContextMenuButtonItem(
          label: '转入世界书',
          onPressed: () {
            ContextMenuController.removeAny();
            widget.onExtractToWorldBook?.call(_selectedText);
          },
        ),
      ],
    );
  }
}
