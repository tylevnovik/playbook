import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../domain/entities/character.dart';
import '../../../../domain/repositories/character_repository.dart';

// Events
abstract class HomeEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoadCharacters extends HomeEvent {}

class SearchCharacters extends HomeEvent {
  final String query;
  SearchCharacters(this.query);
  @override
  List<Object> get props => [query];
}

class DeleteCharacter extends HomeEvent {
  final String id;
  DeleteCharacter(this.id);
  @override
  List<Object> get props => [id];
}

// States
abstract class HomeState extends Equatable {
  @override
  List<Object> get props => [];
}

class HomeInitial extends HomeState {}
class HomeLoading extends HomeState {}
class HomeLoaded extends HomeState {
  final List<Character> characters;
  HomeLoaded(this.characters);
  @override
  List<Object> get props => [characters];
}
class HomeError extends HomeState {
  final String message;
  HomeError(this.message);
  @override
  List<Object> get props => [message];
}

// BLoC
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final CharacterRepository _repository;

  HomeBloc(this._repository) : super(HomeInitial()) {
    on<LoadCharacters>(_onLoad);
    on<SearchCharacters>(_onSearch);
    on<DeleteCharacter>(_onDelete);
  }

  Future<void> _onLoad(LoadCharacters event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    final result = await _repository.getAllCharacters();
    result.fold(
      (failure) => emit(HomeError(failure.message)),
      (characters) => emit(HomeLoaded(characters)),
    );
  }

  Future<void> _onSearch(SearchCharacters event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    final result = await _repository.searchCharacters(event.query);
    result.fold(
      (failure) => emit(HomeError(failure.message)),
      (characters) => emit(HomeLoaded(characters)),
    );
  }

  Future<void> _onDelete(DeleteCharacter event, Emitter<HomeState> emit) async {
    await _repository.deleteCharacter(event.id);
    add(LoadCharacters());
  }
}
