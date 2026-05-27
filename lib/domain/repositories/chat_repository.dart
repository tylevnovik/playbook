import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/chat.dart';
import '../entities/message.dart';

abstract class ChatRepository {
  Future<Either<Failure, List<Chat>>> getChatsForCharacter(String characterId);
  Future<Either<Failure, Chat>> createChat(String characterId);
  Future<Either<Failure, void>> deleteChat(String id);
  Future<Either<Failure, List<Message>>> getMessages(String chatId);
  Future<Either<Failure, Message>> getMessage(String id);
  Future<Either<Failure, Message>> saveMessage(Message message);
  Future<Either<Failure, List<Message>>> getBranchMessages(String chatId, String? leafMessageId);
  Future<Either<Failure, List<Message>>> getMessageBranches(String chatId, String parentId);
}
