import 'database_service.dart';

class ChatDao {
  Future<List<Map<String, dynamic>>> getByCharacterId(String characterId) async {
    final db = await DatabaseService.database;
    return await db.query(
      'chats',
      where: 'character_id = ?',
      whereArgs: [characterId],
      orderBy: 'updated_at DESC',
    );
  }

  Future<Map<String, dynamic>?> getById(String id) async {
    final db = await DatabaseService.database;
    final results = await db.query('chats', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> insert(Map<String, dynamic> data) async {
    final db = await DatabaseService.database;
    await db.insert('chats', data);
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    final db = await DatabaseService.database;
    await db.update('chats', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(String id) async {
    final db = await DatabaseService.database;
    await db.delete('chats', where: 'id = ?', whereArgs: [id]);
  }
}
