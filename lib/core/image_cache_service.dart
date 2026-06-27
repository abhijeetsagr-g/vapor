import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'app_paths.dart';

class ImageCacheService {
  final Set<String> _cacheableTypes = {
    'cover', 'background', 'grid', 'hero', 'logo', 'icon',
  };

  bool isCacheable(String type) =>
      _cacheableTypes.contains(type) || type.startsWith('achievement');

  String _fileFor(String type) => '$type.jpg';

  String _gameDir(String gameKey) =>
      p.join(AppPaths.imageCacheDir, gameKey);

  Future<String?> getLocalPath(String gameKey, String type) async {
    final file = File(p.join(_gameDir(gameKey), _fileFor(type)));
    if (await file.exists()) return file.path;
    return null;
  }

  Future<String> cache(String gameKey, String type, String url) async {
    final dir = Directory(_gameDir(gameKey));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final file = File(p.join(dir.path, _fileFor(type)));
    if (await file.exists()) return file.path;

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
      }
    } catch (_) {
      // best-effort
    }
    return file.path;
  }

  Future<void> cacheAll(String gameKey, Map<String, String> imageUrls) async {
    for (final entry in imageUrls.entries) {
      if (!isCacheable(entry.key)) continue;
      await cache(gameKey, entry.key, entry.value);
    }
  }

  Future<void> deleteGameCache(String gameKey) async {
    final dir = Directory(_gameDir(gameKey));
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}
