import 'package:equatable/equatable.dart';

class Character extends Equatable {
  final String id;
  final String name;
  final String? avatarPath;
  final String description;
  final String greeting;
  final String? exampleMessages;
  final String? systemPrompt;
  final List<String> tags;
  final String? worldBookId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastChattedAt;

  const Character({
    required this.id,
    required this.name,
    this.avatarPath,
    required this.description,
    required this.greeting,
    this.exampleMessages,
    this.systemPrompt,
    this.tags = const [],
    this.worldBookId,
    required this.createdAt,
    required this.updatedAt,
    this.lastChattedAt,
  });

  Character copyWith({
    String? name,
    String? avatarPath,
    String? description,
    String? greeting,
    String? exampleMessages,
    String? systemPrompt,
    List<String>? tags,
    String? worldBookId,
    DateTime? lastChattedAt,
  }) {
    return Character(
      id: id,
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
      description: description ?? this.description,
      greeting: greeting ?? this.greeting,
      exampleMessages: exampleMessages ?? this.exampleMessages,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      tags: tags ?? this.tags,
      worldBookId: worldBookId ?? this.worldBookId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      lastChattedAt: lastChattedAt ?? this.lastChattedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, description, greeting];
}
