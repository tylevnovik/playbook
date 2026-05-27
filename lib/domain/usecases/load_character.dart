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

  Future<Either<Failure, (Chat, List<Character>)>> call(String chatId) async {
    final chatResult = await chatRepository.getChat(chatId);
    return await chatResult.fold(
      (failure) => Left(failure),
      (chat) async {
        final List<Character> characters = [];
        for (final charId in chat.characterIds) {
          final charResult = await characterRepository.getCharacter(charId);
          charResult.fold(
            (_) => null,
            (char) => characters.add(char),
          );
        }
        return Right((chat, characters));
      },
    );
  }
}
