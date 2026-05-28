import 'package:equatable/equatable.dart';

enum StoryStateCategory {
  character,
  location,
  event,
  relationship,
  taboo,
  style,
}

class StoryState extends Equatable {
  final String id;
  final String chatId;
  final StoryStateCategory category;
  final String? targetId;
  final String content;
  final bool isActive;
  final DateTime updatedAt;

  const StoryState({
    required this.id,
    required this.chatId,
    required this.category,
    this.targetId,
    required this.content,
    this.isActive = true,
    required this.updatedAt,
  });

  StoryState copyWith({
    StoryStateCategory? category,
    String? targetId,
    String? content,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return StoryState(
      id: id,
      chatId: chatId,
      category: category ?? this.category,
      targetId: targetId ?? this.targetId,
      content: content ?? this.content,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        chatId,
        category,
        targetId,
        content,
        isActive,
        updatedAt,
      ];
}
