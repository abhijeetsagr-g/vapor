import 'dart:async';

import '../../../core/database/database_service.dart';
import '../../../core/image_cache_service.dart';
import '../models/game_metadata.dart';
import 'rawg_api_service.dart';
import 'steamgriddb_service.dart';

class MetadataService {
  final RawgApiService _rawg;
  final SteamGridDbService _sgdb;
  final DatabaseService _db;
  final ImageCacheService _imageCache;

  MetadataService({
    required this._rawg,
    required this._sgdb,
    required this._db,
    required this._imageCache,
  });

  Future<GameMetadata?> get(int gameId) {
    return _db.getMetadataByGameId(gameId);
  }

  Future<GameMetadata> fetchAndCache(
    int gameId,
    String gameName, {
    String slug = '',
  }) async {
    final key = slug.isNotEmpty ? slug : gameId.toString();
    final cached = await _db.getMetadataByGameId(gameId);
    if (cached != null) {
      unawaited(_cacheImages(key, cached));
      return cached;
    }

    var meta = GameMetadata(gameId: gameId);

    // ── RAWG ──────────────────────────────────────────────────────
    try {
      final results = await _rawg.search(gameName);
      if (results.isNotEmpty) {
        final detail = await _rawg.getById(results.first.id);
        if (detail != null) {
          meta = meta.copyWith(
            rawgId: detail.id,
            coverUrl: detail.coverUrl,
            backgroundUrl: detail.backgroundUrl,
            description: detail.description,
            genres: detail.genres,
            tags: detail.tags,
            releaseDate: detail.released,
            esrbRating: detail.esrbRating,
            metacritic: detail.metacritic,
            website: detail.website,
          );

          final screenshots = await _rawg.getScreenshots(detail.id);
          final movieUrl = await _rawg.getMovie(detail.id);
          final achievements = await _rawg.getAchievements(detail.id);
          meta = meta.copyWith(
            screenshots: screenshots,
            movieUrl: movieUrl,
            achievements: achievements,
          );
        }
      }
    } catch (_) {
      // best-effort
    }

    // ── SteamGridDB ────────────────────────────────────────────────
    try {
      if (_sgdb.apiKey.isNotEmpty) {
        final sgResults = await _sgdb.search(gameName);
        if (sgResults.isNotEmpty) {
          final sgId = sgResults.first.id;
          meta = meta.copyWith(
            gridUrl: await _sgdb.getGrid(sgId),
            heroUrl: await _sgdb.getHero(sgId),
            logoUrl: await _sgdb.getLogo(sgId),
            iconUrl: await _sgdb.getIcon(sgId),
          );
        }
      }
    } catch (_) {
      // best-effort
    }

    await _db.upsertMetadata(meta);
    unawaited(_cacheImages(key, meta));
    return meta;
  }

  Future<List<RawgGameSearchResult>> search(String query) {
    return _rawg.search(query);
  }

  Future<void> _cacheImages(String gameKey, GameMetadata meta) async {
    final urls = <String, String>{
      if (meta.coverUrl != null) 'cover': meta.coverUrl!,
      if (meta.backgroundUrl != null) 'background': meta.backgroundUrl!,
      if (meta.gridUrl != null) 'grid': meta.gridUrl!,
      if (meta.heroUrl != null) 'hero': meta.heroUrl!,
      if (meta.logoUrl != null) 'logo': meta.logoUrl!,
      if (meta.iconUrl != null) 'icon': meta.iconUrl!,
    };
    for (var i = 0; i < meta.achievements.length; i++) {
      urls['achievement_$i'] = meta.achievements[i].image;
    }
    await _imageCache.cacheAll(gameKey, urls);
  }
}
