import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/constants.dart';
import '../providers/recipe_provider.dart';
import '../widgets/error_view.dart';
import '../widgets/recipe_card.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  final _scroll = ScrollController();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
      context.read<RecipeProvider>().loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<RecipeProvider>().setSearch(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecipeProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search by title, ingredient or description',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchCtrl.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        provider.setSearch('');
                        setState(() {});
                      },
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              _FilterChip(
                label: 'Category',
                value: provider.category,
                options: kCategories,
                onChanged: (v) => provider.setFilters(
                  category: v,
                  cuisine: provider.cuisine,
                  difficulty: provider.difficulty,
                ),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Cuisine',
                value: provider.cuisine,
                options: kCuisines,
                onChanged: (v) => provider.setFilters(
                  category: provider.category,
                  cuisine: v,
                  difficulty: provider.difficulty,
                ),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Difficulty',
                value: provider.difficulty,
                options: kDifficulties,
                onChanged: (v) => provider.setFilters(
                  category: provider.category,
                  cuisine: provider.cuisine,
                  difficulty: v,
                ),
              ),
              if (provider.hasFilters) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => provider.setFilters(),
                  icon: const Icon(Icons.filter_alt_off, size: 18),
                  label: const Text('Clear'),
                ),
              ],
            ],
          ),
        ),
        Expanded(child: _buildBody(provider)),
      ],
    );
  }

  Widget _buildBody(RecipeProvider provider) {
    if (provider.loading && provider.recipes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null && provider.recipes.isEmpty) {
      return ErrorView(message: provider.error!, onRetry: provider.loadRecipes);
    }
    if (provider.recipes.isEmpty) {
      return const Center(child: Text('No recipes found.'));
    }
    return RefreshIndicator(
      onRefresh: provider.loadRecipes,
      child: RecipeGrid(
        recipes: provider.recipes,
        controller: _scroll,
        showLoader: provider.loadingMore,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (v) => onChanged(v == '__all__' ? null : v),
      itemBuilder: (_) => [
        PopupMenuItem(value: '__all__', child: Text('All ${label.toLowerCase()}')),
        ...options.map((o) => PopupMenuItem(value: o, child: Text(o))),
      ],
      child: Chip(
        label: Text(value ?? label),
        avatar: Icon(
          value == null ? Icons.tune : Icons.check_circle,
          size: 18,
        ),
        backgroundColor:
            value == null ? null : Theme.of(context).colorScheme.primaryContainer,
      ),
    );
  }
}
