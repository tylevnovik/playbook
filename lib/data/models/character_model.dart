import 'dart:convert';
import '../../domain/entities/character.dart';

class CharacterModel {
  static Character fromMap(Map<String, dynamic> map) {
    return Character(
      id: map['id'] as String,
      name: map['name'] as String,
      avatarPath: map['avatar_path'] as String?,
      description: map['description'] as String,
      greeting: map['greeting'] as String,
      exampleMessages: map['example_messages'] as String?,
      systemPrompt: map['system_prompt'] as String?,
      tags: List<String>.from(jsonDecode(map['tags'] as String? ?? '[]')),
      worldBookId: map['world_book_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      lastChattedAt: map['last_chatted_at'] != null
          ? DateTime.parse(map['last_chatted_at'] as String)
          : null,
    );
  }

  static Map<String, dynamic> toMap(Character character) {
    return {
      'id': character.id,
      'name': character.name,
      'avatar_path': character.avatarPath,
      'description': character.description,
      'greeting': character.greeting,
      'example_messages': character.exampleMessages,
      'system_prompt': character.systemPrompt,
      'tags': jsonEncode(character.tags),
      'world_book_id': character.worldBookId,
      'created_at': character.createdAt.toIso8601String(),
      'updated_at': character.updatedAt.toIso8601String(),
      'last_chatted_at': character.lastChattedAt?.toIso8601String(),
    };
  }

  static String toJson(Character character) => jsonEncode(toMap(character));
  
  static Character fromJson(String json) => fromMap(jsonDecode(json));
}
