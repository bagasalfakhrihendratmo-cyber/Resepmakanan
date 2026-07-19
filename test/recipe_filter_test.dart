import 'package:flutter_test/flutter_test.dart';
import 'package:makanan/services/recipe_service.dart';

void main() {
  group('Recipe search filters', () {
    test('returns only quick recipes when quick filter is selected', () async {
      final service = RecipeService();
      final recipes = await service.searchRecipes('nasi', filter: 'quick');

      expect(recipes, isNotEmpty);
      expect(
        recipes.every((recipe) => (recipe.readyInMinutes ?? 999) <= 20),
        isTrue,
      );
    });
  });
}
