import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'database.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
        onUpgrade: (db, oldVersion, newVersion) {
          if (oldVersion < newVersion) {
            db.execute('DROP TABLE IF EXISTS tasks');
            _onCreate(db, newVersion);  // Recreate the table
          }
        }
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        isDone INTEGER,
        date TEXT,
        startTime TEXT,
        endTime TEXT,
        notify INTEGER
      )
    ''');
  }
}
