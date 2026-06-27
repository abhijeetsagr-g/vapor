import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/cached_game_image.dart';
import '../models/game_model.dart';
import 'add_game_screen.dart';
import 'cubit/game_launch/game_launch_cubit.dart';
import 'cubit/game_launch/game_launch_state.dart';
import 'cubit/library/library_cubit.dart';
import 'cubit/library/library_state.dart';
import 'game_detail_screen.dart';
import 'log_screen.dart';
import 'runner_list_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<GameLaunchCubit, GameLaunchState>(
      listenWhen: (prev, next) => next.lastError != null,
      listener: (ctx, state) {
        if (state.lastError != null) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text(state.lastError!)),
          );
          ctx.read<GameLaunchCubit>().clearError();
        }
      },
      child: BlocConsumer<LibraryCubit, LibraryState>(
        listenWhen: (prev, next) =>
            next.snackbarMessage != prev.snackbarMessage &&
            next.snackbarMessage != null,
        listener: (ctx, state) {
          if (state.snackbarMessage != null) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text(state.snackbarMessage!)),
            );
            ctx.read<LibraryCubit>().clearSnackbar();
          }
        },
        builder: (ctx, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Library'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.auto_awesome),
                  tooltip: 'Fetch metadata for all games',
                  onPressed: state.status == LibraryStatus.loaded && !state.isImporting
                      ? () => ctx.read<LibraryCubit>().fetchAllMetadata()
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.file_download_outlined),
                  tooltip: 'Import from Lutris',
                  onPressed: state.isImporting
                      ? null
                      : () => ctx.read<LibraryCubit>().importFromLutris(),
                ),
                IconButton(
                  icon: const Icon(Icons.desktop_windows_outlined),
                  tooltip: 'Available runners',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RunnerListScreen()),
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
              ).then((_) => context.read<LibraryCubit>().load()),
            ),
            body: _buildBody(ctx, state),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, LibraryState state) {
    if (state.status == LibraryStatus.initial ||
        state.status == LibraryStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == LibraryStatus.error) {
      return Center(child: Text('Error: ${state.errorMessage}'));
    }

    return Column(
      children: [
        if (state.isImporting)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: LinearProgressIndicator(),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search games...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (q) => context.read<LibraryCubit>().search(q),
          ),
        ),
        if (state.fetchProgress.inProgress)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                LinearProgressIndicator(value: state.fetchProgress.ratio),
                const SizedBox(height: 4),
                Text(
                  '${state.fetchProgress.done} / ${state.fetchProgress.total}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        Expanded(
          child: state.filteredGames.isEmpty
              ? const Center(child: Text('No games yet'))
              : ListView.builder(
                  itemCount: state.filteredGames.length,
                  itemBuilder: (ctx, index) {
                    final game = state.filteredGames[index];
                    return _GameTile(game: game);
                  },
                ),
        ),
      ],
    );
  }
}

class _GameTile extends StatelessWidget {
  final GameModel game;
  const _GameTile({required this.game});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameLaunchCubit, GameLaunchState>(
      builder: (ctx, launchState) {
        final isPlaying = launchState.playingGameId == game.id;
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
                content: Text('Remove "${game.name}" from your library?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Remove'),
                  ),
                ],
              ),
            );
          },
          onDismissed: (_) {
            context.read<LibraryCubit>().deleteGame(game);
          },
          child: ListTile(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GameDetailScreen(gameId: game.id!),
              ),
            ),
            leading: _GameLeading(game: game),
            title: Text(game.name),
            subtitle: Text(
              '${game.runnerPath}  ·  ${_formatPlaytime(game.playtime)}',
            ),
            trailing: isPlaying
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () =>
                        context.read<LibraryCubit>().launch(game),
                  ),
          ),
        );
      },
    );
  }

  String _formatPlaytime(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

class _GameLeading extends StatelessWidget {
  final GameModel game;
  const _GameLeading({required this.game});

  @override
  Widget build(BuildContext context) {
    final libraryState = context.watch<LibraryCubit>().state;
    final meta = libraryState.metadata[game.id];
    final thumbUrl = meta?.gridUrl ?? meta?.coverUrl;

    if (game.id != null && thumbUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: CachedGameImage(
          gameKey: game.slug.isNotEmpty ? game.slug : game.id.toString(),
          imageUrl: thumbUrl,
          type: meta?.gridUrl != null ? 'grid' : 'cover',
          width: 48,
          height: 48,
          errorBuilder: (_, _, _) => _serviceIcon(game.service),
        ),
      );
    }

    return _serviceIcon(game.service);
  }

  Widget _serviceIcon(Service service) {
    return CircleAvatar(
      child: switch (service) {
        Service.steam => const Text('S'),
        Service.lutris => const Text('L'),
        Service.manual => const Icon(Icons.games, size: 20),
      },
    );
  }
}
