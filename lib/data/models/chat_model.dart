import '../../domain/entities/chat.dart';

class ChatModel {
  static Chat fromMap(Map<String, dynamic> map) {
    return Chat(
      id: map['id'] as String,
      characterId: map['character_id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  static Map<String, dynamic> toMap(Chat chat) {
    return {
      'id': chat.id,
      'character_id': chat.characterId,
      'created_at': chat.createdAt.toIso8601String(),
      'updated_at': chat.updatedAt.toIso8601String(),
    };
  }
}
