import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cubit/game_log/game_log_cubit.dart';
import 'cubit/game_log/game_log_state.dart';

class LogScreen extends StatelessWidget {
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log')),
      body: BlocBuilder<GameLogCubit, GameLogState>(
        builder: (context, state) {
          if (state.entries.isEmpty) {
            return const Center(child: Text('No log entries'));
          }
          return ListView.builder(
            itemCount: state.entries.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: Text(
                state.entries[i],
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
            ),
          );
        },
      ),
    );
  }
}
