import 'dart:convert';

import 'package:http/http.dart' as http;

const _kBase = 'https://www.steamgriddb.com/api/v2';

class SgdbGameResult {
  final int id;
  final String name;

  SgdbGameResult({required this.id, required this.name});
}

class SteamGridDbService {
  final String apiKey;

  SteamGridDbService({required this.apiKey});

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $apiKey',
        'Accept': 'application/json',
      };

  Future<List<SgdbGameResult>> search(String query) async {
    final uri = Uri.parse('$_kBase/search/autocomplete/$query');
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) return [];

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>?;
    if (data == null) return [];

    return data.map((r) => SgdbGameResult(
      id: r['id'] as int,
      name: r['name'] as String,
    )).toList();
  }

  Future<String?> _firstAsset(int gameId, String type) async {
    final uri = Uri.parse('$_kBase/$type/game/$gameId');
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200 && response.statusCode != 207) return null;

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>?;
    if (data == null || data.isEmpty) return null;

    final url = data.first['url'] as String?;
    return url;
  }

  Future<String?> getGrid(int gameId) =>
      _firstAsset(gameId, 'grids');

  Future<String?> getHero(int gameId) =>
      _firstAsset(gameId, 'heroes');

  Future<String?> getLogo(int gameId) =>
      _firstAsset(gameId, 'logos');

  Future<String?> getIcon(int gameId) =>
      _firstAsset(gameId, 'icons');
}
