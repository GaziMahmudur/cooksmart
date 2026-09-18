import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/recipe.dart';
import '../services/gemini_recipe_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'recipe_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final AppState appState;

  const HomeScreen({super.key, required this.appState});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextEditingController _searchController;
  bool _isRefreshing = false;
  bool _isSearchingAI = false;

  final List<String> _categories = [
    '🔥 All',
    '⚡ Fast (<20m)',
    '🥗 Healthy',
    '🍝 Pasta',
    '🥩 Meat',
    '🌱 Veggie',
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.appState.homeSearchQuery);
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.appState.homeSearchQuery != _searchController.text) {
      _searchController.text = widget.appState.homeSearchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleAiRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    try {
      final newRecipes = await GeminiRecipeService.discoverOnlineRecipes(
        language: widget.appState.language,
      );
      if (!mounted) return;
      widget.appState.addDiscoveredRecipes(newRecipes);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.appState.isBangla
                ? '✨ ${newRecipes.length}টি নতুন ট্রেন্ডিং রেসিপি যুক্ত হয়েছে!'
                : '✨ Found ${newRecipes.length} fresh trending dishes!',
          ),
          backgroundColor: AppColors.surfaceElevated,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.appState.isBangla
                ? 'রেসিপি রিফ্রেশ করা যায়নি। ইন্টারনেট সংযোগ চেক করুন।'
                : 'Could not refresh web recipes. Check connection.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _handleAiSearch(String query) async {
    if (_isSearchingAI || query.trim().isEmpty) return;
    setState(() => _isSearchingAI = true);

    try {
      final recipe = await GeminiRecipeService.searchOrGenerateRecipe(
        query,
        language: widget.appState.language,
      );
      if (!mounted) return;
      widget.appState.addRecipe(recipe);
      setState(() => _isSearchingAI = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeDetailScreen(
            recipe: recipe,
            appState: widget.appState,
          ),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _isSearchingAI = false);
    }
  }

  List<Recipe> _getFilteredRecipes() {
    final query = widget.appState.homeSearchQuery.trim().toLowerCase();
    final category = widget.appState.homeCategory;

    return widget.appState.allRecipes.where((recipe) {
      final matchesSearch = query.isEmpty ||
          recipe.title.toLowerCase().contains(query) ||
          (recipe.titleBn?.toLowerCase().contains(query) ?? false) ||
          recipe.subtitle.toLowerCase().contains(query) ||
          (recipe.subtitleBn?.toLowerCase().contains(query) ?? false) ||
          recipe.tags.any((t) => t.toLowerCase().contains(query)) ||
          recipe.ingredients.any((i) => i.toLowerCase().contains(query)) ||
          (recipe.ingredientsBn?.any((i) => i.toLowerCase().contains(query)) ?? false);

      bool matchesCategory = true;
      if (category == '🔥 All' || category == '🔥 Trending') {
        matchesCategory = true;
      } else if (category == '⚡ Fast (<20m)') {
        final minutes = int.tryParse(recipe.cookTime.replaceAll(RegExp(r'[^0-9]'), '')) ?? 99;
        matchesCategory = recipe.tags.any((t) => t.toLowerCase().contains('quick')) || minutes <= 20;
      } else if (category == '🥗 Healthy') {
        matchesCategory = recipe.tags.any((t) =>
            t.toLowerCase().contains('healthy') || t.toLowerCase().contains('vegetarian'));
      } else if (category == '🍝 Pasta') {
        matchesCategory = recipe.tags.any((t) =>
            t.toLowerCase().contains('pasta') || t.toLowerCase().contains('italian'));
      } else if (category == '🥩 Meat') {
        matchesCategory = recipe.tags.any((t) =>
            t.toLowerCase().contains('protein') ||
            recipe.title.toLowerCase().contains('chicken') ||
            recipe.title.toLowerCase().contains('beef'));
      } else if (category == '🌱 Veggie') {
        matchesCategory = recipe.tags.any((t) => t.toLowerCase().contains('vegetarian')) ||
            recipe.title.toLowerCase().contains('salad') ||
            recipe.title.toLowerCase().contains('chickpea');
      }

      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _showNotificationsSheet(BuildContext context) {
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
                      children: const [
                        Icon(Icons.notifications_active, color: AppColors.primaryOrange, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Notifications',
                          style: TextStyle(
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
                const SizedBox(height: 16),
                _notificationTile(
                  icon: Icons.public,
                  title: widget.appState.tr('webShowcaseTitle'),
                  subtitle: widget.appState.tr('webShowcaseDesc'),
                  time: 'Website',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showWebsiteLinkDialog(context);
                  },
                ),
                const SizedBox(height: 12),
                _notificationTile(
                  icon: Icons.auto_awesome,
                  title: 'Gemini AI Recipe Assistant Ready',
                  subtitle: 'Add ingredients from your pantry to generate personalized recipes.',
                  time: 'Just now',
                ),
                const SizedBox(height: 12),
                _notificationTile(
                  icon: Icons.star,
                  title: 'Chef Pick of the Week',
                  subtitle: 'Tuscan Garlic Butter Salmon has been added to your favorites.',
                  time: 'Today',
                ),
                const SizedBox(height: 12),
                _notificationTile(
                  icon: Icons.kitchen,
                  title: 'Pantry Ready',
                  subtitle: '4 fresh ingredients currently tracked in your basket.',
                  time: '1h ago',
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _notificationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primaryOrange, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        time,
                        style: const TextStyle(color: AppColors.textSubtle, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.3),
                  ),
                ],
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              const Icon(Icons.open_in_new, color: AppColors.primaryOrange, size: 16),
            ],
          ],
        ),
      ),
    );
  }

  void _showWebsiteLinkDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.public, color: AppColors.primaryOrange, size: 22),
            SizedBox(width: 8),
            Text(
              'CookSmart Website',
              style: TextStyle(color: AppColors.textWhite, fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Visit our official showcase website to watch video walkthroughs, explore feature deep dives, and download the latest Android APK release.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: const [
                  Icon(Icons.link, color: AppColors.primaryOrange, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'https://site-five-kohl-ioqd6kzeb3.vercel.app',
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Clipboard.setData(
                const ClipboardData(text: 'https://site-five-kohl-ioqd6kzeb3.vercel.app'),
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Website link copied to clipboard! (https://site-five-kohl-ioqd6kzeb3.vercel.app)'),
                  backgroundColor: AppColors.surfaceElevated,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
            ),
            child: const Text('Visit Site', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
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
                      children: const [
                        Icon(Icons.tune, color: AppColors.primaryOrange, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Filter & Discover',
                          style: TextStyle(
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
                const Text(
                  'Select Category',
                  style: TextStyle(color: AppColors.textWhite, fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((cat) {
                    final isSelected = widget.appState.homeCategory == cat;
                    return GestureDetector(
                      onTap: () {
                        widget.appState.setHomeCategory(cat);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryOrange : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(
                            color: isSelected ? AppColors.primaryOrange : AppColors.borderSubtle,
                          ),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _searchController.clear();
                          widget.appState.setHomeSearchQuery('');
                          widget.appState.setHomeCategory('🔥 All');
                          Navigator.pop(ctx);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.borderMedium),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                        ),
                        child: const Text('Reset All', style: TextStyle(color: AppColors.textWhite)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                        ),
                        child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
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
    final isFiltering = appState.homeSearchQuery.isNotEmpty ||
        (appState.homeCategory != '🔥 All' && appState.homeCategory != '🔥 Trending');
    final filteredRecipes = _getFilteredRecipes();

    final featuredRecipe = appState.allRecipes.firstWhere(
      (r) => r.id == 'garlic-chicken',
      orElse: () => appState.allRecipes.first,
    );

    final popularRecipes =
        appState.allRecipes.where((r) => r.id != featuredRecipe.id).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryOrange,
          backgroundColor: AppColors.surfaceElevated,
          onRefresh: () async {
            await appState.refreshHomeFeed();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(appState.tr('refreshedSuccess')),
                  backgroundColor: AppColors.surfaceElevated,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.4)),
                        ),
                        child: const Center(
                          child: Icon(Icons.local_fire_department, color: AppColors.primaryOrange, size: 24),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appState.tr('greeting'),
                              style: const TextStyle(
                                color: AppColors.textWhite,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              appState.tr('homeSubtitle'),
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Compact Language Dropdown Menu
                      PopupMenuButton<String>(
                        tooltip: 'Language / ভাষা',
                        color: AppColors.surfaceElevated,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: AppColors.borderSubtle),
                        ),
                        offset: const Offset(0, 42),
                        onSelected: (lang) => appState.setLanguage(lang),
                        itemBuilder: (ctx) => [
                          PopupMenuItem(
                            value: 'en',
                            child: Row(
                              children: [
                                const Text('🇺🇸', style: TextStyle(fontSize: 15)),
                                const SizedBox(width: 8),
                                Text(
                                  'English',
                                  style: TextStyle(
                                    color: !appState.isBangla ? AppColors.primaryOrange : AppColors.textWhite,
                                    fontWeight: !appState.isBangla ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                                if (!appState.isBangla) ...[
                                  const Spacer(),
                                  const Icon(Icons.check, color: AppColors.primaryOrange, size: 16),
                                ],
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'bn',
                            child: Row(
                              children: [
                                const Text('🇧🇩', style: TextStyle(fontSize: 15)),
                                const SizedBox(width: 8),
                                Text(
                                  'বাংলা',
                                  style: TextStyle(
                                    color: appState.isBangla ? AppColors.primaryOrange : AppColors.textWhite,
                                    fontWeight: appState.isBangla ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                                if (appState.isBangla) ...[
                                  const Spacer(),
                                  const Icon(Icons.check, color: AppColors.primaryOrange, size: 16),
                                ],
                              ],
                            ),
                          ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(
                              color: appState.isBangla ? AppColors.primaryOrange : AppColors.borderSubtle,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.language, color: AppColors.primaryOrange, size: 15),
                              const SizedBox(width: 4),
                              Text(
                                appState.language.toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(Icons.arrow_drop_down, color: AppColors.textMuted, size: 16),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showNotificationsSheet(context),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: const Icon(Icons.notifications_none, color: AppColors.textWhite, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),

              // 2. Interactive Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: appState.tr('searchHint'),
                            hintStyle: const TextStyle(color: AppColors.textSubtle, fontSize: 13),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onChanged: (val) {
                            appState.setHomeSearchQuery(val);
                            setState(() {});
                          },
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            appState.setHomeSearchQuery('');
                            setState(() {});
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(Icons.clear, color: AppColors.textMuted, size: 18),
                          ),
                        ),
                      GestureDetector(
                        onTap: () => _showFilterSheet(context),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: const Icon(Icons.tune, color: AppColors.primaryOrange, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // AI Search Generator Suggestion
              if (_searchController.text.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryOrange,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appState.tr('aiSearchCardTitle'),
                                style: const TextStyle(
                                  color: AppColors.primaryOrange,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${appState.tr("aiSearchCardSubtitle")} "${_searchController.text.trim()}"',
                                style: const TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        ElevatedButton(
                          onPressed: _isSearchingAI
                              ? null
                              : () => _handleAiSearch(_searchController.text.trim()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                            elevation: 0,
                          ),
                          child: _isSearchingAI
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  appState.tr('aiSearchCardBtn'),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // 3. Category Filter Chips
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isActive = appState.homeCategory == cat;
                    return GestureDetector(
                      onTap: () {
                        appState.setHomeCategory(cat);
                        setState(() {});
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.primaryOrange : AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(
                            color: isActive ? AppColors.primaryOrange : AppColors.borderSubtle,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: isActive ? Colors.white : AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // If filtering or searching, show filtered results
              if (isFiltering) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Results (${filteredRecipes.length})',
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          appState.setHomeSearchQuery('');
                          appState.setHomeCategory('🔥 All');
                          setState(() {});
                        },
                        child: const Text(
                          'Show All',
                          style: TextStyle(
                            color: AppColors.primaryOrange,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                if (filteredRecipes.isEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.search_off, color: AppColors.textMuted, size: 48),
                          const SizedBox(height: 12),
                          const Text(
                            'No recipes found locally',
                            style: TextStyle(color: AppColors.textWhite, fontSize: 16, fontWeight: FontWeight.w700),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            appState.homeSearchQuery.isNotEmpty
                                ? 'Want Gemini AI to invent a recipe for "${appState.homeSearchQuery}"?'
                                : 'No dishes found in category "${appState.homeCategory}".',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          if (appState.homeSearchQuery.isNotEmpty)
                            ElevatedButton.icon(
                              onPressed: _isSearchingAI
                                  ? null
                                  : () => _handleAiSearch(appState.homeSearchQuery),
                              icon: const Icon(Icons.auto_awesome, size: 16),
                              label: _isSearchingAI
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Generate with Gemini AI'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryOrange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                              ),
                            )
                          else
                            ElevatedButton(
                              onPressed: () {
                                _searchController.clear();
                                appState.setHomeSearchQuery('');
                                appState.setHomeCategory('🔥 All');
                                setState(() {});
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryOrange,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                              ),
                              child: const Text('Show All Recipes'),
                            ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filteredRecipes.length,
                    itemBuilder: (context, index) {
                      final recipe = filteredRecipes[index];
                      return _recipeListCard(context, recipe, appState);
                    },
                  ),
              ] else ...[
                // 4. Featured Hero Recipe Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Flexible(
                            child: Text(
                              'Featured Recipe',
                              style: TextStyle(
                                color: AppColors.textWhite,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            'Chef Pick',
                            style: TextStyle(
                              color: AppColors.primaryOrange,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RecipeDetailScreen(
                                recipe: featuredRecipe,
                                appState: appState,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: AppColors.borderSubtle),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black45,
                                blurRadius: 15,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  SizedBox(
                                    height: 200,
                                    width: double.infinity,
                                    child: Image.network(
                                      featuredRecipe.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: AppColors.surfaceElevated,
                                        child: const Icon(Icons.restaurant, color: AppColors.textMuted, size: 50),
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
                                            Colors.black.withValues(alpha: 0.8),
                                          ],
                                          stops: const [0.5, 1.0],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 12,
                                    left: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.65),
                                        borderRadius: BorderRadius.circular(9999),
                                        border: Border.all(color: AppColors.borderSubtle),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.star, color: AppColors.primaryOrange, size: 14),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${featuredRecipe.rating} (${featuredRecipe.reviewsCount})',
                                            style: const TextStyle(
                                              color: AppColors.textWhite,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: GestureDetector(
                                      onTap: () => appState.toggleSaveRecipe(featuredRecipe.id),
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.65),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: AppColors.borderSubtle),
                                        ),
                                        child: Icon(
                                          featuredRecipe.isSaved ? Icons.bookmark : Icons.bookmark_border,
                                          color: featuredRecipe.isSaved ? AppColors.primaryOrange : AppColors.textWhite,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      featuredRecipe.getTitle(appState.isBangla),
                                      style: const TextStyle(
                                        color: AppColors.textWhite,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      featuredRecipe.getSubtitle(appState.isBangla),
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              const Icon(Icons.schedule, color: AppColors.textMuted, size: 14),
                                              const SizedBox(width: 4),
                                              Text(
                                                featuredRecipe.cookTime,
                                                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                              ),
                                              const SizedBox(width: 10),
                                              const Icon(Icons.local_fire_department, color: AppColors.primaryOrange, size: 14),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  featuredRecipe.calories,
                                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryOrange,
                                            borderRadius: BorderRadius.circular(9999),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.primaryOrange.withValues(alpha: 0.35),
                                                blurRadius: 10,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                appState.isBangla ? 'রান্না শুরু করুন' : 'Cook Now',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(Icons.arrow_forward, color: Colors.white, size: 14),
                                            ],
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
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const SizedBox(height: 24),

                // 5. "What's in your fridge?" Pantry Banner
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.surfaceElevated, AppColors.surfaceCard],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.kitchen, color: AppColors.primaryOrange, size: 24),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appState.tr('pantryBannerTitle'),
                                style: const TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                appState.tr('pantryBannerSubtitle'),
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        ElevatedButton(
                          onPressed: () => appState.setTab(1),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                            elevation: 0,
                          ),
                          child: Text(
                            appState.tr('pantryBannerBtn'),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 6. Ask AI Chef Banner
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.auto_awesome, color: Colors.amber, size: 24),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appState.tr('askChefBannerTitle'),
                                style: const TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                appState.tr('askChefBannerSubtitle'),
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        OutlinedButton(
                          onPressed: () => appState.setTab(2),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primaryOrange),
                            foregroundColor: AppColors.primaryOrange,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                          ),
                          child: Text(
                            appState.tr('askChefBannerBtn'),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // 7. Trending from the Web (AI Recipe Feed + Refresh)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appState.tr('trendingTitle'),
                              style: const TextStyle(
                                color: AppColors.textWhite,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              appState.tr('trendingSubtitle'),
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _isRefreshing ? null : _handleAiRefresh,
                        icon: _isRefreshing
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.refresh, size: 14),
                        label: Text(
                          _isRefreshing ? appState.tr('findingBtn') : appState.tr('discoverBtn'),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surfaceElevated,
                          foregroundColor: AppColors.primaryOrange,
                          side: const BorderSide(color: AppColors.primaryOrange),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                SizedBox(
                  height: 235,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: popularRecipes.length,
                    itemBuilder: (context, index) {
                      final recipe = popularRecipes[index];
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
                          width: 185,
                          margin: const EdgeInsets.only(right: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  SizedBox(
                                    height: 115,
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
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.7),
                                        borderRadius: BorderRadius.circular(9999),
                                        border: Border.all(color: AppColors.borderSubtle),
                                      ),
                                      child: Text(
                                        recipe.sourceBadge,
                                        style: const TextStyle(
                                          color: AppColors.primaryOrange,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                        ),
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
                                          color: Colors.black.withValues(alpha: 0.65),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          recipe.isSaved ? Icons.bookmark : Icons.bookmark_border,
                                          color: recipe.isSaved ? AppColors.primaryOrange : Colors.white,
                                          size: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                                  Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      recipe.getTitle(appState.isBangla),
                                      style: const TextStyle(
                                        color: AppColors.textWhite,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      recipe.getSubtitle(appState.isBangla),
                                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.schedule, color: AppColors.textMuted, size: 12),
                                            const SizedBox(width: 3),
                                            Text(
                                              recipe.cookTime,
                                              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            const Icon(Icons.star, color: Colors.amber, size: 12),
                                            const SizedBox(width: 3),
                                            Text(
                                              '${recipe.rating}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
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
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}


  Widget _recipeListCard(BuildContext context, Recipe recipe, AppState appState) {
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
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: Image.network(
                recipe.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.surfaceElevated,
                  child: const Icon(Icons.restaurant, color: AppColors.textMuted),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            recipe.getTitle(appState.isBangla),
                            style: const TextStyle(
                              color: AppColors.textWhite,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => appState.toggleSaveRecipe(recipe.id),
                          child: Icon(
                            recipe.isSaved ? Icons.bookmark : Icons.bookmark_border,
                            color: recipe.isSaved ? AppColors.primaryOrange : AppColors.textMuted,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recipe.getSubtitle(appState.isBangla),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.schedule, color: AppColors.textMuted, size: 12),
                        const SizedBox(width: 4),
                        Text(recipe.cookTime, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        const SizedBox(width: 8),
                        const Icon(Icons.star, color: AppColors.primaryOrange, size: 12),
                        const SizedBox(width: 2),
                        Text('${recipe.rating}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                      ],
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
}
