import 'dart:convert';

import 'ingredient.dart';

class Recipe {
  const Recipe({
    required this.id,
    required this.title,
    required this.image,
    this.readyInMinutes,
    this.servings,
    required this.ingredients,
    required this.instructions,
    this.ingredientData,
  });

  final int id;
  final String title;
  final String image;
  final int? readyInMinutes;
  final int? servings;
  final List<String> ingredients;
  final List<String> instructions;
  final List<Ingredient>? ingredientData;

  factory Recipe.fromJson(Map<String, dynamic> json) {
    final ingredients = <String>[];
    final ingredientData = <Ingredient>[];

    final ingredientList =
        json['extendedIngredients'] as List<dynamic>? ?? <dynamic>[];
    for (final item in ingredientList) {
      if (item is Map<String, dynamic>) {
        final ing = Ingredient.fromJson(item);
        ingredientData.add(ing);
        ingredients.add(ing.toDisplayString());
      }
    }

    final instructions = <String>[];

    final instructionGroups =
        json['analyzedInstructions'] as List<dynamic>? ?? <dynamic>[];
    for (final group in instructionGroups) {
      if (group is Map<String, dynamic>) {
        final steps = group['steps'] as List<dynamic>? ?? <dynamic>[];
        for (final step in steps) {
          if (step is Map<String, dynamic>) {
            final number = step['number']?.toString() ?? '1';
            final text = step['step']?.toString() ?? '';
            if (text.isNotEmpty) {
              instructions.add('$number. $text');
            }
          }
        }
      }
    }

    if (instructions.isEmpty) {
      instructions.add('Langkah memasak belum tersedia.');
    }

    if (ingredients.isEmpty) {
      ingredients.add('Daftar bahan belum tersedia.');
    }

    return Recipe(
      id: json['id']?.toInt() ?? 0,
      title: json['title']?.toString() ?? 'Resep',
      image: json['image']?.toString() ?? '',
      readyInMinutes: json['readyInMinutes']?.toInt(),
      servings: json['servings']?.toInt(),
      ingredients: ingredients,
      instructions: instructions,
      ingredientData: ingredientData.isNotEmpty ? ingredientData : null,
    );
  }

  factory Recipe.fromDbMap(Map<String, dynamic> map) {
    final ingredients = _decodeDbList(map['ingredients'] as String);
    return Recipe(
      id: map['id'] as int,
      title: map['title'] as String,
      image: map['image'] as String,
      readyInMinutes: map['readyInMinutes'] as int?,
      servings: map['servings'] as int?,
      ingredients: ingredients,
      instructions: _decodeDbList(map['instructions'] as String),
      ingredientData: map['ingredient_data'] != null
          ? _decodeIngredientData(map['ingredient_data'] as String)
          : _parseStructuredIngredients(ingredients),
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'title': title,
      'image': image,
      'readyInMinutes': readyInMinutes,
      'servings': servings,
      'ingredients': ingredients.join('||'),
      'instructions': instructions.join('||'),
      if (ingredientData != null)
        'ingredient_data':
            jsonEncode(ingredientData!.map((i) => i.toJson()).toList()),
    };
  }

  static List<String> _decodeDbList(String value) {
    if (value.trimLeft().startsWith('[')) {
      final decoded = jsonDecode(value) as List<dynamic>;
      return decoded
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return value.split('||').where((item) => item.isNotEmpty).toList();
  }

  static List<Ingredient> _decodeIngredientData(String value) {
    final decoded = jsonDecode(value) as List<dynamic>;
    return decoded
        .map((item) => Ingredient.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static List<Ingredient> _parseStructuredIngredients(List<String> strings) {
    return strings.map((s) => Ingredient.fromDisplayString(s)).toList();
  }
}
