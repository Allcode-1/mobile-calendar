import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/event_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'quiz_calendar.db');
    // update version to 2 because i changed table structure
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDb,
      onUpgrade: _onUpgrade,
    );
  }

  // method for db update if user already installed app
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE events ADD COLUMN is_completed INTEGER DEFAULT 0',
      );
    }
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color TEXT,
        icon TEXT,
        user_id TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE events (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        is_completed INTEGER DEFAULT 0,
        start_time TEXT,
        end_time TEXT,
        category_id TEXT,
        user_id TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_deleted INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> updateEventFields(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final db = await database;

    // copy map to not kill og table
    final Map<String, dynamic> dbUpdates = Map.from(updates);

    // convert bool into int for sqlite
    if (dbUpdates.containsKey('is_completed')) {
      dbUpdates['is_completed'] = dbUpdates['is_completed'] == true ? 1 : 0;
    }
    if (dbUpdates.containsKey('is_deleted')) {
      dbUpdates['is_deleted'] = dbUpdates['is_deleted'] == true ? 1 : 0;
    }

    dbUpdates['updated_at'] = DateTime.now().toIso8601String();

    await db.update('events', dbUpdates, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> upsertEvent(EventModel event) async {
    final db = await database;
    await db.insert(
      'events',
      event.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<EventModel>> getActiveEvents() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: 'is_deleted = 0',
    );
    return List.generate(maps.length, (i) => EventModel.fromJson(maps[i]));
  }

  Future<List<EventModel>> getAllEventsForSync() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('events');
    return List.generate(maps.length, (i) => EventModel.fromJson(maps[i]));
  }

  Future<void> softDeleteEvent(String id) async {
    await updateEventFields(id, {'is_deleted': true});
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('events');
    await db.delete('categories');
  }
}
