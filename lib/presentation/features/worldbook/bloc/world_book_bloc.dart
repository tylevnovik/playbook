import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../data/samples/sample_content.dart';
import '../../../../domain/entities/world_book.dart';
import '../../../../domain/repositories/world_book_repository.dart';

// Events
abstract class WorldBookEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadWorldBooks extends WorldBookEvent {}

class CreateWorldBookEvent extends WorldBookEvent {
  final String name;
  final String? description;
  CreateWorldBookEvent({required this.name, this.description});
  @override
  List<Object?> get props => [name, description];
}

class DeleteWorldBookEvent extends WorldBookEvent {
  final String id;
  DeleteWorldBookEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class LoadEntriesEvent extends WorldBookEvent {
  final String worldBookId;
  LoadEntriesEvent(this.worldBookId);
  @override
  List<Object?> get props => [worldBookId];
}

class SaveEntryEvent extends WorldBookEvent {
  final WorldBookEntry entry;
  SaveEntryEvent(this.entry);
  @override
  List<Object?> get props => [entry];
}

class DeleteEntryEvent extends WorldBookEvent {
  final String entryId;
  final String worldBookId;
  DeleteEntryEvent(this.entryId, this.worldBookId);
  @override
  List<Object?> get props => [entryId, worldBookId];
}

class CreateExampleWorldBooks extends WorldBookEvent {}

// States
abstract class WorldBookState extends Equatable {
  @override
  List<Object?> get props => [];
}

class WorldBookInitial extends WorldBookState {}

class WorldBookLoading extends WorldBookState {}

class WorldBookLoaded extends WorldBookState {
  final List<WorldBook> worldBooks;
  final String? selectedWorldBookId;
  final List<WorldBookEntry> entries;

  WorldBookLoaded({
    required this.worldBooks,
    this.selectedWorldBookId,
    this.entries = const [],
  });

  WorldBookLoaded copyWith({
    List<WorldBook>? worldBooks,
    String? selectedWorldBookId,
    List<WorldBookEntry>? entries,
  }) {
    return WorldBookLoaded(
      worldBooks: worldBooks ?? this.worldBooks,
      selectedWorldBookId: selectedWorldBookId ?? this.selectedWorldBookId,
      entries: entries ?? this.entries,
    );
  }

  @override
  List<Object?> get props => [worldBooks, selectedWorldBookId, entries];
}

class WorldBookError extends WorldBookState {
  final String message;
  WorldBookError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class WorldBookBloc extends Bloc<WorldBookEvent, WorldBookState> {
  final WorldBookRepository _repository;

  WorldBookBloc(this._repository) : super(WorldBookInitial()) {
    on<LoadWorldBooks>(_onLoadWorldBooks);
    on<CreateWorldBookEvent>(_onCreateWorldBook);
    on<DeleteWorldBookEvent>(_onDeleteWorldBook);
    on<LoadEntriesEvent>(_onLoadEntries);
    on<SaveEntryEvent>(_onSaveEntry);
    on<DeleteEntryEvent>(_onDeleteEntry);
    on<CreateExampleWorldBooks>(_onCreateExamples);
  }

  Future<void> _onLoadWorldBooks(
    LoadWorldBooks event,
    Emitter<WorldBookState> emit,
  ) async {
    emit(WorldBookLoading());
    final result = await _repository.getAllWorldBooks();
    await result.fold(
      (failure) async => emit(WorldBookError(failure.message)),
      (books) async {
        if (books.isNotEmpty) {
          final entriesResult = await _repository.getEntries(books.first.id);
          entriesResult.fold(
            (failure) => emit(WorldBookError(failure.message)),
            (entries) => emit(
              WorldBookLoaded(
                worldBooks: books,
                selectedWorldBookId: books.first.id,
                entries: entries,
              ),
            ),
          );
        } else {
          emit(WorldBookLoaded(worldBooks: const []));
        }
      },
    );
  }

  Future<void> _onCreateWorldBook(
    CreateWorldBookEvent event,
    Emitter<WorldBookState> emit,
  ) async {
    final book = WorldBook(
      id: '',
      name: event.name,
      description: event.description,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _repository.createWorldBook(book);
    add(LoadWorldBooks());
  }

  Future<void> _onDeleteWorldBook(
    DeleteWorldBookEvent event,
    Emitter<WorldBookState> emit,
  ) async {
    await _repository.deleteWorldBook(event.id);
    add(LoadWorldBooks());
  }

  Future<void> _onLoadEntries(
    LoadEntriesEvent event,
    Emitter<WorldBookState> emit,
  ) async {
    final currentState = state;
    if (currentState is WorldBookLoaded) {
      final entriesResult = await _repository.getEntries(event.worldBookId);
      entriesResult.fold(
        (failure) => emit(WorldBookError(failure.message)),
        (entries) => emit(
          currentState.copyWith(
            selectedWorldBookId: event.worldBookId,
            entries: entries,
          ),
        ),
      );
    }
  }

  Future<void> _onSaveEntry(
    SaveEntryEvent event,
    Emitter<WorldBookState> emit,
  ) async {
    final currentState = state;
    if (currentState is WorldBookLoaded) {
      final result = event.entry.id.isEmpty
          ? await _repository.createEntry(event.entry)
          : await _repository.updateEntry(event.entry);

      await result.fold(
        (failure) async => emit(WorldBookError(failure.message)),
        (_) async {
          add(LoadEntriesEvent(event.entry.worldBookId));
        },
      );
    }
  }

  Future<void> _onDeleteEntry(
    DeleteEntryEvent event,
    Emitter<WorldBookState> emit,
  ) async {
    await _repository.deleteEntry(event.entryId);
    add(LoadEntriesEvent(event.worldBookId));
  }

  Future<void> _onCreateExamples(
    CreateExampleWorldBooks event,
    Emitter<WorldBookState> emit,
  ) async {
    for (final template in SampleContent.worldBooks()) {
      final bookResult = await _repository.createWorldBook(
        template.toWorldBook(),
      );
      if (bookResult.isLeft()) {
        bookResult.fold(
          (failure) => emit(WorldBookError(failure.message)),
          (_) => null,
        );
        return;
      }

      final book = bookResult.getOrElse(() => template.toWorldBook());
      for (final entryTemplate in template.entries) {
        final entryResult = await _repository.createEntry(
          entryTemplate.toEntry(book.id),
        );
        if (entryResult.isLeft()) {
          entryResult.fold(
            (failure) => emit(WorldBookError(failure.message)),
            (_) => null,
          );
          return;
        }
      }
    }
    add(LoadWorldBooks());
  }
}
