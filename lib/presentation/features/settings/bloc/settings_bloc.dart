import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
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

// States
abstract class SettingsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {}
class SettingsLoading extends SettingsState {}
class SettingsLoaded extends SettingsState {
  final Map<String, String> values;
  final LlmProviderType defaultProvider;

  SettingsLoaded({required this.values, required this.defaultProvider});

  @override
  List<Object?> get props => [values, defaultProvider];
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

  SettingsBloc(this._repository) : super(SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateStringSetting>(_onUpdateString);
    on<UpdateProviderSetting>(_onUpdateProvider);
  }

  Future<void> _onLoadSettings(LoadSettings event, Emitter<SettingsState> emit) async {
    emit(SettingsLoading());
    final keys = [
      AppConstants.keyThemeMode,
      AppConstants.keyLanguage,
      AppConstants.keyUsername,
      AppConstants.keyOpenaiApiKey,
      AppConstants.keyOpenaiBaseUrl,
      AppConstants.keyOpenaiModel,
      AppConstants.keyAnthropicApiKey,
      AppConstants.keyAnthropicModel,
      AppConstants.keyGeminiApiKey,
      AppConstants.keyGeminiModel,
    ];

    final Map<String, String> values = {};
    for (final key in keys) {
      final res = await _repository.getString(key);
      res.fold(
        (failure) => null,
        (val) => values[key] = val ?? '',
      );
    }

    final providerRes = await _repository.getDefaultProvider();
    providerRes.fold(
      (failure) => emit(SettingsError(failure.message)),
      (provider) => emit(SettingsLoaded(values: values, defaultProvider: provider)),
    );
  }

  Future<void> _onUpdateString(UpdateStringSetting event, Emitter<SettingsState> emit) async {
    await _repository.setString(event.key, event.value);
    add(LoadSettings());
  }

  Future<void> _onUpdateProvider(UpdateProviderSetting event, Emitter<SettingsState> emit) async {
    await _repository.setString(AppConstants.keyDefaultProvider, event.type.name);
    add(LoadSettings());
  }
}
