class Recipe {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String cookTime;
  final String calories;
  final String servings;
  final String difficulty;
  final double rating;
  final int reviewsCount;
  final List<String> tags;
  final List<String> ingredients;
  final List<CookingStep> steps;
  final String proTip;
  final String sourceBadge;
  bool isSaved;

  Recipe({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.cookTime,
    required this.calories,
    this.servings = '2 People',
    this.difficulty = 'Easy',
    required this.rating,
    this.reviewsCount = 1200,
    this.tags = const [],
    this.sourceBadge = 'Chef Pick',
    required this.ingredients,
    required this.steps,
    this.proTip = '',
    this.isSaved = false,
  });
}

class CookingStep {
  final int stepNumber;
  final String title;
  final String timeBadge;
  final String instruction;

  CookingStep({
    required this.stepNumber,
    required this.title,
    required this.timeBadge,
    required this.instruction,
  });
}
