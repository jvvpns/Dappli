import 'package:kusinai01_app/data/recipe_model.dart';

class SearchLogic {
  /// Calculates a relevance score for a recipe based on a given search query.
  /// Higher score means a better match.
  static int calculateRelevanceScore(Recipe recipe, String query) {
    if (query.trim().isEmpty) return 0;
    
    int score = 0;
    final lowerQuery = query.toLowerCase();
    final queryIngredients = lowerQuery
        .split(",")
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // 1. Keyword search priority
    if (recipe.title.toLowerCase().contains(lowerQuery)) {
      score += 50;
    } else if (recipe.displayTitle.toLowerCase().contains(lowerQuery)) {
      score += 40;
    }

    // 2. Ingredient count match
    final recipeIngredients = recipe.ingredients.map((e) => e.toLowerCase()).toList();
    for (final qIng in queryIngredients) {
      for (final rIng in recipeIngredients) {
        if (rIng.contains(qIng)) {
          if (rIng == qIng) {
            score += 30; // Exact match bonus
          } else {
            score += 20; // Partial match
          }
          break; // Only count one match per query ingredient against the recipe
        }
      }
    }

    return score;
  }
}
