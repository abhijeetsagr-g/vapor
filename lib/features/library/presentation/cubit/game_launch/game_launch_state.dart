import 'package:equatable/equatable.dart';

class GameLaunchState extends Equatable {
  final int? playingGameId;
  final String? lastError;

  const GameLaunchState({this.playingGameId, this.lastError});

  GameLaunchState copyWith({int? playingGameId, String? lastError}) =>
      GameLaunchState(
        playingGameId: playingGameId ?? this.playingGameId,
        lastError: lastError ?? this.lastError,
      );

  @override
  List<Object?> get props => [playingGameId, lastError];
}
