import 'package:equatable/equatable.dart';
import '../../../../domain/entities/message.dart';

abstract class ChatEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadChat extends ChatEvent {
  final String characterId;
  final String? chatId;
  LoadChat({required this.characterId, this.chatId});
  @override
  List<Object?> get props => [characterId, chatId];
}

class SendChatMessage extends ChatEvent {
  final String content;
  final List<MessageAttachment>? attachments;
  SendChatMessage(this.content, {this.attachments});
  @override
  List<Object?> get props => [content, attachments];
}

class SwitchChatBranch extends ChatEvent {
  final String? leafMessageId;
  SwitchChatBranch(this.leafMessageId);
  @override
  List<Object?> get props => [leafMessageId];
}

class SwitchToSiblingBranch extends ChatEvent {
  final String messageId;
  final bool next; // true = next sibling, false = previous sibling
  SwitchToSiblingBranch(this.messageId, {required this.next});
  @override
  List<Object?> get props => [messageId, next];
}
