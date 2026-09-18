import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'recipe_detail_screen.dart';

class SavedScreen extends StatefulWidget {
  final AppState appState;

  const SavedScreen({super.key, required this.appState});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  String _selectedFilterKey = 'filterAll';
  String _sortKey = 'sortDefault';

  final List<String> _filterKeys = ['filterAll', 'filterQuick', 'filterProtein', 'filterHealthy'];
  final List<String> _sortKeys = ['sortDefault', 'sortRating', 'sortTime', 'sortAlpha'];

  List<Recipe> _getFilteredSavedList(List<Recipe> rawList) {
    var list = rawList.where((recipe) {
      if (_selectedFilterKey == 'filterAll') return true;
      if (_selectedFilterKey == 'filterQuick') {
        final mins = int.tryParse(recipe.cookTime.replaceAll(RegExp(r'[^0-9]'), '')) ?? 99;
        return recipe.tags.any((t) => t.toLowerCase().contains('quick')) || mins <= 30;
      }
      if (_selectedFilterKey == 'filterProtein') {
        return recipe.tags.any((t) => t.toLowerCase().contains('protein'));
      }
      if (_selectedFilterKey == 'filterHealthy') {
        return recipe.tags.any((t) =>
            t.toLowerCase().contains('healthy') ||
            t.toLowerCase().contains('veggie') ||
            t.toLowerCase().contains('vegetarian'));
      }
      return true;
    }).toList();

    if (_sortKey == 'sortRating') {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_sortKey == 'sortTime') {
      list.sort((a, b) {
        final aMins = int.tryParse(a.cookTime.replaceAll(RegExp(r'[^0-9]'), '')) ?? 99;
        final bMins = int.tryParse(b.cookTime.replaceAll(RegExp(r'[^0-9]'), '')) ?? 99;
        return aMins.compareTo(bMins);
      });
    } else if (_sortKey == 'sortAlpha') {
      list.sort((a, b) => a.title.compareTo(b.title));
    }

    return list;
  }

  void _showSortSheet(BuildContext context) {
    final appState = widget.appState;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.swap_vert, color: AppColors.primaryOrange, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          appState.tr('sortSheetTitle'),
                          style: const TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._sortKeys.map((key) {
                  final isSelected = _sortKey == key;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      appState.tr(key),
                      style: TextStyle(
                        color: isSelected ? AppColors.primaryOrange : AppColors.textWhite,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: AppColors.primaryOrange, size: 20)
                        : null,
                    onTap: () {
                      setState(() => _sortKey = key);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    final allSaved = appState.savedRecipes;
    final savedList = _getFilteredSavedList(allSaved);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24, left: 20, right: 20, top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Header Bar
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
                        Text(
                          appState.tr('savedRecipesTitle'),
                          style: const TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            appState.isBangla
                                ? '${allSaved.length} টি রেসিপি সেভ করা'
                                : '${allSaved.length} meals saved',
                            style: const TextStyle(
                              color: AppColors.primaryOrange,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showSortSheet(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: const Icon(Icons.swap_vert, color: AppColors.textWhite, size: 20),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 2. Category Filter Pills
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _filterKeys.map((fKey) {
                    final isActive = _selectedFilterKey == fKey;
                    final count = fKey == 'filterAll'
                        ? allSaved.length
                        : allSaved.where((r) {
                            if (fKey == 'filterQuick') {
                              final mins = int.tryParse(r.cookTime.replaceAll(RegExp(r'[^0-9]'), '')) ?? 99;
                              return r.tags.any((t) => t.toLowerCase().contains('quick')) || mins <= 30;
                            }
                            if (fKey == 'filterProtein') return r.tags.any((t) => t.toLowerCase().contains('protein'));
                            if (fKey == 'filterHealthy') {
                              return r.tags.any((t) =>
                                  t.toLowerCase().contains('healthy') ||
                                  t.toLowerCase().contains('veggie') ||
                                  t.toLowerCase().contains('vegetarian'));
                            }
                            return true;
                          }).length;

                    final label = '${appState.tr(fKey)} ($count)';

                    return GestureDetector(
                      onTap: () => setState(() => _selectedFilterKey = fKey),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.primaryOrange : AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(
                            color: isActive ? AppColors.primaryOrange : AppColors.borderSubtle,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            label,
                            style: TextStyle(
                              color: isActive ? Colors.white : AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),

              // 3. 2-Column Mobile Recipe Grid
              if (allSaved.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.bookmark_border, color: AppColors.textMuted, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        appState.tr('noSavedTitle'),
                        style: const TextStyle(color: AppColors.textWhite, fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        appState.tr('noSavedDesc'),
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => appState.setTab(0),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                        ),
                        child: Text(appState.tr('exploreRecipesBtn')),
                      ),
                    ],
                  ),
                )
              else if (savedList.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.filter_list_off, color: AppColors.textMuted, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        appState.isBangla
                            ? 'এই ফিল্টারে কোনো সংরক্ষিত রেসিপি নেই'
                            : 'No saved recipes in this filter',
                        style: const TextStyle(color: AppColors.textWhite, fontSize: 15, fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        appState.isBangla
                            ? 'অন্য কোনো ক্যাটাগরি বেছে নিন অথবা সব রেসিপি দেখুন।'
                            : 'Try picking a different category filter or browse all saved.',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        onPressed: () => setState(() => _selectedFilterKey = 'filterAll'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                        ),
                        child: Text(appState.tr('filterAll')),
                      ),
                    ],
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.76,
                  ),
                  itemCount: savedList.length,
                  itemBuilder: (context, index) {
                    final recipe = savedList[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RecipeDetailScreen(
                              recipe: recipe,
                              appState: appState,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Card Thumbnail Image with Bookmark
                            Stack(
                              children: [
                                SizedBox(
                                  height: 110,
                                  width: double.infinity,
                                  child: Image.network(
                                    recipe.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: AppColors.surfaceElevated,
                                      child: const Icon(Icons.restaurant, color: AppColors.textMuted),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () => appState.toggleSaveRecipe(recipe.id),
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: AppColors.borderSubtle),
                                      ),
                                      child: const Icon(Icons.bookmark, color: AppColors.primaryOrange, size: 16),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(9999),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.star, color: AppColors.primaryOrange, size: 11),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${recipe.rating}',
                                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Recipe Info
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    recipe.getTitle(appState.isBangla),
                                    style: const TextStyle(
                                      color: AppColors.textWhite,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.schedule, color: AppColors.textMuted, size: 12),
                                      const SizedBox(width: 3),
                                      Text(
                                        recipe.cookTime,
                                        style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text('•', style: TextStyle(color: AppColors.textSubtle, fontSize: 10)),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          recipe.calories,
                                          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 24),

              // 4. Discovery Inspiration Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.surfaceElevated, AppColors.surfaceCard],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: AppColors.primaryOrange, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          appState.tr('smartAssistant'),
                          style: const TextStyle(
                            color: AppColors.primaryOrange,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      appState.tr('wantNewInspiration'),
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      appState.tr('tellFridgeIngredients'),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => appState.setTab(1),
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(
                        appState.tr('addIngredients'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
