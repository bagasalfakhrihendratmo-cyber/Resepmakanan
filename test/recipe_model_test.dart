import 'package:flutter_test/flutter_test.dart';
import 'package:makanan/models/recipe.dart';

void main() {
  group('Recipe model', () {
    test('parses recipe data from JSON', () {
      final recipe = Recipe.fromJson({
        'id': 101,
        'title': 'Nasi Goreng',
        'image': 'https://example.com/nasi.jpg',
        'readyInMinutes': 20,
        'servings': 2,
        'extendedIngredients': [
          {'name': 'nasi', 'amount': 2, 'unit': 'piring'},
        ],
        'analyzedInstructions': [
          {
            'steps': [
              {'number': 1, 'step': 'Tumis bawang.'},
            ],
          },
        ],
      });

      expect(recipe.id, 101);
      expect(recipe.title, 'Nasi Goreng');
      expect(recipe.ingredients, contains('nasi (2 piring)'));
      expect(recipe.instructions, contains('1. Tumis bawang.'));
    });
  });
}
