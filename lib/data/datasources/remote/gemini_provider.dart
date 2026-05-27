import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../domain/entities/message.dart';
import '../../../domain/entities/llm_config.dart';
import 'llm_provider.dart';

class GeminiProvider implements LlmProvider {
  final Dio _dio;

  GeminiProvider({Dio? dio}) : _dio = dio ?? Dio();

  @override
  Future<ChatResponse> sendMessage({
    required List<Message> messages,
    required LlmConfig config,
    List<MessageAttachment>? attachments,
  }) async {
    final response = await _dio.post(
      'https://generativelanguage.googleapis.com/v1beta/models/${config.model}:generateContent?key=${config.apiKey}',
      options: Options(headers: {'Content-Type': 'application/json'}),
      data: jsonEncode(_buildRequest(messages, config, attachments)),
    );

    final data = response.data;
    return ChatResponse(
      content: data['candidates'][0]['content']['parts'][0]['text'] as String,
      tokensUsed: data['usageMetadata']?['totalTokenCount'] as int?,
    );
  }

  @override
  Stream<ChatChunk> streamMessage({
    required List<Message> messages,
    required LlmConfig config,
    List<MessageAttachment>? attachments,
  }) async* {
    final response = await _dio.post(
      'https://generativelanguage.googleapis.com/v1beta/models/${config.model}:streamGenerateContent?key=${config.apiKey}',
      options: Options(
        headers: {'Content-Type': 'application/json'},
        responseType: ResponseType.stream,
      ),
      data: jsonEncode(_buildRequest(messages, config, attachments)),
    );

    final stream = response.data.stream as Stream<List<int>>;
    String buffer = '';

    await for (final chunk in stream) {
      buffer += utf8.decode(chunk);
      // Gemini streams JSON arrays
      if (buffer.contains('}')) {
        try {
          final json = jsonDecode(buffer);
          buffer = '';
          if (json is List && json.isNotEmpty) {
            final text = json.last['candidates']?[0]?['content']?['parts']?[0]?['text'];
            if (text != null) {
              yield ChatChunk(content: text as String);
            }
          }
        } catch (_) {}
      }
    }
    yield const ChatChunk(content: '', isDone: true);
  }

  Map<String, dynamic> _buildRequest(
    List<Message> messages,
    LlmConfig config,
    List<MessageAttachment>? attachments,
  ) {
    final contents = <Map<String, dynamic>>[];
    String? systemInstruction;

    for (final msg in messages) {
      if (msg.role == MessageRole.system) {
        systemInstruction = msg.content;
      } else {
        final parts = <Map<String, dynamic>>[{'text': msg.content}];
        
        if (attachments != null && attachments.isNotEmpty && msg.role == MessageRole.user) {
          for (final a in attachments) {
            parts.add({
              'inline_data': {
                'mime_type': a.mimeType,
                'data': a.path,
              },
            });
          }
        }

        contents.add({
          'role': msg.role == MessageRole.user ? 'user' : 'model',
          'parts': parts,
        });
      }
    }

    final request = <String, dynamic>{
      'contents': contents,
      'generationConfig': {
        'temperature': config.temperature,
        'maxOutputTokens': config.maxTokens,
      },
    };

    if (systemInstruction != null) {
      request['systemInstruction'] = {'parts': [{'text': systemInstruction}]};
    }

    return request;
  }
}
