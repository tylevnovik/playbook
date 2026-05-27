import 'package:equatable/equatable.dart';

class Chat extends Equatable {
  final String id;
  final String characterId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Chat({
    required this.id,
    required this.characterId,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, characterId];
}
