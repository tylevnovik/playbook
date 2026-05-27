import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/world_book.dart';

abstract class WorldBookRepository {
  Future<Either<Failure, List<WorldBook>>> getAllWorldBooks();
  Future<Either<Failure, WorldBook>> getWorldBook(String id);
  Future<Either<Failure, WorldBook>> createWorldBook(WorldBook worldBook);
  Future<Either<Failure, WorldBook>> updateWorldBook(WorldBook worldBook);
  Future<Either<Failure, void>> deleteWorldBook(String id);
  Future<Either<Failure, List<WorldBookEntry>>> getEntries(String worldBookId);
  Future<Either<Failure, WorldBookEntry>> createEntry(WorldBookEntry entry);
  Future<Either<Failure, WorldBookEntry>> updateEntry(WorldBookEntry entry);
  Future<Either<Failure, void>> deleteEntry(String entryId);
  Future<Either<Failure, List<WorldBookEntry>>> matchEntries(String worldBookId, String text);
}
