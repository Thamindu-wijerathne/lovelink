import 'dart:convert';
import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class PrivateKeyHelper {
  static Database? _db;

  // Get or create database
  static Future<Database> getDatabase() async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  // Initialize DB and table
  static Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'private_keys.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE private_keys(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId TEXT UNIQUE,
            privateKey TEXT
          )
        ''');
      },
    );
  }

  // Save or update private key for a user
  static Future<void> savePrivateKey(String userId, Uint8List privateKeyBytes) async {
    final db = await getDatabase();
    final privateKeyBase64 = base64Encode(privateKeyBytes);

    await db.insert(
      'private_keys',
      {'userId': userId, 'privateKey': privateKeyBase64},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Retrieve private key for a user
  static Future<Uint8List?> getPrivateKey(String userId) async {
    final db = await getDatabase();
    final result = await db.query(
      'private_keys',
      where: 'userId = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return base64Decode(result.first['privateKey'] as String);
    }
    return null;
  }

  // Delete private key (e.g., on logout or account deletion)
  static Future<void> deletePrivateKey(String userId) async {
    final db = await getDatabase();
    await db.delete('private_keys', where: 'userId = ?', whereArgs: [userId]);
  }
}
