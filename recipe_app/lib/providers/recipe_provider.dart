import 'package:flutter/foundation.dart';

import '../models/recipe.dart';
import '../services/api_service.dart';

class RecipeProvider extends ChangeNotifier {
  RecipeProvider(this._api);

  final ApiService _api;

  final List<Recipe> recipes = [];
  List<Recipe> favorites = [];
  final Set<int> _favoriteIds = {};

  bool loading = false;
  bool loadingMore = false;
  bool hasMore = true;
  String? error;
  int _page = 1;

  String search = '';
  String? category;
  String? cuisine;
  String? difficulty;

  bool get hasFilters =>
      category != null || cuisine != null || difficulty != null;

  bool isFavorite(int id) => _favoriteIds.contains(id);

  // ---------- Listing ----------

  Future<void> loadRecipes() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final res = await _api.getRecipes(
        page: 1,
        search: search,
        category: category,
        cuisine: cuisine,
        difficulty: difficulty,
      );
      recipes
        ..clear()
        ..addAll(res.recipes);
      _page = 1;
      hasMore = res.hasNext;
    } on ApiException catch (e) {
      error = e.message;
    }
    loading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (loading || loadingMore || !hasMore) return;
    loadingMore = true;
    notifyListeners();
    try {
      final res = await _api.getRecipes(
        page: _page + 1,
        search: search,
        category: category,
        cuisine: cuisine,
        difficulty: difficulty,
      );
      recipes.addAll(res.recipes);
      _page++;
      hasMore = res.hasNext;
    } on ApiException catch (e) {
      error = e.message;
    }
    loadingMore = false;
    notifyListeners();
  }

  Future<void> setSearch(String value) {
    search = value.trim();
    return loadRecipes();
  }

  Future<void> setFilters({
    String? category,
    String? cuisine,
    String? difficulty,
  }) {
    this.category = category;
    this.cuisine = cuisine;
    this.difficulty = difficulty;
    return loadRecipes();
  }

  Future<Recipe> fetchRecipe(int id) => _api.getRecipe(id);

  // ---------- CRUD (return an error message or null) ----------

  Future<String?> createRecipe(Map<String, dynamic> payload) async {
    try {
      await _api.createRecipe(payload);
      await loadRecipes();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> updateRecipe(int id, Map<String, dynamic> payload) async {
    try {
      final updated = await _api.updateRecipe(id, payload);
      final i = recipes.indexWhere((r) => r.id == id);
      if (i != -1) recipes[i] = updated;
      final f = favorites.indexWhere((r) => r.id == id);
      if (f != -1) favorites[f] = updated;
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> deleteRecipe(int id) async {
    try {
      await _api.deleteRecipe(id);
      recipes.removeWhere((r) => r.id == id);
      favorites.removeWhere((r) => r.id == id);
      _favoriteIds.remove(id);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  // ---------- Favorites ----------

  Future<void> loadFavorites() async {
    try {
      favorites = await _api.getFavorites();
      _favoriteIds
        ..clear()
        ..addAll(favorites.map((r) => r.id));
    } on ApiException catch (e) {
      error = e.message;
    }
    notifyListeners();
  }

  /// Returns an error message, or null on success.
  Future<String?> toggleFavorite(Recipe recipe) async {
    try {
      if (isFavorite(recipe.id)) {
        await _api.removeFavorite(recipe.id);
        _favoriteIds.remove(recipe.id);
        favorites.removeWhere((r) => r.id == recipe.id);
      } else {
        await _api.addFavorite(recipe.id);
        _favoriteIds.add(recipe.id);
        favorites.insert(0, recipe);
      }
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  /// Clears all user-specific state (used on logout).
  void reset() {
    recipes.clear();
    favorites = [];
    _favoriteIds.clear();
    search = '';
    category = cuisine = difficulty = null;
    hasMore = true;
    error = null;
    notifyListeners();
  }
}
