import 'package:flutter/material.dart';

class RecipeImage extends StatelessWidget {
  const RecipeImage({super.key, required this.url, this.height});

  final String url;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = Container(
      height: height,
      width: double.infinity,
      color: scheme.surfaceContainerHighest,
      child: Icon(Icons.restaurant_menu,
          size: 48, color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
    );

    if (url.isEmpty) return placeholder;

    return Image.network(
      url,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => placeholder,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : placeholder,
    );
  }
}
