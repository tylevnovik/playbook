import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/character.dart';
import '../entities/chat.dart';
import '../repositories/character_repository.dart';
import '../repositories/chat_repository.dart';

class LoadCharacter {
  final CharacterRepository characterRepository;
  final ChatRepository chatRepository;

  LoadCharacter({
    required this.characterRepository,
    required this.chatRepository,
  });

  Future<Either<Failure, (Character, List<Chat>)>> call(String characterId) async {
    final charResult = await characterRepository.getCharacter(characterId);
    return charResult.fold(
      (failure) => Left(failure),
      (character) async {
        final chatsResult = await chatRepository.getChatsForCharacter(characterId);
        return chatsResult.fold(
          (failure) => Left(failure),
          (chats) => Right((character, chats)),
        );
      },
    );
  }
}
