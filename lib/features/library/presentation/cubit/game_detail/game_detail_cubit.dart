import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vapor/core/database/database_service.dart';

import '../game_launch/game_launch_cubit.dart';
import 'game_detail_state.dart';

class GameDetailCubit extends Cubit<GameDetailState> {
  final int _gameId;
  final DatabaseService _db;
  final GameLaunchCubit _gameLaunch;

  GameDetailCubit({
    required int gameId,
    required DatabaseService db,
    required GameLaunchCubit gameLaunch,
  })  : _gameId = gameId,
        _db = db,
        _gameLaunch = gameLaunch,
        super(const GameDetailState());

  Future<void> load() async {
    emit(state.copyWith(status: GameDetailStatus.loading));
    try {
      final game = await _db.getGame(_gameId);
      if (game == null) {
        emit(state.copyWith(status: GameDetailStatus.notFound));
        return;
      }
      final meta = await _db.getMetadataByGameId(_gameId);
      emit(state.copyWith(
        game: game,
        metadata: meta,
        status: GameDetailStatus.loaded,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: GameDetailStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void launch() {
    final game = state.game;
    if (game != null) {
      _gameLaunch.launch(game);
    }
  }
}
