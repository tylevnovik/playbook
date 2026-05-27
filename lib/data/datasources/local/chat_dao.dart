import 'database_service.dart';

class ChatDao {
  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await DatabaseService.database;
    final results = await db.query('chats', orderBy: 'updated_at DESC');
    final List<Map<String, dynamic>> list = [];
    for (final row in results) {
      final map = Map<String, dynamic>.from(row);
      final chatId = map['id'] as String;
      
      final chars = await db.query('chat_characters', columns: ['character_id'], where: 'chat_id = ?', whereArgs: [chatId]);
      map['character_ids'] = chars.map((c) => c['character_id'] as String).toList();
      
      final wbs = await db.query('chat_world_books', columns: ['world_book_id'], where: 'chat_id = ?', whereArgs: [chatId]);
      map['world_book_ids'] = wbs.map((w) => w['world_book_id'] as String).toList();
      
      list.add(map);
    }
    return list;
  }

  Future<List<Map<String, dynamic>>> getByCharacterId(String characterId) async {
    final db = await DatabaseService.database;
    final results = await db.rawQuery('''
      SELECT chats.* FROM chats
      INNER JOIN chat_characters ON chats.id = chat_characters.chat_id
      WHERE chat_characters.character_id = ?
      ORDER BY chats.updated_at DESC
    ''', [characterId]);
    
    final List<Map<String, dynamic>> list = [];
    for (final row in results) {
      final map = Map<String, dynamic>.from(row);
      final chatId = map['id'] as String;
      
      final chars = await db.query('chat_characters', columns: ['character_id'], where: 'chat_id = ?', whereArgs: [chatId]);
      map['character_ids'] = chars.map((c) => c['character_id'] as String).toList();
      
      final wbs = await db.query('chat_world_books', columns: ['world_book_id'], where: 'chat_id = ?', whereArgs: [chatId]);
      map['world_book_ids'] = wbs.map((w) => w['world_book_id'] as String).toList();
      
      list.add(map);
    }
    return list;
  }

  Future<Map<String, dynamic>?> getById(String id) async {
    final db = await DatabaseService.database;
    final results = await db.query('chats', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    
    final map = Map<String, dynamic>.from(results.first);
    
    final chars = await db.query('chat_characters', columns: ['character_id'], where: 'chat_id = ?', whereArgs: [id]);
    map['character_ids'] = chars.map((c) => c['character_id'] as String).toList();
    
    final wbs = await db.query('chat_world_books', columns: ['world_book_id'], where: 'chat_id = ?', whereArgs: [id]);
    map['world_book_ids'] = wbs.map((w) => w['world_book_id'] as String).toList();
    
    return map;
  }

  Future<void> insert(Map<String, dynamic> data) async {
    final db = await DatabaseService.database;
    final characterIds = data['character_ids'] as List<dynamic>? ?? [];
    final worldBookIds = data['world_book_ids'] as List<dynamic>? ?? [];
    
    final chatData = Map<String, dynamic>.from(data)
      ..remove('character_ids')
      ..remove('world_book_ids');
      
    await db.transaction((txn) async {
      await txn.insert('chats', chatData);
      for (final charId in characterIds) {
        await txn.insert('chat_characters', {
          'chat_id': data['id'],
          'character_id': charId,
        });
      }
      for (final wbId in worldBookIds) {
        await txn.insert('chat_world_books', {
          'chat_id': data['id'],
          'world_book_id': wbId,
        });
      }
    });
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    final db = await DatabaseService.database;
    final characterIds = data['character_ids'] as List<dynamic>?;
    final worldBookIds = data['world_book_ids'] as List<dynamic>?;
    
    final chatData = Map<String, dynamic>.from(data)
      ..remove('character_ids')
      ..remove('world_book_ids');
      
    await db.transaction((txn) async {
      if (chatData.isNotEmpty) {
        await txn.update('chats', chatData, where: 'id = ?', whereArgs: [id]);
      }
      if (characterIds != null) {
        await txn.delete('chat_characters', where: 'chat_id = ?', whereArgs: [id]);
        for (final charId in characterIds) {
          await txn.insert('chat_characters', {
            'chat_id': id,
            'character_id': charId,
          });
        }
      }
      if (worldBookIds != null) {
        await txn.delete('chat_world_books', where: 'chat_id = ?', whereArgs: [id]);
        for (final wbId in worldBookIds) {
          await txn.insert('chat_world_books', {
            'chat_id': id,
            'world_book_id': wbId,
          });
        }
      }
    });
  }

  Future<void> delete(String id) async {
    final db = await DatabaseService.database;
    await db.delete('chats', where: 'id = ?', whereArgs: [id]);
  }
}
