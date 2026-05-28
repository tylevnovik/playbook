import 'package:equatable/equatable.dart';
import '../../../../domain/entities/message.dart';
import '../../../../domain/entities/story_state.dart';

abstract class ChatEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadChat extends ChatEvent {
  final String chatId;
  LoadChat({required this.chatId});
  @override
  List<Object?> get props => [chatId];
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

class UpdateChatCharacters extends ChatEvent {
  final List<String> characterIds;
  UpdateChatCharacters(this.characterIds);
  @override
  List<Object?> get props => [characterIds];
}

class UpdateChatWorldBooks extends ChatEvent {
  final List<String> worldBookIds;
  UpdateChatWorldBooks(this.worldBookIds);
  @override
  List<Object?> get props => [worldBookIds];
}

class SetActiveCharacter extends ChatEvent {
  final String characterId;
  SetActiveCharacter(this.characterId);
  @override
  List<Object?> get props => [characterId];
}

class AddStoryState extends ChatEvent {
  final StoryStateCategory category;
  final String? targetId;
  final String content;
  AddStoryState({required this.category, this.targetId, required this.content});
  @override
  List<Object?> get props => [category, targetId, content];
}

class UpdateStoryStateEvent extends ChatEvent {
  final StoryState state;
  UpdateStoryStateEvent(this.state);
  @override
  List<Object?> get props => [state];
}

class DeleteStoryStateEvent extends ChatEvent {
  final String id;
  DeleteStoryStateEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class ToggleMessageCanon extends ChatEvent {
  final String messageId;
  final bool isCanon;
  ToggleMessageCanon({required this.messageId, required this.isCanon});
  @override
  List<Object?> get props => [messageId, isCanon];
}

class EditMessage extends ChatEvent {
  final String messageId;
  final String newContent;
  EditMessage({required this.messageId, required this.newContent});
  @override
  List<Object?> get props => [messageId, newContent];
}

class RewriteMessage extends ChatEvent {
  final String messageId;
  final String selectedText;
  final String instruction; // e.g. "以 X 视角重写" or "续写"
  final String? senderId;
  RewriteMessage({
    required this.messageId,
    required this.selectedText,
    required this.instruction,
    this.senderId,
  });
  @override
  List<Object?> get props => [messageId, selectedText, instruction, senderId];
}

class ImportExtractedEntities extends ChatEvent {
  final List<Map<String, String>> characters; // Name, Description, Greeting
  final List<Map<String, dynamic>> entries; // Name, Keywords, Content, Category
  ImportExtractedEntities({required this.characters, required this.entries});
  @override
  List<Object?> get props => [characters, entries];
}
