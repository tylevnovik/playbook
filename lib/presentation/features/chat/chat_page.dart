import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injection.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/entities/message.dart';
import '../../../domain/usecases/load_character.dart';
import '../../../domain/usecases/manage_chat.dart';
import '../../../domain/usecases/send_message.dart';
import '../../common/widgets/desktop_character_sidebar.dart';
import '../../common/widgets/responsive_layout.dart';
import '../../common/widgets/error_dialog.dart';
import 'bloc/chat_bloc.dart';
import 'bloc/chat_event.dart';
import 'bloc/chat_state.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/chat_input.dart';
import 'widgets/chat_drawer.dart';

class ChatPage extends StatefulWidget {
  final String characterId;
  final String? chatId;

  const ChatPage({super.key, required this.characterId, this.chatId});

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
      )..add(LoadChat(characterId: widget.characterId, chatId: widget.chatId)),
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
                    characterId: widget.characterId,
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
      final character = state.character;
      final messages = state.messages;

      return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              if (character.avatarPath != null &&
                  character.avatarPath!.isNotEmpty) ...[
                CircleAvatar(
                  backgroundImage: NetworkImage(character.avatarPath!),
                  radius: 18,
                ),
                const SizedBox(width: 8),
              ],
              Text(character.name),
            ],
          ),
          actions: [
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
          initialSystemPrompt: _systemPromptOverride ?? character.systemPrompt,
          onSettingsChanged: (temp, maxT, prompt) {
            setState(() {
              _temperature = temp;
              _maxTokens = maxT;
              _systemPromptOverride = prompt;
            });
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
                        final parentId = msg.parentId;
                        int branchCount = 1;
                        int currentBranchIndex = 0;
                        if (parentId != null) {
                          final siblings = state.branches[parentId] ?? [];
                          branchCount = siblings.length;
                          currentBranchIndex = siblings.indexWhere(
                            (m) => m.id == msg.id,
                          );
                          if (currentBranchIndex == -1) currentBranchIndex = 0;
                        }

                        return ChatBubble(
                          message: msg,
                          characterName: character.name,
                          characterAvatar: character.avatarPath,
                          branchCount: branchCount,
                          currentBranchIndex: currentBranchIndex,
                          onPreviousBranch: () {
                            context.read<ChatBloc>().add(
                              SwitchToSiblingBranch(msg.id, next: false),
                            );
                          },
                          onNextBranch: () {
                            context.read<ChatBloc>().add(
                              SwitchToSiblingBranch(msg.id, next: true),
                            );
                          },
                        );
                      },
                    ),
            ),
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
          DesktopCharacterSidebar(selectedCharacterId: widget.characterId),
          const Expanded(child: Center(child: CircularProgressIndicator())),
        ],
      );
    }

    if (state is ChatError) {
      return Row(
        children: [
          DesktopCharacterSidebar(selectedCharacterId: widget.characterId),
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
      final character = state.character;
      final messages = state.messages;

      return Row(
        children: [
          DesktopCharacterSidebar(selectedCharacterId: widget.characterId),
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: Row(
                  children: [
                    if (character.avatarPath != null &&
                        character.avatarPath!.isNotEmpty) ...[
                      CircleAvatar(
                        backgroundImage: NetworkImage(character.avatarPath!),
                        radius: 18,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(character.name),
                  ],
                ),
                actions: [
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
                    _systemPromptOverride ?? character.systemPrompt,
                onSettingsChanged: (temp, maxT, prompt) {
                  setState(() {
                    _temperature = temp;
                    _maxTokens = maxT;
                    _systemPromptOverride = prompt;
                  });
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
                              final parentId = msg.parentId;
                              int branchCount = 1;
                              int currentBranchIndex = 0;
                              if (parentId != null) {
                                final siblings = state.branches[parentId] ?? [];
                                branchCount = siblings.length;
                                currentBranchIndex = siblings.indexWhere(
                                  (m) => m.id == msg.id,
                                );
                                if (currentBranchIndex == -1) {
                                  currentBranchIndex = 0;
                                }
                              }

                              return ChatBubble(
                                message: msg,
                                characterName: character.name,
                                characterAvatar: character.avatarPath,
                                branchCount: branchCount,
                                currentBranchIndex: currentBranchIndex,
                                onPreviousBranch: () {
                                  context.read<ChatBloc>().add(
                                    SwitchToSiblingBranch(msg.id, next: false),
                                  );
                                },
                                onNextBranch: () {
                                  context.read<ChatBloc>().add(
                                    SwitchToSiblingBranch(msg.id, next: true),
                                  );
                                },
                              );
                            },
                          ),
                  ),
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
        DesktopCharacterSidebar(selectedCharacterId: widget.characterId),
        Expanded(child: Center(child: Text(loc.get('loading')))),
      ],
    );
  }
}
