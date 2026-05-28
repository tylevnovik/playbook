import 'package:equatable/equatable.dart';

abstract class ExtractorEvent extends Equatable {
  const ExtractorEvent();

  @override
  List<Object?> get props => [];
}

class LoadExtractorInitialData extends ExtractorEvent {}

class ExtractFromTextEvent extends ExtractorEvent {
  final String text;

  const ExtractFromTextEvent(this.text);

  @override
  List<Object?> get props => [text];
}

class ExtractFromChatEvent extends ExtractorEvent {
  final String chatId;

  const ExtractFromChatEvent(this.chatId);

  @override
  List<Object?> get props => [chatId];
}

class ImportSelectedEntitiesEvent extends ExtractorEvent {
  final List<Map<String, String>> characters;
  final List<Map<String, dynamic>> entries;
  final String? destinationWorldBookId;
  final String? newWorldBookName;

  const ImportSelectedEntitiesEvent({
    required this.characters,
    required this.entries,
    this.destinationWorldBookId,
    this.newWorldBookName,
  });

  @override
  List<Object?> get props => [
        characters,
        entries,
        destinationWorldBookId,
        newWorldBookName,
      ];
}
