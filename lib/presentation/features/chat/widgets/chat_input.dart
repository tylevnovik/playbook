import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:collection/collection.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../domain/entities/character.dart';

class ChatInput extends StatefulWidget {
  final Function(String, List<String>, String?) onSend;
  final bool isSending;
  final List<Character> allAvailableCharacters;
  final String username;

  const ChatInput({
    super.key,
    required this.onSend,
    this.isSending = false,
    this.allAvailableCharacters = const [],
    this.username = 'User',
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _controller = TextEditingController();
  final List<String> _selectedAttachmentPaths = [];
  late final FocusNode _focusNode;

  // Speaking identity state: null = User, 'dm' = DM, or character.id
  String? _selectedSenderId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(onKeyEvent: (node, event) {
      if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
        if (HardwareKeyboard.instance.isShiftPressed) {
          return KeyEventResult.ignored;
        } else {
          _handleSend();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedAttachmentPaths.add(image.path);
      });
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _selectedAttachmentPaths.removeAt(index);
    });
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isNotEmpty || _selectedAttachmentPaths.isNotEmpty) {
      widget.onSend(text, List.from(_selectedAttachmentPaths), _selectedSenderId);
      _controller.clear();
      setState(() {
        _selectedAttachmentPaths.clear();
      });
    }
  }

  void _showIdentityPicker(BuildContext context) {
    final theme = Theme.of(context);
    _searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final List<Character> filteredCharacters = widget.allAvailableCharacters
                .where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    c.description.toLowerCase().contains(_searchQuery.toLowerCase()))
                .toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.65,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Column(
                    children: [
                      // Handle bar
                      Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: Row(
                          children: [
                            Text(
                              '选择发言身份 (套皮)',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Search bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: '搜索角色库...',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          onChanged: (val) {
                            setModalState(() {
                              _searchQuery = val;
                            });
                          },
                        ),
                      ),
                      const Divider(height: 1),
                      // Options list
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            // 1. User Option
                            _buildIdentityTile(
                              title: '${widget.username} (默认用户)',
                              subtitle: '使用设置中的用户名以普通玩家身份发言',
                              isSelected: _selectedSenderId == null,
                              icon: Icons.person_outline,
                              color: theme.colorScheme.primary,
                              onTap: () {
                                setState(() {
                                  _selectedSenderId = null;
                                });
                                Navigator.pop(context);
                              },
                              theme: theme,
                            ),
                            // 2. DM Option
                            _buildIdentityTile(
                              title: '旁白 (DM)',
                              subtitle: '扮演主持人/旁白进行场景描写、推动环境与剧情变化',
                              isSelected: _selectedSenderId == 'dm',
                              icon: Icons.auto_stories_outlined,
                              color: Colors.amber[800]!,
                              onTap: () {
                                setState(() {
                                  _selectedSenderId = 'dm';
                                });
                                Navigator.pop(context);
                              },
                              theme: theme,
                            ),
                            // Divider
                            if (filteredCharacters.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                child: Text(
                                  '角色库中的皮',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                              ...filteredCharacters.map((char) {
                                final isSelected = _selectedSenderId == char.id;
                                return _buildIdentityTile(
                                  title: char.name,
                                  subtitle: char.description,
                                  avatarUrl: char.avatarPath,
                                  isSelected: isSelected,
                                  onTap: () {
                                    setState(() {
                                      _selectedSenderId = char.id;
                                    });
                                    Navigator.pop(context);
                                  },
                                  theme: theme,
                                );
                              }),
                            ],
                            if (filteredCharacters.isEmpty && _searchQuery.isNotEmpty)
                              const Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Center(
                                  child: Text('没有找到符合条件的皮', style: TextStyle(color: Colors.grey)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildIdentityTile({
    required String title,
    required String subtitle,
    IconData? icon,
    String? avatarUrl,
    Color? color,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: color != null ? color.withValues(alpha: 0.15) : theme.colorScheme.surfaceContainerHighest,
        backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
        child: avatarUrl == null || avatarUrl.isEmpty
            ? Icon(icon ?? Icons.person, color: color ?? theme.colorScheme.onSurfaceVariant)
            : null,
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }

  Widget _buildCurrentIdentityAvatar(ThemeData theme) {
    // Resolve avatar and visual design based on current selected sender
    if (_selectedSenderId == null) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: theme.colorScheme.tertiaryContainer,
        child: Icon(
          Icons.person,
          size: 20,
          color: theme.colorScheme.onTertiaryContainer,
        ),
      );
    } else if (_selectedSenderId == 'dm') {
      return CircleAvatar(
        radius: 18,
        backgroundColor: Colors.amber[100],
        child: Icon(
          Icons.auto_stories,
          size: 20,
          color: Colors.amber[900],
        ),
      );
    } else {
      final char = widget.allAvailableCharacters.firstWhereOrNull((c) => c.id == _selectedSenderId);
      final avatarUrl = char?.avatarPath;
      final initials = char != null && char.name.isNotEmpty ? char.name[0].toUpperCase() : '?';
      return CircleAvatar(
        radius: 18,
        backgroundColor: theme.colorScheme.primaryContainer,
        backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
        child: avatarUrl == null || avatarUrl.isEmpty
            ? Text(
                initials,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Attachment list
        if (_selectedAttachmentPaths.isNotEmpty)
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedAttachmentPaths.length,
              itemBuilder: (context, index) {
                final path = _selectedAttachmentPaths[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Stack(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(path),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _removeAttachment(index),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

        // Input row
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              // Identity switcher (Premium skin wearer icon)
              InkWell(
                onTap: () => _showIdentityPicker(context),
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Tooltip(
                    message: '切换发言身份',
                    child: _buildCurrentIdentityAvatar(theme),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.add_photo_alternate_outlined),
                tooltip: loc.get('attachImage'),
                onPressed: widget.isSending ? null : _pickImage,
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: 4,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: _selectedSenderId == 'dm'
                        ? '以旁白视角描写场景/环境变化...'
                        : (_selectedSenderId != null
                            ? '扮演角色发言...'
                            : loc.get('typeMessage')),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                icon: widget.isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                onPressed: widget.isSending ? null : _handleSend,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
