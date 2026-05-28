import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/chat.dart';
import '../entities/message.dart';

abstract class ChatRepository {
  Future<Either<Failure, Chat>> getChat(String id);
  Future<Either<Failure, void>> updateChat(Chat chat);
  Future<Either<Failure, List<Chat>>> getAllChats();
  Future<Either<Failure, List<Chat>>> getChatsForCharacter(String characterId);
  Future<Either<Failure, Chat>> createChat({
    required List<String> characterIds,
    List<String> worldBookIds = const [],
  });
  Future<Either<Failure, void>> deleteChat(String id);
  Future<Either<Failure, List<Message>>> getMessages(String chatId);
  Future<Either<Failure, Message>> getMessage(String id);
  Future<Either<Failure, Message>> saveMessage(Message message);
  Future<Either<Failure, List<Message>>> getBranchMessages(String chatId, String? leafMessageId);
  Future<Either<Failure, List<Message>>> getMessageBranches(String chatId, String parentId);
  Future<Either<Failure, void>> toggleMessageCanon(String messageId, bool isCanon);
}
