import 'dart:io';

class RunnerInfo {
  final String name;
  final String path;
  final RunnerSource source;
  final bool isProton;

  RunnerInfo({
    required this.name,
    required this.path,
    required this.source,
    required this.isProton,
  });
}

enum RunnerSource { lutris, steam, system }

class RunnerDiscoveryService {
  List<RunnerInfo> discover() {
    final runners = <RunnerInfo>[];
    final home = Platform.environment['HOME'] ?? '/home/${Platform.environment['USER']}';

    final lutrisWine = Directory('$home/.local/share/lutris/runners/wine');
    if (lutrisWine.existsSync()) {
      for (final entry in lutrisWine.listSync()) {
        if (entry is Directory) {
          final wineBin = File('${entry.path}/bin/wine');
          final protonScript = File('${entry.path}/proton');
          if (wineBin.existsSync()) {
            runners.add(RunnerInfo(
              name: entry.path.split('/').last,
              path: wineBin.path,
              source: RunnerSource.lutris,
              isProton: false,
            ));
          } else if (protonScript.existsSync()) {
            runners.add(RunnerInfo(
              name: entry.path.split('/').last,
              path: protonScript.path,
              source: RunnerSource.lutris,
              isProton: true,
            ));
          }
        }
      }
    }

    final steamCompat = Directory('$home/.steam/steam/compatibilitytools.d');
    if (steamCompat.existsSync()) {
      for (final entry in steamCompat.listSync()) {
        if (entry is Directory) {
          final proton = File('${entry.path}/proton');
          if (proton.existsSync()) {
            runners.add(RunnerInfo(
              name: entry.path.split('/').last,
              path: proton.path,
              source: RunnerSource.steam,
              isProton: true,
            ));
          }
        }
      }
    }

    final systemCompat = Directory('/usr/share/steam/compatibilitytools.d');
    if (systemCompat.existsSync()) {
      for (final entry in systemCompat.listSync()) {
        if (entry is Directory) {
          final proton = File('${entry.path}/proton');
          if (proton.existsSync()) {
            runners.add(RunnerInfo(
              name: entry.path.split('/').last,
              path: proton.path,
              source: RunnerSource.system,
              isProton: true,
            ));
          }
        }
      }
    }

    final which = Process.runSync('which', ['wine']);
    if (which.exitCode == 0) {
      final path = which.stdout.toString().trim();
      if (path.isNotEmpty) {
        runners.add(RunnerInfo(
          name: 'system-wine',
          path: path,
          source: RunnerSource.system,
          isProton: false,
        ));
      }
    }

    return runners;
  }

  bool isUmuAvailable() {
    final result = Process.runSync('which', ['umu-run']);
    return result.exitCode == 0;
  }
}
