import 'dart:io';

class Config {
  static final Map<String, String> _env = {};

  static Future<void> load() async {
    final file = File('.env');
    if (!file.existsSync()) return;

    for (final line in file.readAsLinesSync()) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final eq = trimmed.indexOf('=');
      if (eq == -1) continue;
      final key = trimmed.substring(0, eq).trim();
      final value = trimmed
          .substring(eq + 1)
          .trim()
          .replaceAll(RegExp(r'^"|"$'), '');
      _env[key] = value;
    }
  }

  static String? get(String key) => _env[key] ?? Platform.environment[key];
}
