import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/animal.dart';
import '../models/measurement.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'bovinos.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE animals (
        id TEXT PRIMARY KEY,
        tag TEXT NOT NULL,
        name TEXT,
        breed TEXT,
        sex TEXT,
        birth_date TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE measurements (
        id TEXT PRIMARY KEY,
        animal_id TEXT NOT NULL,
        date TEXT NOT NULL,
        icc REAL,
        icc_method TEXT,
        weight_kg REAL,
        weight_method TEXT,
        heart_girth_cm REAL,
        body_length_cm REAL,
        hip_width_cm REAL,
        withers_height_cm REAL,
        body_depth_cm REAL,
        rump_angle_deg REAL,
        coat_score REAL,
        bbox_confidence REAL,
        photo_side_path TEXT,
        photo_rear_path TEXT,
        photo_front_path TEXT,
        notes TEXT,
        FOREIGN KEY (animal_id) REFERENCES animals(id) ON DELETE CASCADE
      )
    ''');
  }

  // Animals CRUD
  Future<void> insertAnimal(Animal animal) async {
    final database = await db;
    await database.insert('animals', animal.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateAnimal(Animal animal) async {
    final database = await db;
    await database.update('animals', animal.toMap(),
        where: 'id = ?', whereArgs: [animal.id]);
  }

  Future<void> deleteAnimal(String id) async {
    final database = await db;
    await database.delete('animals', where: 'id = ?', whereArgs: [id]);
  }

  Future<Animal?> getAnimal(String id) async {
    final database = await db;
    final maps =
        await database.query('animals', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Animal.fromMap(maps.first);
  }

  Future<List<Animal>> getAnimals({String? searchQuery}) async {
    final database = await db;
    List<Map<String, dynamic>> maps;
    if (searchQuery != null && searchQuery.isNotEmpty) {
      maps = await database.query(
        'animals',
        where: 'tag LIKE ? OR name LIKE ?',
        whereArgs: ['%$searchQuery%', '%$searchQuery%'],
        orderBy: 'created_at DESC',
      );
    } else {
      maps = await database.query('animals', orderBy: 'created_at DESC');
    }
    return maps.map(Animal.fromMap).toList();
  }

  Future<bool> tagExists(String tag, {String? excludeId}) async {
    final database = await db;
    final maps = await database.query(
      'animals',
      where: excludeId != null ? 'tag = ? AND id != ?' : 'tag = ?',
      whereArgs: excludeId != null ? [tag, excludeId] : [tag],
    );
    return maps.isNotEmpty;
  }

  // Measurements CRUD
  Future<void> insertMeasurement(Measurement m) async {
    final database = await db;
    await database.insert('measurements', m.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateMeasurement(Measurement m) async {
    final database = await db;
    await database.update('measurements', m.toMap(),
        where: 'id = ?', whereArgs: [m.id]);
  }

  Future<void> deleteMeasurement(String id) async {
    final database = await db;
    await database
        .delete('measurements', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Measurement>> getMeasurements(String animalId) async {
    final database = await db;
    final maps = await database.query(
      'measurements',
      where: 'animal_id = ?',
      whereArgs: [animalId],
      orderBy: 'date DESC',
    );
    return maps.map(Measurement.fromMap).toList();
  }

  Future<Measurement?> getLatestMeasurement(String animalId) async {
    final database = await db;
    final maps = await database.query(
      'measurements',
      where: 'animal_id = ?',
      whereArgs: [animalId],
      orderBy: 'date DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Measurement.fromMap(maps.first);
  }

  Future<Map<String, dynamic>> getStats() async {
    final database = await db;
    final animalCount = Sqflite.firstIntValue(
        await database.rawQuery('SELECT COUNT(*) FROM animals'));
    final measurementCount = Sqflite.firstIntValue(
        await database.rawQuery('SELECT COUNT(*) FROM measurements'));
    final avgIcc = (await database.rawQuery(
            'SELECT AVG(icc) as avg FROM measurements WHERE icc IS NOT NULL'))
        .first['avg'];
    final avgWeight = (await database.rawQuery(
            'SELECT AVG(weight_kg) as avg FROM measurements WHERE weight_kg IS NOT NULL'))
        .first['avg'];
    return {
      'animals': animalCount ?? 0,
      'measurements': measurementCount ?? 0,
      'avgIcc': avgIcc,
      'avgWeight': avgWeight,
    };
  }
}
