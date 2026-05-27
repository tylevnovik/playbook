import '../../../domain/entities/message.dart';
import '../../../domain/entities/llm_config.dart';

class ChatResponse {
  final String content;
  final int? tokensUsed;
  
  const ChatResponse({required this.content, this.tokensUsed});
}

class ChatChunk {
  final String content;
  final bool isDone;
  
  const ChatChunk({required this.content, this.isDone = false});
}

abstract class LlmProvider {
  Future<ChatResponse> sendMessage({
    required List<Message> messages,
    required LlmConfig config,
    List<MessageAttachment>? attachments,
  });

  Stream<ChatChunk> streamMessage({
    required List<Message> messages,
    required LlmConfig config,
    List<MessageAttachment>? attachments,
  });
}
