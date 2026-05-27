import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../domain/entities/message.dart';
import '../../../domain/entities/llm_config.dart';
import 'llm_provider.dart';

class AnthropicProvider implements LlmProvider {
  final Dio _dio;

  AnthropicProvider({Dio? dio}) : _dio = dio ?? Dio();

  @override
  Future<ChatResponse> sendMessage({
    required List<Message> messages,
    required LlmConfig config,
    List<MessageAttachment>? attachments,
  }) async {
    final formatted = _formatMessages(messages, attachments);
    
    final response = await _dio.post(
      'https://api.anthropic.com/v1/messages',
      options: Options(
        headers: {
          'x-api-key': config.apiKey,
          'anthropic-version': '2023-06-01',
          'Content-Type': 'application/json',
        },
      ),
      data: jsonEncode({
        'model': config.model,
        'max_tokens': config.maxTokens,
        'system': formatted.systemPrompt,
        'messages': formatted.messages,
      }),
    );

    final data = response.data;
    return ChatResponse(
      content: data['content'][0]['text'] as String,
      tokensUsed: (data['usage']?['input_tokens'] as int? ?? 0) +
          (data['usage']?['output_tokens'] as int? ?? 0),
    );
  }

  @override
  Stream<ChatChunk> streamMessage({
    required List<Message> messages,
    required LlmConfig config,
    List<MessageAttachment>? attachments,
  }) async* {
    final formatted = _formatMessages(messages, attachments);
    
    final response = await _dio.post(
      'https://api.anthropic.com/v1/messages',
      options: Options(
        headers: {
          'x-api-key': config.apiKey,
          'anthropic-version': '2023-06-01',
          'Content-Type': 'application/json',
        },
        responseType: ResponseType.stream,
      ),
      data: jsonEncode({
        'model': config.model,
        'max_tokens': config.maxTokens,
        'system': formatted.systemPrompt,
        'messages': formatted.messages,
        'stream': true,
      }),
    );

    final stream = response.data.stream as Stream<List<int>>;
    String buffer = '';

    await for (final chunk in stream) {
      buffer += utf8.decode(chunk);
      final lines = buffer.split('\n');
      buffer = lines.removeLast();

      for (final line in lines) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6).trim();
          try {
            final json = jsonDecode(data);
            if (json['type'] == 'content_block_delta') {
              yield ChatChunk(content: json['delta']['text'] as String);
            } else if (json['type'] == 'message_stop') {
              yield const ChatChunk(content: '', isDone: true);
              return;
            }
          } catch (_) {}
        }
      }
    }
  }

  _FormattedMessages _formatMessages(
    List<Message> messages,
    List<MessageAttachment>? attachments,
  ) {
    String? systemPrompt;
    final List<Map<String, dynamic>> formattedMessages = [];

    for (final msg in messages) {
      if (msg.role == MessageRole.system) {
        systemPrompt = msg.content;
      } else {
        formattedMessages.add({
          'role': msg.role.name,
          'content': msg.role == MessageRole.user && attachments != null && attachments.isNotEmpty
              ? [
                  {'type': 'text', 'text': msg.content},
                  ...attachments.map((a) => {
                    'type': 'image',
                    'source': {
                      'type': 'base64',
                      'media_type': a.mimeType,
                      'data': a.path,
                    },
                  }),
                ]
              : msg.content,
        });
      }
    }

    return _FormattedMessages(
      systemPrompt: systemPrompt ?? '',
      messages: formattedMessages,
    );
  }
}

class _FormattedMessages {
  final String systemPrompt;
  final List<Map<String, dynamic>> messages;
  
  const _FormattedMessages({required this.systemPrompt, required this.messages});
}
