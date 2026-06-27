// ignore_for_file: prefer_initializing_formals

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vapor/core/database/database_service.dart';
import 'package:vapor/core/image_cache_service.dart';
import 'package:vapor/features/library/models/game_metadata.dart';
import 'package:vapor/features/library/models/game_model.dart';
import 'package:vapor/features/library/services/lutris_import_service.dart';
import 'package:vapor/features/library/services/metadata_service.dart';

import '../game_launch/game_launch_cubit.dart';
import 'library_state.dart';

class LibraryCubit extends Cubit<LibraryState> {
  final DatabaseService _db;
  final MetadataService _metadata;
  final LutrisImportService _lutris;
  final GameLaunchCubit _gameLaunch;
  final ImageCacheService _imageCache;

  LibraryCubit({
    required DatabaseService db,
    required MetadataService metadata,
    required LutrisImportService lutris,
    required GameLaunchCubit gameLaunch,
    required ImageCacheService imageCache,
  }) : _db = db,
       _metadata = metadata,
       _lutris = lutris,
       _gameLaunch = gameLaunch,
       _imageCache = imageCache,
       super(const LibraryState());

  Future<void> load() async {
    emit(state.copyWith(status: LibraryStatus.loading));
    try {
      final games = await _db.getAllGames();
      final metaMap = <int, GameMetadata>{};
      for (final g in games) {
        if (g.id == null) continue;
        final m = await _db.getMetadataByGameId(g.id!);
        if (m != null) metaMap[g.id!] = m;
      }
      emit(
        state.copyWith(
          games: games,
          metadata: metaMap,
          status: LibraryStatus.loaded,
        ),
      );
      _applyFilter(state.searchQuery);
    } catch (e) {
      emit(
        state.copyWith(status: LibraryStatus.error, errorMessage: e.toString()),
      );
    }
  }

  void search(String query) {
    emit(state.copyWith(searchQuery: query));
    _applyFilter(query);
  }

  void _applyFilter(String? query) {
    if (query == null || query.isEmpty) {
      emit(state.copyWith(filteredGames: state.games));
    } else {
      emit(
        state.copyWith(
          filteredGames: state.games
              .where((g) => g.name.toLowerCase().contains(query.toLowerCase()))
              .toList(),
        ),
      );
    }
  }

  Future<void> deleteGame(GameModel game) async {
    final gameKey = game.slug.isNotEmpty ? game.slug : game.id.toString();
    await _imageCache.deleteGameCache(gameKey);
    await _db.deleteMetadata(game.id!);
    await _db.deleteGame(game.id!);
    await load();
  }

  Future<void> importFromLutris() async {
    emit(state.copyWith(isImporting: true));
    final result = await _lutris.import();
    emit(state.copyWith(isImporting: false));
    if (result.error != null) {
      emit(state.copyWith(snackbarMessage: result.error));
    } else {
      emit(
        state.copyWith(
          snackbarMessage: '${result.imported} new, ${result.updated} updated',
        ),
      );
    }
    await load();
  }

  Future<void> fetchAllMetadata() async {
    final games = state.games.where((g) => g.id != null).toList();
    emit(
      state.copyWith(
        fetchProgress: MetadataFetchProgress(
          inProgress: true,
          done: 0,
          total: games.length,
        ),
      ),
    );
    for (final game in games) {
      try {
        await _metadata.fetchAndCache(game.id!, game.name, slug: game.slug);
      } catch (_) {}
      emit(
        state.copyWith(
          fetchProgress: MetadataFetchProgress(
            inProgress: true,
            done: state.fetchProgress.done + 1,
            total: games.length,
          ),
        ),
      );
    }
    emit(
      state.copyWith(
        fetchProgress: const MetadataFetchProgress(),
        snackbarMessage:
            'Metadata fetched for ${games.length}/${games.length} games',
      ),
    );
    await load();
  }

  void launch(GameModel game) {
    _gameLaunch.launch(game);
  }

  void clearSnackbar() {
    emit(state.copyWith(clearSnackbar: true));
  }
}
