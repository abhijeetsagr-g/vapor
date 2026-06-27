import 'dart:convert';
import 'dart:io';

import '../models/game_model.dart';
import 'runner_discovery_service.dart';

class GameLog {
  static final List<String> _entries = [];

  static List<String> get entries => List.unmodifiable(_entries);

  static void write(String msg) {
    _entries.add('[${DateTime.now()}] $msg');
  }
}

class GameRunnerService {
  static Future<Process> launch(GameModel game) async {
    GameLog.write('Launching ${game.name} (${game.service})');

    switch (game.service) {
      case Service.lutris:
        GameLog.write('Command: lutris lutris:rungame/${game.slug}');
        return _capture('lutris', ['lutris:rungame/${game.slug}']);
      case Service.manual:
        return _launchManual(game);
      case Service.steam:
        throw UnimplementedError('Steam launch not yet supported');
    }
  }

  static Future<Process> _launchManual(GameModel game) async {
    final hasRunner = game.runnerPath.isNotEmpty &&
        game.runnerPath != '/usr/bin';

    if (hasRunner) {
      final isProton = game.runnerPath.endsWith('/proton');

      if (isProton && RunnerDiscoveryService.isUmuAvailable()) {
        final protonDir = File(game.runnerPath).parent.path;
        GameLog.write('Command: umu-run ${game.execPath}');
        GameLog.write('WINEPREFIX=${game.configPath}');
        GameLog.write('PROTONPATH=$protonDir');
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
        GameLog.write('ERROR: Proton runner requires UMU-Launcher. '
            'Install it or use a Wine runner.');
        throw ProcessException(
          'umu-run',
          [game.execPath],
          'UMU-Launcher not found. Install with: pip install umu-launcher',
          127,
        );
      }

      GameLog.write('Command: ${game.runnerPath} ${game.execPath}');
      GameLog.write('WINEPREFIX=${game.configPath}');
      return _capture(
        game.runnerPath,
        [game.execPath],
        environment: {
          if (game.configPath.isNotEmpty) 'WINEPREFIX': game.configPath,
        },
      );
    }

    GameLog.write('Command: ${game.execPath}');
    return _capture(game.execPath, [], runInShell: true);
  }

  static Future<Process> _capture(
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
      GameLog.write('[stderr] $data');
    });
    process.stdout.transform(utf8.decoder).listen((data) {
      GameLog.write('[stdout] $data');
    });

    return process;
  }
}
