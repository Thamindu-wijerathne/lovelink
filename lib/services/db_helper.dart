import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> getDatabase() async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }

  static Future<Database> initDB() async {
    String path = join(await getDatabasesPath(), 'preferences.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE preferences(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            preference TEXT
          )
        ''');
      },
    );
  }

  static Future<void> savePreferences(List<String> prefs) async {
    final db = await getDatabase();
    await db.delete('preferences'); // remove old
    for (var p in prefs) {
      await db.insert('preferences', {'preference': p});
    }
  }

  static Future<List<String>> getPreferences() async {
    final db = await getDatabase();
    final result = await db.query('preferences');
    return result.map((e) => e['preference'] as String).toList();
  }
}
