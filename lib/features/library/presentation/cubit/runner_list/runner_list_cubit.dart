import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vapor/features/library/services/runner_discovery_service.dart';

import 'runner_list_state.dart';

class RunnerListCubit extends Cubit<RunnerListState> {
  final RunnerDiscoveryService _runnerDiscovery;

  RunnerListCubit({required RunnerDiscoveryService runnerDiscovery})
      : _runnerDiscovery = runnerDiscovery,
        super(const RunnerListState());

  void refresh() {
    emit(RunnerListState(runners: _runnerDiscovery.discover()));
  }
}
