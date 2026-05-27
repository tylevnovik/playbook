import 'package:equatable/equatable.dart';
import '../../../../domain/entities/character.dart';
import '../../../../domain/entities/chat.dart';
import '../../../../domain/entities/message.dart';

abstract class ChatState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}
class ChatLoading extends ChatState {}
class ChatLoaded extends ChatState {
  final Character character;
  final Chat chat;
  final List<Message> messages;
  final Map<String, List<Message>> branches; // Maps parentId to children
  final String? currentLeafMessageId;

  ChatLoaded({
    required this.character,
    required this.chat,
    required this.messages,
    required this.branches,
    this.currentLeafMessageId,
  });

  ChatLoaded copyWith({
    List<Message>? messages,
    Map<String, List<Message>>? branches,
    String? currentLeafMessageId,
  }) {
    return ChatLoaded(
      character: character,
      chat: chat,
      messages: messages ?? this.messages,
      branches: branches ?? this.branches,
      currentLeafMessageId: currentLeafMessageId ?? this.currentLeafMessageId,
    );
  }

  @override
  List<Object?> get props => [character, chat, messages, branches, currentLeafMessageId];
}
class ChatError extends ChatState {
  final String message;
  ChatError(this.message);
  @override
  List<Object?> get props => [message];
}
