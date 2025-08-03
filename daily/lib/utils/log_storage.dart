import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/daily_log.dart';

  class LogStorage {
    static Database? _db;

    static Future<Database> get database async {
      if (_db != null) return _db!;
      _db = await _initDB();
      return _db!;
    }

    static Future<Database> _initDB() async {
      final dir = await getExternalStorageDirectory();
      if (dir == null) {
        throw Exception('External storage directory is unavailable.');
      }

      final path = join(dir.path, 'journal_logs.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            mood INTEGER,
            text TEXT,
            imagePath TEXT,
            city TEXT
          )
        ''');
      },
    );
  }

  static Future<void> saveLogs(List<DailyLog> logs) async {
    try {
      final db = await database;
      await db.transaction((txn) async {
        await txn.delete('logs');
        for (DailyLog log in logs) {
          await txn.insert('logs', log.toJson());
        }
      });
    } catch (e) {
      print('Error saving logs: $e');
    }
  }

  static Future<List<DailyLog>> loadLogs() async {
    try {
      final db = await database;
      final maps = await db.query('logs');
      return maps.map((json) => DailyLog.fromJson(json)).toList();
    } catch (e) {
      print('Error loading logs: $e');
      return [];
    }
  }

  static Future<void> insertLog(DailyLog log) async {
    try {
      final db = await database;
      await db.insert('logs', log.toJson());
    } catch (e) {
      print('Error inserting log: $e');
    }
  }

  static Future<void> deleteAllLogs() async {
    try {
      final db = await database;
      await db.delete('logs');
    } catch (e) {
      print('Error deleting all logs: $e');
    }
  }

  static Future<void> deleteLogByDate(String date) async {
    try {
      final db = await database;
      await db.delete('logs', where: 'date = ?', whereArgs: [date]);
    } catch (e) {
      print('Error deleting log by date: $e');
    }
  }
}
