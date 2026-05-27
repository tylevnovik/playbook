import 'database_service.dart';

class CharacterDao {
  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await DatabaseService.database;
    final results = await db.query('characters', orderBy: 'last_chatted_at DESC');
    final List<Map<String, dynamic>> list = [];
    for (final row in results) {
      final map = Map<String, dynamic>.from(row);
      final charId = map['id'] as String;
      final wbs = await db.query('character_world_books', columns: ['world_book_id'], where: 'character_id = ?', whereArgs: [charId]);
      map['world_book_ids'] = wbs.map((w) => w['world_book_id'] as String).toList();
      list.add(map);
    }
    return list;
  }

  Future<Map<String, dynamic>?> getById(String id) async {
    final db = await DatabaseService.database;
    final results = await db.query('characters', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    
    final map = Map<String, dynamic>.from(results.first);
    final wbs = await db.query('character_world_books', columns: ['world_book_id'], where: 'character_id = ?', whereArgs: [id]);
    map['world_book_ids'] = wbs.map((w) => w['world_book_id'] as String).toList();
    return map;
  }

  Future<void> insert(Map<String, dynamic> data) async {
    final db = await DatabaseService.database;
    final worldBookIds = data['world_book_ids'] as List<dynamic>? ?? [];
    
    final charData = Map<String, dynamic>.from(data)
      ..remove('world_book_ids');
      
    await db.transaction((txn) async {
      await txn.insert('characters', charData);
      for (final wbId in worldBookIds) {
        await txn.insert('character_world_books', {
          'character_id': data['id'],
          'world_book_id': wbId,
        });
      }
    });
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    final db = await DatabaseService.database;
    final worldBookIds = data['world_book_ids'] as List<dynamic>?;
    
    final charData = Map<String, dynamic>.from(data)
      ..remove('world_book_ids');
      
    await db.transaction((txn) async {
      if (charData.isNotEmpty) {
        await txn.update('characters', charData, where: 'id = ?', whereArgs: [id]);
      }
      if (worldBookIds != null) {
        await txn.delete('character_world_books', where: 'character_id = ?', whereArgs: [id]);
        for (final wbId in worldBookIds) {
          await txn.insert('character_world_books', {
            'character_id': id,
            'world_book_id': wbId,
          });
        }
      }
    });
  }

  Future<void> delete(String id) async {
    final db = await DatabaseService.database;
    await db.delete('characters', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> search(String query) async {
    final db = await DatabaseService.database;
    final results = await db.query(
      'characters',
      where: 'name LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    final List<Map<String, dynamic>> list = [];
    for (final row in results) {
      final map = Map<String, dynamic>.from(row);
      final charId = map['id'] as String;
      final wbs = await db.query('character_world_books', columns: ['world_book_id'], where: 'character_id = ?', whereArgs: [charId]);
      map['world_book_ids'] = wbs.map((w) => w['world_book_id'] as String).toList();
      list.add(map);
    }
    return list;
  }
}
