import 'package:equatable/equatable.dart';

enum LlmProviderType { openai, anthropic, gemini }

class LlmConfig extends Equatable {
  final LlmProviderType providerType;
  final String apiKey;
  final String? baseUrl;
  final String model;
  final double temperature;
  final int maxTokens;
  final int contextWindow;

  const LlmConfig({
    required this.providerType,
    required this.apiKey,
    this.baseUrl,
    required this.model,
    this.temperature = 0.7,
    this.maxTokens = 1000,
    this.contextWindow = 8000,
  });

  @override
  List<Object?> get props => [providerType, model];
}
