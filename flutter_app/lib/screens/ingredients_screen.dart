import 'package:flutter/material.dart';
import '../services/gemini_recipe_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'recipe_detail_screen.dart';

class IngredientsScreen extends StatefulWidget {
  final AppState appState;

  const IngredientsScreen({super.key, required this.appState});

  @override
  State<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends State<IngredientsScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  List<Map<String, String>> _getStaples(AppState appState) {
    if (appState.isBangla) {
      return [
        {'name': 'রসুন', 'icon': '🧄'},
        {'name': 'তেল', 'icon': '🫒'},
        {'name': 'পেঁয়াজ', 'icon': '🧅'},
        {'name': 'মাখন', 'icon': '🧈'},
        {'name': 'ডিম', 'icon': '🥚'},
        {'name': 'মুরগির মাংস', 'icon': '🍗'},
        {'name': 'ভাত/চাল', 'icon': '🍚'},
        {'name': 'পনির', 'icon': '🧀'},
        {'name': 'লেবু', 'icon': '🍋'},
        {'name': 'টমেটো', 'icon': '🍅'},
      ];
    }
    return [
      {'name': 'Garlic', 'icon': '🧄'},
      {'name': 'Olive oil', 'icon': '🫒'},
      {'name': 'Onion', 'icon': '🧅'},
      {'name': 'Butter', 'icon': '🧈'},
      {'name': 'Eggs', 'icon': '🥚'},
      {'name': 'Chicken', 'icon': '🍗'},
      {'name': 'Rice', 'icon': '🍚'},
      {'name': 'Cheese', 'icon': '🧀'},
      {'name': 'Lemon', 'icon': '🍋'},
      {'name': 'Tomatoes', 'icon': '🍅'},
    ];
  }

  List<String> _getPreferences(AppState appState) => [
    appState.tr('prefFast'),
    appState.tr('prefHealthy'),
    appState.tr('prefProtein'),
    appState.tr('prefNoMeat'),
    appState.tr('prefGlutenFree'),
  ];

  void _handleAdd() {
    if (_controller.text.trim().isNotEmpty) {
      widget.appState.addIngredient(_controller.text.trim());
      _controller.clear();
      setState(() {});
    }
  }

