import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/stock_item.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'smartstock.db';
  static const _dbVersion = 1;
  static const _tableName = 'stock_items';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            quantity INTEGER NOT NULL,
            price REAL NOT NULL,
            description TEXT,
            date TEXT NOT NULL,
            imagePath TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insertStockItem(StockItem item) async {
    final db = await database;
    return db.insert(_tableName, item.toMap());
  }

  Future<List<StockItem>> getStockItems() async {
    final db = await database;
    final maps = await db.query(_tableName, orderBy: 'date DESC');
    return maps.map(StockItem.fromMap).toList();
  }

  Future<int> updateStockItem(StockItem item) async {
    final db = await database;
    return db.update(
      _tableName,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteStockItem(int id) async {
    final db = await database;
    return db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }
}
