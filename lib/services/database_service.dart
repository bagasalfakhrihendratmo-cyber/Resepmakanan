import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../models/recipe.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'favorites.db';
  static const String _tableName = 'favorites';
  static const String _webStorageKey = 'favorite_recipes';

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY,
            title TEXT,
            image TEXT,
            readyInMinutes INTEGER,
            servings INTEGER,
            ingredients TEXT,
            instructions TEXT
          )
        ''');
      },
    );
  }

  Future<List<Recipe>> getFavorites() async {
    if (kIsWeb) {
      return _getFavoritesFromWeb();
    }

    final db = await database;
    final maps = await db.query(_tableName, orderBy: 'title ASC');
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
      _tableName,
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
    await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> isFavorite(int id) async {
    if (kIsWeb) {
      final favorites = await _getFavoritesFromWeb();
      return favorites.any((item) => item.id == id);
    }

    final db = await database;
    final result = await db.query(
      _tableName,
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
      });
    }).toList();
  }
}
