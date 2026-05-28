import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collection/collection.dart';
import '../../../core/di/injection.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/entities/message.dart';
import '../../../domain/usecases/load_character.dart';
import '../../../domain/usecases/manage_chat.dart';
import '../../../domain/usecases/send_message.dart';
import '../../../domain/repositories/story_state_repository.dart';
import '../../common/widgets/desktop_chat_sidebar.dart';
import '../../common/widgets/responsive_layout.dart';
import '../../common/widgets/error_dialog.dart';
import 'bloc/chat_bloc.dart';
import 'bloc/chat_event.dart';
import 'bloc/chat_state.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/chat_input.dart';
import 'widgets/chat_drawer.dart';
import 'widgets/worldview_extractor_dialog.dart';

class ChatPage extends StatefulWidget {
  final String chatId;

  const ChatPage({super.key, required this.chatId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _scrollController = ScrollController();

  double _temperature = 0.7;
  int _maxTokens = 1000;
  String? _systemPromptOverride;

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return BlocProvider(
      create: (context) => ChatBloc(
        loadCharacter: getIt<LoadCharacter>(),
        manageChat: getIt<ManageChat>(),
        sendMessage: getIt<SendMessage>(),
        storyStateRepository: getIt<StoryStateRepository>(),
      )..add(LoadChat(chatId: widget.chatId)),
      child: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is ChatLoaded) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _scrollToBottom(),
            );
          } else if (state is ChatError) {
            ErrorDialog.show(
              context,
              title: loc.get('generationFailed'),
              message: state.message,
              onRetry: () {
                context.read<ChatBloc>().add(
                  LoadChat(
                    chatId: widget.chatId,
                  ),
                );
              },
            );
          }
        },
        builder: (context, state) {
          return ResponsiveLayout(
            mobileBody: _buildMobileBody(context, state),
            desktopBody: _buildDesktopBody(context, state),
          );
        },
      ),
    );
  }

  Widget _buildMobileBody(BuildContext context, ChatState state) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    if (state is ChatLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (state is ChatError) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.get('error'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              state.message,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ),
      );
    }

    if (state is ChatLoaded) {
      final activeCharId = state.activeCharacterId;
      final activeChar = state.characters.firstWhereOrNull((c) => c.id == activeCharId) ??
          (state.characters.isNotEmpty ? state.characters.first : null);
      final messages = state.messages;

      return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              if (activeChar != null &&
                  activeChar.avatarPath != null &&
                  activeChar.avatarPath!.isNotEmpty) ...[
                CircleAvatar(
                  backgroundImage: NetworkImage(activeChar.avatarPath!),
                  radius: 18,
                ),
                const SizedBox(width: 8),
              ],
              Text(activeChar?.name ?? 'Chats'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.psychology),
              tooltip: 'AI 世界设定提取',
              onPressed: () => _showWorldviewExtractorDialog(context, state),
            ),
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.tune),
                tooltip: loc.get('chatSettings'),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
          ],
        ),
        endDrawer: ChatDrawer(
          initialTemperature: _temperature,
          initialMaxTokens: _maxTokens,
          initialSystemPrompt: _systemPromptOverride ?? activeChar?.systemPrompt,
          onSettingsChanged: (temp, maxT, prompt) {
            setState(() {
              _temperature = temp;
              _maxTokens = maxT;
              _systemPromptOverride = prompt;
            });
          },
          selectedCharacterIds: state.chat.characterIds,
          allAvailableCharacters: state.allAvailableCharacters,
          onCharactersChanged: (newIds) {
            context.read<ChatBloc>().add(UpdateChatCharacters(newIds));
          },
          selectedWorldBookIds: state.chat.worldBookIds,
          allAvailableWorldBooks: state.allAvailableWorldBooks,
          onWorldBooksChanged: (newIds) {
            context.read<ChatBloc>().add(UpdateChatWorldBooks(newIds));
          },
          storyStates: state.storyStates,
          onAddStoryState: (category, content) {
            context.read<ChatBloc>().add(AddStoryState(category: category, content: content));
          },
          onUpdateStoryState: (storyState) {
            context.read<ChatBloc>().add(UpdateStoryStateEvent(storyState));
          },
          onDeleteStoryState: (id) {
            context.read<ChatBloc>().add(DeleteStoryStateEvent(id));
          },
        ),
        body: Column(
          children: [
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Text(
                        loc.get('startChatting'),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        return _buildChatBubble(context, state, msg);
                      },
                    ),
            ),
            if (state.characters.length > 1) _buildCharacterSwitcher(context, state),
            ChatInput(
              isSending: state is ChatLoading,
              onSend: (text, attachments) {
                final attachmentEntities = attachments
                    .map(
                      (path) =>
                          MessageAttachment(path: path, mimeType: 'image/jpeg'),
                    )
                    .toList();
                context.read<ChatBloc>().add(
                  SendChatMessage(
                    text,
                    attachments: attachmentEntities.isEmpty
                        ? null
                        : attachmentEntities,
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    return Scaffold(body: Center(child: Text(loc.get('loading'))));
  }

  Widget _buildDesktopBody(BuildContext context, ChatState state) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    if (state is ChatLoading) {
      return Row(
        children: [
          DesktopChatSidebar(selectedChatId: widget.chatId),
          const Expanded(child: Center(child: CircularProgressIndicator())),
        ],
      );
    }

    if (state is ChatError) {
      return Row(
        children: [
          DesktopChatSidebar(selectedChatId: widget.chatId),
          Expanded(
            child: Scaffold(
              appBar: AppBar(title: Text(loc.get('error'))),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    state.message,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (state is ChatLoaded) {
      final activeCharId = state.activeCharacterId;
      final activeChar = state.characters.firstWhereOrNull((c) => c.id == activeCharId) ??
          (state.characters.isNotEmpty ? state.characters.first : null);
      final messages = state.messages;

      return Row(
        children: [
          DesktopChatSidebar(selectedChatId: widget.chatId),
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: Row(
                  children: [
                    if (activeChar != null &&
                        activeChar.avatarPath != null &&
                        activeChar.avatarPath!.isNotEmpty) ...[
                      CircleAvatar(
                        backgroundImage: NetworkImage(activeChar.avatarPath!),
                        radius: 18,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(activeChar?.name ?? 'Chats'),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.psychology),
                    tooltip: 'AI 世界设定提取',
                    onPressed: () => _showWorldviewExtractorDialog(context, state),
                  ),
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.tune),
                      tooltip: loc.get('chatSettings'),
                      onPressed: () => Scaffold.of(context).openEndDrawer(),
                    ),
                  ),
                ],
              ),
              endDrawer: ChatDrawer(
                initialTemperature: _temperature,
                initialMaxTokens: _maxTokens,
                initialSystemPrompt:
                    _systemPromptOverride ?? activeChar?.systemPrompt,
                onSettingsChanged: (temp, maxT, prompt) {
                  setState(() {
                    _temperature = temp;
                    _maxTokens = maxT;
                    _systemPromptOverride = prompt;
                  });
                },
                selectedCharacterIds: state.chat.characterIds,
                allAvailableCharacters: state.allAvailableCharacters,
                onCharactersChanged: (newIds) {
                  context.read<ChatBloc>().add(UpdateChatCharacters(newIds));
                },
                selectedWorldBookIds: state.chat.worldBookIds,
                allAvailableWorldBooks: state.allAvailableWorldBooks,
                onWorldBooksChanged: (newIds) {
                  context.read<ChatBloc>().add(UpdateChatWorldBooks(newIds));
                },
                storyStates: state.storyStates,
                onAddStoryState: (category, content) {
                  context.read<ChatBloc>().add(AddStoryState(category: category, content: content));
                },
                onUpdateStoryState: (storyState) {
                  context.read<ChatBloc>().add(UpdateStoryStateEvent(storyState));
                },
                onDeleteStoryState: (id) {
                  context.read<ChatBloc>().add(DeleteStoryStateEvent(id));
                },
              ),
              body: Column(
                children: [
                  Expanded(
                    child: messages.isEmpty
                        ? Center(
                            child: Text(
                              loc.get('startChatting'),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final msg = messages[index];
                              return _buildChatBubble(context, state, msg);
                            },
                          ),
                  ),
                  if (state.characters.length > 1) _buildCharacterSwitcher(context, state),
                  ChatInput(
                    isSending: state is ChatLoading,
                    onSend: (text, attachments) {
                      final attachmentEntities = attachments
                          .map(
                            (path) => MessageAttachment(
                              path: path,
                              mimeType: 'image/jpeg',
                            ),
                          )
                          .toList();
                      context.read<ChatBloc>().add(
                        SendChatMessage(
                          text,
                          attachments: attachmentEntities.isEmpty
                              ? null
                              : attachmentEntities,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        DesktopChatSidebar(selectedChatId: widget.chatId),
        Expanded(child: Center(child: Text(loc.get('loading')))),
      ],
    );
  }

  Widget _buildCharacterSwitcher(BuildContext context, ChatLoaded state) {
    final theme = Theme.of(context);
    final activeCharId = state.activeCharacterId;

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: state.characters.map((char) {
          final isSelected = char.id == activeCharId;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              avatar: CircleAvatar(
                backgroundImage: char.avatarPath != null && char.avatarPath!.isNotEmpty
                    ? NetworkImage(char.avatarPath!)
                    : null,
                child: char.avatarPath == null || char.avatarPath!.isEmpty
                    ? Text(char.name.isNotEmpty ? char.name[0].toUpperCase() : '?')
                    : null,
              ),
              label: Text(char.name),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  context.read<ChatBloc>().add(SetActiveCharacter(char.id));
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showWorldviewExtractorDialog(BuildContext context, ChatLoaded state) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return WorldviewExtractorDialog(
          chatState: state,
          chatBloc: context.read<ChatBloc>(),
        );
      },
    );
  }

  void _showExtractToWorldBookDialog(BuildContext context, ChatLoaded state, String text) {
    final nameController = TextEditingController(
      text: text.length > 20 ? '${text.substring(0, 17)}...' : text,
    );
    final keywordsController = TextEditingController();
    final contentController = TextEditingController(text: text);
    String category = 'general';
    String? selectedWbId = state.worldBooks.isNotEmpty ? state.worldBooks.first.id : null;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('提取到世界书'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: '条目名称'),
                ),
                TextField(
                  controller: keywordsController,
                  decoration: const InputDecoration(labelText: '触发关键字 (逗号分隔)'),
                ),
                TextField(
                  controller: contentController,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: '设定内容'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: '类别'),
                  items: const [
                    DropdownMenuItem(value: 'general', child: Text('常规设定')),
                    DropdownMenuItem(value: 'character', child: Text('角色状态')),
                    DropdownMenuItem(value: 'location', child: Text('地点环境')),
                    DropdownMenuItem(value: 'event', child: Text('事件伏笔')),
                  ],
                  onChanged: (val) {
                    if (val != null) category = val;
                  },
                ),
                if (state.worldBooks.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue: selectedWbId,
                    decoration: const InputDecoration(labelText: '选择世界书'),
                    items: state.worldBooks.map((wb) {
                      return DropdownMenuItem(value: wb.id, child: Text(wb.name));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) selectedWbId = val;
                    },
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      '未绑定世界书，保存后将自动为您创建一本新世界书并绑定。',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final entryName = nameController.text.trim();
                final entryContent = contentController.text.trim();
                final kwList = keywordsController.text
                    .split(',')
                    .map((k) => k.trim())
                    .where((k) => k.isNotEmpty)
                    .toList();

                if (entryName.isEmpty || entryContent.isEmpty) {
                  return;
                }

                Navigator.pop(dialogCtx);

                context.read<ChatBloc>().add(
                  ImportExtractedEntities(
                    characters: const [],
                    entries: [
                      {
                        'name': entryName,
                        'keywords': kwList,
                        'content': entryContent,
                        'category': category,
                        'priority': 0,
                      }
                    ],
                  ),
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('成功提取并保存至世界书')),
                );
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChatBubble(BuildContext context, ChatLoaded state, Message msg) {
    final parentId = msg.parentId;
    int branchCount = 1;
    int currentBranchIndex = 0;
    if (parentId != null) {
      final siblings = state.branches[parentId] ?? [];
      branchCount = siblings.length;
      currentBranchIndex = siblings.indexWhere((m) => m.id == msg.id);
      if (currentBranchIndex == -1) currentBranchIndex = 0;
    }

    final senderChar = state.characters.firstWhereOrNull((c) => c.id == msg.senderId) ??
        (state.characters.isNotEmpty ? state.characters.first : null);
    final charName = senderChar?.name ?? 'Assistant';
    final charAvatar = senderChar?.avatarPath;

    return ChatBubble(
      message: msg,
      characterName: charName,
      characterAvatar: charAvatar,
      branchCount: branchCount,
      currentBranchIndex: currentBranchIndex,
      availableCharacters: state.characters,
      onPreviousBranch: () {
        context.read<ChatBloc>().add(SwitchToSiblingBranch(msg.id, next: false));
      },
      onNextBranch: () {
        context.read<ChatBloc>().add(SwitchToSiblingBranch(msg.id, next: true));
      },
      onToggleCanon: () {
        context.read<ChatBloc>().add(ToggleMessageCanon(messageId: msg.id, isCanon: !msg.isCanon));
      },
      onEditMessage: (newContent) {
        context.read<ChatBloc>().add(EditMessage(messageId: msg.id, newContent: newContent));
      },
      onRewrite: (selectedText, instruction, senderId) {
        context.read<ChatBloc>().add(RewriteMessage(
          messageId: msg.id,
          selectedText: selectedText,
          instruction: instruction,
          senderId: senderId,
        ));
      },
      onExtractToWorldBook: (selectedText) {
        _showExtractToWorldBookDialog(context, state, selectedText);
      },
    );
  }
}
