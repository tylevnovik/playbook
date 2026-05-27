import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../data/services/api_diagnostics_service.dart';
import '../../../../domain/repositories/settings_repository.dart';
import '../../../../domain/entities/llm_config.dart';
import '../../../../core/constants/app_constants.dart';

// Events
abstract class SettingsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadSettings extends SettingsEvent {}

class UpdateStringSetting extends SettingsEvent {
  final String key;
  final String value;
  UpdateStringSetting({required this.key, required this.value});
  @override
  List<Object?> get props => [key, value];
}

class UpdateProviderSetting extends SettingsEvent {
  final LlmProviderType type;
  UpdateProviderSetting(this.type);
  @override
  List<Object?> get props => [type];
}

class TestProviderConnection extends SettingsEvent {
  final LlmProviderType type;
  TestProviderConnection(this.type);
  @override
  List<Object?> get props => [type];
}

class DiscoverProviderModels extends SettingsEvent {
  final LlmProviderType type;
  DiscoverProviderModels(this.type);
  @override
  List<Object?> get props => [type];
}

// States
abstract class SettingsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class ProviderDiagnostics extends Equatable {
  final bool isTesting;
  final bool isDiscovering;
  final bool? connectionOk;
  final String? connectionMessage;
  final bool? discoveryOk;
  final String? discoveryMessage;
  final List<String> models;

  const ProviderDiagnostics({
    this.isTesting = false,
    this.isDiscovering = false,
    this.connectionOk,
    this.connectionMessage,
    this.discoveryOk,
    this.discoveryMessage,
    this.models = const [],
  });

  ProviderDiagnostics copyWith({
    bool? isTesting,
    bool? isDiscovering,
    bool? connectionOk,
    String? connectionMessage,
    bool? discoveryOk,
    String? discoveryMessage,
    List<String>? models,
  }) {
    return ProviderDiagnostics(
      isTesting: isTesting ?? this.isTesting,
      isDiscovering: isDiscovering ?? this.isDiscovering,
      connectionOk: connectionOk ?? this.connectionOk,
      connectionMessage: connectionMessage ?? this.connectionMessage,
      discoveryOk: discoveryOk ?? this.discoveryOk,
      discoveryMessage: discoveryMessage ?? this.discoveryMessage,
      models: models ?? this.models,
    );
  }

  @override
  List<Object?> get props => [
    isTesting,
    isDiscovering,
    connectionOk,
    connectionMessage,
    discoveryOk,
    discoveryMessage,
    models,
  ];
}

class SettingsLoaded extends SettingsState {
  final Map<String, String> values;
  final LlmProviderType defaultProvider;
  final Map<LlmProviderType, ProviderDiagnostics> diagnostics;

  SettingsLoaded({
    required this.values,
    required this.defaultProvider,
    this.diagnostics = const {},
  });

  SettingsLoaded copyWith({
    Map<String, String>? values,
    LlmProviderType? defaultProvider,
    Map<LlmProviderType, ProviderDiagnostics>? diagnostics,
  }) {
    return SettingsLoaded(
      values: values ?? this.values,
      defaultProvider: defaultProvider ?? this.defaultProvider,
      diagnostics: diagnostics ?? this.diagnostics,
    );
  }

  @override
  List<Object?> get props => [values, defaultProvider, diagnostics];
}

class SettingsError extends SettingsState {
  final String message;
  SettingsError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _repository;
  final ApiDiagnosticsService _diagnosticsService;

  SettingsBloc(this._repository, {ApiDiagnosticsService? diagnosticsService})
    : _diagnosticsService = diagnosticsService ?? ApiDiagnosticsService(),
      super(SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateStringSetting>(_onUpdateString);
    on<UpdateProviderSetting>(_onUpdateProvider);
    on<TestProviderConnection>(_onTestConnection);
    on<DiscoverProviderModels>(_onDiscoverModels);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    final previousDiagnostics = state is SettingsLoaded
        ? (state as SettingsLoaded).diagnostics
        : const <LlmProviderType, ProviderDiagnostics>{};
    emit(SettingsLoading());
    final keys = [
      AppConstants.keyThemeMode,
      AppConstants.keyLanguage,
      AppConstants.keyUsername,
      AppConstants.keyOpenaiApiKey,
      AppConstants.keyOpenaiBaseUrl,
      AppConstants.keyOpenaiModel,
      AppConstants.keyAnthropicApiKey,
      AppConstants.keyAnthropicBaseUrl,
      AppConstants.keyAnthropicModel,
      AppConstants.keyGeminiApiKey,
      AppConstants.keyGeminiBaseUrl,
      AppConstants.keyGeminiModel,
    ];

    final Map<String, String> values = {};
    for (final key in keys) {
      final res = await _repository.getString(key);
      res.fold((failure) => null, (val) => values[key] = val ?? '');
    }

    final providerRes = await _repository.getDefaultProvider();
    providerRes.fold(
      (failure) => emit(SettingsError(failure.message)),
      (provider) => emit(
        SettingsLoaded(
          values: values,
          defaultProvider: provider,
          diagnostics: previousDiagnostics,
        ),
      ),
    );
  }

