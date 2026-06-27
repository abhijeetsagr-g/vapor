// ignore_for_file: prefer_initializing_formals

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vapor/core/database/database_service.dart';
import 'package:vapor/features/library/models/game_model.dart';
import 'package:vapor/features/library/services/metadata_service.dart';
import 'package:vapor/features/library/services/runner_discovery_service.dart';

import 'add_game_state.dart';

class AddGameCubit extends Cubit<AddGameState> {
  final DatabaseService _db;
  final MetadataService _metadata;
  final RunnerDiscoveryService _runnerDiscovery;

  AddGameCubit({
    required this._db,
    required MetadataService metadata,
    required this._runnerDiscovery,
  }) : _metadata = metadata,
       super(const AddGameState());

  void loadRunners() {
    emit(state.copyWith(runners: _runnerDiscovery.discover()));
  }

  void setName(String value) => emit(state.copyWith(name: value));

  void setExecPath(String value) => emit(state.copyWith(execPath: value));

  void setPrefixPath(String value) => emit(state.copyWith(prefixPath: value));

  void setPlatform(bool isLinux) => emit(
    state.copyWith(
      isLinux: isLinux,
      selectedRunnerPath: isLinux ? null : state.selectedRunnerPath,
    ),
  );

  void setRunner(String? path) =>
      emit(state.copyWith(selectedRunnerPath: path));

  Future<void> save() async {
    if (state.name.trim().isEmpty) return;
    emit(state.copyWith(status: AddGameStatus.saving, clearError: true));

    try {
      final slug = state.name.trim().toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9]+'),
        '-',
      );
      final game = GameModel(
        name: state.name.trim(),
        slug: slug,
        service: Service.manual,
        execPath: state.execPath.trim(),
        runnerPath: state.isLinux
            ? '/usr/bin'
            : (state.selectedRunnerPath ?? ''),
        configPath: state.isLinux ? '' : state.prefixPath.trim(),
        playtime: Duration.zero,
        installed: true,
      );

      final newId = await _db.insertGame(game);
      try {
        await _metadata.fetchAndCache(newId, state.name.trim(), slug: slug);
      } catch (_) {}

      emit(state.copyWith(status: AddGameStatus.saved));
    } catch (e) {
      emit(
        state.copyWith(status: AddGameStatus.error, errorMessage: e.toString()),
      );
    }
  }

  void reset() {
    emit(const AddGameState());
    loadRunners();
  }
}
