import 'package:equatable/equatable.dart';

class GameLogState extends Equatable {
  final List<String> entries;

  const GameLogState({this.entries = const []});

  @override
  List<Object?> get props => [entries];
}
