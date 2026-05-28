import 'database_service.dart';

class StoryStateDao {
  Future<List<Map<String, dynamic>>> getByChatId(String chatId) async {
    final db = await DatabaseService.database;
    return await db.query(
      'story_states',
      where: 'chat_id = ?',
      whereArgs: [chatId],
      orderBy: 'updated_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getActiveByChatId(String chatId) async {
    final db = await DatabaseService.database;
    return await db.query(
      'story_states',
      where: 'chat_id = ? AND is_active = 1',
      whereArgs: [chatId],
      orderBy: 'updated_at DESC',
    );
  }

  Future<void> insert(Map<String, dynamic> data) async {
    final db = await DatabaseService.database;
    await db.insert('story_states', data);
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    final db = await DatabaseService.database;
    await db.update(
      'story_states',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(String id) async {
    final db = await DatabaseService.database;
    await db.delete('story_states', where: 'id = ?', whereArgs: [id]);
  }
}
