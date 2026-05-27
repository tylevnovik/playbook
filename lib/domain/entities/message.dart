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
    this.senderId,
  });

  @override
  List<Object?> get props => [id, chatId, parentId, role, content, senderId];
}
