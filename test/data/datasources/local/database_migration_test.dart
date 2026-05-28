import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:playbook/data/datasources/local/database_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('Database contains correct tables and columns', () async {
    final db = await DatabaseService.database;
    
    final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
    final tableNames = tables.map((t) => t['name'] as String).toList();
    
    expect(tableNames, contains('story_states'));
    expect(tableNames, contains('messages'));
    
    final messagesInfo = await db.rawQuery('PRAGMA table_info(messages)');
    final messageColumns = messagesInfo.map((c) => c['name'] as String).toList();
    expect(messageColumns, contains('is_canon'));

    final statesInfo = await db.rawQuery('PRAGMA table_info(story_states)');
    final stateColumns = statesInfo.map((c) => c['name'] as String).toList();
    expect(stateColumns, contains('id'));
    expect(stateColumns, contains('chat_id'));
    expect(stateColumns, contains('category'));
    expect(stateColumns, contains('content'));
    expect(stateColumns, contains('is_active'));
  });
}
