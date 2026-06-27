import 'package:equatable/equatable.dart';
import 'package:vapor/features/library/services/runner_discovery_service.dart';

class RunnerListState extends Equatable {
  final List<RunnerInfo> runners;

  const RunnerListState({this.runners = const []});

  @override
  List<Object?> get props => [runners];
}
