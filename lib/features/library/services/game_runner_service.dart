import 'dart:convert';
import 'dart:io';

import '../models/game_model.dart';
import 'runner_discovery_service.dart';

class GameRunnerService {
  final RunnerDiscoveryService _runnerDiscovery;
  final void Function(String) _log;

  GameRunnerService({
    required RunnerDiscoveryService runnerDiscovery,
    required void Function(String) log,
  })  : _runnerDiscovery = runnerDiscovery,
        _log = log;

  Future<Process> launch(GameModel game) async {
    _log('Launching ${game.name} (${game.service})');

    switch (game.service) {
      case Service.lutris:
        _log('Command: lutris lutris:rungame/${game.slug}');
        return _capture('lutris', ['lutris:rungame/${game.slug}']);
      case Service.manual:
        return _launchManual(game);
      case Service.steam:
        throw UnimplementedError('Steam launch not yet supported');
    }
  }

  Future<Process> _launchManual(GameModel game) async {
    final hasRunner = game.runnerPath.isNotEmpty &&
        game.runnerPath != '/usr/bin';

    if (hasRunner) {
      final isProton = game.runnerPath.endsWith('/proton');

      if (isProton && _runnerDiscovery.isUmuAvailable()) {
        final protonDir = File(game.runnerPath).parent.path;
        _log('Command: umu-run ${game.execPath}');
        _log('WINEPREFIX=${game.configPath}');
        _log('PROTONPATH=$protonDir');
        return _capture(
          'umu-run',
          [game.execPath],
          environment: {
            if (game.configPath.isNotEmpty) 'WINEPREFIX': game.configPath,
            'PROTONPATH': protonDir,
          },
        );
      }

      if (isProton) {
        _log('ERROR: Proton runner requires UMU-Launcher. '
            'Install it or use a Wine runner.');
        throw ProcessException(
          'umu-run',
          [game.execPath],
          'UMU-Launcher not found. Install with: pip install umu-launcher',
          127,
        );
      }

      _log('Command: ${game.runnerPath} ${game.execPath}');
      _log('WINEPREFIX=${game.configPath}');
      return _capture(
        game.runnerPath,
        [game.execPath],
        environment: {
          if (game.configPath.isNotEmpty) 'WINEPREFIX': game.configPath,
        },
      );
    }

    _log('Command: ${game.execPath}');
    return _capture(game.execPath, [], runInShell: true);
  }

  Future<Process> _capture(
    String executable,
    List<String> args, {
    Map<String, String>? environment,
    bool runInShell = false,
  }) async {
    final process = await Process.start(
      executable,
      args,
      environment: environment,
      runInShell: runInShell,
    );

    process.stderr.transform(utf8.decoder).listen((data) {
      _log('[stderr] $data');
    });
    process.stdout.transform(utf8.decoder).listen((data) {
      _log('[stdout] $data');
    });

    return process;
  }
}
