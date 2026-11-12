import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/constants.dart';
import '../models/recipe.dart';
import '../providers/auth_provider.dart';
import '../providers/recipe_provider.dart';
import '../widgets/recipe_image.dart';
import 'recipe_form_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({super.key, required this.recipe});

  final Recipe recipe;

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late Recipe _recipe;

  @override
  void initState() {
    super.initState();
    _recipe = widget.recipe;
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final fresh = await context.read<RecipeProvider>().fetchRecipe(_recipe.id);
      if (mounted) setState(() => _recipe = fresh);
    } catch (_) {
      // Keep showing the cached recipe if the refresh fails.
    }
  }

  Future<void> _edit() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => RecipeFormScreen(recipe: _recipe)),
    );
    if (changed == true) _refresh();
  }

  Future<void> _delete() async {
    final provider = context.read<RecipeProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete recipe?'),
        content: Text('"${_recipe.title}" will be permanently deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;

    final err = await provider.deleteRecipe(_recipe.id);
    if (err != null) {
      messenger.showSnackBar(SnackBar(content: Text(err)));
    } else {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = context.watch<AuthProvider>().user?.id;
    final isOwner = currentUserId == _recipe.userId;
    final isFav = context
        .select<RecipeProvider, bool>((p) => p.isFavorite(_recipe.id));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 260,
            flexibleSpace: FlexibleSpaceBar(
              background: RecipeImage(url: _recipe.imageUrl, height: 260),
            ),
            actions: [
              IconButton(
                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.redAccent : null),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final err = await context
                      .read<RecipeProvider>()
                      .toggleFavorite(_recipe);
                  if (err != null) {
                    messenger.showSnackBar(SnackBar(content: Text(err)));
                  }
                },
              ),
              if (isOwner) ...[
                IconButton(icon: const Icon(Icons.edit), onPressed: _edit),
                IconButton(icon: const Icon(Icons.delete), onPressed: _delete),
              ],
            ],
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_recipe.title,
                          style: theme.textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      if (_recipe.author != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('by ${_recipe.author}',
                              style: theme.textTheme.bodyMedium),
                        ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (_recipe.category.isNotEmpty)
                            Chip(label: Text(_recipe.category)),
                          if (_recipe.cuisine.isNotEmpty)
                            Chip(label: Text(_recipe.cuisine)),
                          Chip(
                            label: Text(_recipe.difficulty),
                            backgroundColor: difficultyColor(_recipe.difficulty)
                                .withValues(alpha: 0.15),
                          ),
                        ],
                      ),
                      if (_recipe.description.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(_recipe.description,
                            style: theme.textTheme.bodyLarge),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _Stat(Icons.timer_outlined, '${_recipe.prepTime} min',
                              'Prep'),
                          _Stat(Icons.local_fire_department_outlined,
                              '${_recipe.cookTime} min', 'Cook'),
                          _Stat(Icons.people_outline, '${_recipe.servings}',
                              'Servings'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text('Ingredients', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 8),
                      ..._recipe.ingredients.map(
                        (i) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(Icons.check_circle_outline,
                                    size: 18),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(i)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('Instructions', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 8),
                      ..._recipe.steps.asMap().entries.map(
                            (e) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    child: Text('${e.key + 1}',
                                        style: const TextStyle(fontSize: 12)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(e.value,
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(height: 1.4)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.value, this.label);

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
