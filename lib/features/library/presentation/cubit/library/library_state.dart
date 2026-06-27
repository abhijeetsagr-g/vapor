import 'package:equatable/equatable.dart';
import 'package:vapor/features/library/models/game_metadata.dart';
import 'package:vapor/features/library/models/game_model.dart';

enum LibraryStatus { initial, loading, loaded, error }

class MetadataFetchProgress extends Equatable {
  final bool inProgress;
  final int done;
  final int total;

  const MetadataFetchProgress({
    this.inProgress = false,
    this.done = 0,
    this.total = 0,
  });

  double? get ratio => total > 0 ? done / total : null;

  @override
  List<Object?> get props => [inProgress, done, total];
}

class LibraryState extends Equatable {
  final List<GameModel> games;
  final List<GameModel> filteredGames;
  final Map<int, GameMetadata> metadata;
  final LibraryStatus status;
  final MetadataFetchProgress fetchProgress;
  final String? errorMessage;
  final bool isImporting;
  final String? searchQuery;
  final String? snackbarMessage;

  const LibraryState({
    this.games = const [],
    this.filteredGames = const [],
    this.metadata = const {},
    this.status = LibraryStatus.initial,
    this.fetchProgress = const MetadataFetchProgress(),
    this.isImporting = false,
    this.errorMessage,
    this.searchQuery,
    this.snackbarMessage,
  });

  LibraryState copyWith({
    List<GameModel>? games,
    List<GameModel>? filteredGames,
    Map<int, GameMetadata>? metadata,
    LibraryStatus? status,
    MetadataFetchProgress? fetchProgress,
    bool? isImporting,
    String? errorMessage,
    String? searchQuery,
    String? snackbarMessage,
    bool clearError = false,
    bool clearSnackbar = false,
  }) =>
      LibraryState(
        games: games ?? this.games,
        filteredGames: filteredGames ?? this.filteredGames,
        metadata: metadata ?? this.metadata,
        status: status ?? this.status,
        fetchProgress: fetchProgress ?? this.fetchProgress,
        isImporting: isImporting ?? this.isImporting,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        searchQuery: searchQuery ?? this.searchQuery,
        snackbarMessage:
            clearSnackbar ? null : (snackbarMessage ?? this.snackbarMessage),
      );

  @override
  List<Object?> get props => [
        games,
        filteredGames,
        metadata,
        status,
        fetchProgress,
        isImporting,
        errorMessage,
        searchQuery,
        snackbarMessage,
      ];
}
