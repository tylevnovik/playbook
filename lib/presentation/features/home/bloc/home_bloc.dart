import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../data/samples/sample_content.dart';
import '../../../../domain/entities/character.dart';
import '../../../../domain/entities/chat.dart';
import '../../../../domain/repositories/character_repository.dart';
import '../../../../domain/repositories/chat_repository.dart';

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

class CreateExampleCharacters extends HomeEvent {}

// States
abstract class HomeState extends Equatable {
  @override
  List<Object> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<Character> characters;
  final List<Chat> chats;
  HomeLoaded({required this.characters, required this.chats});
  @override
  List<Object> get props => [characters, chats];
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
  final ChatRepository _chatRepository;

  HomeBloc(this._repository, this._chatRepository) : super(HomeInitial()) {
    on<LoadCharacters>(_onLoad);
    on<SearchCharacters>(_onSearch);
    on<DeleteCharacter>(_onDelete);
    on<CreateExampleCharacters>(_onCreateExamples);
  }

  Future<void> _onLoad(LoadCharacters event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    final charResult = await _repository.getAllCharacters();
    final chatResult = await _chatRepository.getAllChats();
    
    charResult.fold(
      (failure) => emit(HomeError(failure.message)),
      (characters) {
        chatResult.fold(
          (failure) => emit(HomeError(failure.message)),
          (chats) => emit(HomeLoaded(characters: characters, chats: chats)),
        );
      },
    );
  }

  Future<void> _onSearch(
    SearchCharacters event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeLoading());
    final result = await _repository.searchCharacters(event.query);
    final chatResult = await _chatRepository.getAllChats();
    result.fold(
      (failure) => emit(HomeError(failure.message)),
      (characters) {
        chatResult.fold(
          (failure) => emit(HomeError(failure.message)),
          (chats) => emit(HomeLoaded(characters: characters, chats: chats)),
        );
      },
    );
  }

  Future<void> _onDelete(DeleteCharacter event, Emitter<HomeState> emit) async {
    await _repository.deleteCharacter(event.id);
    add(LoadCharacters());
  }

  Future<void> _onCreateExamples(
    CreateExampleCharacters event,
    Emitter<HomeState> emit,
  ) async {
    for (final character in SampleContent.characters()) {
      final result = await _repository.createCharacter(character);
      if (result.isLeft()) {
        result.fold((failure) => emit(HomeError(failure.message)), (_) => null);
        return;
      }
    }
    add(LoadCharacters());
  }
}
