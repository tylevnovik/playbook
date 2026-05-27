import 'package:equatable/equatable.dart';

class WorldBook extends Equatable {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WorldBook({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, name];
}

class WorldBookEntry extends Equatable {
  final String id;
  final String worldBookId;
  final String name;
  final List<String> keywords;
  final String content;
  final String category;
  final int priority;
  final bool enabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WorldBookEntry({
    required this.id,
    required this.worldBookId,
    required this.name,
    required this.keywords,
    required this.content,
    this.category = 'general',
    this.priority = 0,
    this.enabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, worldBookId, name, keywords];
}
