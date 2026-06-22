import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static Database? _db;

  static Future<Database> get instance async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'suru_gardas.db');
    _db = await openDatabase(path, version: 1, onCreate: _create);
    return _db!;
  }

  static Future<void> _create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE paddocks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        note TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE animals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        earTag TEXT NOT NULL UNIQUE,
        type TEXT NOT NULL,
        gender TEXT NOT NULL,
        breed TEXT,
        birthDate TEXT,
        motherEarTag TEXT,
        fatherEarTag TEXT,
        purchaseDate TEXT,
        purchasePrice REAL DEFAULT 0,
        purchasedFrom TEXT,
        status TEXT NOT NULL,
        paddock TEXT,
        note TEXT,
        photoPath TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_animals_ear_tag ON animals(earTag)');
    await db.execute('CREATE INDEX idx_animals_status ON animals(status)');
    await db.execute('''
      CREATE TABLE lambings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        motherId INTEGER,
        motherEarTag TEXT NOT NULL,
        birthDate TEXT NOT NULL,
        lambCount INTEGER DEFAULT 0,
        aliveCount INTEGER DEFAULT 0,
        deadCount INTEGER DEFAULT 0,
        gendersText TEXT,
        birthNote TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE breedings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        eweId INTEGER,
        eweEarTag TEXT NOT NULL,
        ramId INTEGER,
        ramEarTag TEXT NOT NULL,
        breedingDate TEXT NOT NULL,
        estimatedBirthDate TEXT NOT NULL,
        pregnancyStatus TEXT NOT NULL,
        controlDate TEXT,
        reminderDate TEXT,
        note TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE health_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        animalId INTEGER,
        earTag TEXT NOT NULL,
        recordType TEXT NOT NULL,
        recordDate TEXT NOT NULL,
        vetName TEXT,
        cost REAL DEFAULT 0,
        nextControlDate TEXT,
        note TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE feeds(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        amount REAL DEFAULT 0,
        unit TEXT NOT NULL,
        unitPrice REAL DEFAULT 0,
        total REAL DEFAULT 0,
        purchaseDate TEXT NOT NULL,
        supplier TEXT,
        stock REAL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE feed_usages(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        feedId INTEGER NOT NULL,
        feedName TEXT NOT NULL,
        amount REAL DEFAULT 0,
        usageDate TEXT NOT NULL,
        note TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kind TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL DEFAULT 0,
        txDate TEXT NOT NULL,
        description TEXT,
        animalId INTEGER,
        createdAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE purchases(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        animalCount INTEGER DEFAULT 1,
        earTag TEXT,
        purchasePrice REAL DEFAULT 0,
        sellerName TEXT,
        purchaseDate TEXT NOT NULL,
        note TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE sales(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        animalId INTEGER NOT NULL,
        earTag TEXT NOT NULL,
        salePrice REAL DEFAULT 0,
        buyerName TEXT,
        saleDate TEXT NOT NULL,
        paymentStatus TEXT NOT NULL,
        profit REAL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  static Future<List<Map<String, Object?>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    return (await instance).query(table, where: where, whereArgs: whereArgs, orderBy: orderBy, limit: limit);
  }

  static Future<int> insert(String table, Map<String, Object?> values) async {
    return (await instance).insert(table, values, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<int> update(String table, int id, Map<String, Object?> values) async {
    final clean = Map<String, Object?>.from(values)..remove('id');
    return (await instance).update(table, clean, where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<Map<String, Object?>>> raw(String sql, [List<Object?> args = const []]) async {
    return (await instance).rawQuery(sql, args);
  }
}
