import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/recipe.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;
  final AppState appState;

  const RecipeDetailScreen({
    super.key,
    required this.recipe,
    required this.appState,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final Set<int> _checkedIngredients = {0, 1}; // Pre-check some for realism

  void _toggleIngredient(int index) {
    setState(() {
      if (_checkedIngredients.contains(index)) {
        _checkedIngredients.remove(index);
      } else {
        _checkedIngredients.add(index);
      }
    });
  }

  void _toggleSaveWithFeedback() {
    final recipe = widget.recipe;
    final willSave = !recipe.isSaved;
    widget.appState.toggleSaveRecipe(recipe.id);
    setState(() {});

    final msg = willSave
        ? (widget.appState.isBangla
            ? 'পছন্দের তালিকায় "${recipe.title}" সেভ করা হয়েছে'
            : 'Saved "${recipe.title}" to My Recipes')
        : widget.appState.tr('removedFromFavorites');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.surfaceElevated,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleShare() {
    final recipe = widget.recipe;
    final summary = StringBuffer();
    summary.writeln('🍳 CookSmart Recipe: ${recipe.title}');
    summary.writeln('⏱️ Cook Time: ${recipe.cookTime} | 🔥 ${recipe.calories} | 👥 ${recipe.servings}');
    summary.writeln('\n🛒 Ingredients:');
    for (final ing in recipe.ingredients) {
      summary.writeln('• $ing');
    }
    summary.writeln('\n👨‍🍳 Steps:');
    for (final step in recipe.steps) {
      summary.writeln('${step.stepNumber}. ${step.title} (${step.timeBadge}): ${step.instruction}');
    }
    if (recipe.proTip.isNotEmpty) {
      summary.writeln('\n💡 Chef\'s Pro Tip: ${recipe.proTip}');
    }

    Clipboard.setData(ClipboardData(text: summary.toString()));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.appState.tr('copiedToClipboard')),
        backgroundColor: AppColors.surfaceElevated,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final isSaved = recipe.isSaved;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top App Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceCard,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: const Icon(Icons.arrow_back, color: AppColors.textWhite, size: 20),
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              widget.appState.tr('smartMatch'),
                              style: const TextStyle(
                                color: AppColors.primaryOrange,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.appState.tr('recipeDetailTitle'),
                              style: const TextStyle(
                                color: AppColors.textWhite,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _toggleSaveWithFeedback,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceCard,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.borderSubtle),
                                ),
                                child: Icon(
                                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                                  color: isSaved ? AppColors.primaryOrange : AppColors.textWhite,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _handleShare,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceCard,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.borderSubtle),
                                ),
                                child: const Icon(Icons.share, color: AppColors.textWhite, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 2. Hero Image with culinary badges
                  Stack(
                    children: [
                      SizedBox(
                        height: 220,
                        width: double.infinity,
                        child: Image.network(
                          recipe.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppColors.surfaceElevated,
                            child: const Icon(Icons.restaurant, color: AppColors.textMuted, size: 60),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                AppColors.background.withValues(alpha: 0.9),
                              ],
                              stops: const [0.6, 1.0],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        left: 16,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryOrange,
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.auto_awesome, color: Colors.black, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    recipe.sourceBadge.isNotEmpty ? recipe.sourceBadge : 'CookSmart AI',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(9999),
                                border: Border.all(color: AppColors.borderSubtle),
                              ),
                              child: Text(
                                recipe.difficulty.isNotEmpty ? recipe.difficulty : 'Easy',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.successGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: AppColors.successGreen, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                widget.appState.tr('readyToCook'),
                                style: const TextStyle(
                                  color: AppColors.successGreen,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 3. Title & Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.title,
                          style: const TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          recipe.subtitle,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // 4. Quick Metrics Grid
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _metricItem(Icons.schedule, recipe.cookTime, widget.appState.tr('cookTime')),
                              _metricDivider(),
                              _metricItem(Icons.local_fire_department, recipe.calories, widget.appState.tr('calories')),
                              _metricDivider(),
                              _metricItem(Icons.group_outlined, recipe.servings, widget.appState.tr('servings')),
                              _metricDivider(),
                              _metricItem(Icons.signal_cellular_alt, recipe.difficulty, widget.appState.tr('level')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 5. Ingredients Checklist
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.appState.tr('ingredientsTitle'),
                              style: const TextStyle(
                                color: AppColors.textWhite,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              widget.appState.isBangla
                                  ? '(${recipe.ingredients.length} টি উপকরণ)'
                                  : '(${recipe.ingredients.length} items)',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: recipe.ingredients.length,
                          itemBuilder: (context, index) {
                            final item = recipe.ingredients[index];
                            final isChecked = _checkedIngredients.contains(index);

                            return GestureDetector(
                              onTap: () => _toggleIngredient(index),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceCard,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isChecked
                                        ? AppColors.primaryOrange.withValues(alpha: 0.3)
                                        : AppColors.borderSubtle,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isChecked ? AppColors.primaryOrange : Colors.transparent,
                                        border: Border.all(
                                          color: isChecked
                                              ? AppColors.primaryOrange
                                              : AppColors.borderMedium,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: isChecked
                                          ? const Icon(Icons.check, size: 13, color: Colors.black)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        item,
                                        style: TextStyle(
                                          color: isChecked ? AppColors.textMuted : AppColors.textWhite,
                                          fontSize: 13,
                                          decoration: isChecked
                                              ? TextDecoration.lineThrough
                                              : TextDecoration.none,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 6. Step-by-Step Cooking Steps
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.appState.tr('cookingStepsTitle'),
                          style: const TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),

                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: recipe.steps.length,
                          itemBuilder: (context, index) {
                            final step = recipe.steps[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceCard,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.borderSubtle),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryOrange.withValues(alpha: 0.2),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${step.stepNumber}',
                                                style: const TextStyle(
                                                  color: AppColors.primaryOrange,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            step.title,
                                            style: const TextStyle(
                                              color: AppColors.textWhite,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceElevated,
                                          borderRadius: BorderRadius.circular(9999),
                                          border: Border.all(color: AppColors.borderSubtle),
                                        ),
                                        child: Text(
                                          step.timeBadge,
                                          style: const TextStyle(
                                            color: AppColors.primaryOrange,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    step.instruction,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 13,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  if (recipe.proTip.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.lightbulb_outline, color: AppColors.primaryOrange, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.appState.tr('chefsTipTitle'),
                                    style: const TextStyle(
                                      color: AppColors.primaryOrange,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    recipe.proTip,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // 7. Interactive Ask AI Chef Helper Card
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.surfaceCard,
                            AppColors.primaryOrange.withValues(alpha: 0.12),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.35)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryOrange.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.auto_awesome, color: AppColors.primaryOrange, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.appState.tr('needCookingHelp'),
                                      style: const TextStyle(
                                        color: AppColors.textWhite,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      widget.appState.tr('askAiChefHelp'),
                                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _askChip(widget.appState.tr('chipScale5')),
                              _askChip(widget.appState.tr('chipScale2')),
                              _askChip(widget.appState.tr('chipSwap')),
                              _askChip(widget.appState.tr('chipFaster')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 8. Fixed Bottom Actions Bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.95),
                  border: const Border(top: BorderSide(color: AppColors.borderSubtle)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: () {
                          widget.appState.openAskChefWithRecipe(recipe);
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primaryOrange),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.auto_awesome, color: AppColors.primaryOrange, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              widget.appState.tr('askAiChefBtn'),
                              style: const TextStyle(
                                color: AppColors.primaryOrange,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: ElevatedButton(
                        onPressed: () {
                          final wasSaved = recipe.isSaved;
                          if (!wasSaved) {
                            widget.appState.toggleSaveRecipe(recipe.id);
                            setState(() {});
                            final msg = widget.appState.isBangla
                                ? 'পছন্দের তালিকায় "${recipe.title}" সেভ করা হয়েছে'
                                : 'Saved "${recipe.title}" to My Recipes';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                backgroundColor: AppColors.surfaceElevated,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          } else {
                            Navigator.pop(context);
                            widget.appState.setTab(3); // Tab 3 is Saved
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                          elevation: 0,
                          shadowColor: AppColors.primaryOrange.withValues(alpha: 0.4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              recipe.isSaved ? Icons.bookmark_added : Icons.bookmark_add,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              recipe.isSaved
                                  ? widget.appState.tr('savedViewBtn')
                                  : widget.appState.tr('saveRecipeBtn'),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryOrange, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: AppColors.textWhite, fontSize: 12, fontWeight: FontWeight.w700),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSubtle, fontSize: 10),
        ),
      ],
    );
  }

  Widget _metricDivider() {
    return Container(
      width: 1,
      height: 28,
      color: AppColors.borderSubtle,
    );
  }

  Widget _askChip(String label) {
    return GestureDetector(
      onTap: () {
        widget.appState.openAskChefWithRecipe(widget.recipe);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primaryOrange,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward, color: AppColors.primaryOrange, size: 12),
          ],
        ),
      ),
    );
  }
}
