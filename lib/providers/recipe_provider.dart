import 'package:flutter/material.dart';

import '../models/nutrition_info.dart';
import '../models/recipe.dart';
import '../models/user_rating.dart';
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

  // ─── EXISTING STATE ──────────────────────────────────────────────────────
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

  // ─── NEW FEATURE STATE ───────────────────────────────────────────────────
  // Advanced Search
  String? _cuisineFilter;
  String? _dietFilter;
  String? _intoleranceFilter;
  int? _maxReadyTime;

  String? get cuisineFilter => _cuisineFilter;
  String? get dietFilter => _dietFilter;
  String? get intoleranceFilter => _intoleranceFilter;
  int? get maxReadyTime => _maxReadyTime;

  // Search History
  List<SearchHistory> _searchHistory = [];
  bool _historyLoading = false;

  List<SearchHistory> get searchHistory => _searchHistory;
  bool get historyLoading => _historyLoading;

  // Collections
  List<Collection> _collections = [];
  Map<int, List<int>> _collectionRecipeIds = {};
  bool _collectionsLoading = false;

  List<Collection> get collections => _collections;
  Map<int, List<int>> get collectionRecipeIds => _collectionRecipeIds;
  bool get collectionsLoading => _collectionsLoading;

  // User Ratings
  final Map<int, UserRating> _userRatings = {};
  final bool _ratingsLoading = false;

  Map<int, UserRating> get userRatings => _userRatings;
  bool get ratingsLoading => _ratingsLoading;

  // Nutrition
  NutritionInfo? _nutritionInfo;
  bool _nutritionLoading = false;

  NutritionInfo? get nutritionInfo => _nutritionInfo;
  bool get nutritionLoading => _nutritionLoading;

  // ─── EXISTING METHODS ────────────────────────────────────────────────────
  Future<void> searchRecipes(String query, {String filter = 'all'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _activeFilter = filter;

    try {
      final recipes = await _recipeService.searchRecipes(
        query,
        filter: filter,
        cuisine: 'Indonesian',
        diet: _dietFilter,
        intolerance: _intoleranceFilter,
        maxReadyTime: _maxReadyTime,
      );
      _searchResults = recipes;
      // Hanya set errorMessage untuk error API sungguhan (catch block),
      // bukan untuk hasil kosong - UI akan deteksi dari searchResults.isEmpty
    } catch (_) {
      _searchResults = [];
      _errorMessage = 'Gagal terhubung ke server. Menggunakan data lokal...';
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

  void updateFilter(String filter) {
    _activeFilter = filter;
    notifyListeners();
  }

  bool isFavorite(int id) {
    return _favoriteIds.contains(id);
  }

  // ─── ADVANCED SEARCH FILTERS ─────────────────────────────────────────────
  void setAdvancedFilters({
    String? cuisine,
    String? diet,
    String? intolerance,
    int? maxReadyTime,
  }) {
    _cuisineFilter = cuisine;
    _dietFilter = diet;
    _intoleranceFilter = intolerance;
    _maxReadyTime = maxReadyTime;
    notifyListeners();
  }

  void clearAdvancedFilters() {
    _cuisineFilter = null;
    _dietFilter = null;
    _intoleranceFilter = null;
    _maxReadyTime = null;
    notifyListeners();
  }

  bool get hasActiveAdvancedFilters =>
      (_cuisineFilter != null && _cuisineFilter! != 'any') ||
      (_dietFilter != null && _dietFilter! != 'any') ||
      (_intoleranceFilter != null && _intoleranceFilter! != 'any') ||
      (_maxReadyTime != null && _maxReadyTime! > 0);

  // ─── SEARCH HISTORY ──────────────────────────────────────────────────────
  Future<void> loadSearchHistory() async {
    _historyLoading = true;
    notifyListeners();

    try {
      _searchHistory = await _databaseService.getSearchHistory();
    } catch (_) {
      // Silent fail
    } finally {
      _historyLoading = false;
      notifyListeners();
    }
  }

  Future<void> addToSearchHistory(Recipe recipe) async {
    try {
      await _databaseService.addSearchHistory(SearchHistory(
        recipeId: recipe.id,
        title: recipe.title,
        imageUrl: recipe.image,
        viewedAt: DateTime.now(),
      ));
      await loadSearchHistory();
    } catch (_) {
      // Silent fail
    }
  }

  Future<void> deleteSearchHistoryItem(int id) async {
    try {
      await _databaseService.deleteSearchHistoryItem(id);
      _searchHistory.removeWhere((item) => item.id == id);
      notifyListeners();
    } catch (_) {
      // Silent fail
    }
  }

  Future<void> clearSearchHistory() async {
    try {
      await _databaseService.clearSearchHistory();
      _searchHistory.clear();
      notifyListeners();
    } catch (_) {
      // Silent fail
    }
  }

  // ─── COLLECTIONS ─────────────────────────────────────────────────────────
  Future<void> loadCollections() async {
    _collectionsLoading = true;
    notifyListeners();

    try {
      _collections = await _databaseService.getCollections();
      _collectionRecipeIds = await _databaseService.getAllCollectionRecipeIds();
    } catch (_) {
      // Silent fail
    } finally {
      _collectionsLoading = false;
      notifyListeners();
    }
  }

  Future<void> createCollection(String name) async {
    try {
      await _databaseService.createCollection(name);
      await loadCollections();
    } catch (_) {
      // Silent fail
    }
  }

  Future<void> deleteCollection(int id) async {
    try {
      await _databaseService.deleteCollection(id);
      _collections.removeWhere((c) => c.id == id);
      _collectionRecipeIds.remove(id);
      notifyListeners();
    } catch (_) {
      // Silent fail
    }
  }

  Future<List<int>> getCollectionRecipeIds(int collectionId) async {
    return _collectionRecipeIds[collectionId] ?? [];
  }

  Future<void> addRecipeToCollection(int collectionId, int recipeId) async {
    try {
      await _databaseService.addRecipeToCollection(collectionId, recipeId);
      _collectionRecipeIds.putIfAbsent(collectionId, () => []);
      _collectionRecipeIds[collectionId]!.add(recipeId);
      notifyListeners();
    } catch (_) {
      // Silent fail
    }
  }

  Future<void> removeRecipeFromCollection(int collectionId, int recipeId) async {
    try {
      await _databaseService.removeRecipeFromCollection(collectionId, recipeId);
      _collectionRecipeIds[collectionId]?.remove(recipeId);
      notifyListeners();
    } catch (_) {
      // Silent fail
    }
  }

  bool isRecipeInCollection(int collectionId, int recipeId) {
    return (_collectionRecipeIds[collectionId] ?? []).contains(recipeId);
  }

  int getRecipeCountInCollection(int collectionId) {
    return _collectionRecipeIds[collectionId]?.length ?? 0;
  }

  // ─── USER RATINGS ────────────────────────────────────────────────────────
  Future<int?> getUserRating(int recipeId) async {
    if (_userRatings.containsKey(recipeId)) {
      return _userRatings[recipeId]!.rating;
    }

    try {
      final rating = await _databaseService.getUserRating(recipeId);
      if (rating != null) {
        _userRatings[recipeId] = rating;
        return rating.rating;
      }
    } catch (_) {
      // Silent fail
    }
    return null;
  }

  Future<void> saveUserRating(int recipeId, int rating) async {
    try {
      await _databaseService.saveUserRating(recipeId, rating);
      _userRatings[recipeId] = UserRating(
        recipeId: recipeId,
        rating: rating,
        ratedAt: DateTime.now(),
      );
      notifyListeners();
    } catch (_) {
      // Silent fail
    }
  }

  // ─── NUTRITION INFO ──────────────────────────────────────────────────────
  Future<void> loadNutritionInfo(int recipeId) async {
    _nutritionLoading = true;
    _nutritionInfo = null;
    notifyListeners();

    try {
      _nutritionInfo = await _recipeService.getNutritionInfo(recipeId);
    } catch (_) {
      // Silent fail
    } finally {
      _nutritionLoading = false;
      notifyListeners();
    }
  }
}
