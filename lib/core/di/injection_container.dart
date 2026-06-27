import 'package:get_it/get_it.dart';
import 'package:vapor/core/config.dart';
import 'package:vapor/core/database/database_service.dart';
import 'package:vapor/core/image_cache_service.dart';
import 'package:vapor/features/library/presentation/cubit/add_game/add_game_cubit.dart';
import 'package:vapor/features/library/presentation/cubit/game_detail/game_detail_cubit.dart';
import 'package:vapor/features/library/presentation/cubit/game_launch/game_launch_cubit.dart';
import 'package:vapor/features/library/presentation/cubit/game_log/game_log_cubit.dart';
import 'package:vapor/features/library/presentation/cubit/library/library_cubit.dart';
import 'package:vapor/features/library/presentation/cubit/runner_list/runner_list_cubit.dart';
import 'package:vapor/features/library/services/game_runner_service.dart';
import 'package:vapor/features/library/services/lutris_import_service.dart';
import 'package:vapor/features/library/services/metadata_service.dart';
import 'package:vapor/features/library/services/rawg_api_service.dart';
import 'package:vapor/features/library/services/runner_discovery_service.dart';
import 'package:vapor/features/library/services/steamgriddb_service.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // ── Core services
  getIt.registerLazySingleton<DatabaseService>(() => DatabaseService.instance);
  getIt.registerLazySingleton<ImageCacheService>(() => ImageCacheService());

  // ── API services
  getIt.registerLazySingleton<RawgApiService>(() {
    final key = Config.get('RAWG_KEY');
    if (key == null || key.isEmpty) {
      throw Exception('RAWG_KEY not found in .env or environment');
    }
    return RawgApiService(apiKey: key);
  });

  getIt.registerLazySingleton<SteamGridDbService>(() {
    final key = Config.get('STEAMGRIDDB_KEY');
    return SteamGridDbService(apiKey: key ?? '');
  });

  // ── App services ────────────────────────────────────────────
  getIt.registerLazySingleton<RunnerDiscoveryService>(
    () => RunnerDiscoveryService(),
  );

  getIt.registerLazySingleton<MetadataService>(
    () => MetadataService(
      rawg: getIt<RawgApiService>(),
      sgdb: getIt<SteamGridDbService>(),
      db: getIt<DatabaseService>(),
      imageCache: getIt<ImageCacheService>(),
    ),
  );

  getIt.registerLazySingleton<LutrisImportService>(
    () => LutrisImportService(
      db: getIt<DatabaseService>(),
      metadata: getIt<MetadataService>(),
    ),
  );

  // ── Shared cubits ───────────────────────────────────────────
  getIt.registerLazySingleton<GameLogCubit>(() => GameLogCubit());

  getIt.registerLazySingleton<GameRunnerService>(
    () => GameRunnerService(
      runnerDiscovery: getIt<RunnerDiscoveryService>(),
      log: getIt<GameLogCubit>().write,
    ),
  );

  getIt.registerLazySingleton<GameLaunchCubit>(
    () => GameLaunchCubit(
      gameRunner: getIt<GameRunnerService>(),
      db: getIt<DatabaseService>(),
      log: getIt<GameLogCubit>(),
    ),
  );

  // ── Feature cubits (factory = new instance per provider) ────
  getIt.registerFactory<LibraryCubit>(
    () => LibraryCubit(
      db: getIt<DatabaseService>(),
      metadata: getIt<MetadataService>(),
      lutris: getIt<LutrisImportService>(),
      gameLaunch: getIt<GameLaunchCubit>(),
      imageCache: getIt<ImageCacheService>(),
    ),
  );

  getIt.registerFactoryParam<GameDetailCubit, int, void>(
    (gameId, _) => GameDetailCubit(
      gameId: gameId,
      db: getIt<DatabaseService>(),
      gameLaunch: getIt<GameLaunchCubit>(),
    ),
  );

  getIt.registerFactory<AddGameCubit>(
    () => AddGameCubit(
      db: getIt<DatabaseService>(),
      metadata: getIt<MetadataService>(),
      runnerDiscovery: getIt<RunnerDiscoveryService>(),
    ),
  );

  getIt.registerFactory<RunnerListCubit>(
    () => RunnerListCubit(runnerDiscovery: getIt<RunnerDiscoveryService>()),
  );
}
