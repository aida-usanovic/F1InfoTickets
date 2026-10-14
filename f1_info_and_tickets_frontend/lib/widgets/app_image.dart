import 'package:flutter/material.dart';

import '../config/api_config.dart';

/// Image stored on the API server (driver photo, team logo...), with an icon when it is missing.
class AppImage extends StatelessWidget {
  final String? path;
  final double size;
  final IconData fallback;
  final bool circle;
  final BoxFit fit;

  const AppImage({
    super.key,
    required this.path,
    this.size = 40,
    this.fallback = Icons.image_outlined,
    this.circle = false,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final url = ApiConfig.imageUrl(path);
    final placeholder = Container(
      width: size,
      height: size,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(fallback, size: size * 0.55, color: Theme.of(context).disabledColor),
    );
    final image = url == null
        ? placeholder
        : Image.network(url, width: size, height: size, fit: fit, errorBuilder: (_, _, _) => placeholder);
    return circle ? ClipOval(child: image) : ClipRRect(borderRadius: BorderRadius.circular(8), child: image);
  }
}
