import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/message.dart';
import '../../../domain/entities/llm_config.dart';
import 'llm_provider.dart';

class OpenAiProvider implements LlmProvider {
  final Dio _dio;

  OpenAiProvider({Dio? dio}) : _dio = dio ?? Dio();

  @override
  Future<ChatResponse> sendMessage({
    required List<Message> messages,
    required LlmConfig config,
    List<MessageAttachment>? attachments,
  }) async {
    final response = await _dio.post(
      _joinVersionedPath(_baseUrl(config), '/v1/chat/completions'),
      options: Options(
        headers: {
          'Authorization': 'Bearer ${config.apiKey}',
          'Content-Type': 'application/json',
        },
      ),
      data: jsonEncode({
        'model': config.model,
        'messages': _formatMessages(messages, attachments),
        'temperature': config.temperature,
        'max_tokens': config.maxTokens,
      }),
    );

    final data = response.data;
    return ChatResponse(
      content: data['choices'][0]['message']['content'] as String,
      tokensUsed: data['usage']?['total_tokens'] as int?,
    );
  }

  @override
  Stream<ChatChunk> streamMessage({
    required List<Message> messages,
    required LlmConfig config,
    List<MessageAttachment>? attachments,
  }) async* {
    final response = await _dio.post(
      _joinVersionedPath(_baseUrl(config), '/v1/chat/completions'),
      options: Options(
        headers: {
          'Authorization': 'Bearer ${config.apiKey}',
          'Content-Type': 'application/json',
        },
        responseType: ResponseType.stream,
      ),
      data: jsonEncode({
        'model': config.model,
        'messages': _formatMessages(messages, attachments),
        'temperature': config.temperature,
        'max_tokens': config.maxTokens,
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
          if (data == '[DONE]') {
            yield const ChatChunk(content: '', isDone: true);
            return;
          }
          try {
            final json = jsonDecode(data);
            final delta = json['choices'][0]['delta'];
            if (delta != null && delta['content'] != null) {
              yield ChatChunk(content: delta['content'] as String);
            }
          } catch (_) {}
        }
      }
    }
  }

  List<Map<String, dynamic>> _formatMessages(
    List<Message> messages,
    List<MessageAttachment>? attachments,
  ) {
    return messages.map((m) {
      final msg = <String, dynamic>{
        'role': m.role.name,
        'content':
            m.role == MessageRole.user &&
                attachments != null &&
                attachments.isNotEmpty
            ? [
                {'type': 'text', 'text': m.content},
                ...attachments.map(
                  (a) => {
                    'type': 'image_url',
                    'image_url': {'url': 'data:${a.mimeType};base64,${a.path}'},
                  },
                ),
              ]
            : m.content,
      };
      return msg;
    }).toList();
  }

  String _baseUrl(LlmConfig config) {
    final value = config.baseUrl?.trim();
    if (value == null || value.isEmpty) {
      return AppConstants.defaultOpenaiBaseUrl;
    }
    return value;
  }

  String _joinVersionedPath(String baseUrl, String path) {
    final normalized = baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    if (normalized.endsWith('/v1') && path.startsWith('/v1/')) {
      return '$normalized${path.substring(3)}';
    }
    return '$normalized$path';
  }
}
