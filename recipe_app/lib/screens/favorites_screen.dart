import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/recipe_provider.dart';
import '../widgets/recipe_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecipeProvider>();

    if (provider.favorites.isEmpty) {
      return RefreshIndicator(
        onRefresh: provider.loadFavorites,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Icon(Icons.favorite_border, size: 56),
            SizedBox(height: 12),
            Center(child: Text('No favorites yet. Tap the heart on a recipe!')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.loadFavorites,
      child: RecipeGrid(recipes: provider.favorites),
    );
  }
}
