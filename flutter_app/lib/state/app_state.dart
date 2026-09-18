import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/recipe.dart';

class AppState extends ChangeNotifier {
  // Language support (en = English, bn = Bangla)
  String _language = 'en';
  String get language => _language;
  bool get isBangla => _language == 'bn';

  void setLanguage(String lang) {
    if (_language != lang) {
      _language = lang;
      notifyListeners();
    }
  }

  void toggleLanguage() {
    _language = _language == 'en' ? 'bn' : 'en';
    notifyListeners();
  }

  String tr(String key) => AppStrings.tr(key, lang: _language);

  // Navigation
  int _currentTabIndex = 0;
  int get currentTabIndex => _currentTabIndex;

  void setTab(int index) {
    if (_currentTabIndex != index) {
      _currentTabIndex = index;
      notifyListeners();
    }
  }

  // Search in Home & Saved
  String _homeSearchQuery = '';
  String get homeSearchQuery => _homeSearchQuery;

  void setHomeSearchQuery(String query) {
    _homeSearchQuery = query;
    notifyListeners();
  }

  // Active Category Filter in Home
  String _homeCategory = '🔥 Trending';
  String get homeCategory => _homeCategory;

  void setHomeCategory(String cat) {
    _homeCategory = cat;
    notifyListeners();
  }

  // Selected ingredients basket - starts completely EMPTY for fresh install
  final List<String> _selectedIngredients = [];
  List<String> get selectedIngredients => List.unmodifiable(_selectedIngredients);

  void addIngredient(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (!_selectedIngredients.any((item) => item.toLowerCase() == trimmed.toLowerCase())) {
      _selectedIngredients.add(trimmed);
      notifyListeners();
    }
  }

  void removeIngredient(String name) {
    _selectedIngredients.removeWhere((item) => item.toLowerCase() == name.toLowerCase());
    notifyListeners();
  }

  void clearIngredients() {
    _selectedIngredients.clear();
    notifyListeners();
  }

  // Dietary & cooking preferences - starts completely EMPTY for fresh install
  final Set<String> _selectedPreferences = {};
  Set<String> get selectedPreferences => Set.unmodifiable(_selectedPreferences);

  void togglePreference(String pref) {
    if (_selectedPreferences.contains(pref)) {
      _selectedPreferences.remove(pref);
    } else {
      _selectedPreferences.add(pref);
    }
    notifyListeners();
  }

  // Selected recipe for Ask Chef assistant
  Recipe? _selectedAskRecipe;
  Recipe? get selectedAskRecipe => _selectedAskRecipe;

  void setAskRecipe(Recipe? recipe) {
    _selectedAskRecipe = recipe;
    notifyListeners();
  }

  void openAskChefWithRecipe(Recipe recipe) {
    _selectedAskRecipe = recipe;
    _currentTabIndex = 2; // Jump straight to Ask Chef tab
    notifyListeners();
  }

  // Recipes list
  late final List<Recipe> _allRecipes;
  List<Recipe> get allRecipes => _allRecipes;

  // Saved recipes list - starts completely EMPTY because all initial recipes have isSaved = false
  List<Recipe> get savedRecipes => _allRecipes.where((r) => r.isSaved).toList();

  void addRecipe(Recipe recipe) {
    if (!_allRecipes.any((r) => r.id == recipe.id)) {
      _allRecipes.insert(0, recipe);
      notifyListeners();
    }
  }

  void addDiscoveredRecipes(List<Recipe> newRecipes) {
    for (final recipe in newRecipes.reversed) {
      if (!_allRecipes.any((r) => r.id == recipe.id || r.title.toLowerCase() == recipe.title.toLowerCase())) {
        _allRecipes.insert(0, recipe);
      }
    }
    notifyListeners();
  }

  void toggleSaveRecipe(String id) {
    final index = _allRecipes.indexWhere((r) => r.id == id);
    if (index != -1) {
      _allRecipes[index].isSaved = !_allRecipes[index].isSaved;
      notifyListeners();
    }
  }

  void saveRecipe(Recipe recipe) {
    final index = _allRecipes.indexWhere((r) => r.id == recipe.id);
    if (index != -1) {
      _allRecipes[index].isSaved = true;
    } else {
      recipe.isSaved = true;
      _allRecipes.insert(0, recipe);
    }
    notifyListeners();
  }

  AppState() {
    _initializeRecipes();
  }

