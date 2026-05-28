import 'package:equatable/equatable.dart';
import '../../../../domain/entities/world_book.dart';
import '../../../../domain/entities/chat.dart';
import '../../../../domain/entities/character.dart';

enum ExtractorStatus { initial, loading, success, error, importSuccess }

class ExtractorState extends Equatable {
  final ExtractorStatus status;
  final List<WorldBook> worldBooks;
  final List<Chat> chats;
  final List<Character> allCharacters;
  final List<Map<String, String>> extractedCharacters;
  final List<Map<String, dynamic>> extractedEntries;
  final String? errorMessage;
  final String? extractionProgressMessage;

  const ExtractorState({
    this.status = ExtractorStatus.initial,
    this.worldBooks = const [],
    this.chats = const [],
    this.allCharacters = const [],
    this.extractedCharacters = const [],
    this.extractedEntries = const [],
    this.errorMessage,
    this.extractionProgressMessage,
  });

  ExtractorState copyWith({
    ExtractorStatus? status,
    List<WorldBook>? worldBooks,
    List<Chat>? chats,
    List<Character>? allCharacters,
    List<Map<String, String>>? extractedCharacters,
    List<Map<String, dynamic>>? extractedEntries,
    String? errorMessage,
    String? extractionProgressMessage,
  }) {
    return ExtractorState(
      status: status ?? this.status,
      worldBooks: worldBooks ?? this.worldBooks,
      chats: chats ?? this.chats,
      allCharacters: allCharacters ?? this.allCharacters,
      extractedCharacters: extractedCharacters ?? this.extractedCharacters,
      extractedEntries: extractedEntries ?? this.extractedEntries,
      errorMessage: errorMessage ?? this.errorMessage,
      extractionProgressMessage: extractionProgressMessage ?? this.extractionProgressMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        worldBooks,
        chats,
        allCharacters,
        extractedCharacters,
        extractedEntries,
        errorMessage,
        extractionProgressMessage,
      ];
}
