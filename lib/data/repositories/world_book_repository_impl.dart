import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/utils/id_generator.dart';
import '../../../domain/entities/world_book.dart';
import '../../../domain/repositories/world_book_repository.dart';
import '../datasources/local/world_book_dao.dart';
import '../models/world_book_model.dart';

class WorldBookRepositoryImpl implements WorldBookRepository {
  final WorldBookDao _dao;

  WorldBookRepositoryImpl(this._dao);

  @override
  Future<Either<Failure, List<WorldBook>>> getAllWorldBooks() async {
    try {
      final maps = await _dao.getAll();
      return Right(maps.map(WorldBookModel.fromMap).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, WorldBook>> getWorldBook(String id) async {
    try {
      final map = await _dao.getById(id);
      if (map == null) return const Left(DatabaseFailure('World book not found'));
      return Right(WorldBookModel.fromMap(map));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, WorldBook>> createWorldBook(WorldBook worldBook) async {
    try {
      final now = DateTime.now();
      final newBook = WorldBook(
        id: worldBook.id.isEmpty ? IdGenerator.generate() : worldBook.id,
        name: worldBook.name,
        description: worldBook.description,
        createdAt: now,
        updatedAt: now,
      );
      await _dao.insert(WorldBookModel.toMap(newBook));
      return Right(newBook);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, WorldBook>> updateWorldBook(WorldBook worldBook) async {
    try {
      final updated = WorldBook(
        id: worldBook.id,
        name: worldBook.name,
        description: worldBook.description,
        createdAt: worldBook.createdAt,
        updatedAt: DateTime.now(),
      );
      await _dao.update(worldBook.id, WorldBookModel.toMap(updated));
      return Right(updated);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteWorldBook(String id) async {
    try {
      await _dao.delete(id);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<WorldBookEntry>>> getEntries(String worldBookId) async {
    try {
      final maps = await _dao.getEntries(worldBookId);
      return Right(maps.map(WorldBookEntryModel.fromMap).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, WorldBookEntry>> createEntry(WorldBookEntry entry) async {
    try {
      final now = DateTime.now();
      final newEntry = WorldBookEntry(
        id: entry.id.isEmpty ? IdGenerator.generate() : entry.id,
        worldBookId: entry.worldBookId,
        name: entry.name,
        keywords: entry.keywords,
        content: entry.content,
        category: entry.category,
        priority: entry.priority,
        enabled: entry.enabled,
        createdAt: now,
        updatedAt: now,
      );
      await _dao.insertEntry(WorldBookEntryModel.toMap(newEntry));
      return Right(newEntry);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, WorldBookEntry>> updateEntry(WorldBookEntry entry) async {
    try {
      final updated = WorldBookEntry(
        id: entry.id,
        worldBookId: entry.worldBookId,
        name: entry.name,
        keywords: entry.keywords,
        content: entry.content,
        category: entry.category,
        priority: entry.priority,
        enabled: entry.enabled,
        createdAt: entry.createdAt,
        updatedAt: DateTime.now(),
      );
      await _dao.updateEntry(entry.id, WorldBookEntryModel.toMap(updated));
      return Right(updated);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteEntry(String entryId) async {
    try {
      await _dao.deleteEntry(entryId);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<WorldBookEntry>>> matchEntries(String worldBookId, String text) async {
    try {
      final maps = await _dao.matchEntries(worldBookId, text);
      return Right(maps.map(WorldBookEntryModel.fromMap).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
