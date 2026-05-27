import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_constants.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    if (kIsWeb) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfiWeb;
    }
    
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE characters (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        avatar_path TEXT,
        description TEXT NOT NULL,
        greeting TEXT NOT NULL,
        example_messages TEXT,
        system_prompt TEXT,
        tags TEXT DEFAULT '[]',
        world_book_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_chatted_at TEXT,
        FOREIGN KEY (world_book_id) REFERENCES world_books(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE chats (
        id TEXT PRIMARY KEY,
        character_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (character_id) REFERENCES characters(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        chat_id TEXT NOT NULL,
        parent_id TEXT,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        attachments TEXT,
        tokens_used INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE,
        FOREIGN KEY (parent_id) REFERENCES messages(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE world_books (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE world_book_entries (
        id TEXT PRIMARY KEY,
        world_book_id TEXT NOT NULL,
        name TEXT NOT NULL,
        keywords TEXT NOT NULL,
        content TEXT NOT NULL,
        category TEXT DEFAULT 'general',
        priority INTEGER DEFAULT 0,
        enabled INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (world_book_id) REFERENCES world_books(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Indexes
    await db.execute('CREATE INDEX idx_chats_character ON chats(character_id)');
    await db.execute('CREATE INDEX idx_messages_chat ON messages(chat_id)');
    await db.execute('CREATE INDEX idx_messages_parent ON messages(parent_id)');
    await db.execute('CREATE INDEX idx_entries_worldbook ON world_book_entries(world_book_id)');
  }

  static Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