  void _handleClearAll() {
    final appState = widget.appState;
    if (appState.selectedIngredients.isEmpty) return;

    final backup = List<String>.from(appState.selectedIngredients);
    appState.clearIngredients();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(appState.tr('basketCleared')),
        backgroundColor: AppColors.surfaceElevated,
        action: SnackBarAction(
          label: appState.tr('undo'),
          textColor: AppColors.primaryOrange,
          onPressed: () {
            for (final item in backup) {
              appState.addIngredient(item);
            }
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleGenerate() async {
    if (_isLoading) return;

    final appState = widget.appState;
    if (appState.selectedIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appState.tr('emptyBasketWarning')),
          backgroundColor: AppColors.surfaceElevated,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final generatedRecipe = await GeminiRecipeService.generateRecipe(
        ingredients: appState.selectedIngredients,
        dietaryPreferences: appState.selectedPreferences.toList(),
        language: appState.language,
      );

      if (!mounted) return;

      // Add to session recipes list
      appState.addRecipe(generatedRecipe);

      setState(() {
        _isLoading = false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeDetailScreen(
            recipe: generatedRecipe,
            appState: appState,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Generation failed: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    final selectedCount = appState.selectedIngredients.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100, left: 20, right: 20, top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => appState.setTab(0),
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
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.auto_awesome, color: AppColors.primaryOrange, size: 16),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    appState.tr('smartPantryTitle'),
                                    style: const TextStyle(
                                      color: AppColors.textWhite,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              appState.tr('poweredByGemini'),
                              style: const TextStyle(
                                color: AppColors.primaryOrange,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: selectedCount > 0 ? _handleClearAll : null,
                        child: Text(
                          appState.tr('clearAll'),
                          style: TextStyle(
                            color: selectedCount > 0 ? AppColors.primaryOrange : AppColors.textSubtle,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 2. Search & Add Bar
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            children: [
                              const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: appState.tr('addIngredientHint'),
                                    hintStyle: const TextStyle(color: AppColors.textSubtle, fontSize: 12),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                  onSubmitted: (_) => _handleAdd(),
                                ),
                              ),
                              if (_controller.text.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    _controller.clear();
                                    setState(() {});
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 4),
                                    child: Icon(Icons.clear, color: AppColors.textMuted, size: 18),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _handleAdd,
                        child: Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryOrange.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              appState.tr('addBtn'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 3. Selected Ingredients Basket
                  Row(
                    children: [
                      const Icon(Icons.shopping_basket_outlined, color: AppColors.primaryOrange, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        appState.tr('yourBasket'),
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          appState.isBangla
                              ? '$selectedCount টি উপকরণ'
                              : '$selectedCount item${selectedCount == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: AppColors.primaryOrange,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (selectedCount == 0)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.kitchen, color: AppColors.textMuted, size: 36),
                          const SizedBox(height: 8),
                          Text(
                            appState.tr('basketEmptyTitle'),
                            style: const TextStyle(color: AppColors.textWhite, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            appState.tr('basketEmptyDesc'),
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: appState.selectedIngredients.map((item) {
                        return Container(
                          padding: const EdgeInsets.only(left: 12, right: 6, top: 6, bottom: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryOrange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item,
                                style: const TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => appState.removeIngredient(item),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(Icons.close, size: 14, color: AppColors.textMuted),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 28),

                  // 4. Quick-Add Essentials
                  Text(
                    appState.tr('quickAddTitle'),
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    appState.tr('quickAddSubtitle'),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _getStaples(appState).map((staple) {
                      final name = staple['name']!;
                      final icon = staple['icon']!;
                      final isAlreadyAdded = appState.selectedIngredients
                          .any((i) => i.toLowerCase() == name.toLowerCase());

                      return GestureDetector(
                        onTap: () {
                          if (isAlreadyAdded) {
                            appState.removeIngredient(name);
                          } else {
                            appState.addIngredient(name);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isAlreadyAdded
                                ? AppColors.primaryOrange.withValues(alpha: 0.15)
                                : AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(
                              color: isAlreadyAdded
                                  ? AppColors.primaryOrange
                                  : AppColors.borderSubtle,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(icon, style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
                              Text(
                                name,
                                style: TextStyle(
                                  color: isAlreadyAdded ? AppColors.primaryOrange : AppColors.textWhite,
                                  fontSize: 12,
                                  fontWeight: isAlreadyAdded ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                isAlreadyAdded ? Icons.check : Icons.add,
                                size: 14,
                                color: isAlreadyAdded ? AppColors.primaryOrange : AppColors.textMuted,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 28),

                  // 5. Cooking Preferences & Time Filters
                  Text(
                    appState.tr('prefTitle'),
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _getPreferences(appState).map((pref) {
                      final isSelected = appState.selectedPreferences.contains(pref);
                      return GestureDetector(
                        onTap: () => appState.togglePreference(pref),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryOrange.withValues(alpha: 0.15)
                                : AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryOrange : AppColors.borderSubtle,
                            ),
                          ),
                          child: Text(
                            pref,
                            style: TextStyle(
                              color: isSelected ? AppColors.primaryOrange : AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // 6. Gemini AI Culinary Badge Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.surfaceElevated,
                          AppColors.primaryOrange.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.4)),
                          ),
                          child: const Icon(Icons.auto_awesome, color: AppColors.primaryOrange, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appState.tr('pantryEngine'),
                                style: const TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                appState.tr('pantryEngineDesc'),
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 7. Sticky Primary CTA Button with Loading State
            Positioned(
              bottom: 16,
              left: 20,
              right: 20,
              child: GestureDetector(
                onTap: _isLoading ? null : _handleGenerate,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryOrange, AppColors.primaryOrangeHover],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryOrange.withValues(alpha: 0.4),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isLoading) ...[
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          appState.tr('creatingRecipeBtn'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ] else ...[
                        const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            appState.tr('makeRecipeBtn'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            '$selectedCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
