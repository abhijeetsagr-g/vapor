import '../../../core/config.dart';
import '../../../core/database/database_service.dart';
import '../models/game_metadata.dart';
import 'rawg_api_service.dart';
import 'steamgriddb_service.dart';

class MetadataService {
  static RawgApiService? _rawg;
  static SteamGridDbService? _sgdb;

  static RawgApiService get _rawgClient {
    if (_rawg != null) return _rawg!;
    final key = Config.get('RAWG_KEY');
    if (key == null || key.isEmpty) {
      throw Exception('RAWG_KEY not found in .env or environment');
    }
    _rawg = RawgApiService(apiKey: key);
    return _rawg!;
  }

  static SteamGridDbService get _sgdbClient {
    if (_sgdb != null) return _sgdb!;
    final key = Config.get('STEAMGRIDDB_KEY');
    if (key == null || key.isEmpty) {
      _sgdb = SteamGridDbService(apiKey: '');
      return _sgdb!;
    }
    _sgdb = SteamGridDbService(apiKey: key);
    return _sgdb!;
  }

  static Future<GameMetadata?> get(int gameId) {
    return DatabaseService.instance.getMetadataByGameId(gameId);
  }

  static Future<GameMetadata> fetchAndCache(int gameId, String gameName) async {
    final cached = await DatabaseService.instance.getMetadataByGameId(gameId);
    if (cached != null) return cached;

    var meta = GameMetadata(gameId: gameId);

    // ── RAWG ──────────────────────────────────────────────────────
    try {
      final results = await _rawgClient.search(gameName);
      if (results.isNotEmpty) {
        final detail = await _rawgClient.getById(results.first.id);
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

          final screenshots = await _rawgClient.getScreenshots(detail.id);
          final movieUrl = await _rawgClient.getMovie(detail.id);
          meta = meta.copyWith(
            screenshots: screenshots,
            movieUrl: movieUrl,
          );
        }
      }
    } catch (_) {
      // best-effort
    }

    // ── SteamGridDB ────────────────────────────────────────────────
    try {
      if (_sgdbClient.apiKey.isNotEmpty) {
        final sgResults = await _sgdbClient.search(gameName);
        if (sgResults.isNotEmpty) {
          final sgId = sgResults.first.id;
          meta = meta.copyWith(
            gridUrl: await _sgdbClient.getGrid(sgId),
            heroUrl: await _sgdbClient.getHero(sgId),
            logoUrl: await _sgdbClient.getLogo(sgId),
            iconUrl: await _sgdbClient.getIcon(sgId),
          );
        }
      }
    } catch (_) {
      // best-effort
    }

    await DatabaseService.instance.upsertMetadata(meta);
    return meta;
  }

  static Future<List<RawgGameSearchResult>> search(String query) {
    return _rawgClient.search(query);
  }
}
