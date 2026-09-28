import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/core_providers.dart';

class ProfileImageContent extends ConsumerStatefulWidget {
  const ProfileImageContent({
    required this.path,
    required this.fallback,
    super.key,
  });

  final String? path;
  final Widget fallback;

  @override
  ConsumerState<ProfileImageContent> createState() =>
      _ProfileImageContentState();
}

class _ProfileImageContentState extends ConsumerState<ProfileImageContent> {
  Future<Uint8List?>? _image;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ProfileImageContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) _load();
  }

  void _load() {
    final path = widget.path;
    _image = path == null || path.startsWith('http')
        ? null
        : ref.read(storageServiceProvider).downloadProfileImage(path);
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.path;
    if (path == null) return widget.fallback;
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => widget.fallback,
      );
    }
    return FutureBuilder<Uint8List?>(
      future: _image,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) return widget.fallback;
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => widget.fallback,
        );
      },
    );
  }
}
