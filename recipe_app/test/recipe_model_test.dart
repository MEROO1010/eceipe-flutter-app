import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/models/recipe.dart';

void main() {
  test('Recipe.fromJson parses API payload', () {
    final recipe = Recipe.fromJson({
      'id': 1,
      'title': 'Spaghetti Carbonara',
      'description': 'Classic',
      'ingredients': ['spaghetti', 'eggs'],
      'instructions': 'Boil.\nMix.',
      'prep_time': 10,
      'cook_time': 15,
      'servings': 4,
      'difficulty': 'Medium',
      'category': 'Dinner',
      'cuisine': 'Italian',
      'image_url': '',
      'user_id': 2,
      'author': 'demo',
    });

    expect(recipe.title, 'Spaghetti Carbonara');
    expect(recipe.totalTime, 25);
    expect(recipe.ingredients.length, 2);
    expect(recipe.steps, ['Boil.', 'Mix.']);
  });
}
