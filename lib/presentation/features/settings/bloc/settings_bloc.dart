import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../data/services/api_diagnostics_service.dart';
import '../../../../domain/entities/llm_config.dart';
import '../../../../domain/repositories/settings_repository.dart';

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

class SaveProviderProfile extends SettingsEvent {
  final LlmProviderProfile profile;

  SaveProviderProfile(this.profile);

  @override
  List<Object?> get props => [profile];
}

class AddProviderProfile extends SettingsEvent {
  final LlmProviderProfile profile;

  AddProviderProfile(this.profile);

  @override
  List<Object?> get props => [profile];
}

class DeleteProviderProfile extends SettingsEvent {
  final String id;

  DeleteProviderProfile(this.id);

  @override
  List<Object?> get props => [id];
}

class SetDefaultProviderProfile extends SettingsEvent {
  final String id;

  SetDefaultProviderProfile(this.id);

  @override
  List<Object?> get props => [id];
}

class TestProviderConnection extends SettingsEvent {
  final LlmProviderProfile profile;

  TestProviderConnection(this.profile);

  @override
  List<Object?> get props => [profile];
}

class DiscoverProviderModels extends SettingsEvent {
  final LlmProviderProfile profile;

  DiscoverProviderModels(this.profile);

  @override
  List<Object?> get props => [profile];
}

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
  final List<LlmProviderProfile> providerProfiles;
  final String defaultProviderProfileId;
  final Map<String, ProviderDiagnostics> diagnostics;

  SettingsLoaded({
    required this.values,
    required this.providerProfiles,
    required this.defaultProviderProfileId,
    this.diagnostics = const {},
  });

  LlmProviderProfile get defaultProviderProfile {
    return providerProfiles.firstWhere(
      (profile) => profile.id == defaultProviderProfileId,
      orElse: () => providerProfiles.first,
    );
  }

  SettingsLoaded copyWith({
    Map<String, String>? values,
    List<LlmProviderProfile>? providerProfiles,
    String? defaultProviderProfileId,
    Map<String, ProviderDiagnostics>? diagnostics,
  }) {
    return SettingsLoaded(
      values: values ?? this.values,
      providerProfiles: providerProfiles ?? this.providerProfiles,
      defaultProviderProfileId:
          defaultProviderProfileId ?? this.defaultProviderProfileId,
      diagnostics: diagnostics ?? this.diagnostics,
    );
  }

  @override
  List<Object?> get props => [
    values,
    providerProfiles,
    defaultProviderProfileId,
    diagnostics,
  ];
}

class SettingsError extends SettingsState {
  final String message;

  SettingsError(this.message);

