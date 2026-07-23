import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../models/recipe.dart';
import '../models/user_rating.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'makanan.db';
  static const String _tableFavorites = 'favorites';
  static const String _tableSearchHistory = 'search_history';
  static const String _tableCollections = 'collections';
  static const String _tableCollectionRecipes = 'collection_recipes';
  static const String _tableUserRatings = 'user_ratings';
  static const String _webStorageKey = 'favorite_recipes';
  static const int _dbVersion = 2;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await _createAllTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createNewTables(db);
        }
      },
    );
  }

  Future<void> _createAllTables(Database db) async {
    await db.execute('''
      CREATE TABLE $_tableFavorites (
        id INTEGER PRIMARY KEY,
        title TEXT,
        image TEXT,
        readyInMinutes INTEGER,
        servings INTEGER,
        ingredients TEXT,
        instructions TEXT,
        ingredient_data TEXT
      )
    ''');
    await _createNewTables(db);
  }

  Future<void> _createNewTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableSearchHistory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipe_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        image_url TEXT DEFAULT '',
        viewed_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableCollections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableCollectionRecipes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        collection_id INTEGER NOT NULL,
        recipe_id INTEGER NOT NULL,
        UNIQUE(collection_id, recipe_id),
        FOREIGN KEY (collection_id) REFERENCES $_tableCollections(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableUserRatings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipe_id INTEGER NOT NULL UNIQUE,
        rating INTEGER NOT NULL,
        rated_at TEXT NOT NULL
      )
    ''');
  }

  // ─── FAVORITES ──────────────────────────────────────────────────────────────

  Future<List<Recipe>> getFavorites() async {
    if (kIsWeb) {
      return _getFavoritesFromWeb();
    }

    final db = await database;
    final maps = await db.query(_tableFavorites, orderBy: 'title ASC');
    return maps
        .map(
          (item) => Recipe.fromDbMap({
            'id': item['id'] as int,
            'title': item['title'] as String,
            'image': item['image'] as String,
            'readyInMinutes': item['readyInMinutes'] as int?,
            'servings': item['servings'] as int?,
            'ingredients': item['ingredients'] as String,
            'instructions': item['instructions'] as String,
            'ingredient_data': item['ingredient_data'] as String?,
          }),
        )
        .toList();
  }

  Future<void> saveFavorite(Recipe recipe) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final favorites = await _getFavoritesFromWeb();
      final existingIndex = favorites.indexWhere(
        (item) => item.id == recipe.id,
      );
      if (existingIndex >= 0) {
        favorites[existingIndex] = recipe;
      } else {
        favorites.add(recipe);
      }
      await prefs.setString(
        _webStorageKey,
        jsonEncode(favorites.map((item) => item.toDbMap()).toList()),
      );
      return;
    }

    final db = await database;
    await db.insert(
      _tableFavorites,
      recipe.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeFavorite(int id) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final favorites = await _getFavoritesFromWeb();
      favorites.removeWhere((item) => item.id == id);
      await prefs.setString(
        _webStorageKey,
        jsonEncode(favorites.map((item) => item.toDbMap()).toList()),
      );
      return;
    }

    final db = await database;
    await db.delete(_tableFavorites, where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> isFavorite(int id) async {
    if (kIsWeb) {
      final favorites = await _getFavoritesFromWeb();
      return favorites.any((item) => item.id == id);
    }

    final db = await database;
    final result = await db.query(
      _tableFavorites,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<List<Recipe>> _getFavoritesFromWeb() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_webStorageKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((item) {
      final map = item as Map<String, dynamic>;
      return Recipe.fromDbMap({
        'id': map['id'] as int,
        'title': map['title'] as String,
        'image': map['image'] as String,
        'readyInMinutes': map['readyInMinutes'] as int?,
        'servings': map['servings'] as int?,
        'ingredients': map['ingredients'] as String,
        'instructions': map['instructions'] as String,
        'ingredient_data': map['ingredient_data'] as String?,
      });
    }).toList();
  }

  // ─── SEARCH HISTORY ─────────────────────────────────────────────────────────

  Future<List<SearchHistory>> getSearchHistory() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('search_history');
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => SearchHistory.fromMap(item as Map<String, dynamic>))
          .toList();
    }

    final db = await database;
    final maps =
        await db.query(_tableSearchHistory, orderBy: 'viewed_at DESC', limit: 100);
    return maps.map((item) => SearchHistory.fromMap(item)).toList();
  }

  Future<void> addSearchHistory(SearchHistory entry) async {
    if (kIsWeb) {
      final history = await getSearchHistory();
      history.removeWhere((h) => h.recipeId == entry.recipeId);
      history.insert(0, entry);
      if (history.length > 100) history.removeLast();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'search_history',
        jsonEncode(history.map((h) => h.toMap()).toList()),
      );
      return;
    }

    final db = await database;
    // Remove duplicate entry if exists
    await db.delete(_tableSearchHistory, where: 'recipe_id = ?', whereArgs: [entry.recipeId]);
    await db.insert(_tableSearchHistory, entry.toMap());
  }

  Future<void> deleteSearchHistoryItem(int id) async {
    if (kIsWeb) {
      final history = await getSearchHistory();
      history.removeWhere((h) => h.id == id);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'search_history',
        jsonEncode(history.map((h) => h.toMap()).toList()),
      );
      return;
    }

    final db = await database;
    await db.delete(_tableSearchHistory, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearSearchHistory() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('search_history');
      return;
    }

    final db = await database;
    await db.delete(_tableSearchHistory);
  }

  // ─── COLLECTIONS ───────────────────────────────────────────────────────────

  Future<List<Collection>> getCollections() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('collections');
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => Collection.fromMap(item as Map<String, dynamic>))
          .toList();
    }

    final db = await database;
    final maps = await db.query(_tableCollections, orderBy: 'created_at DESC');
    return maps.map((item) => Collection.fromMap(item)).toList();
  }

  Future<void> createCollection(String name) async {
    final collection = Collection(
      name: name,
      createdAt: DateTime.now(),
    );

    if (kIsWeb) {
      final collections = await getCollections();
      final newCollection = Collection(
        id: collections.isEmpty ? 1 : collections.map((c) => c.id ?? 0).reduce((a, b) => a > b ? a : b) + 1,
        name: name,
        createdAt: DateTime.now(),
      );
      collections.insert(0, newCollection);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'collections',
        jsonEncode(collections.map((c) => c.toMap()).toList()),
      );
      return;
    }

    final db = await database;
    await db.insert(_tableCollections, collection.toMap());
  }

  Future<void> deleteCollection(int id) async {
    if (kIsWeb) {
      final collections = await getCollections();
      collections.removeWhere((c) => c.id == id);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'collections',
        jsonEncode(collections.map((c) => c.toMap()).toList()),
      );
      // Also delete collection_recipes
      final recipeIds = await getCollectionRecipeIds(id);
      for (final recipeId in recipeIds) {
        await removeRecipeFromCollection(id, recipeId);
      }
      return;
    }

    final db = await database;
    await db.delete(_tableCollectionRecipes,
        where: 'collection_id = ?', whereArgs: [id]);
    await db.delete(_tableCollections, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<int>> getCollectionRecipeIds(int collectionId) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('collection_recipes_$collectionId');
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => e as int).toList();
    }

    final db = await database;
    final maps = await db.query(_tableCollectionRecipes,
        where: 'collection_id = ?', whereArgs: [collectionId]);
    return maps.map((m) => m['recipe_id'] as int).toList();
  }

  Future<void> addRecipeToCollection(int collectionId, int recipeId) async {
    if (kIsWeb) {
      final ids = await getCollectionRecipeIds(collectionId);
      if (!ids.contains(recipeId)) {
        ids.add(recipeId);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'collection_recipes_$collectionId',
          jsonEncode(ids),
        );
      }
      return;
    }

    final db = await database;
    try {
      await db.insert(_tableCollectionRecipes, {
        'collection_id': collectionId,
        'recipe_id': recipeId,
      });
    } catch (_) {
      // Ignore duplicate
    }
  }

  Future<void> removeRecipeFromCollection(int collectionId, int recipeId) async {
    if (kIsWeb) {
      final ids = await getCollectionRecipeIds(collectionId);
      ids.remove(recipeId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'collection_recipes_$collectionId',
        jsonEncode(ids),
      );
      return;
    }

    final db = await database;
    await db.delete(_tableCollectionRecipes,
        where: 'collection_id = ? AND recipe_id = ?',
        whereArgs: [collectionId, recipeId]);
  }

  Future<Map<int, List<int>>> getAllCollectionRecipeIds() async {
    if (kIsWeb) {
      final collections = await getCollections();
      final result = <int, List<int>>{};
      for (final c in collections) {
        result[c.id!] = await getCollectionRecipeIds(c.id!);
      }
      return result;
    }

    final db = await database;
    final maps = await db.query(_tableCollectionRecipes);
    final result = <int, List<int>>{};
    for (final m in maps) {
      final colId = m['collection_id'] as int;
      final recId = m['recipe_id'] as int;
      result.putIfAbsent(colId, () => []);
      result[colId]!.add(recId);
    }
    return result;
  }

  // ─── USER RATINGS ──────────────────────────────────────────────────────────

  Future<UserRating?> getUserRating(int recipeId) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('user_ratings');
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw) as List<dynamic>;
      final match = decoded.firstWhere(
        (item) => (item as Map<String, dynamic>)['recipe_id'] == recipeId,
        orElse: () => null,
      );
      if (match == null) return null;
      return UserRating.fromMap(match as Map<String, dynamic>);
    }

    final db = await database;
    final maps = await db.query(_tableUserRatings,
        where: 'recipe_id = ?', whereArgs: [recipeId], limit: 1);
    if (maps.isEmpty) return null;
    return UserRating.fromMap(maps.first);
  }

  Future<void> saveUserRating(int recipeId, int rating) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('user_ratings');
      var ratings = <Map<String, dynamic>>[];
      if (raw != null && raw.isNotEmpty) {
        ratings = (jsonDecode(raw) as List<dynamic>)
            .map((item) => item as Map<String, dynamic>)
            .toList();
      }
      ratings.removeWhere((r) => r['recipe_id'] == recipeId);
      ratings.add({
        'recipe_id': recipeId,
        'rating': rating,
        'rated_at': DateTime.now().toIso8601String(),
      });
      await prefs.setString('user_ratings', jsonEncode(ratings));
      return;
    }

    final db = await database;
    await db.insert(
      _tableUserRatings,
      UserRating(
        recipeId: recipeId,
        rating: rating,
        ratedAt: DateTime.now(),
      ).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─── COLLECTION RECIPES DATA ───────────────────────────────────────────────

  Future<List<Recipe>> getRecipesByIds(List<int> ids, {List<Recipe>? allRecipes}) async {
    if (allRecipes != null) {
      return allRecipes.where((r) => ids.contains(r.id)).toList();
    }
    // Fallback: get from favorites
    final favorites = await getFavorites();
    return favorites.where((r) => ids.contains(r.id)).toList();
  }
}
