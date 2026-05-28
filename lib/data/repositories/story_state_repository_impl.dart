import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../domain/entities/story_state.dart';
import '../../../domain/repositories/story_state_repository.dart';
import '../datasources/local/story_state_dao.dart';
import '../models/story_state_model.dart';

class StoryStateRepositoryImpl implements StoryStateRepository {
  final StoryStateDao _dao;

  StoryStateRepositoryImpl(this._dao);

  @override
  Future<Either<Failure, List<StoryState>>> getStoryStates(String chatId) async {
    try {
      final maps = await _dao.getByChatId(chatId);
      return Right(maps.map(StoryStateModel.fromMap).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<StoryState>>> getActiveStoryStates(
    String chatId,
  ) async {
    try {
      final maps = await _dao.getActiveByChatId(chatId);
      return Right(maps.map(StoryStateModel.fromMap).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, StoryState>> addStoryState(StoryState state) async {
    try {
      await _dao.insert(StoryStateModel.toMap(state));
      return Right(state);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateStoryState(StoryState state) async {
    try {
      await _dao.update(state.id, StoryStateModel.toMap(state));
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteStoryState(String id) async {
    try {
      await _dao.delete(id);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