  void _initializeRecipes() {
    // Fresh install: ALL initial recipes have isSaved: false!
    _allRecipes = [
      Recipe(
        id: 'garlic-chicken',
        title: 'Garlic Butter Chicken',
        subtitle: 'Tender chicken pieces cooked in garlic butter with sweet cherry tomatoes and soft spinach.',
        imageUrl: 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?auto=format&fit=crop&w=800&q=80',
        cookTime: '20 min',
        calories: '450 cal',
        servings: '2 People',
        difficulty: 'Easy',
        rating: 4.9,
        reviewsCount: 1420,
        sourceBadge: 'Chef Pick',
        tags: ['Quick (<20m)', 'High Protein', 'Healthy'],
        isSaved: false,
        proTip: 'Pat the chicken dry with a paper towel first so it gets nicely browned and crispy in the pan.',
        ingredients: [
          '2 chicken breasts, cut into bite-sized pieces',
          '4 garlic cloves, minced',
          '2 tablespoons olive oil',
          '1 cup cherry tomatoes, cut in half',
          '2 cups fresh baby spinach',
          'Half cup heavy cream or milk',
          '1 pinch salt, black pepper, and dried oregano',
        ],
        steps: [
          CookingStep(
            stepNumber: 1,
            title: 'Brown the Chicken',
            timeBadge: '5 min',
            instruction: 'Season chicken with salt and pepper. Heat oil in a pan on medium-high. Cook chicken for 5 minutes until golden brown. Move to a clean plate.',
          ),
          CookingStep(
            stepNumber: 2,
            title: 'Cook Garlic & Tomatoes',
            timeBadge: '3 min',
            instruction: 'In the same pan, add garlic and halved tomatoes. Cook for 2 to 3 minutes until fragrant and soft.',
          ),
          CookingStep(
            stepNumber: 3,
            title: 'Make the Sauce',
            timeBadge: '4 min',
            instruction: 'Turn heat to low. Pour in cream and stir gently. Add spinach leaves and stir until they soften into the sauce.',
          ),
          CookingStep(
            stepNumber: 4,
            title: 'Combine & Serve',
            timeBadge: 'Ready',
            instruction: 'Put the cooked chicken back into the warm pan. Spoon sauce over the top and serve hot!',
          ),
        ],
      ),
      Recipe(
        id: 'lemon-salmon',
        title: 'Lemon Butter Salmon',
        subtitle: 'Pan-fried salmon fillet topped with a fresh lemon garlic butter glaze.',
        imageUrl: 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?auto=format&fit=crop&w=800&q=80',
        cookTime: '15 min',
        calories: '420 cal',
        servings: '2 People',
        difficulty: 'Easy',
        rating: 4.9,
        reviewsCount: 1200,
        sourceBadge: 'TikTok Viral',
        tags: ['Quick (<20m)', 'Healthy', 'High Protein'],
        isSaved: false,
        proTip: 'Cook the salmon skin-side down first without moving it to get the skin super crispy.',
        ingredients: [
          '2 fresh salmon fillets',
          '3 cloves garlic, minced',
          '1 tablespoon butter & 1 tablespoon olive oil',
          '1 whole lemon (sliced and juiced)',
          'Fresh parsley, chopped',
          'Pinch of salt and black pepper',
        ],
        steps: [
          CookingStep(
            stepNumber: 1,
            title: 'Pan-fry Salmon',
            timeBadge: '8 min',
            instruction: 'Heat oil and butter in a pan. Cook salmon skin-side down for 5 minutes. Flip and cook for 3 minutes more.',
          ),
          CookingStep(
            stepNumber: 2,
            title: 'Add Lemon Glaze',
            timeBadge: '3 min',
            instruction: 'Add garlic and lemon juice around the salmon. Spoon melted butter over the top and garnish with parsley.',
          ),
        ],
      ),
      Recipe(
        id: 'honey-chicken',
        title: 'Crispy Honey Sesame Chicken',
        subtitle: 'Sweet and savory chicken bites glazed with honey, soy sauce, and toasted sesame seeds.',
        imageUrl: 'https://images.unsplash.com/photo-1527477378370-d9c02ff5a2fa?auto=format&fit=crop&w=800&q=80',
        cookTime: '18 min',
        calories: '510 cal',
        servings: '2 People',
        difficulty: 'Easy',
        rating: 4.8,
        reviewsCount: 890,
        sourceBadge: 'Tasty',
        tags: ['Quick (<20m)', 'High Protein'],
        isSaved: false,
        proTip: 'Toss the chicken with a tablespoon of cornstarch before frying for extra crispy edges.',
        ingredients: [
          '400g chicken thighs or breasts, diced',
          '2 tablespoons honey',
          '2 tablespoons soy sauce',
          '1 tablespoon sesame seeds',
          '2 cloves garlic, minced',
        ],
        steps: [
          CookingStep(
            stepNumber: 1,
            title: 'Fry Chicken',
            timeBadge: '6 min',
            instruction: 'Heat 1 spoon of oil in a pan. Stir-fry chicken on high heat for 6 minutes until crisp and cooked through.',
          ),
          CookingStep(
            stepNumber: 2,
            title: 'Glaze & Toss',
            timeBadge: '2 min',
            instruction: 'Turn down heat. Add honey, soy sauce, and garlic. Stir for 2 minutes until glossy, then sprinkle sesame seeds.',
          ),
        ],
      ),
      Recipe(
        id: 'creamy-mushroom-rice',
        title: 'Creamy Mushroom Rice',
        subtitle: 'Warm and comforting rice slowly cooked with buttery sliced mushrooms and cheese.',
        imageUrl: 'https://images.unsplash.com/photo-1633964913295-ceb43826e7c9?auto=format&fit=crop&w=800&q=80',
        cookTime: '25 min',
        calories: '390 cal',
        servings: '3 People',
        difficulty: 'Medium',
        rating: 4.9,
        reviewsCount: 650,
        sourceBadge: 'NYT Cooking',
        tags: ['Healthy', 'Vegetarian', 'Italian'],
        isSaved: false,
        proTip: 'Use warm vegetable broth instead of cold broth so the rice cooks evenly without slowing down.',
        ingredients: [
          '1 cup white rice or Arborio rice',
          '200g mushrooms, sliced',
          '3 cups warm vegetable broth',
          'Third cup grated parmesan or cheddar cheese',
          '2 tablespoons butter',
          'Salt and black pepper',
        ],
        steps: [
          CookingStep(
            stepNumber: 1,
            title: 'Brown Mushrooms',
            timeBadge: '5 min',
            instruction: 'Melt 1 spoon of butter in a pot. Cook sliced mushrooms for 5 minutes until browned and fragrant.',
          ),
          CookingStep(
            stepNumber: 2,
            title: 'Simmer Rice',
            timeBadge: '18 min',
            instruction: 'Add rice and pour in warm broth a little at a time. Stir often until rice is soft and creamy.',
          ),
          CookingStep(
            stepNumber: 3,
            title: 'Stir in Cheese',
            timeBadge: '2 min',
            instruction: 'Stir in cheese and remaining butter until melted. Serve hot!',
          ),
        ],
      ),
      Recipe(
        id: 'spicy-beef-basil',
        title: 'Quick Beef & Sweet Basil',
        subtitle: 'Savory ground beef stir-fried with garlic, soy sauce, and fresh green basil leaves.',
        imageUrl: 'https://images.unsplash.com/photo-1589302168068-964664d93dc0?auto=format&fit=crop&w=800&q=80',
        cookTime: '15 min',
        calories: '460 cal',
        servings: '2 People',
        difficulty: 'Easy',
        rating: 4.7,
        reviewsCount: 510,
        sourceBadge: 'Street Food',
        tags: ['Quick (<20m)', 'High Protein'],
        isSaved: false,
        proTip: 'Turn off the heat before stirring in the basil leaves so they stay bright green and fragrant.',
        ingredients: [
          '300g ground beef',
          '3 cloves garlic, crushed',
          '1 cup fresh basil leaves',
          '1 tablespoon soy sauce or oyster sauce',
          '1 teaspoon chili flakes (optional)',
        ],
        steps: [
          CookingStep(
            stepNumber: 1,
            title: 'Cook the Beef',
            timeBadge: '5 min',
            instruction: 'Heat a pan on high. Add garlic and ground beef. Break up the beef and cook 5 minutes until browned.',
          ),
          CookingStep(
            stepNumber: 2,
            title: 'Sauce & Basil',
            timeBadge: '2 min',
            instruction: 'Pour in soy sauce and chili flakes. Remove from heat, toss in fresh basil leaves, and serve with rice.',
          ),
        ],
      ),
      Recipe(
        id: 'chickpea-salad',
        title: 'Fresh Chickpea Salad',
        subtitle: 'Crisp cucumber, sweet tomatoes, and tender chickpeas tossed in olive oil and lemon juice.',
        imageUrl: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&w=800&q=80',
        cookTime: '10 min',
        calories: '310 cal',
        servings: '2 People',
        difficulty: 'Easy',
        rating: 4.8,
        reviewsCount: 780,
        sourceBadge: 'Healthy Bites',
        tags: ['Healthy', 'Vegetarian', 'Quick (<20m)'],
        isSaved: false,
        proTip: 'Rinse and drain the canned chickpeas thoroughly in cold water for the best fresh crunch.',
        ingredients: [
          '1 can chickpeas, rinsed and drained',
          '1 cucumber, diced',
          '1 cup cherry tomatoes, cut in half',
          '2 tablespoons olive oil',
          'Juice of half a lemon',
          'Salt and dried herbs',
        ],
        steps: [
          CookingStep(
            stepNumber: 1,
            title: 'Chop Veggies',
            timeBadge: '8 min',
            instruction: 'Chop the cucumber and slice tomatoes in half. Put them in a large salad bowl with the chickpeas.',
          ),
          CookingStep(
            stepNumber: 2,
            title: 'Dress & Toss',
            timeBadge: '2 min',
            instruction: 'Drizzle with olive oil, lemon juice, and a pinch of salt. Toss everything well and enjoy fresh!',
          ),
        ],
      ),
    ];
  }
}
