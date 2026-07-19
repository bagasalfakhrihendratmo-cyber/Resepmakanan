import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/recipe.dart';

class RecipeService {
  static const String _baseUrl = 'https://api.spoonacular.com/recipes';

  Future<List<Recipe>> searchRecipes(
    String query, {
    String filter = 'all',
  }) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return [];
    }

    final apiKey = _apiKey;
    if (apiKey.isEmpty || apiKey == 'demo_key') {
      return _searchDemoRecipes(normalizedQuery, filter);
    }

    final uri = Uri.parse(
      '$_baseUrl/complexSearch?apiKey=$apiKey&query=${Uri.encodeComponent(normalizedQuery)}&number=10&addRecipeInformation=true',
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final results = decoded['results'] as List<dynamic>? ?? <dynamic>[];
        final recipes = results
            .map((item) => Recipe.fromJson(item as Map<String, dynamic>))
            .toList();
        return _applyFilter(recipes, filter);
      }
    } catch (_) {
      // Fallback to demo data when the API cannot be reached.
    }

    return _searchDemoRecipes(normalizedQuery, filter);
  }

  List<Recipe> _applyFilter(List<Recipe> recipes, String filter) {
    switch (filter) {
      case 'quick':
        return recipes
            .where((recipe) => (recipe.readyInMinutes ?? 999) <= 20)
            .toList();
      case 'simple':
        return recipes
            .where((recipe) => (recipe.ingredients.length <= 5))
            .toList();
      default:
        return recipes;
    }
  }

  Future<Recipe?> getRecipeDetail(int id) async {
    final apiKey = _apiKey;
    if (apiKey.isEmpty || apiKey == 'demo_key') {
      return _demoRecipes().firstWhere(
        (recipe) => recipe.id == id,
        orElse: () => _demoRecipes().first,
      );
    }

    final uri = Uri.parse('$_baseUrl/$id/information?apiKey=$apiKey');

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return Recipe.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
    } catch (_) {
      // Fallback to demo data when the API cannot be reached.
    }

    return _demoRecipes().firstWhere(
      (recipe) => recipe.id == id,
      orElse: () => _demoRecipes().first,
    );
  }

  String get _apiKey {
    if (!dotenv.isInitialized) {
      return '';
    }

    return dotenv.env['SPOONACULAR_API_KEY'] ?? '';
  }

  List<Recipe> _searchDemoRecipes(String normalizedQuery, String filter) {
    final recipes = _demoRecipes()
        .where(
          (recipe) => recipe.title.toLowerCase().contains(
            normalizedQuery.toLowerCase(),
          ),
        )
        .toList();
    return _applyFilter(recipes, filter);
  }

  List<Recipe> _demoRecipes() {
    return [
      const Recipe(
        id: 1,
        title: 'Nasi Goreng Spesial',
        image:
            'https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&w=800&q=80',
        readyInMinutes: 20,
        servings: 2,
        ingredients: ['Nasi', 'Telur', 'Bawang', 'Kecap', 'Cabai'],
        instructions: [
          '1. Tumis bawang.',
          '2. Masukkan nasi dan bumbu.',
          '3. Sajikan hangat.',
        ],
      ),
      const Recipe(
        id: 2,
        title: 'Soto Ayam Hangat',
        image:
            'https://images.unsplash.com/photo-1547592166-23ac45744acd?auto=format&fit=crop&w=800&q=80',
        readyInMinutes: 35,
        servings: 4,
        ingredients: ['Ayam', 'Bawang', 'Daun bawang', 'Sereh', 'Kaldu'],
        instructions: [
          '1. Rebus ayam dan bumbu.',
          '2. Tambahkan sayur.',
          '3. Sajikan dengan nasi.',
        ],
      ),
      const Recipe(
        id: 3,
        title: 'Pasta Carbonara',
        image:
            'https://images.unsplash.com/photo-1612874742237-6526221588e3?auto=format&fit=crop&w=800&q=80',
        readyInMinutes: 25,
        servings: 2,
        ingredients: ['Pasta', 'Keju', 'Susu', 'Bawang putih', 'Lada'],
        instructions: [
          '1. Rebus pasta.',
          '2. Campur bahan saus.',
          '3. Sajikan cepat.',
        ],
      ),
    ];
  }
}
