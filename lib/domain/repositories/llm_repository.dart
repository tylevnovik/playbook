import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/message.dart';
import '../entities/llm_config.dart';

abstract class LlmRepository {
  Future<Either<Failure, String>> sendMessage({
    required List<Message> messages,
    required LlmConfig config,
    List<MessageAttachment>? attachments,
  });

  Stream<Either<Failure, String>> streamMessage({
    required List<Message> messages,
    required LlmConfig config,
    List<MessageAttachment>? attachments,
  });

  Future<Either<Failure, String>> summarize({
    required List<Message> messages,
    required LlmConfig config,
  });
}
