import 'dart:io';

import 'package:path/path.dart' as p;

class AppPaths {
  AppPaths._();

  static String get _home =>
      Platform.environment['HOME'] ?? '/home/${Platform.environment['USER']}';

  static String get baseDir => p.join(_home, '.local', 'share', 'vapor');
  static String get dbPath => p.join(baseDir, 'vapor.db');
  static String get imageCacheDir => p.join(baseDir, 'images');

  static Future<void> ensureDirs() async {
    final dirs = [baseDir, imageCacheDir];
    for (final d in dirs) {
      final dir = Directory(d);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    }
  }
}
