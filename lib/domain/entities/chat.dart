import 'package:equatable/equatable.dart';

class Chat extends Equatable {
  final String id;
  final List<String> characterIds;
  final List<String> worldBookIds;
  final String? summary;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Chat({
    required this.id,
    required this.characterIds,
    required this.worldBookIds,
    this.summary,
    required this.createdAt,
    required this.updatedAt,
  });

  Chat copyWith({
    List<String>? characterIds,
    List<String>? worldBookIds,
    String? summary,
    DateTime? updatedAt,
  }) {
    return Chat(
      id: id,
      characterIds: characterIds ?? this.characterIds,
      worldBookIds: worldBookIds ?? this.worldBookIds,
      summary: summary ?? this.summary,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, characterIds, worldBookIds, summary];
}
