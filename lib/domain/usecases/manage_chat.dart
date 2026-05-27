import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/chat.dart';
import '../entities/message.dart';
import '../repositories/chat_repository.dart';

class ManageChat {
  final ChatRepository repository;

  ManageChat({required this.repository});

  Future<Either<Failure, Chat>> createChat({
    required List<String> characterIds,
    List<String> worldBookIds = const [],
  }) {
    return repository.createChat(
      characterIds: characterIds,
      worldBookIds: worldBookIds,
    );
  }

  Future<Either<Failure, void>> deleteChat(String id) {
    return repository.deleteChat(id);
  }

  Future<Either<Failure, List<Message>>> getMessages(String chatId) {
    return repository.getMessages(chatId);
  }

  Future<Either<Failure, List<Message>>> switchBranch(String chatId, String? leafMessageId) {
    return repository.getBranchMessages(chatId, leafMessageId);
  }

  Future<Either<Failure, List<Message>>> getBranches(String chatId, String parentId) {
    return repository.getMessageBranches(chatId, parentId);
  }
}
