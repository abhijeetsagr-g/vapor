import 'dart:convert';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vapor/core/app_paths.dart';
import 'package:vapor/features/library/models/achievement.dart';
import 'package:vapor/features/library/models/game_metadata.dart';
import 'package:vapor/features/library/models/game_model.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static Database? _db;

  DatabaseService._();

  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  Future<Database> _init() async {
    sqfliteFfiInit();
    await AppPaths.ensureDirs();
    return openDatabase(
      AppPaths.dbPath,
      version: 5,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE games (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            appId TEXT,
            name TEXT NOT NULL,
            slug TEXT NOT NULL,
            service TEXT NOT NULL,
            execPath TEXT NOT NULL,
            runnerPath TEXT NOT NULL,
            configPath TEXT NOT NULL,
            playtime INTEGER NOT NULL DEFAULT 0,
            installed INTEGER NOT NULL DEFAULT 0,
            lastPlayed INTEGER
          )
        ''');
        await _createMetadataTable(db);
      },
      onUpgrade: (db, old, now) async {
        if (old < 2) {
          await db.execute('ALTER TABLE games ADD COLUMN slug TEXT NOT NULL DEFAULT ""');
        }
        if (old < 3) {
          await _createMetadataTable(db);
        }
        if (old < 4) {
          await _migrateMetadataV4(db);
        }
        if (old < 5) {
          await _migrateMetadataV5(db);
        }
      },
    );
  }

  Future<int> insertGame(GameModel game) async {
    final db = await database;
    return db.insert('games', _toMap(game));
  }

  Future<List<GameModel>> getAllGames() async {
    final db = await database;
    final maps = await db.query('games', orderBy: 'name ASC');
    return maps.map(_fromMap).toList();
  }

  Future<GameModel?> getGameByService(String service, String appId) async {
    final db = await database;
    final maps = await db.query(
      'games',
      where: 'service = ? AND appId = ?',
      whereArgs: [service, appId],
    );
    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  Future<GameModel?> getGame(int id) async {
    final db = await database;
    final maps = await db.query('games', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  Future<int> updateGame(GameModel game) async {
    final db = await database;
    return db.update(
      'games',
      _toMap(game),
      where: 'id = ?',
      whereArgs: [game.id],
    );
  }

  Future<int> deleteGame(int id) async {
    final db = await database;
    return db.delete('games', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> _createMetadataTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS game_metadata (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        gameId INTEGER NOT NULL UNIQUE,
        rawgId INTEGER,
        coverUrl TEXT,
        backgroundUrl TEXT,
        description TEXT,
        genres TEXT NOT NULL DEFAULT '[]',
        tags TEXT NOT NULL DEFAULT '[]',
        releaseDate TEXT,
        esrbRating TEXT,
        metacritic REAL,
        website TEXT,
        gridUrl TEXT,
        heroUrl TEXT,
        logoUrl TEXT,
        iconUrl TEXT,
        screenshots TEXT NOT NULL DEFAULT '[]',
        movieUrl TEXT,
        achievements TEXT NOT NULL DEFAULT '[]',
        FOREIGN KEY (gameId) REFERENCES games(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _migrateMetadataV4(Database db) async {
    await db.execute('ALTER TABLE game_metadata ADD COLUMN gridUrl TEXT');
    await db.execute('ALTER TABLE game_metadata ADD COLUMN heroUrl TEXT');
    await db.execute('ALTER TABLE game_metadata ADD COLUMN logoUrl TEXT');
    await db.execute('ALTER TABLE game_metadata ADD COLUMN iconUrl TEXT');
    await db.execute(
      'ALTER TABLE game_metadata ADD COLUMN screenshots TEXT NOT NULL DEFAULT "[]"',
    );
    await db.execute('ALTER TABLE game_metadata ADD COLUMN movieUrl TEXT');
  }

  Future<void> _migrateMetadataV5(Database db) async {
    await db.execute(
      'ALTER TABLE game_metadata ADD COLUMN achievements TEXT NOT NULL DEFAULT "[]"',
    );
  }

  Future<void> upsertMetadata(GameMetadata meta) async {
    final db = await database;
    await db.insert(
      'game_metadata',
      _metaToMap(meta),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<GameMetadata?> getMetadataByGameId(int gameId) async {
    final db = await database;
    final maps = await db.query(
      'game_metadata',
      where: 'gameId = ?',
      whereArgs: [gameId],
    );
    if (maps.isEmpty) return null;
    return _metaFromMap(maps.first);
  }

  Future<void> deleteMetadata(int gameId) async {
    final db = await database;
    await db.delete('game_metadata', where: 'gameId = ?', whereArgs: [gameId]);
  }

  Map<String, dynamic> _metaToMap(GameMetadata meta) => {
        'gameId': meta.gameId,
        'rawgId': meta.rawgId,
        'coverUrl': meta.coverUrl,
        'backgroundUrl': meta.backgroundUrl,
        'description': meta.description,
        'genres': jsonEncode(meta.genres),
        'tags': jsonEncode(meta.tags),
        'releaseDate': meta.releaseDate,
        'esrbRating': meta.esrbRating,
        'metacritic': meta.metacritic,
        'website': meta.website,
        'gridUrl': meta.gridUrl,
        'heroUrl': meta.heroUrl,
        'logoUrl': meta.logoUrl,
        'iconUrl': meta.iconUrl,
        'screenshots': jsonEncode(meta.screenshots),
        'movieUrl': meta.movieUrl,
        'achievements': jsonEncode(meta.achievements.map((a) => a.toJson()).toList()),
      };

  GameMetadata _metaFromMap(Map<String, dynamic> map) => GameMetadata(
        id: map['id'] as int,
        gameId: map['gameId'] as int,
        rawgId: map['rawgId'] as int?,
        coverUrl: map['coverUrl'] as String?,
        backgroundUrl: map['backgroundUrl'] as String?,
        description: map['description'] as String?,
        genres: (jsonDecode(map['genres'] as String) as List<dynamic>)
            .cast<String>(),
        tags: (jsonDecode(map['tags'] as String) as List<dynamic>)
            .cast<String>(),
        releaseDate: map['releaseDate'] as String?,
        esrbRating: map['esrbRating'] as String?,
        metacritic: (map['metacritic'] as num?)?.toDouble(),
        website: map['website'] as String?,
        gridUrl: map['gridUrl'] as String?,
        heroUrl: map['heroUrl'] as String?,
        logoUrl: map['logoUrl'] as String?,
        iconUrl: map['iconUrl'] as String?,
        screenshots:
            (jsonDecode(map['screenshots'] as String) as List<dynamic>)
                .cast<String>(),
        movieUrl: map['movieUrl'] as String?,
        achievements: (jsonDecode(map['achievements'] as String) as List<dynamic>)
            .map((a) => Achievement.fromJson(a as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> _toMap(GameModel game) => {
        'appId': game.appId,
        'name': game.name,
        'slug': game.slug,
        'service': game.service.name,
        'execPath': game.execPath,
        'runnerPath': game.runnerPath,
        'configPath': game.configPath,
        'playtime': game.playtime.inSeconds,
        'installed': game.installed ? 1 : 0,
        'lastPlayed': game.lastPlayed?.millisecondsSinceEpoch,
      };

  GameModel _fromMap(Map<String, dynamic> map) => GameModel(
        id: map['id'] as int,
        appId: map['appId'] as String?,
        name: map['name'] as String,
        slug: map['slug'] as String,
        service: Service.values.byName(map['service'] as String),
        execPath: map['execPath'] as String,
        runnerPath: map['runnerPath'] as String,
        configPath: map['configPath'] as String,
        playtime: Duration(seconds: map['playtime'] as int),
        installed: (map['installed'] as int) == 1,
        lastPlayed: map['lastPlayed'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['lastPlayed'] as int)
            : null,
      );
}
