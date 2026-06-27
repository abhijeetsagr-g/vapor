// ignore_for_file: prefer_initializing_formals

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vapor/core/database/database_service.dart';
import 'package:vapor/features/library/models/game_model.dart';
import 'package:vapor/features/library/services/game_runner_service.dart';

import '../game_log/game_log_cubit.dart';
import 'game_launch_state.dart';

class GameLaunchCubit extends Cubit<GameLaunchState> {
  final GameRunnerService _gameRunner;
  final DatabaseService _db;
  final GameLogCubit _log;

  GameLaunchCubit({
    required GameRunnerService gameRunner,
    required DatabaseService db,
    required GameLogCubit log,
  }) : _gameRunner = gameRunner,
       _db = db,
       _log = log,
       super(const GameLaunchState());

  Future<void> launch(GameModel game) async {
    if (state.playingGameId != null) return;
    emit(state.copyWith(playingGameId: game.id, lastError: null));

    final stopwatch = Stopwatch()..start();
    try {
      final process = await _gameRunner.launch(game);
      await process.exitCode;
    } catch (e) {
      _log.write('Launch failed: $e');
      emit(state.copyWith(lastError: 'Failed to launch ${game.name}'));
    } finally {
      stopwatch.stop();
      await _db.updateGame(
        game.copyWith(
          playtime: game.playtime + stopwatch.elapsed,
          lastPlayed: DateTime.now(),
        ),
      );
      emit(state.copyWith(playingGameId: null));
    }
  }

  void clearError() {
    emit(state.copyWith(lastError: null));
  }
}
