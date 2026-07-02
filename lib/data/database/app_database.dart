import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_constants.dart';

/// Центральная точка доступа к локальной базе данных SQLite.
///
/// Вся информация приложения хранится исключительно на устройстве.
/// Не используется ни одна сетевая зависимость для чтения/записи данных.
class AppDatabase {
  AppDatabase._internal();

  static final AppDatabase instance = AppDatabase._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<String> get documentsPath async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  Future<Directory> photosDirectory() async {
    final docs = await documentsPath;
    final dir = Directory(p.join(docs, AppConstants.photosDirName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> backupsDirectory() async {
    final docs = await documentsPath;
    final dir = Directory(p.join(docs, AppConstants.backupsDirName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> tileCacheDirectory() async {
    final docs = await documentsPath;
    final dir = Directory(p.join(docs, AppConstants.tileCacheDirName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Database> _open() async {
    final docs = await documentsPath;
    final path = p.join(docs, AppConstants.dbName);
    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE fish (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT,
        photo_paths TEXT,
        notes TEXT,
        favorite_bait_id TEXT,
        average_size_cm REAL,
        record_weight_kg REAL,
        record_length_cm REAL,
        color TEXT,
        habitat_notes TEXT,
        custom_notes TEXT,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE baits (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        photo_paths TEXT,
        brand TEXT,
        type TEXT,
        color TEXT,
        size TEXT,
        weight_g REAL,
        notes TEXT,
        rating INTEGER NOT NULL DEFAULT 0,
        favorite_fish_id TEXT,
        best_season TEXT,
        best_weather TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE equipment (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        photo_paths TEXT,
        brand TEXT,
        model TEXT,
        purchase_date TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE spots (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        marker_type TEXT NOT NULL DEFAULT 'spot',
        color TEXT,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        photo_paths TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE trips (
        id TEXT PRIMARY KEY,
        title TEXT,
        start_date TEXT NOT NULL,
        end_date TEXT,
        notes TEXT,
        photo_paths TEXT,
        distance_km REAL,
        favorite_catch_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE catches (
        id TEXT PRIMARY KEY,
        fish_id TEXT,
        trip_id TEXT,
        spot_id TEXT,
        date TEXT NOT NULL,
        weight_kg REAL,
        length_cm REAL,
        quantity INTEGER NOT NULL DEFAULT 1,
        latitude REAL,
        longitude REAL,
        photo_paths TEXT,
        bait_id TEXT,
        lure_equipment_id TEXT,
        rod_equipment_id TEXT,
        reel_equipment_id TEXT,
        line_equipment_id TEXT,
        hook_equipment_id TEXT,
        method TEXT,
        weather_text TEXT,
        water_temp_c REAL,
        air_temp_c REAL,
        wind_text TEXT,
        pressure_hpa REAL,
        water_clarity TEXT,
        water_level TEXT,
        notes TEXT,
        rating INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (fish_id) REFERENCES fish (id) ON DELETE SET NULL,
        FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE SET NULL,
        FOREIGN KEY (spot_id) REFERENCES spots (id) ON DELETE SET NULL,
        FOREIGN KEY (bait_id) REFERENCES baits (id) ON DELETE SET NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE map_areas (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        area_type TEXT NOT NULL DEFAULT 'fishing',
        color TEXT,
        points TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE routes (
        id TEXT PRIMARY KEY,
        trip_id TEXT,
        name TEXT,
        points TEXT NOT NULL,
        distance_km REAL,
        started_at TEXT NOT NULL,
        finished_at TEXT,
        FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE SET NULL
      )
    ''');

    batch.execute('CREATE INDEX idx_catches_date ON catches (date)');
    batch.execute('CREATE INDEX idx_catches_fish ON catches (fish_id)');
    batch.execute('CREATE INDEX idx_catches_spot ON catches (spot_id)');
    batch.execute('CREATE INDEX idx_catches_trip ON catches (trip_id)');
    batch.execute('CREATE INDEX idx_catches_bait ON catches (bait_id)');
    batch.execute('CREATE INDEX idx_trips_start ON trips (start_date)');
    batch.execute('CREATE INDEX idx_spots_favorite ON spots (is_favorite)');

    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }

  /// Полный сброс локальной базы данных (используется при восстановлении
  /// из резервной копии или при очистке данных в настройках).
  Future<void> resetDatabase() async {
    final docs = await documentsPath;
    final path = p.join(docs, AppConstants.dbName);
    await close();
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    _db = await _open();
  }
}