  @override
  List<Object?> get props => [message];
}

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _repository;
  final ApiDiagnosticsService _diagnosticsService;

  SettingsBloc(this._repository, {ApiDiagnosticsService? diagnosticsService})
    : _diagnosticsService = diagnosticsService ?? ApiDiagnosticsService(),
      super(SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateStringSetting>(_onUpdateString);
    on<SaveProviderProfile>(_onSaveProviderProfile);
    on<AddProviderProfile>(_onAddProviderProfile);
    on<DeleteProviderProfile>(_onDeleteProviderProfile);
    on<SetDefaultProviderProfile>(_onSetDefaultProviderProfile);
    on<TestProviderConnection>(_onTestConnection);
    on<DiscoverProviderModels>(_onDiscoverModels);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    final previousDiagnostics = state is SettingsLoaded
        ? (state as SettingsLoaded).diagnostics
        : const <String, ProviderDiagnostics>{};
    emit(SettingsLoading());

    final valuesResult = await _loadValues();
    final profilesResult = await _repository.getProviderProfiles();
    final defaultIdResult = await _repository.getDefaultProviderProfileId();

    final failure =
        valuesResult.$1 ??
        profilesResult.fold((f) => f, (_) => null) ??
        defaultIdResult.fold((f) => f, (_) => null);
    if (failure != null) {
      emit(SettingsError(failure.message));
      return;
    }

    final values = valuesResult.$2;
    final profiles = profilesResult.getOrElse(() => const []);
    final defaultId = defaultIdResult.getOrElse(
      () => profiles.isNotEmpty
          ? profiles.first.id
          : AppConstants.profileOpenaiOfficial,
    );

    emit(
      SettingsLoaded(
        values: values,
        providerProfiles: profiles,
        defaultProviderProfileId: defaultId,
        diagnostics: previousDiagnostics,
      ),
    );
  }

  Future<void> _onUpdateString(
    UpdateStringSetting event,
    Emitter<SettingsState> emit,
  ) async {
    final result = await _repository.setString(event.key, event.value);
    result.fold((failure) => emit(SettingsError(failure.message)), (_) {
      final current = state;
      if (current is SettingsLoaded) {
        final values = Map<String, String>.from(current.values)
          ..[event.key] = event.value;
        emit(current.copyWith(values: values));
      } else {
        add(LoadSettings());
      }
    });
  }

  Future<void> _onSaveProviderProfile(
    SaveProviderProfile event,
    Emitter<SettingsState> emit,
  ) async {
    final current = state;
    if (current is! SettingsLoaded) return;

    final profiles = current.providerProfiles.map((profile) {
      return profile.id == event.profile.id ? event.profile : profile;
    }).toList();

    final result = await _repository.saveProviderProfiles(profiles);
    result.fold((failure) => emit(SettingsError(failure.message)), (_) {
      emit(current.copyWith(providerProfiles: profiles));
    });
  }

  Future<void> _onAddProviderProfile(
    AddProviderProfile event,
    Emitter<SettingsState> emit,
  ) async {
    final current = state;
    if (current is! SettingsLoaded) return;

    final profiles = [...current.providerProfiles, event.profile];
    final result = await _repository.saveProviderProfiles(profiles);
    result.fold((failure) => emit(SettingsError(failure.message)), (_) {
      emit(current.copyWith(providerProfiles: profiles));
    });
  }

  Future<void> _onDeleteProviderProfile(
    DeleteProviderProfile event,
    Emitter<SettingsState> emit,
  ) async {
    final current = state;
    if (current is! SettingsLoaded) return;
    final target = current.providerProfiles
        .where((profile) => profile.id == event.id)
        .firstOrNull;
    if (target == null || target.isBuiltIn) return;

    final profiles = current.providerProfiles
        .where((profile) => profile.id != event.id)
        .toList();
    final nextDefaultId = current.defaultProviderProfileId == event.id
        ? profiles.first.id
        : current.defaultProviderProfileId;
    final saveResult = await _repository.saveProviderProfiles(profiles);
    final defaultResult = await _repository.setDefaultProviderProfileId(
      nextDefaultId,
    );

    final failure =
        saveResult.fold((f) => f, (_) => null) ??
        defaultResult.fold((f) => f, (_) => null);
    if (failure != null) {
      emit(SettingsError(failure.message));
      return;
    }

    emit(
      current.copyWith(
        providerProfiles: profiles,
        defaultProviderProfileId: nextDefaultId,
      ),
    );
  }

  Future<void> _onSetDefaultProviderProfile(
    SetDefaultProviderProfile event,
    Emitter<SettingsState> emit,
  ) async {
    final current = state;
    if (current is! SettingsLoaded) return;
    if (!current.providerProfiles.any((profile) => profile.id == event.id)) {
      return;
    }

    final result = await _repository.setDefaultProviderProfileId(event.id);
    result.fold((failure) => emit(SettingsError(failure.message)), (_) {
      emit(current.copyWith(defaultProviderProfileId: event.id));
    });
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
          event.profile.id,
          (existing) => existing.copyWith(isTesting: true),
        ),
      ),
    );

    final result = await _diagnosticsService.testConnection(
      providerType: event.profile.providerType,
      apiKey: event.profile.apiKey,
      baseUrl: event.profile.baseUrl,
      model: event.profile.model,
    );

    final latest = state;
    if (latest is! SettingsLoaded) return;
    emit(
      latest.copyWith(
        diagnostics: _updateDiagnostics(
          latest,
          event.profile.id,
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
          event.profile.id,
          (existing) => existing.copyWith(isDiscovering: true),
        ),
      ),
    );

    final result = await _diagnosticsService.discoverModels(
      providerType: event.profile.providerType,
      apiKey: event.profile.apiKey,
      baseUrl: event.profile.baseUrl,
    );

    final latest = state;
    if (latest is! SettingsLoaded) return;
    emit(
      latest.copyWith(
        diagnostics: _updateDiagnostics(
          latest,
          event.profile.id,
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

  Future<(Failure?, Map<String, String>)> _loadValues() async {
    final keys = [
      AppConstants.keyThemeMode,
      AppConstants.keyLanguage,
      AppConstants.keyUsername,
    ];

    final values = <String, String>{};
    for (final key in keys) {
      final res = await _repository.getString(key);
      final failure = res.fold((failure) => failure, (_) => null);
      if (failure != null) return (failure, values);
      values[key] = res.getOrElse(() => '') ?? '';
    }
    return (null, values);
  }

  Map<String, ProviderDiagnostics> _updateDiagnostics(
    SettingsLoaded state,
    String profileId,
    ProviderDiagnostics Function(ProviderDiagnostics existing) update,
  ) {
    final updated = Map<String, ProviderDiagnostics>.from(state.diagnostics);
    updated[profileId] = update(
      updated[profileId] ?? const ProviderDiagnostics(),
    );
    return updated;
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) return iterator.current;
    return null;
  }
}
