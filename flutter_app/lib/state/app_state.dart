import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/recipe.dart';
import '../services/gemini_recipe_service.dart';

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

  bool _isRefreshingFeed = false;
  bool get isRefreshingFeed => _isRefreshingFeed;

  Future<void> refreshHomeFeed() async {
    if (_isRefreshingFeed) return;
    _isRefreshingFeed = true;
    notifyListeners();
    try {
      final newRecipes = await GeminiRecipeService.discoverOnlineRecipes(
        language: _language,
      );
      if (newRecipes.isNotEmpty) {
        addDiscoveredRecipes(newRecipes);
      }
    } catch (_) {}
    _isRefreshingFeed = false;
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
        titleBn: 'রসুন মাখন চিকেন',
        subtitle: 'Tender chicken pieces cooked in garlic butter with sweet cherry tomatoes and soft spinach.',
        subtitleBn: 'রসুন মাখনে রান্না করা নরম মুরগির টুকরো, চেরি টমেটো ও পালং শাক।',
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
        proTipBn: 'প্যানে দেওয়ার আগে টিস্যু দিয়ে চিকেনের টুকরো শুকিয়ে নিলে বাইরের অংশটা চমৎকার মচমচে ও বাদামি হয়।',
        ingredients: [
          '2 chicken breasts, cut into bite-sized pieces',
          '4 garlic cloves, minced',
          '2 tablespoons olive oil',
          '1 cup cherry tomatoes, cut in half',
          '2 cups fresh baby spinach',
          'Half cup heavy cream or milk',
          '1 pinch salt, black pepper, and dried oregano',
        ],
        ingredientsBn: [
          '২টি মুরগির বুকের মাংস, ছোট টুকরো করা',
          '৪ কোয়া রসুন, কুচানো',
          '২ টেবিল চামচ অলিভ অয়েল',
          '১ কাপ চেরি টমেটো, অর্ধেক করে কাটা',
          '২ কাপ তাজা কচি পালং শাক',
          'আধ কাপ হেভি ক্রিম বা দুধ',
          '১ চিমটি লবণ, গোলমরিচ গুঁড়া এবং ওরেগানো',
        ],
        steps: [
          CookingStep(
            stepNumber: 1,
            title: 'Brown the Chicken',
            titleBn: 'চিকেন ভেজে নিন',
            timeBadge: '5 min',
            instruction: 'Season chicken with salt and pepper. Heat oil in a pan on medium-high. Cook chicken for 5 minutes until golden brown. Move to a clean plate.',
            instructionBn: 'লবণ ও গোলমরিচ দিয়ে মাংস মেখে নিন। মাঝারি আঁচে প্যানে তেল গরম করে ৫ মিনিট মাংস বাদামি করে ভেজে প্লেটে তুলে রাখুন।',
          ),
          CookingStep(
            stepNumber: 2,
            title: 'Cook Garlic & Tomatoes',
            titleBn: 'রসুন ও টমেটো ভাজুন',
            timeBadge: '3 min',
            instruction: 'In the same pan, add garlic and halved tomatoes. Cook for 2 to 3 minutes until fragrant and soft.',
            instructionBn: 'একই প্যানে কুচানো রসুন ও কাটা টমেটো দিন। সুবাস বের হওয়া এবং নরম হওয়া পর্যন্ত ২-৩ মিনিট নাড়ুন।',
          ),
          CookingStep(
            stepNumber: 3,
            title: 'Make the Sauce',
            titleBn: 'সস তৈরি করুন',
            timeBadge: '4 min',
            instruction: 'Turn heat to low. Pour in cream and stir gently. Add spinach leaves and stir until they soften into the sauce.',
            instructionBn: 'আঁচ কমিয়ে ক্রিম ঢেলে ধীরে ধীরে নাড়ুন। পালং শাক দিন এবং সসের সাথে নরম হওয়া পর্যন্ত মেশান।',
          ),
          CookingStep(
            stepNumber: 4,
            title: 'Combine & Serve',
            titleBn: 'একসাথে মিশিয়ে পরিবেশন করুন',
            timeBadge: 'Ready',
            instruction: 'Put the cooked chicken back into the warm pan. Spoon sauce over the top and serve hot!',
            instructionBn: 'ভাজা চিকেন প্যানে দিয়ে দিন। উপরে সস ছড়িয়ে দিয়ে গরম গরম পরিবেশন করুন!',
          ),
        ],
      ),
      Recipe(
        id: 'lemon-salmon',
        title: 'Lemon Butter Salmon',
        titleBn: 'লেমন বাটার স্যামন',
        subtitle: 'Pan-fried salmon fillet topped with a fresh lemon garlic butter glaze.',
        subtitleBn: 'তাজা লেবু, রসুন ও মাখনের স্বাদে প্যানে ভাজা লোভনীয় স্যামন মাছ।',
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
        proTipBn: 'চামড়ার দিকটা প্রথমে না নেড়ে ভালো করে ভাজলে চামড়াটা দারুণ মুচমুচে হয়।',
        ingredients: [
          '2 fresh salmon fillets',
          '3 cloves garlic, minced',
          '1 tablespoon butter & 1 tablespoon olive oil',
          '1 whole lemon (sliced and juiced)',
          'Fresh parsley, chopped',
          'Pinch of salt and black pepper',
        ],
        ingredientsBn: [
          '২ টুকরো তাজা স্যামন ফিলেট',
          '৩ কোয়া রসুন, কুচানো',
          '১ টেবিল চামচ মাখন ও ১ টেবিল চামচ অলিভ অয়েল',
          '১টি আস্ত লেবুর রস ও স্লাইস',
          'কুচানো তাজা ধনেপাতা বা পার্সলে',
          'এক চিমটি লবণ ও গোলমরিচ গুঁড়া',
        ],
        steps: [
          CookingStep(
            stepNumber: 1,
            title: 'Pan-fry Salmon',
            titleBn: 'স্যামন ভাজুন',
            timeBadge: '8 min',
            instruction: 'Heat oil and butter in a pan. Cook salmon skin-side down for 5 minutes. Flip and cook for 3 minutes more.',
            instructionBn: 'প্যানে তেল ও মাখন গরম করুন। স্যামন চামড়ার দিক নিচে দিয়ে ৫ মিনিট ভাজুন। উল্টে আরও ৩ মিনিট ভাজুন।',
          ),
          CookingStep(
            stepNumber: 2,
            title: 'Add Lemon Glaze',
            titleBn: 'লেবু ও মাখনের সস দিন',
            timeBadge: '3 min',
            instruction: 'Add garlic and lemon juice around the salmon. Spoon melted butter over the top and garnish with parsley.',
            instructionBn: 'স্যামনের পাশে রসুন ও লেবুর রস দিন। গলানো মাখন মাছের উপর ছড়িয়ে পার্সলে পাতা দিয়ে সাজিয়ে নিন।',
          ),
        ],
      ),
      Recipe(
        id: 'honey-chicken',
        title: 'Crispy Honey Sesame Chicken',
        titleBn: 'ক্রিস্পি হানি তিল চিকেন',
        subtitle: 'Sweet and savory chicken bites glazed with honey, soy sauce, and toasted sesame seeds.',
        subtitleBn: 'মধু, সয়া সস এবং ভাজা তিলের মিষ্টি ও নোনতা স্বাদে গ্লেজ করা চিকেন।',
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
        proTipBn: 'ভাজার আগে মাংসে এক টেবিল চামচ কর্নফ্লাওয়ার মাখিয়ে নিলে চিকেনের প্রান্তগুলো খুব মুচমুচে হয়।',
        ingredients: [
          '400g chicken thighs or breasts, diced',
          '2 tablespoons honey',
          '2 tablespoons soy sauce',
          '1 tablespoon sesame seeds',
          '2 cloves garlic, minced',
        ],
        ingredientsBn: [
          '৪০০ গ্রাম মুরগির মাংস, ছোট টুকরো করা',
          '২ টেবিল চামচ খাঁটি মধু',
          '২ টেবিল চামচ সয়া সস',
          '১ টেবিল চামচ ভাজা সাদা তিল',
          '২ কোয়া রসুন, কুচানো',
        ],
        steps: [
          CookingStep(
            stepNumber: 1,
            title: 'Fry Chicken',
            titleBn: 'চিকেন ভেজে নিন',
            timeBadge: '6 min',
            instruction: 'Heat 1 spoon of oil in a pan. Stir-fry chicken on high heat for 6 minutes until crisp and cooked through.',
            instructionBn: 'প্যানে ১ চামচ তেল গরম করুন। তীব্র আঁচে ৬ মিনিট নেড়ে মাংস ভালো করে ভাজুন।',
          ),
          CookingStep(
            stepNumber: 2,
            title: 'Glaze & Toss',
            titleBn: 'সস মিশিয়ে নিন',
            timeBadge: '2 min',
            instruction: 'Turn down heat. Add honey, soy sauce, and garlic. Stir for 2 minutes until glossy, then sprinkle sesame seeds.',
            instructionBn: 'আঁচ কমিয়ে মধু, সয়া সস ও রসুন দিন। ২ মিনিট নেড়ে চকচকে সস তৈরি করে উপরে তিল ছড়িয়ে দিন।',
          ),
        ],
      ),
      Recipe(
        id: 'creamy-mushroom-rice',
        title: 'Creamy Mushroom Rice',
        titleBn: 'ক্রিমি মাশরুম রাইস',
        subtitle: 'Warm and comforting rice slowly cooked with buttery sliced mushrooms and cheese.',
        subtitleBn: 'মাখন, কাটা মাশরুম ও চিজ দিয়ে ধীরে ধীরে রান্না করা নরম আরামদায়ক রাইস।',
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
        proTipBn: 'ঠান্ডা পানির বদলে গরম ভেজিটেবল স্যুপ বা স্টক ব্যবহার করলে চাল সমানভাবে এবং দ্রুত সেদ্ধ হয়।',
        ingredients: [
          '1 cup white rice or Arborio rice',
          '200g mushrooms, sliced',
          '3 cups warm vegetable broth',
          'Third cup grated parmesan or cheddar cheese',
          '2 tablespoons butter',
          'Salt and black pepper',
        ],
        ingredientsBn: [
          '১ কাপ বাসমতী বা পোলাওয়ের চাল',
          '২০০ গ্রাম মাশরুম, পাতলা কাটা',
          '৩ কাপ গরম ভেজিটেবল স্টক বা পানি',
          '১/৩ কাপ গ্রেট করা চিজ',
          '২ টেবিল চামচ মাখন',
          'লবণ ও গোলমরিচ গুঁড়া',
        ],
        steps: [
          CookingStep(
            stepNumber: 1,
            title: 'Brown Mushrooms',
            titleBn: 'মাশরুম ভেজে নিন',
            timeBadge: '5 min',
            instruction: 'Melt 1 spoon of butter in a pot. Cook sliced mushrooms for 5 minutes until browned and fragrant.',
            instructionBn: 'পাত্রে ১ চামচ মাখন গলিয়ে নিন। মাশরুম ৫ মিনিট ভেজে বাদামি ও সুবাসিত করুন।',
          ),
          CookingStep(
            stepNumber: 2,
            title: 'Simmer Rice',
            titleBn: 'চাল সেদ্ধ করুন',
            timeBadge: '18 min',
            instruction: 'Add rice and pour in warm broth a little at a time. Stir often until rice is soft and creamy.',
            instructionBn: 'চাল দিয়ে অল্প অল্প করে গরম পানি বা স্টক ঢালুন। চাল নরম ও ক্রিমি না হওয়া পর্যন্ত নাড়তে থাকুন।',
          ),
          CookingStep(
            stepNumber: 3,
            title: 'Stir in Cheese',
            titleBn: 'চিজ মিশিয়ে নিন',
            timeBadge: '2 min',
            instruction: 'Stir in cheese and remaining butter until melted. Serve hot!',
            instructionBn: 'বাকি মাখন ও চিজ দিয়ে ভালো করে নেড়ে মিশিয়ে নিন। গরম গরম পরিবেশন করুন!',
          ),
        ],
      ),
      Recipe(
        id: 'spicy-beef-basil',
        title: 'Quick Beef & Sweet Basil',
        titleBn: 'কুইক বিফ অ্যান্ড তুলসী/বেসিল',
        subtitle: 'Savory ground beef stir-fried with garlic, soy sauce, and fresh green basil leaves.',
        subtitleBn: 'রসুন, সয়া সস এবং তাজা সুগন্ধি বেসিল বা তুলসী পাতা দিয়ে ভাজা বিফ কিমা।',
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
        proTipBn: 'বেসিল বা তুলসী পাতা দেওয়ার ঠিক আগেই চুলা বন্ধ করে দিন, যাতে পাতার সতেজ সবুজ রঙ ও তীব্র সুবাস বজায় থাকে।',
        ingredients: [
          '300g ground beef',
          '3 cloves garlic, crushed',
          '1 cup fresh basil leaves',
          '1 tablespoon soy sauce or oyster sauce',
          '1 teaspoon chili flakes (optional)',
        ],
        ingredientsBn: [
          '৩০০ গ্রাম বিফ কিমা',
          '৩ কোয়া রসুন, থেঁতো করা',
          '১ কাপ তাজা বেসিল বা মিষ্টি তুলসী পাতা',
          '১ টেবিল চামচ সয়া সস বা অয়েস্টার সস',
          '১ চা চামচ চিলি ফ্লেক্স বা শুকনা মরিচ গুঁড়া',
        ],
        steps: [
          CookingStep(
            stepNumber: 1,
            title: 'Cook the Beef',
            titleBn: 'বিফ কিমা রান্না করুন',
            timeBadge: '5 min',
            instruction: 'Heat a pan on high. Add garlic and ground beef. Break up the beef and cook 5 minutes until browned.',
            instructionBn: 'তীব্র আঁচে প্যান গরম করে রসুন ও মাংস দিন। ৫ মিনিট নেড়েচেড়ে কিমা বাদামি করে ভাজুন।',
          ),
          CookingStep(
            stepNumber: 2,
            title: 'Sauce & Basil',
            titleBn: 'সস ও পাতা মেশান',
            timeBadge: '2 min',
            instruction: 'Pour in soy sauce and chili flakes. Remove from heat, toss in fresh basil leaves, and serve with rice.',
            instructionBn: 'সয়া সস ও মরিচ গুঁড়া দিন। চুলা থেকে নামিয়ে তাজা বেসিল পাতা মিশিয়ে গরম ভাতের সাথে পরিবেশন করুন।',
          ),
        ],
      ),
      Recipe(
        id: 'chickpea-salad',
        title: 'Fresh Chickpea Salad',
        titleBn: 'তাজা চানা / ছোলার সালাদ',
        subtitle: 'Crisp cucumber, sweet tomatoes, and tender chickpeas tossed in olive oil and lemon juice.',
        subtitleBn: 'শসা, মিষ্টি টমেটো ও সেদ্ধ ছোলা অলিভ অয়েল ও লেবুর রসে মাখানো স্বাস্থ্যকর সালাদ।',
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
        proTipBn: 'ছোলা ঠাণ্ডা পানিতে ভালো করে ধুয়ে জল ঝরিয়ে নিলে সালাদটি আরও মচমচে ও সতেজ লাগে।',
        ingredients: [
          '1 can chickpeas, rinsed and drained',
          '1 cucumber, diced',
          '1 cup cherry tomatoes, cut in half',
          '2 tablespoons olive oil',
          'Juice of half a lemon',
          'Salt and dried herbs',
        ],
        ingredientsBn: [
          '১ কাপ সেদ্ধ ছোলা বা চানা',
          '১টি শসা, কিউব করে কাটা',
          '১ কাপ চেরি টমেটো বা সাধারণ টমেটো কুচি',
          '২ টেবিল চামচ অলিভ অয়েল',
          'অর্ধেক লেবুর তাজা রস',
          'লবণ ও শুকনো গোলমরিচ গুঁড়া',
        ],
        steps: [
          CookingStep(
            stepNumber: 1,
            title: 'Chop Veggies',
            titleBn: 'সবজি কেটে নিন',
            timeBadge: '8 min',
            instruction: 'Chop the cucumber and slice tomatoes in half. Put them in a large salad bowl with the chickpeas.',
            instructionBn: 'শসা ও টমেটো ছোট টুকরো করে কেটে নিন। বড় সালাদের বাটিতে ছোলার সাথে রাখুন।',
          ),
          CookingStep(
            stepNumber: 2,
            title: 'Dress & Toss',
            titleBn: 'সালাদ মাখিয়ে নিন',
            timeBadge: '2 min',
            instruction: 'Drizzle with olive oil, lemon juice, and a pinch of salt. Toss everything well and enjoy fresh!',
            instructionBn: 'অলিভ অয়েল, লেবুর রস ও এক চিমটি লবণ দিন। ভালো করে নেড়ে মিশিয়ে পরিবেশন করুন!',
          ),
        ],
      ),
    ];
  }
}

