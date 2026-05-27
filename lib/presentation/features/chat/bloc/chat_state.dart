import 'package:equatable/equatable.dart';
import '../../../../domain/entities/character.dart';
import '../../../../domain/entities/chat.dart';
import '../../../../domain/entities/message.dart';
import '../../../../domain/entities/world_book.dart';

abstract class ChatState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}
class ChatLoading extends ChatState {}
class ChatLoaded extends ChatState {
  final List<Character> characters;
  final List<Character> allAvailableCharacters;
  final List<WorldBook> worldBooks;
  final List<WorldBook> allAvailableWorldBooks;
  final Chat chat;
  final List<Message> messages;
  final Map<String, List<Message>> branches; // Maps parentId to children
  final String? currentLeafMessageId;
  final String? activeCharacterId;

  ChatLoaded({
    required this.characters,
    required this.allAvailableCharacters,
    required this.worldBooks,
    required this.allAvailableWorldBooks,
    required this.chat,
    required this.messages,
    required this.branches,
    this.currentLeafMessageId,
    this.activeCharacterId,
  });

  ChatLoaded copyWith({
    List<Character>? characters,
    List<Character>? allAvailableCharacters,
    List<WorldBook>? worldBooks,
    List<WorldBook>? allAvailableWorldBooks,
    Chat? chat,
    List<Message>? messages,
    Map<String, List<Message>>? branches,
    String? currentLeafMessageId,
    String? activeCharacterId,
  }) {
    return ChatLoaded(
      characters: characters ?? this.characters,
      allAvailableCharacters: allAvailableCharacters ?? this.allAvailableCharacters,
      worldBooks: worldBooks ?? this.worldBooks,
      allAvailableWorldBooks: allAvailableWorldBooks ?? this.allAvailableWorldBooks,
      chat: chat ?? this.chat,
      messages: messages ?? this.messages,
      branches: branches ?? this.branches,
      currentLeafMessageId: currentLeafMessageId ?? this.currentLeafMessageId,
      activeCharacterId: activeCharacterId ?? this.activeCharacterId,
    );
  }

  @override
  List<Object?> get props => [
        characters,
        allAvailableCharacters,
        worldBooks,
        allAvailableWorldBooks,
        chat,
        messages,
        branches,
        currentLeafMessageId,
        activeCharacterId
      ];
}
class ChatError extends ChatState {
  final String message;
  ChatError(this.message);
  @override
  List<Object?> get props => [message];
}
