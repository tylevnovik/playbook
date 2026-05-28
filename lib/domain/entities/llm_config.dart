import 'package:equatable/equatable.dart';

enum LlmProviderType { openai, anthropic, gemini, mimo, tokenPlan, deepseek }

class LlmConfig extends Equatable {
  final String? providerId;
  final String? providerName;
  final LlmProviderType providerType;
  final String apiKey;
  final String? baseUrl;
  final String model;
  final double temperature;
  final int maxTokens;
  final int contextWindow;

  const LlmConfig({
    this.providerId,
    this.providerName,
    required this.providerType,
    required this.apiKey,
    this.baseUrl,
    required this.model,
    this.temperature = 0.7,
    this.maxTokens = 1000,
    this.contextWindow = 8000,
  });

  @override
  List<Object?> get props => [providerId, providerName, providerType, model];
}

class LlmProviderProfile extends Equatable {
  final String id;
  final String name;
  final LlmProviderType providerType;
  final String apiKey;
  final String baseUrl;
  final String model;
  final int contextWindow;
  final int maxTokens;
  final bool isBuiltIn;

  const LlmProviderProfile({
    required this.id,
    required this.name,
    required this.providerType,
    required this.apiKey,
    required this.baseUrl,
    required this.model,
    required this.contextWindow,
    required this.maxTokens,
    this.isBuiltIn = false,
  });

  LlmConfig toConfig() {
    return LlmConfig(
      providerId: id,
      providerName: name,
      providerType: providerType,
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model,
      contextWindow: contextWindow,
      maxTokens: maxTokens,
    );
  }

  LlmProviderProfile copyWith({
    String? id,
    String? name,
    LlmProviderType? providerType,
    String? apiKey,
    String? baseUrl,
    String? model,
    int? contextWindow,
    int? maxTokens,
    bool? isBuiltIn,
  }) {
    return LlmProviderProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      providerType: providerType ?? this.providerType,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      contextWindow: contextWindow ?? this.contextWindow,
      maxTokens: maxTokens ?? this.maxTokens,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'provider_type': providerType.name,
      'api_key': apiKey,
      'base_url': baseUrl,
      'model': model,
      'context_window': contextWindow,
      'max_tokens': maxTokens,
      'is_built_in': isBuiltIn,
    };
  }

  static LlmProviderProfile fromJson(Map<String, dynamic> json) {
    final typeName = json['provider_type'] as String? ?? 'openai';
    final type = LlmProviderType.values.firstWhere(
      (item) => item.name == typeName,
      orElse: () => LlmProviderType.openai,
    );

    return LlmProviderProfile(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Provider',
      providerType: type,
      apiKey: json['api_key'] as String? ?? '',
      baseUrl: json['base_url'] as String? ?? '',
      model: json['model'] as String? ?? '',
      contextWindow: json['context_window'] as int? ?? 8000,
      maxTokens: json['max_tokens'] as int? ?? 1000,
      isBuiltIn: json['is_built_in'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    providerType,
    apiKey,
    baseUrl,
    model,
    contextWindow,
    maxTokens,
    isBuiltIn,
  ];
}
