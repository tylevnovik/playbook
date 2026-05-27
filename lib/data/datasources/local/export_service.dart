import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'database_service.dart';

@lazySingleton
class ExportService {
  Future<String> exportBackup() async {
    final db = await DatabaseService.database;
    
    final characters = await db.query('characters');
    final chats = await db.query('chats');
    final messages = await db.query('messages');
    final worldBooks = await db.query('world_books');
    final worldBookEntries = await db.query('world_book_entries');
    final settings = await db.query('settings');

    final backup = {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'characters': characters,
      'chats': chats,
      'messages': messages,
      'world_books': worldBooks,
      'world_book_entries': worldBookEntries,
      'settings': settings,
    };

    return const JsonEncoder.withIndent('  ').convert(backup);
  }

  Future<void> importBackup(String jsonContent) async {
    final Map<String, dynamic> backup = jsonDecode(jsonContent);
    
    if (!backup.containsKey('version')) {
      throw const FormatException('Invalid backup file format: missing version');
    }

    final db = await DatabaseService.database;

    await db.transaction((txn) async {
      // Delete in correct order to respect foreign keys (messages first, then chats/characters, then world books)
      await txn.delete('messages');
      await txn.delete('chats');
      await txn.delete('characters');
      await txn.delete('world_book_entries');
      await txn.delete('world_books');
      await txn.delete('settings');

      // Insert in reverse dependency order
      if (backup['world_books'] != null) {
        for (var row in List<Map<String, dynamic>>.from(backup['world_books'])) {
          await txn.insert('world_books', row);
        }
      }
      if (backup['world_book_entries'] != null) {
        for (var row in List<Map<String, dynamic>>.from(backup['world_book_entries'])) {
          await txn.insert('world_book_entries', row);
        }
      }
      if (backup['characters'] != null) {
        for (var row in List<Map<String, dynamic>>.from(backup['characters'])) {
          await txn.insert('characters', row);
        }
      }
      if (backup['chats'] != null) {
        for (var row in List<Map<String, dynamic>>.from(backup['chats'])) {
          await txn.insert('chats', row);
        }
      }
      if (backup['messages'] != null) {
        for (var row in List<Map<String, dynamic>>.from(backup['messages'])) {
          await txn.insert('messages', row);
        }
      }
      if (backup['settings'] != null) {
        for (var row in List<Map<String, dynamic>>.from(backup['settings'])) {
          await txn.insert('settings', row);
        }
      }
    });
  }
}
