import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/story_state.dart';

abstract class StoryStateRepository {
  Future<Either<Failure, List<StoryState>>> getStoryStates(String chatId);
  Future<Either<Failure, List<StoryState>>> getActiveStoryStates(String chatId);
  Future<Either<Failure, StoryState>> addStoryState(StoryState state);
  Future<Either<Failure, void>> updateStoryState(StoryState state);
  Future<Either<Failure, void>> deleteStoryState(String id);
}
