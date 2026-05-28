import 'package:equatable/equatable.dart';

enum MessageRole { user, assistant, system }

class MessageAttachment {
  final String path; // local file path or base64
  final String mimeType;
  
  const MessageAttachment({required this.path, required this.mimeType});
}

class Message extends Equatable {
  final String id;
  final String chatId;
  final String? parentId; // null = root, otherwise points to parent for tree structure
  final MessageRole role;
  final String content;
  final List<MessageAttachment>? attachments;
  final int? tokensUsed;
  final DateTime createdAt;
  final bool isCanon;
  final String? senderId;

  const Message({
    required this.id,
    required this.chatId,
    this.parentId,
    required this.role,
    required this.content,
    this.attachments,
    this.tokensUsed,
    required this.createdAt,
    this.isCanon = false,
    this.senderId,
  });

  Message copyWith({
    String? id,
    String? chatId,
    String? parentId,
    MessageRole? role,
    String? content,
    List<MessageAttachment>? attachments,
    int? tokensUsed,
    DateTime? createdAt,
    bool? isCanon,
    String? senderId,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      parentId: parentId ?? this.parentId,
      role: role ?? this.role,
      content: content ?? this.content,
      attachments: attachments ?? this.attachments,
      tokensUsed: tokensUsed ?? this.tokensUsed,
      createdAt: createdAt ?? this.createdAt,
      isCanon: isCanon ?? this.isCanon,
      senderId: senderId ?? this.senderId,
    );
  }

  @override
  List<Object?> get props => [id, chatId, parentId, role, content, isCanon, senderId];
}
