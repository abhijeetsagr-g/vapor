import 'package:equatable/equatable.dart';
import 'package:vapor/features/library/models/game_metadata.dart';
import 'package:vapor/features/library/models/game_model.dart';

enum GameDetailStatus { initial, loading, loaded, notFound, error }

class GameDetailState extends Equatable {
  final GameModel? game;
  final GameMetadata? metadata;
  final GameDetailStatus status;
  final String? errorMessage;

  const GameDetailState({
    this.game,
    this.metadata,
    this.status = GameDetailStatus.initial,
    this.errorMessage,
  });

  GameDetailState copyWith({
    GameModel? game,
    GameMetadata? metadata,
    GameDetailStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) =>
      GameDetailState(
        game: game ?? this.game,
        metadata: metadata ?? this.metadata,
        status: status ?? this.status,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [game, metadata, status, errorMessage];
}
