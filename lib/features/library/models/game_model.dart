enum Service { steam, lutris, manual }

class GameModel {
  final int? id;
  final String? appId;
  final String name;
  final String slug;
  final Service service;

  final String execPath;
  final String runnerPath;
  final String configPath;

  final Duration playtime;
  final bool installed;
  final DateTime? lastPlayed;

  GameModel({
    this.id,
    required this.name,
    required this.slug,
    required this.service,
    required this.runnerPath,
    required this.configPath,
    required this.playtime,
    required this.installed,
    required this.execPath,
    this.appId,
    this.lastPlayed,
  });

  GameModel copyWith({
    int? id,
    String? appId,
    String? name,
    String? slug,
    Service? service,
    String? execPath,
    String? runnerPath,
    String? configPath,
    Duration? playtime,
    bool? installed,
    DateTime? lastPlayed,
  }) =>
      GameModel(
        id: id ?? this.id,
        appId: appId ?? this.appId,
        name: name ?? this.name,
        slug: slug ?? this.slug,
        service: service ?? this.service,
        execPath: execPath ?? this.execPath,
        runnerPath: runnerPath ?? this.runnerPath,
        configPath: configPath ?? this.configPath,
        playtime: playtime ?? this.playtime,
        installed: installed ?? this.installed,
        lastPlayed: lastPlayed ?? this.lastPlayed,
      );
}
