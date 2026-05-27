import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/character.dart';

abstract class CharacterRepository {
  Future<Either<Failure, List<Character>>> getAllCharacters();
  Future<Either<Failure, Character>> getCharacter(String id);
  Future<Either<Failure, Character>> createCharacter(Character character);
  Future<Either<Failure, Character>> updateCharacter(Character character);
  Future<Either<Failure, void>> deleteCharacter(String id);
  Future<Either<Failure, List<Character>>> searchCharacters(String query);
  Future<Either<Failure, void>> importCharacter(String jsonContent);
  Future<Either<Failure, String>> exportCharacter(String id);
}
