import 'dart:convert';

import 'package:http/http.dart' as http;

const _kDefaultBase = 'https://api.rawg.io/api';

class RawgGameSearchResult {
  final int id;
  final String name;
  final String? coverUrl;
  final String? released;
  final double? metacritic;
  final List<String> genres;

  RawgGameSearchResult({
    required this.id,
    required this.name,
    this.coverUrl,
    this.released,
    this.metacritic,
    this.genres = const [],
  });
}

class RawgGameDetail {
  final int id;
  final String name;
  final String? coverUrl;
  final String? backgroundUrl;
  final String? description;
  final String? released;
  final double? metacritic;
  final String? website;
  final List<String> genres;
  final List<String> tags;
  final String? esrbRating;

  RawgGameDetail({
    required this.id,
    required this.name,
    this.coverUrl,
    this.backgroundUrl,
    this.description,
    this.released,
    this.metacritic,
    this.website,
    this.genres = const [],
    this.tags = const [],
    this.esrbRating,
  });
}

class RawgApiService {
  final String apiKey;
  final String baseUrl;

  RawgApiService({
    required this.apiKey,
    this.baseUrl = _kDefaultBase,
  });

  Future<List<RawgGameSearchResult>> search(String query) async {
    final uri = Uri.parse('$baseUrl/games').replace(queryParameters: {
      'key': apiKey,
      'search': query,
      'page_size': '10',
    });

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('RAWG search failed: ${response.statusCode} ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = body['results'] as List<dynamic>;

    return results.map((r) {
      final genres = (r['genres'] as List<dynamic>?)
              ?.map((g) => g['name'] as String)
              .toList() ??
          [];
      return RawgGameSearchResult(
        id: r['id'] as int,
        name: r['name'] as String,
        coverUrl: r['background_image'] as String?,
        released: r['released'] as String?,
        metacritic: (r['metacritic'] as num?)?.toDouble(),
        genres: genres,
      );
    }).toList();
  }

  Future<RawgGameDetail?> getById(int rawgId) async {
    final uri = Uri.parse('$baseUrl/games/$rawgId').replace(queryParameters: {
      'key': apiKey,
    });

    final response = await http.get(uri);
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw Exception('RAWG detail failed: ${response.statusCode} ${response.body}');
    }

    final r = jsonDecode(response.body) as Map<String, dynamic>;

    final genres = (r['genres'] as List<dynamic>?)
            ?.map((g) => g['name'] as String)
            .toList() ??
        [];
    final tags = (r['tags'] as List<dynamic>?)
            ?.map((t) => t['name'] as String)
            .toList() ??
        [];

    return RawgGameDetail(
      id: r['id'] as int,
      name: r['name'] as String,
      coverUrl: r['background_image'] as String?,
      backgroundUrl: (r['background_image_additional'] as String?)
              ?.isNotEmpty == true
          ? r['background_image_additional'] as String
          : r['background_image'] as String?,
      description: r['description_raw'] as String?,
      released: r['released'] as String?,
      metacritic: (r['metacritic'] as num?)?.toDouble(),
      website: r['website'] as String?,
      genres: genres,
      tags: tags,
      esrbRating: (r['esrb_rating'] as Map<String, dynamic>?)?
          ['name'] as String?,
    );
  }
}
