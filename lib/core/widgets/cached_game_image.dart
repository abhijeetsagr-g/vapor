import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../image_cache_service.dart';

class CachedGameImage extends StatefulWidget {
  final String gameKey;
  final String? imageUrl;
  final String type;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const CachedGameImage({
    super.key,
    required this.gameKey,
    this.imageUrl,
    required this.type,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorBuilder,
  });

  @override
  State<CachedGameImage> createState() => _CachedGameImageState();
}

class _CachedGameImageState extends State<CachedGameImage> {
  String? _localPath;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _checkCache();
  }

  @override
  void didUpdateWidget(CachedGameImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gameKey != widget.gameKey ||
        oldWidget.type != widget.type ||
        oldWidget.imageUrl != widget.imageUrl) {
      _checked = false;
      _localPath = null;
      _checkCache();
    }
  }

  Future<void> _checkCache() async {
    final cache = GetIt.instance<ImageCacheService>();
    final path = await cache.getLocalPath(widget.gameKey, widget.type);
    if (!mounted) return;
    setState(() {
      _localPath = path;
      _checked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const SizedBox.shrink();
    }

    if (_localPath != null) {
      return Image.file(
        File(_localPath!),
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: widget.errorBuilder,
      );
    }

    if (widget.imageUrl != null) {
      return Image.network(
        widget.imageUrl!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: widget.errorBuilder,
      );
    }

    if (widget.errorBuilder != null) {
      return widget.errorBuilder!(context, 'No image available', null);
    }

    return const SizedBox.shrink();
  }
}
