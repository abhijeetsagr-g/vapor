import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vapor/core/database/database_service.dart';
import 'package:vapor/features/library/models/game_model.dart';

import 'metadata_service.dart';

class LutrisImportResult {
  final int imported;
  final int updated;
  final String? error;

  LutrisImportResult({
    required this.imported,
    required this.updated,
    this.error,
  });
}

class LutrisImportService {
  static const _lutrisDbPath = '.local/share/lutris/pga.db';

  static String _getLutrisDbPath() {
    final home =
        Platform.environment['HOME'] ?? '/home/${Platform.environment['USER']}';
    return p.join(home, _lutrisDbPath);
  }

  static Future<LutrisImportResult> import({bool onlyInstalled = true}) async {
    final lutrisPath = _getLutrisDbPath();
    Database? lutrisDb;
    try {
      lutrisDb = await databaseFactoryFfi.openDatabase(
        lutrisPath,
        options: OpenDatabaseOptions(readOnly: true),
      );
    } catch (e) {
      return LutrisImportResult(
        imported: 0,
        updated: 0,
        error: 'Could not open Lutris database at $lutrisPath\n$e',
      );
    }

    try {
      final where = onlyInstalled ? 'WHERE installed = 1' : '';
      final rows = await lutrisDb.rawQuery('SELECT * FROM games $where');
      final db = DatabaseService.instance;

      int imported = 0;
      int updated = 0;

      for (final row in rows) {
        final lutrisId = row['id'] as int;
        final lutrisPlaytime = Duration(
          seconds: (((row['playtime'] as num?)?.toDouble() ?? 0.0) * 3600)
              .round(),
        );
        final lutrisLastPlayed =
            row['lastplayed'] != null && (row['lastplayed'] as int) > 0
            ? DateTime.fromMillisecondsSinceEpoch(
                (row['lastplayed'] as int) * 1000,
              )
            : null;

        final existing = await db.getGameByService(
          'lutris',
          lutrisId.toString(),
        );

        if (existing != null) {
          await db.updateGame(
            existing.copyWith(
              name: row['name'] as String,
              slug: (row['slug'] as String?) ?? '',
              playtime: lutrisPlaytime,
              installed: (row['installed'] as int?) == 1,
              lastPlayed: lutrisLastPlayed,
            ),
          );
          updated++;
          continue;
        }

        final newId = await db.insertGame(
          GameModel(
            appId: lutrisId.toString(),
            name: row['name'] as String,
            slug: (row['slug'] as String?) ?? '',
            service: Service.lutris,
            execPath: (row['executable'] as String?) ?? '',
            runnerPath: (row['runner'] as String?) ?? '',
            configPath: (row['configpath'] as String?) ?? '',
            playtime: lutrisPlaytime,
            installed: (row['installed'] as int?) == 1,
            lastPlayed: lutrisLastPlayed,
          ),
        );
        imported++;
        try {
          await MetadataService.fetchAndCache(
            newId,
            row['name'] as String,
          );
        } catch (_) {
          // metadata is best-effort
        }
      }

      return LutrisImportResult(imported: imported, updated: updated);
    } finally {
      await lutrisDb.close();
    }
  }
}
