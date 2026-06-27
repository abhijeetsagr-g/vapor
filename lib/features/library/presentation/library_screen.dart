import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/database/database_service.dart';
import '../models/game_model.dart';
import '../services/game_runner_service.dart';
import '../services/lutris_import_service.dart';
import 'add_game_screen.dart';
import 'log_screen.dart';
import 'runner_list_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<GameModel> _games = [];
  List<GameModel> _filtered = [];
  bool _loading = true;
  int? _playingId;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _launch(GameModel game) async {
    if (_playingId != null) return;
    setState(() => _playingId = game.id);
    final stopwatch = Stopwatch()..start();
    try {
      final process = await GameRunnerService.launch(game);
      await process.exitCode;
    } on ProcessException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to launch ${game.name}')),
      );
    } finally {
      stopwatch.stop();
      setState(() => _playingId = null);
      await DatabaseService.instance.updateGame(
        game.copyWith(
          playtime: game.playtime + stopwatch.elapsed,
          lastPlayed: DateTime.now(),
        ),
      );
      _load();
    }
  }

  Future<void> _importFromLutris() async {
    final result = await LutrisImportService.import();
    if (!mounted) return;

    if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error!)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${result.imported} new, ${result.updated} updated'),
      ),
    );
    await _load();
  }

  Future<void> _load() async {
    final games = await DatabaseService.instance.getAllGames();
    setState(() {
      _games = games;
      _loading = false;
    });
    _filter();
  }

  void _filter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filtered = _games.where((g) => g.name.toLowerCase().contains(query)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Import from Lutris',
            onPressed: _importFromLutris,
          ),
          IconButton(
            icon: const Icon(Icons.desktop_windows_outlined),
            tooltip: 'Available runners',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RunnerListScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.terminal_outlined),
            tooltip: 'Log',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LogScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddGameScreen()),
        ).then((_) => _load()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search games...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _filter(),
                  ),
                ),
                Expanded(
                  child: _filtered.isEmpty
                      ? const Center(child: Text('No games yet'))
                      : ListView.builder(
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final game = _filtered[index];
                            return Dismissible(
                              key: ValueKey(game.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                color: Colors.red,
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              confirmDismiss: (_) async {
                                return await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Remove game?'),
                                    content: Text(
                                        'Remove "${game.name}" from your library?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('Remove'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              onDismissed: (_) async {
                                await DatabaseService.instance
                                    .deleteGame(game.id!);
                                _load();
                              },
                              child: ListTile(
                                leading: _serviceIcon(game.service,
                                    playing: _playingId == game.id),
                                title: Text(game.name),
                                subtitle: Text(
                                  '${game.runnerPath}  ·  ${_formatPlaytime(game.playtime)}',
                                ),
                                trailing: _playingId == game.id
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : IconButton(
                                        icon: const Icon(Icons.play_arrow),
                                        onPressed: () => _launch(game),
                                      ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  String _formatPlaytime(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  Widget _serviceIcon(Service service, {bool playing = false}) {
    return CircleAvatar(
      backgroundColor: playing ? Colors.green : null,
      child: switch (service) {
        Service.steam => const Text('S'),
        Service.lutris => const Text('L'),
        Service.manual => const Icon(Icons.games, size: 20),
      },
    );
  }
}
