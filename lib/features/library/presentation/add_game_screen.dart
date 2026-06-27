import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'cubit/add_game/add_game_cubit.dart';
import 'cubit/add_game/add_game_state.dart';

class AddGameScreen extends StatelessWidget {
  const AddGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<AddGameCubit>()..loadRunners(),
      child: const _AddGameForm(),
    );
  }
}

class _AddGameForm extends StatefulWidget {
  const _AddGameForm();

  @override
  State<_AddGameForm> createState() => _AddGameFormState();
}

class _AddGameFormState extends State<_AddGameForm> {
  final _nameCtrl = TextEditingController();
  final _execCtrl = TextEditingController();
  final _prefixCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _execCtrl.dispose();
    _prefixCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddGameCubit, AddGameState>(
      listener: (ctx, state) {
        if (state.status == AddGameStatus.saved) {
          Navigator.pop(context);
        }
      },
      builder: (ctx, state) {
        final cubit = context.read<AddGameCubit>();
        return Scaffold(
          appBar: AppBar(title: const Text('Add Game')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Game Title',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: cubit.setName,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Platform:'),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text('Linux'),
                      selected: state.isLinux,
                      onSelected: (_) => cubit.setPlatform(true),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Windows'),
                      selected: !state.isLinux,
                      onSelected: (_) => cubit.setPlatform(false),
                    ),
                  ],
                ),
                if (!state.isLinux) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: state.runners
                            .any((r) => r.path == state.selectedRunnerPath)
                        ? state.selectedRunnerPath
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Runner',
                      border: OutlineInputBorder(),
                    ),
                    items: state.runners
                        .map(
                          (r) => DropdownMenuItem(
                            value: r.path,
                            child: Text(
                              '${r.name} (${r.isProton ? "Proton" : "Wine"})',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: cubit.setRunner,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _prefixCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Wine Prefix',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: cubit.setPrefixPath,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.folder_open),
                        onPressed: () async {
                          final dir = await FilePicker.getDirectoryPath();
                          if (dir != null) {
                            _prefixCtrl.text = dir;
                            cubit.setPrefixPath(dir);
                          }
                        },
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _execCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Executable',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: cubit.setExecPath,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.folder_open),
                      onPressed: () async {
                        final result = await FilePicker.pickFiles();
                        if (result != null &&
                            result.files.single.path != null) {
                          final path = result.files.single.path!;
                          _execCtrl.text = path;
                          cubit.setExecPath(path);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: state.status == AddGameStatus.saving
                      ? null
                      : cubit.save,
                  child: state.status == AddGameStatus.saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Add Game'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
