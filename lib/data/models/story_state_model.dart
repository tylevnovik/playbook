import '../../domain/entities/story_state.dart';

class StoryStateModel {
  static StoryState fromMap(Map<String, dynamic> map) {
    final categoryName = map['category'] as String;
    final category = StoryStateCategory.values.firstWhere(
      (c) => c.name == categoryName,
      orElse: () => StoryStateCategory.event,
    );

    return StoryState(
      id: map['id'] as String,
      chatId: map['chat_id'] as String,
      category: category,
      targetId: map['target_id'] as String?,
      content: map['content'] as String,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  static Map<String, dynamic> toMap(StoryState state) {
    return {
      'id': state.id,
      'chat_id': state.chatId,
      'category': state.category.name,
      'target_id': state.targetId,
      'content': state.content,
      'is_active': state.isActive ? 1 : 0,
      'updated_at': state.updatedAt.toIso8601String(),
    };
  }
}