  Future<void> _onUpdateString(
    UpdateStringSetting event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.setString(event.key, event.value);
    add(LoadSettings());
  }

  Future<void> _onUpdateProvider(
    UpdateProviderSetting event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.setString(
      AppConstants.keyDefaultProvider,
      event.type.name,
    );
    add(LoadSettings());
  }

  Future<void> _onTestConnection(
    TestProviderConnection event,
    Emitter<SettingsState> emit,
  ) async {
    final current = state;
    if (current is! SettingsLoaded) return;

    emit(
      current.copyWith(
        diagnostics: _updateDiagnostics(
          current,
          event.type,
          (existing) => existing.copyWith(isTesting: true),
        ),
      ),
    );

    final snapshot = _providerSnapshot(current.values, event.type);
    final result = await _diagnosticsService.testConnection(
      providerType: event.type,
      apiKey: snapshot.apiKey,
      baseUrl: snapshot.baseUrl,
      model: snapshot.model,
    );

    final latest = state;
    if (latest is! SettingsLoaded) return;
    emit(
      latest.copyWith(
        diagnostics: _updateDiagnostics(
          latest,
          event.type,
          (existing) => existing.copyWith(
            isTesting: false,
            connectionOk: result.success,
            connectionMessage: result.message,
          ),
        ),
      ),
    );
  }

  Future<void> _onDiscoverModels(
    DiscoverProviderModels event,
    Emitter<SettingsState> emit,
  ) async {
    final current = state;
    if (current is! SettingsLoaded) return;

    emit(
      current.copyWith(
        diagnostics: _updateDiagnostics(
          current,
          event.type,
          (existing) => existing.copyWith(isDiscovering: true),
        ),
      ),
    );

    final snapshot = _providerSnapshot(current.values, event.type);
    final result = await _diagnosticsService.discoverModels(
      providerType: event.type,
      apiKey: snapshot.apiKey,
      baseUrl: snapshot.baseUrl,
    );

    final latest = state;
    if (latest is! SettingsLoaded) return;
    emit(
      latest.copyWith(
        diagnostics: _updateDiagnostics(
          latest,
          event.type,
          (existing) => existing.copyWith(
            isDiscovering: false,
            discoveryOk: result.success,
            discoveryMessage: result.message,
            models: result.success ? result.models : existing.models,
          ),
        ),
      ),
    );
  }

  Map<LlmProviderType, ProviderDiagnostics> _updateDiagnostics(
    SettingsLoaded state,
    LlmProviderType type,
    ProviderDiagnostics Function(ProviderDiagnostics existing) update,
  ) {
    final updated = Map<LlmProviderType, ProviderDiagnostics>.from(
      state.diagnostics,
    );
    updated[type] = update(updated[type] ?? const ProviderDiagnostics());
    return updated;
  }

  _ProviderSnapshot _providerSnapshot(
    Map<String, String> values,
    LlmProviderType type,
  ) {
    return switch (type) {
      LlmProviderType.openai => _ProviderSnapshot(
        apiKey: values[AppConstants.keyOpenaiApiKey] ?? '',
        baseUrl: _valueOrDefault(
          values[AppConstants.keyOpenaiBaseUrl],
          AppConstants.defaultOpenaiBaseUrl,
        ),
        model: _valueOrDefault(
          values[AppConstants.keyOpenaiModel],
          AppConstants.defaultOpenaiModel,
        ),
      ),
      LlmProviderType.anthropic => _ProviderSnapshot(
        apiKey: values[AppConstants.keyAnthropicApiKey] ?? '',
        baseUrl: _valueOrDefault(
          values[AppConstants.keyAnthropicBaseUrl],
          AppConstants.defaultAnthropicBaseUrl,
        ),
        model: _valueOrDefault(
          values[AppConstants.keyAnthropicModel],
          AppConstants.defaultAnthropicModel,
        ),
      ),
      LlmProviderType.gemini => _ProviderSnapshot(
        apiKey: values[AppConstants.keyGeminiApiKey] ?? '',
        baseUrl: _valueOrDefault(
          values[AppConstants.keyGeminiBaseUrl],
          AppConstants.defaultGeminiBaseUrl,
        ),
        model: _valueOrDefault(
          values[AppConstants.keyGeminiModel],
          AppConstants.defaultGeminiModel,
        ),
      ),
    };
  }

  String _valueOrDefault(String? value, String fallback) {
    if (value == null || value.trim().isEmpty) return fallback;
    return value.trim();
  }
}

class _ProviderSnapshot {
  final String apiKey;
  final String baseUrl;
  final String model;

  const _ProviderSnapshot({
    required this.apiKey,
    required this.baseUrl,
    required this.model,
  });
}
