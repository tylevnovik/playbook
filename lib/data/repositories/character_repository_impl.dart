import 'dart:convert';
import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/utils/id_generator.dart';
import '../../../domain/entities/character.dart';
import '../../../domain/repositories/character_repository.dart';
import '../datasources/local/character_dao.dart';
import '../models/character_model.dart';

class CharacterRepositoryImpl implements CharacterRepository {
  final CharacterDao _dao;

  CharacterRepositoryImpl(this._dao);

  @override
  Future<Either<Failure, List<Character>>> getAllCharacters() async {
    try {
      final maps = await _dao.getAll();
      return Right(maps.map(CharacterModel.fromMap).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Character>> getCharacter(String id) async {
    try {
      final map = await _dao.getById(id);
      if (map == null) return const Left(DatabaseFailure('Character not found'));
      return Right(CharacterModel.fromMap(map));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Character>> createCharacter(Character character) async {
    try {
      final now = DateTime.now();
      final newChar = Character(
        id: character.id.isEmpty ? IdGenerator.generate() : character.id,
        name: character.name,
        avatarPath: character.avatarPath,
        description: character.description,
        greeting: character.greeting,
        exampleMessages: character.exampleMessages,
        systemPrompt: character.systemPrompt,
        tags: character.tags,
        worldBookId: character.worldBookId,
        createdAt: now,
        updatedAt: now,
      );
      await _dao.insert(CharacterModel.toMap(newChar));
      return Right(newChar);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Character>> updateCharacter(Character character) async {
    try {
      await _dao.update(character.id, CharacterModel.toMap(character));
      return Right(character);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCharacter(String id) async {
    try {
      await _dao.delete(id);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Character>>> searchCharacters(String query) async {
    try {
      final maps = await _dao.search(query);
      return Right(maps.map(CharacterModel.fromMap).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> importCharacter(String jsonContent) async {
    try {
      final character = CharacterModel.fromJson(jsonContent);
      await _dao.insert(CharacterModel.toMap(character));
      return const Right(null);
    } catch (e) {
      return Left(ValidationFailure('Invalid character JSON: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> exportCharacter(String id) async {
    try {
      final map = await _dao.getById(id);
      if (map == null) return const Left(DatabaseFailure('Character not found'));
      final character = CharacterModel.fromMap(map);
      return Right(CharacterModel.toJson(character));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
