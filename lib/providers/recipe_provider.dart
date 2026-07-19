import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../services/database_service.dart';
import '../services/recipe_service.dart';

class RecipeProvider extends ChangeNotifier {
  RecipeProvider({bool autoLoadFavorites = true}) {
    if (autoLoadFavorites) {
      loadFavorites();
    }
  }

  final RecipeService _recipeService = RecipeService();
  final DatabaseService _databaseService = DatabaseService();

  List<Recipe> _searchResults = [];
  List<Recipe> _favorites = [];
  Recipe? _selectedRecipe;
  bool _isLoading = false;
  String? _errorMessage;
  String _activeFilter = 'all';
  final Set<int> _favoriteIds = <int>{};

  List<Recipe> get searchResults => _searchResults;
  List<Recipe> get favorites => _favorites;
  Recipe? get selectedRecipe => _selectedRecipe;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Set<int> get favoriteIds => _favoriteIds;
  String get activeFilter => _activeFilter;

  Future<void> searchRecipes(String query, {String filter = 'all'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _activeFilter = filter;

    try {
      final recipes = await _recipeService.searchRecipes(query, filter: filter);
      _searchResults = recipes;
      if (recipes.isEmpty) {
        _errorMessage = 'Tidak ada resep yang ditemukan untuk pencarian ini.';
      }
    } catch (_) {
      _searchResults = [];
      _errorMessage = 'Tidak dapat memuat resep. Coba lagi nanti.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRecipeDetail(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final recipe = await _recipeService.getRecipeDetail(id);
      _selectedRecipe = recipe;
    } catch (_) {
      _errorMessage = 'Tidak dapat memuat detail resep.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFavorites() async {
    final favorites = await _databaseService.getFavorites();
    _favorites = favorites;
    _favoriteIds.clear();
    for (final recipe in favorites) {
      _favoriteIds.add(recipe.id);
    }
    notifyListeners();
  }

  void selectRecipe(Recipe recipe) {
    _selectedRecipe = recipe;
    notifyListeners();
  }

  Future<void> toggleFavorite(Recipe recipe) async {
    if (_favoriteIds.contains(recipe.id)) {
      await _databaseService.removeFavorite(recipe.id);
      _favoriteIds.remove(recipe.id);
      _favorites.removeWhere((item) => item.id == recipe.id);
    } else {
      await _databaseService.saveFavorite(recipe);
      _favoriteIds.add(recipe.id);
      _favorites.add(recipe);
    }
    notifyListeners();
  }

  bool isFavorite(int id) {
    return _favoriteIds.contains(id);
  }
}
