import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../services/runner_discovery_service.dart';
import 'cubit/runner_list/runner_list_cubit.dart';
import 'cubit/runner_list/runner_list_state.dart';

class RunnerListScreen extends StatelessWidget {
  const RunnerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<RunnerListCubit>()..refresh(),
      child: const _RunnerListView(),
    );
  }
}

class _RunnerListView extends StatelessWidget {
  const _RunnerListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Runners'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<RunnerListCubit>().refresh(),
          ),
        ],
      ),
      body: BlocBuilder<RunnerListCubit, RunnerListState>(
        builder: (context, state) {
          if (state.runners.isEmpty) {
            return const Center(child: Text('No runners found'));
          }
          return ListView.builder(
            itemCount: state.runners.length,
            itemBuilder: (_, i) {
              final r = state.runners[i];
              return ListTile(
                leading: Icon(
                  r.source == RunnerSource.system
                      ? Icons.computer
                      : Icons.folder,
                ),
                title: Text(r.name),
                subtitle: Text(r.path),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: r.isProton
                        ? Colors.blue.withValues(alpha: 0.15)
                        : Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    r.isProton ? 'Proton' : 'Wine',
                    style: TextStyle(
                      fontSize: 11,
                      color: r.isProton ? Colors.blue : Colors.green,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
