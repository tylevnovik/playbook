import 'dart:convert';
import '../../domain/entities/message.dart';

class MessageModel {
  static Message fromMap(Map<String, dynamic> map) {
    List<MessageAttachment>? attachments;
    if (map['attachments'] != null) {
      final List<dynamic> list = jsonDecode(map['attachments'] as String);
      attachments = list.map((a) => MessageAttachment(
        path: a['path'] as String,
        mimeType: a['mime_type'] as String,
      )).toList();
    }

    return Message(
      id: map['id'] as String,
      chatId: map['chat_id'] as String,
      parentId: map['parent_id'] as String?,
      role: MessageRole.values.firstWhere((r) => r.name == map['role']),
      content: map['content'] as String,
      attachments: attachments,
      tokensUsed: map['tokens_used'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      senderId: map['sender_id'] as String?,
    );
  }

  static Map<String, dynamic> toMap(Message message) {
    return {
      'id': message.id,
      'chat_id': message.chatId,
      'parent_id': message.parentId,
      'role': message.role.name,
      'content': message.content,
      'attachments': message.attachments != null
          ? jsonEncode(message.attachments!.map((a) => {
              'path': a.path,
              'mime_type': a.mimeType,
            }).toList())
          : null,
      'tokens_used': message.tokensUsed,
      'created_at': message.createdAt.toIso8601String(),
      'sender_id': message.senderId,
    };
  }
}
