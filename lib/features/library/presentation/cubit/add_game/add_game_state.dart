import 'package:equatable/equatable.dart';
import 'package:vapor/features/library/services/runner_discovery_service.dart';

enum AddGameStatus { idle, saving, saved, error }

class AddGameState extends Equatable {
  final String name;
  final String execPath;
  final String prefixPath;
  final bool isLinux;
  final List<RunnerInfo> runners;
  final String? selectedRunnerPath;
  final AddGameStatus status;
  final String? errorMessage;

  const AddGameState({
    this.name = '',
    this.execPath = '',
    this.prefixPath = '',
    this.isLinux = true,
    this.runners = const [],
    this.selectedRunnerPath,
    this.status = AddGameStatus.idle,
    this.errorMessage,
  });

  AddGameState copyWith({
    String? name,
    String? execPath,
    String? prefixPath,
    bool? isLinux,
    List<RunnerInfo>? runners,
    String? selectedRunnerPath,
    AddGameStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) =>
      AddGameState(
        name: name ?? this.name,
        execPath: execPath ?? this.execPath,
        prefixPath: prefixPath ?? this.prefixPath,
        isLinux: isLinux ?? this.isLinux,
        runners: runners ?? this.runners,
        selectedRunnerPath: selectedRunnerPath ?? this.selectedRunnerPath,
        status: status ?? this.status,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [
        name,
        execPath,
        prefixPath,
        isLinux,
        runners,
        selectedRunnerPath,
        status,
        errorMessage,
      ];
}
