import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/database/database_service.dart';
import '../models/game_model.dart';
import '../services/runner_discovery_service.dart';

class AddGameScreen extends StatefulWidget {
  const AddGameScreen({super.key});

  @override
  State<AddGameScreen> createState() => _AddGameScreenState();
}

class _AddGameScreenState extends State<AddGameScreen> {
  final _nameController = TextEditingController();
  final _execController = TextEditingController();
  final _prefixController = TextEditingController();

  List<RunnerInfo> _runners = [];
  String? _selectedRunnerPath;
  bool _isLinux = true;

  @override
  void initState() {
    super.initState();
    _runners = RunnerDiscoveryService.discover();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _execController.dispose();
    _prefixController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(TextEditingController ctrl) async {
    final result = await FilePicker.pickFiles();
    if (result != null && result.files.single.path != null) {
      ctrl.text = result.files.single.path!;
    }
  }

  Future<void> _pickDirectory(TextEditingController ctrl) async {
    final result = await FilePicker.getDirectoryPath();
    if (result != null) {
      ctrl.text = result;
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final game = GameModel(
      name: name,
      slug: name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-'),
      service: Service.manual,
      execPath: _execController.text.trim(),
      runnerPath: _isLinux ? '/usr/bin' : (_selectedRunnerPath ?? ''),
      configPath: _isLinux ? '' : _prefixController.text.trim(),
      playtime: Duration.zero,
      installed: true,
    );

    await DatabaseService.instance.insertGame(game);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Game')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Game Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Platform:'),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('Linux'),
                  selected: _isLinux,
                  onSelected: (_) => setState(() => _isLinux = true),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Windows'),
                  selected: !_isLinux,
                  onSelected: (_) => setState(() => _isLinux = false),
                ),
              ],
            ),
            if (!_isLinux) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedRunnerPath,
                decoration: const InputDecoration(
                  labelText: 'Runner',
                  border: OutlineInputBorder(),
                ),
                items: _runners.map((r) => DropdownMenuItem(
                  value: r.path,
                  child: Text('${r.name} (${r.isProton ? "Proton" : "Wine"})'),
                )).toList(),
                onChanged: (v) => setState(() => _selectedRunnerPath = v),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _prefixController,
                      decoration: const InputDecoration(
                        labelText: 'Wine Prefix',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.folder_open),
                    onPressed: () => _pickDirectory(_prefixController),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _execController,
                    decoration: const InputDecoration(
                      labelText: 'Executable',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.folder_open),
                  onPressed: () => _pickFile(_execController),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              child: const Text('Add Game'),
            ),
          ],
        ),
      ),
    );
  }
}
