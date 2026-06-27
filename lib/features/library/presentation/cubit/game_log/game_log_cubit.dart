import 'package:flutter_bloc/flutter_bloc.dart';

import 'game_log_state.dart';

class GameLogCubit extends Cubit<GameLogState> {
  GameLogCubit() : super(const GameLogState());

  void write(String msg) {
    emit(GameLogState(
      entries: [...state.entries, '[${DateTime.now()}] $msg'],
    ));
  }

  void clear() {
    emit(const GameLogState());
  }
}
