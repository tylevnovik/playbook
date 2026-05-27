import '../../domain/entities/chat.dart';

class ChatModel {
  static Chat fromMap(Map<String, dynamic> map) {
    return Chat(
      id: map['id'] as String,
      characterIds: map['character_ids'] != null
          ? List<String>.from(map['character_ids'] as List)
          : [],
      worldBookIds: map['world_book_ids'] != null
          ? List<String>.from(map['world_book_ids'] as List)
          : [],
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  static Map<String, dynamic> toMap(Chat chat) {
    return {
      'id': chat.id,
      'character_ids': chat.characterIds,
      'world_book_ids': chat.worldBookIds,
      'created_at': chat.createdAt.toIso8601String(),
      'updated_at': chat.updatedAt.toIso8601String(),
    };
  }
}
