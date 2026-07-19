import 'dart:convert';

class Recipe {
  const Recipe({
    required this.id,
    required this.title,
    required this.image,
    this.readyInMinutes,
    this.servings,
    required this.ingredients,
    required this.instructions,
  });

  final int id;
  final String title;
  final String image;
  final int? readyInMinutes;
  final int? servings;
  final List<String> ingredients;
  final List<String> instructions;

  factory Recipe.fromJson(Map<String, dynamic> json) {
    final ingredients = <String>[];
    final instructions = <String>[];

    final ingredientList =
        json['extendedIngredients'] as List<dynamic>? ?? <dynamic>[];
    for (final item in ingredientList) {
      if (item is Map<String, dynamic>) {
        final name = item['name']?.toString() ?? 'Bahan';
        final amount = item['amount']?.toString() ?? '1';
        final unit = item['unit']?.toString() ?? '';
        final suffix = unit.isEmpty ? '' : ' $unit';
        ingredients.add('$name ($amount$suffix)');
      }
    }

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
    );
  }

  factory Recipe.fromDbMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'] as int,
      title: map['title'] as String,
      image: map['image'] as String,
      readyInMinutes: map['readyInMinutes'] as int?,
      servings: map['servings'] as int?,
      ingredients: _decodeDbList(map['ingredients'] as String),
      instructions: _decodeDbList(map['instructions'] as String),
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
}
