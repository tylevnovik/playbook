import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../domain/entities/character.dart';
import '../../../../domain/repositories/character_repository.dart';

// Events
abstract class CharacterEditEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoadCharacterForEdit extends CharacterEditEvent {
  final String id;
  LoadCharacterForEdit(this.id);

  @override
  List<Object> get props => [id];
}

class SaveCharacter extends CharacterEditEvent {
  final Character character;
  SaveCharacter(this.character);

  @override
  List<Object> get props => [character];
}

class ImportCharacterJson extends CharacterEditEvent {
  final String json;
  ImportCharacterJson(this.json);

  @override
  List<Object> get props => [json];
}

// States
abstract class CharacterEditState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CharacterEditInitial extends CharacterEditState {}
class CharacterEditLoading extends CharacterEditState {}
class CharacterEditLoaded extends CharacterEditState {
  final Character? character;
  CharacterEditLoaded(this.character);

  @override
  List<Object?> get props => [character];
}
class CharacterEditSaved extends CharacterEditState {}
class CharacterEditError extends CharacterEditState {
  final String message;
  CharacterEditError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class CharacterEditBloc extends Bloc<CharacterEditEvent, CharacterEditState> {
  final CharacterRepository _repository;

  CharacterEditBloc(this._repository) : super(CharacterEditInitial()) {
    on<LoadCharacterForEdit>(_onLoad);
    on<SaveCharacter>(_onSave);
    on<ImportCharacterJson>(_onImport);
  }

  Future<void> _onLoad(LoadCharacterForEdit event, Emitter<CharacterEditState> emit) async {
    emit(CharacterEditLoading());
    final result = await _repository.getCharacter(event.id);
    result.fold(
      (failure) => emit(CharacterEditError(failure.message)),
      (character) => emit(CharacterEditLoaded(character)),
    );
  }

  Future<void> _onSave(SaveCharacter event, Emitter<CharacterEditState> emit) async {
    emit(CharacterEditLoading());
    final result = event.character.id.isEmpty
        ? await _repository.createCharacter(event.character)
        : await _repository.updateCharacter(event.character);
    result.fold(
      (failure) => emit(CharacterEditError(failure.message)),
      (_) => emit(CharacterEditSaved()),
    );
  }

  Future<void> _onImport(ImportCharacterJson event, Emitter<CharacterEditState> emit) async {
    emit(CharacterEditLoading());
    final result = await _repository.importCharacter(event.json);
    result.fold(
      (failure) => emit(CharacterEditError(failure.message)),
      (_) => emit(CharacterEditSaved()),
    );
  }
}
