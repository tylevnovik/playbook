import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/utils/id_generator.dart';
import '../../../domain/entities/chat.dart';
import '../../../domain/entities/message.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../datasources/local/chat_dao.dart';
import '../datasources/local/message_dao.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatDao _chatDao;
  final MessageDao _messageDao;

  ChatRepositoryImpl(this._chatDao, this._messageDao);

  @override
  Future<Either<Failure, Chat>> getChat(String id) async {
    try {
      final map = await _chatDao.getById(id);
      if (map == null) return const Left(DatabaseFailure('Chat not found'));
      return Right(ChatModel.fromMap(map));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateChat(Chat chat) async {
    try {
      await _chatDao.update(chat.id, ChatModel.toMap(chat));
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Chat>>> getAllChats() async {
    try {
      final maps = await _chatDao.getAll();
      return Right(maps.map(ChatModel.fromMap).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Chat>>> getChatsForCharacter(String characterId) async {
    try {
      final maps = await _chatDao.getByCharacterId(characterId);
      return Right(maps.map(ChatModel.fromMap).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Chat>> createChat({
    required List<String> characterIds,
    List<String> worldBookIds = const [],
  }) async {
    try {
      final now = DateTime.now();
      final chat = Chat(
        id: IdGenerator.generate(),
        characterIds: characterIds,
        worldBookIds: worldBookIds,
        createdAt: now,
        updatedAt: now,
      );
      await _chatDao.insert(ChatModel.toMap(chat));
      return Right(chat);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteChat(String id) async {
    try {
      await _chatDao.delete(id);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Message>>> getMessages(String chatId) async {
    try {
      final maps = await _messageDao.getByChatId(chatId);
      return Right(maps.map(MessageModel.fromMap).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Message>> getMessage(String id) async {
    try {
      final map = await _messageDao.getById(id);
      if (map == null) return const Left(DatabaseFailure('Message not found'));
      return Right(MessageModel.fromMap(map));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Message>> saveMessage(Message message) async {
    try {
      final map = await _messageDao.getById(message.id);
      if (map == null) {
        await _messageDao.insert(MessageModel.toMap(message));
      } else {
        await _messageDao.update(message.id, MessageModel.toMap(message));
      }
      
      // Update chat updatedAt timestamp
      final chatMap = await _chatDao.getById(message.chatId);
      if (chatMap != null) {
        final chat = ChatModel.fromMap(chatMap);
        final updatedChat = chat.copyWith(updatedAt: DateTime.now());
        await _chatDao.update(chat.id, ChatModel.toMap(updatedChat));
      }
      
      return Right(message);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Message>>> getBranchMessages(String chatId, String? leafMessageId) async {
    try {
      final maps = await _messageDao.getBranch(chatId, leafMessageId);
      return Right(maps.map(MessageModel.fromMap).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Message>>> getMessageBranches(String chatId, String parentId) async {
    try {
      final maps = await _messageDao.getChildren(parentId);
      return Right(maps.map(MessageModel.fromMap).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
