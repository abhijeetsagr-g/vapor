class GameMetadata {
  final int? id;
  final int? gameId;
  final int? rawgId;
  final String? coverUrl;
  final String? backgroundUrl;
  final String? description;
  final List<String> genres;
  final List<String> tags;
  final String? releaseDate;
  final String? esrbRating;
  final double? metacritic;
  final String? website;
  final String? gridUrl;
  final String? heroUrl;
  final String? logoUrl;
  final String? iconUrl;
  final List<String> screenshots;
  final String? movieUrl;

  GameMetadata({
    this.id,
    this.gameId,
    this.rawgId,
    this.coverUrl,
    this.backgroundUrl,
    this.description,
    this.genres = const [],
    this.tags = const [],
    this.releaseDate,
    this.esrbRating,
    this.metacritic,
    this.website,
    this.gridUrl,
    this.heroUrl,
    this.logoUrl,
    this.iconUrl,
    this.screenshots = const [],
    this.movieUrl,
  });

  GameMetadata copyWith({
    int? id,
    int? gameId,
    int? rawgId,
    String? coverUrl,
    String? backgroundUrl,
    String? description,
    List<String>? genres,
    List<String>? tags,
    String? releaseDate,
    String? esrbRating,
    double? metacritic,
    String? website,
    String? gridUrl,
    String? heroUrl,
    String? logoUrl,
    String? iconUrl,
    List<String>? screenshots,
    String? movieUrl,
  }) =>
      GameMetadata(
        id: id ?? this.id,
        gameId: gameId ?? this.gameId,
        rawgId: rawgId ?? this.rawgId,
        coverUrl: coverUrl ?? this.coverUrl,
        backgroundUrl: backgroundUrl ?? this.backgroundUrl,
        description: description ?? this.description,
        genres: genres ?? this.genres,
        tags: tags ?? this.tags,
        releaseDate: releaseDate ?? this.releaseDate,
        esrbRating: esrbRating ?? this.esrbRating,
        metacritic: metacritic ?? this.metacritic,
        website: website ?? this.website,
        gridUrl: gridUrl ?? this.gridUrl,
        heroUrl: heroUrl ?? this.heroUrl,
        logoUrl: logoUrl ?? this.logoUrl,
        iconUrl: iconUrl ?? this.iconUrl,
        screenshots: screenshots ?? this.screenshots,
        movieUrl: movieUrl ?? this.movieUrl,
      );
}
