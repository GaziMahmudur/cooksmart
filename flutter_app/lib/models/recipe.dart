class Recipe {
  final String id;
  final String title;
  final String? titleBn;
  final String subtitle;
  final String? subtitleBn;
  final String imageUrl;
  final String cookTime;
  final String calories;
  final String servings;
  final String difficulty;
  final double rating;
  final int reviewsCount;
  final List<String> tags;
  final List<String> ingredients;
  final List<String>? ingredientsBn;
  final List<CookingStep> steps;
  final List<CookingStep>? stepsBn;
  final String proTip;
  final String? proTipBn;
  final String sourceBadge;
  bool isSaved;

  Recipe({
    required this.id,
    required this.title,
    this.titleBn,
    required this.subtitle,
    this.subtitleBn,
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
    this.ingredientsBn,
    required this.steps,
    this.stepsBn,
    this.proTip = '',
    this.proTipBn,
    this.isSaved = false,
  });

  String getTitle(bool isBangla) =>
      (isBangla && titleBn != null && titleBn!.isNotEmpty) ? titleBn! : title;

  String getSubtitle(bool isBangla) =>
      (isBangla && subtitleBn != null && subtitleBn!.isNotEmpty)
          ? subtitleBn!
          : subtitle;

  List<String> getIngredients(bool isBangla) =>
      (isBangla && ingredientsBn != null && ingredientsBn!.isNotEmpty)
          ? ingredientsBn!
          : ingredients;

  List<CookingStep> getSteps(bool isBangla) =>
      (isBangla && stepsBn != null && stepsBn!.isNotEmpty) ? stepsBn! : steps;

  String getProTip(bool isBangla) =>
      (isBangla && proTipBn != null && proTipBn!.isNotEmpty) ? proTipBn! : proTip;
}

class CookingStep {
  final int stepNumber;
  final String title;
  final String? titleBn;
  final String timeBadge;
  final String instruction;
  final String? instructionBn;

  CookingStep({
    required this.stepNumber,
    required this.title,
    this.titleBn,
    required this.timeBadge,
    required this.instruction,
    this.instructionBn,
  });

  String getTitle(bool isBangla) =>
      (isBangla && titleBn != null && titleBn!.isNotEmpty) ? titleBn! : title;

  String getInstruction(bool isBangla) =>
      (isBangla && instructionBn != null && instructionBn!.isNotEmpty)
          ? instructionBn!
          : instruction;
}

