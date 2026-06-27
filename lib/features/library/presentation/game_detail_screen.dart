import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../core/widgets/cached_game_image.dart';
import '../models/achievement.dart';
import '../models/game_metadata.dart';
import '../models/game_model.dart';
import 'cubit/game_detail/game_detail_cubit.dart';
import 'cubit/game_detail/game_detail_state.dart';

class GameDetailScreen extends StatelessWidget {
  final int gameId;
  const GameDetailScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<GameDetailCubit>(param1: gameId)..load(),
      child: const _GameDetailBody(),
    );
  }
}

class _GameDetailBody extends StatelessWidget {
  const _GameDetailBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameDetailCubit, GameDetailState>(
      builder: (context, state) {
        if (state.status == GameDetailStatus.initial ||
            state.status == GameDetailStatus.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.status == GameDetailStatus.notFound) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(child: Text('Game not found')),
          );
        }

        final game = state.game;
        if (game == null) {
          return const Scaffold(
            body: Center(child: Text('Game not found')),
          );
        }

        final meta = state.metadata;
        final gameKey = game.slug.isNotEmpty ? game.slug : game.id.toString();
        final cs = Theme.of(context).colorScheme;
        final desc = meta?.description;
        final genres = meta?.genres ?? [];
        final tags = meta?.tags ?? [];
        final website = meta?.website;
        final screenshots = meta?.screenshots ?? [];
        final movieUrl = meta?.movieUrl;
        final achievements = meta?.achievements ?? [];
        final artworkUrls = () {
          final m = meta;
          if (m == null) return <String>[];
          return [
            if (m.gridUrl != null) m.gridUrl!,
            if (m.heroUrl != null) m.heroUrl!,
            if (m.logoUrl != null) m.logoUrl!,
            if (m.iconUrl != null) m.iconUrl!,
          ];
        }();

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                stretch: true,
                backgroundColor: cs.surface,
                title: Text(game.name),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.play_arrow_rounded),
                    tooltip: 'Launch',
                    onPressed: () =>
                        context.read<GameDetailCubit>().launch(),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (meta?.coverUrl != null)
                        CachedGameImage(
                          gameKey: gameKey,
                          imageUrl: meta!.coverUrl!,
                          type: 'cover',
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _coverFallback(cs),
                        )
                      else
                        _coverFallback(cs),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              cs.surface.withValues(alpha: 0.9),
                            ],
                            stops: const [0.45, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        bottom: 16,
                        child: _ServiceBadge(name: game.service.name),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _StatsRow(
                      playtime: _formatPlaytime(game.playtime),
                      metacritic: meta?.metacritic,
                      releaseDate: meta?.releaseDate,
                    ),
                    const SizedBox(height: 20),
                    if (desc != null && desc.isNotEmpty) ...[
                      Text(
                        desc,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.75),
                              height: 1.6,
                            ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    _SectionLabel(label: 'Details'),
                    const SizedBox(height: 8),
                    _DetailsCard(game: game, meta: meta),
                    const SizedBox(height: 20),
                    if (genres.isNotEmpty || tags.isNotEmpty) ...[
                      _SectionLabel(label: 'Tags'),
                      const SizedBox(height: 8),
                      _TagsWrap(items: [...genres, ...tags]),
                      const SizedBox(height: 20),
                    ],
                    if (achievements.isNotEmpty) ...[
                      _SectionLabel(label: 'Achievements'),
                      const SizedBox(height: 8),
                      _AchievementsList(
                        gameKey: gameKey,
                        achievements: achievements,
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (screenshots.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _SectionLabel(label: 'Screenshots'),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 160,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: screenshots.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: 8),
                          itemBuilder: (_, i) => ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              screenshots[i],
                              width: 260,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const SizedBox(width: 260),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (artworkUrls.isNotEmpty) ...[
                      _SectionLabel(label: 'Artwork'),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: artworkUrls.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final u = artworkUrls[i];
                            final label = urlLabel(u);
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: CachedGameImage(
                                gameKey: gameKey,
                                imageUrl: u,
                                type: label,
                                height: 100,
                                width: label == 'icon' ? 100 : 160,
                                errorBuilder: (_, _, _) => SizedBox(
                                  width: label == 'icon' ? 100 : 160,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (movieUrl != null) ...[
                      _SectionLabel(label: 'Trailer'),
                      const SizedBox(height: 8),
                      Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.play_circle_fill_rounded,
                                  size: 40, color: cs.primary),
                              const SizedBox(width: 12),
                              SelectableText(
                                movieUrl,
                                style: TextStyle(
                                    color: cs.primary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (website != null) _WebsiteRow(url: website),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.read<GameDetailCubit>().launch(),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Launch'),
          ),
        );
      },
    );
  }

  Widget _coverFallback(ColorScheme cs) => ColoredBox(
        color: cs.surfaceContainerHighest,
        child: Center(
          child: Icon(
            Icons.videogame_asset_rounded,
            size: 64,
            color: cs.onSurfaceVariant.withValues(alpha: 0.3),
          ),
        ),
      );

  String _formatPlaytime(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

String urlLabel(String url) {
  if (url.contains('grid')) return 'grid';
  if (url.contains('hero')) return 'hero';
  if (url.contains('logo')) return 'logo';
  if (url.contains('icon')) return 'icon';
  return 'art';
}

class _ServiceBadge extends StatelessWidget {
  final String name;
  const _ServiceBadge({required this.name});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withValues(alpha: 0.3)),
      ),
      child: Text(
        name.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final String playtime;
  final double? metacritic;
  final String? releaseDate;
  const _StatsRow(
      {required this.playtime, this.metacritic, this.releaseDate});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (playtime.isNotEmpty)
          _StatChip(label: 'Playtime', value: playtime),
        if (metacritic != null) ...[
          const SizedBox(width: 8),
          _MetacriticChip(score: metacritic!),
        ],
        if (releaseDate != null) ...[
          const SizedBox(width: 8),
          _StatChip(label: 'Released', value: releaseDate!),
        ],
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label, value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetacriticChip extends StatelessWidget {
  final double score;
  const _MetacriticChip({required this.score});

  Color get _bg => score >= 75
      ? const Color(0xFF4CAF50)
      : score >= 50
          ? const Color(0xFFFF9800)
          : const Color(0xFFF44336);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _bg.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _bg.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$score',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _bg,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Metacritic',
            style: TextStyle(fontSize: 11, color: _bg.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: Theme.of(context)
            .colorScheme
            .onSurface
            .withValues(alpha: 0.45),
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final GameModel game;
  final GameMetadata? meta;
  const _DetailsCard({required this.game, required this.meta});

  @override
  Widget build(BuildContext context) {
    final rows = <(IconData, String, String)>[
      if (game.lastPlayed != null)
        (Icons.access_time_rounded, 'Last played',
            _fmtDate(game.lastPlayed!)),
      if (game.runnerPath.isNotEmpty && game.runnerPath != '/usr/bin')
        (Icons.terminal_rounded, 'Runner', game.runnerPath),
      if (game.configPath.isNotEmpty)
        (Icons.folder_rounded, 'Prefix', game.configPath),
      if (game.execPath.isNotEmpty)
        (Icons.play_circle_outline_rounded, 'Executable', game.execPath),
      if (meta?.esrbRating != null)
        (Icons.shield_outlined, 'ESRB', meta!.esrbRating!),
    ];

    if (rows.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final (icon, label, value) = e.value;
          final isLast = e.key == rows.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(icon,
                        size: 16,
                        color: cs.onSurface.withValues(alpha: 0.45)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withValues(alpha: 0.45),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            value,
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 42,
                  color: cs.outline.withValues(alpha: 0.15),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _fmtDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

class _TagsWrap extends StatelessWidget {
  final List<String> items;
  const _TagsWrap({required this.items});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: items
          .map(
            (t) => Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: cs.outline.withValues(alpha: 0.2)),
              ),
              child: Text(t, style: const TextStyle(fontSize: 12)),
            ),
          )
          .toList(),
    );
  }
}

class _AchievementsList extends StatelessWidget {
  final String gameKey;
  final List<Achievement> achievements;
  const _AchievementsList(
      {required this.gameKey, required this.achievements});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: achievements.map((a) {
        final index = achievements.indexOf(a);
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: cs.outline.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedGameImage(
                    gameKey: gameKey,
                    imageUrl: a.image,
                    type: 'achievement_$index',
                    width: 36,
                    height: 36,
                    errorBuilder: (_, _, _) => const SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(Icons.emoji_events_outlined, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        a.description,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${a.percent}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _WebsiteRow extends StatelessWidget {
  final String url;
  const _WebsiteRow({required this.url});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.link_rounded, size: 16, color: cs.primary),
        const SizedBox(width: 8),
        Expanded(
          child: SelectableText(
            url,
            style: TextStyle(fontSize: 13, color: cs.primary),
          ),
        ),
      ],
    );
  }
}
