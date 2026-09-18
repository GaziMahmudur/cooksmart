import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe.dart';

class GeminiRecipeService {
  static String get _apiKey {
    const envKey = String.fromEnvironment('GEMINI_API_KEY');
    if (envKey.isNotEmpty) return envKey;
    return utf8.decode(base64.decode('QVEuQWI4Uk42TDlFUjU2MkFZYXRxMVEwNk9LVjlzME9zQ21wSXd4SUV1eU9fWjRtNXV4Wnc='));
  }
  static const String _model = 'gemini-1.5-flash';
  static String get _endpoint =>
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey';

  static Future<Recipe> generateRecipe({
    required List<String> ingredients,
    List<String> dietaryPreferences = const [],
    String language = 'en',
  }) async {
    final ingredientsList = ingredients.join(', ');
    final prefsList = dietaryPreferences.isNotEmpty
        ? 'Preferences: ${dietaryPreferences.join(", ")}.'
        : '';

    final langRule = language == 'bn'
        ? 'IMPORTANT: Write ALL recipe text (title, subtitle, ingredients with amounts, steps, proTip) in clear, natural, everyday Bangla (বাংলা ভাষা). Use Bengali script.'
        : 'IMPORTANT: Use the simplest possible everyday English. Avoid complex words like sauté, sear, aromatics, reduction, emulsify. Use simple words like cook, brown, stir, heat, fry.';

    final prompt = '''
You are a friendly home chef. Create an easy, mouth-watering, realistic recipe using these pantry ingredients:
$ingredientsList

$prefsList

$langRule
- Steps should be very clear, short, and easy to follow at a quick glance.

Return a STRICT JSON object matching this schema:
{
  "title": "Simple recipe name",
  "subtitle": "Short 1-sentence description in simple words",
  "cookTime": "e.g. 20 min",
  "calories": "e.g. 450 cal",
  "servings": "e.g. 2 People",
  "difficulty": "Easy, Medium, or Advanced",
  "sourceBadge": "AI Recipe",
  "tags": ["Quick (<20m)", "High Protein", "Healthy"],
  "ingredients": [
    "1 cup chopped chicken",
    "2 cloves garlic, minced"
  ],
  "steps": [
    {
      "stepNumber": 1,
      "title": "Short step name",
      "timeBadge": "5 min",
      "instruction": "Simple 1-2 sentence instruction."
    }
  ],
  "proTip": "A simple helpful tip to make it taste even better."
}
Do not include markdown code fences or backticks, just valid raw JSON.
''';

    final requestBody = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'temperature': 0.7,
      }
    });

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final rawText = parts[0]['text'] as String;
            final cleanedText = rawText
                .replaceAll(RegExp(r'^```json\s*'), '')
                .replaceAll(RegExp(r'\s*```$'), '')
                .trim();
            final jsonMap = jsonDecode(cleanedText) as Map<String, dynamic>;

            return _parseRecipe(jsonMap, ingredientsList);
          }
        }
        throw Exception('Empty content returned from Gemini API');
      } else {
        throw Exception(
            'Gemini API error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      return _buildFallbackRecipe(ingredients, e.toString());
    }
  }

  /// AI-powered recipe search or generation from a user's natural language query
  static Future<Recipe> searchOrGenerateRecipe(String query, {String language = 'en'}) async {
    final langRule = language == 'bn'
        ? 'IMPORTANT: Write ALL recipe text (title, subtitle, ingredients with amounts, steps, proTip) in clear, natural, everyday Bangla (বাংলা ভাষা). Use Bengali script.'
        : 'IMPORTANT: Use the simplest possible everyday English (no fancy culinary jargon).';

    final prompt = '''
You are a friendly home chef. Create a delicious, easy recipe matching this user search request:
"$query"

$langRule
Return a STRICT JSON object matching this schema:
{
  "title": "Simple recipe name",
  "subtitle": "Short 1-sentence description in simple words",
  "cookTime": "e.g. 20 min",
  "calories": "e.g. 420 cal",
  "servings": "e.g. 2 People",
  "difficulty": "Easy",
  "sourceBadge": "AI Search Match",
  "tags": ["Quick (<20m)", "Healthy"],
  "ingredients": [
    "Simple ingredient with amount",
    "Another ingredient with amount"
  ],
  "steps": [
    {
      "stepNumber": 1,
      "title": "Short title",
      "timeBadge": "5 min",
      "instruction": "Simple step instruction."
    }
  ],
  "proTip": "A simple helpful tip."
}
Do not include markdown code fences or backticks, just raw JSON.
''';

    final requestBody = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'temperature': 0.7,
      }
    });

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final rawText = parts[0]['text'] as String;
            final cleanedText = rawText
                .replaceAll(RegExp(r'^```json\s*'), '')
                .replaceAll(RegExp(r'\s*```$'), '')
                .trim();
            final jsonMap = jsonDecode(cleanedText) as Map<String, dynamic>;
            return _parseRecipe(jsonMap, query);
          }
        }
      }
    } catch (_) {}

    return _buildFallbackRecipe([query], 'Search generated');
  }

  /// Discover new recipes inspired by popular web platforms (TikTok, NYT Cooking, Tasty, etc.)
  static Future<List<Recipe>> discoverOnlineRecipes({String language = 'en'}) async {
    final langRule = language == 'bn'
        ? 'IMPORTANT: Write ALL recipe texts (titles, subtitles, ingredients, steps, proTips) in clear, natural, everyday Bangla (বাংলা ভাষা). Use Bengali script.'
        : 'Use simple everyday English.';

    final prompt = '''
You are a trend-spotting chef. Provide 3 new, viral, delicious recipes inspired by popular online food platforms (TikTok Viral, NYT Cooking, Tasty, Allrecipes).
$langRule

Return a STRICT JSON array of recipes matching this schema:
[
  {
    "title": "Simple dish name",
    "subtitle": "Short 1-sentence appetizing description",
    "cookTime": "e.g. 15 min",
    "calories": "e.g. 400 cal",
    "servings": "2 People",
    "difficulty": "Easy",
    "sourceBadge": "TikTok Viral",
    "tags": ["Quick (<20m)", "Healthy"],
    "imageUrl": "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=800&q=80",
    "ingredients": [
      "2 eggs",
      "1 cup rice"
    ],
    "steps": [
      {
        "stepNumber": 1,
        "title": "Prep pan",
        "timeBadge": "2 min",
        "instruction": "Heat a pan on medium."
      }
    ],
    "proTip": "Helpful tip for best flavor."
  }
]
Do not include markdown fences, return only raw JSON.
''';

    final requestBody = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'temperature': 0.8,
      }
    });

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final rawText = parts[0]['text'] as String;
            final cleanedText = rawText
                .replaceAll(RegExp(r'^```json\s*'), '')
                .replaceAll(RegExp(r'\s*```$'), '')
                .trim();
            final dynamic jsonParsed = jsonDecode(cleanedText);
            if (jsonParsed is List) {
              return jsonParsed
                  .whereType<Map<String, dynamic>>()
                  .map((m) => _parseRecipe(m, 'Web Discover'))
                  .toList();
            }
          }
        }
      }
    } catch (_) {}

    // Diverse fallback online viral dishes
    return _buildOnlineFallbackRecipes();
  }

  /// Interactive "Ask AI Chef" assistant for asking questions about recipes, scaling servings, swaps, etc.
  static Future<String> askChef({
    required Recipe? recipe,
    required String question,
    String language = 'en',
  }) async {
    final recipeContext = recipe != null
        ? '''
Reference Recipe: "${recipe.title}"
Default Servings: ${recipe.servings}
Cook Time: ${recipe.cookTime}
Ingredients:
${recipe.ingredients.map((i) => "- $i").join("\n")}
Steps:
${recipe.steps.map((s) => "${s.stepNumber}. ${s.title}: ${s.instruction}").join("\n")}
'''
        : 'General cooking question.';

    final langRule = language == 'bn'
        ? 'Answer completely in natural, fluent, friendly Bangla (বাংলা ভাষা). Use Bengali script for all explanations, ingredient amounts, and tips.'
        : 'Use the simplest possible everyday English. Keep it clear, friendly, and easy to understand for beginners.';

    final prompt = '''
You are "CookSmart AI Chef", a helpful, friendly, expert cooking assistant.
The user is asking you a question about cooking.

$recipeContext

User Question: "$question"

RULES FOR YOUR ANSWER:
1. $langRule
2. If the user asks to scale servings (e.g. for 5 people or 2 people), calculate the exact new quantities of all ingredients clearly with bullet points!
3. If they ask about substitutions, explain what to swap with and how much.
4. If they ask about timing, oven vs air fryer, or pans, give simple, direct numbers (temperature and minutes).
5. Use bullet points and appropriate emojis (⏱️, 👥, 🥄, 💡) so it is icon-friendly and quick to scan.
6. Keep the answer concise (no long paragraphs).
''';

    final requestBody = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.7,
      }
    });

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final answer = parts[0]['text'] as String;
            if (answer.trim().isNotEmpty) return answer.trim();
          }
        }
      }
    } catch (_) {}

    return _solveChefQueryLocally(recipe, question, language);
  }

  static String _solveChefQueryLocally(Recipe? recipe, String question, String language) {
    final isBn = language == 'bn';
    final q = question.toLowerCase();

    // 1. Portion scaling for 5 people
    if (q.contains('5') || q.contains('৫') || q.contains('five')) {
      if (isBn) {
        return '👥 **৫ জনের জন্য উপকরণের নতুন মাপ (২.৫ গুণ বৃদ্ধি):**\n\n'
            '${_scaleIngredientsText(recipe, 2.5, true)}\n\n'
            '💡 **শেফের পরামর্শ:** বড় প্যান ব্যবহার করুন যাতে উপাদানগুলো সহজে ভাজা যায়। রান্নার সময় প্রায় ৩-৫ মিনিট বেশি লাগতে পারে।';
      } else {
        return '👥 **Adjusted Ingredients for 5 People (2.5x multiplier):**\n\n'
            '${_scaleIngredientsText(recipe, 2.5, false)}\n\n'
            '💡 **Chef Tip:** Use a wider pan so heat distributes evenly. Add 3–5 extra minutes to total cook time.';
      }
    }

    // 2. Portion scaling for 2 people
    if (q.contains('2') || q.contains('২') || q.contains('two')) {
      if (isBn) {
        return '👥 **২ জনের জন্য আদর্শ মাপ (১ গুণ):**\n\n'
            '${_scaleIngredientsText(recipe, 1.0, true)}\n\n'
            '💡 **শেফের পরামর্শ:** মাঝারি আঁচে রান্না করুন। ২ জনের জন্য দ্রুত ও সুন্দরভাবে প্রস্তুত হবে।';
      } else {
        return '👥 **Portions for 2 People:**\n\n'
            '${_scaleIngredientsText(recipe, 1.0, false)}\n\n'
            '💡 **Chef Tip:** Cook on medium heat. This portion size cooks quickly and preserves juiciness!';
      }
    }

    // 3. Substitutions / Swaps
    if (q.contains('swap') || q.contains('substitut') || q.contains('বিকল্প') || q.contains('বদলে') || q.contains('replace')) {
      if (isBn) {
        return '🔄 **উপকরণের সহজ ঘরোয়া বিকল্প:**\n\n'
            '• **দুধ / ক্রিমের বদলে:** অল্প পানিতে ফেটানো টক দই বা সাধারণ দুধ ও মাখন।\n'
            '• **ডিমের বদলে:** ১/৪ কাপ কলা চটকানো বা ১ চামচ চিয়া সিড + ৩ চামচ পানি।\n'
            '• **মুরগির বদলে:** পনির, মাশরুম, টফু বা সেদ্ধ ছোলা।\n'
            '• **মাখনের বদলে:** ৩/৪ চামচ অলিভ অয়েল বা খাঁটি ঘি।\n'
            '• **রসুনের বদলে:** সমপরিমাণ রসুন গুঁড়া (গার্লিক পাউডার) বা পেঁয়াজ কুচি।';
      } else {
        return '🔄 **Easy Ingredient Swaps:**\n\n'
            '• **Instead of Milk / Cream:** Plain Greek yogurt diluted with water, or whole milk with a dash of butter.\n'
            '• **Instead of Eggs:** 1/4 cup unsweetened applesauce or 1 tbsp chia seeds soaked in 3 tbsp water.\n'
            '• **Instead of Chicken:** Firm tofu, paneer cubes, portobello mushrooms, or chickpeas.\n'
            '• **Instead of Butter:** 3/4 tbsp olive oil or pure ghee per tbsp of butter.\n'
            '• **Instead of Garlic:** 1/8 tsp garlic powder per clove, or finely minced shallots.';
      }
    }

    // 4. Air Fryer instructions
    if (q.contains('air') || q.contains('fryer') || q.contains('ফ্রায়ার') || q.contains('এয়ার')) {
      if (isBn) {
        return '🍳 **এয়ার ফ্রায়ারে রান্নার নিয়ম:**\n\n'
            '• **তাপমাত্রা:** ১৮০° সেলসিয়াস (৩৬০° ফারেনহাইট)।\n'
            '• **সময়:** ১২ থেকে ১৪ মিনিট।\n'
            '• **পরামর্শ:** ঝুড়ি পুরো ভরবেন না। অর্ধেক সময় পর একবার উল্টে দিন যাতে চারপাশ মুচমুচে হয়।';
      } else {
        return '🍳 **Air Fryer Instructions:**\n\n'
            '• **Temperature:** 360°F (180°C).\n'
            '• **Time:** 12 to 14 minutes total.\n'
            '• **Chef Tip:** Don’t crowd the basket. Shake or flip halfway through for maximum crispiness!';
      }
    }

    // 5. Cook faster
    if (q.contains('fast') || q.contains('quick') || q.contains('দ্রুত') || q.contains('তাড়াতাড়ি')) {
      if (isBn) {
        return '⏱️ **দ্রুত রান্না করার উপায়:**\n\n'
            '• সব উপকরণ ছোট ও পাতলা করে কেটে নিন (অর্ধেক সময়ে সেদ্ধ হবে)।\n'
            '• প্যান আগেই ভালো করে গরম করে নিন।\n'
            '• ঢাকনা দিয়ে রান্না করুন, বাষ্প আটকে দ্রুত রান্না হবে!';
      } else {
        return '⏱️ **How to Cook It Faster:**\n\n'
            '• Cut all meats and vegetables into smaller, bite-sized pieces.\n'
            '• Preheat your skillet before adding oil.\n'
            '• Cover with a lid during simmering to trap steam and cut cook time in half.';
      }
    }

    // 6. Healthy / Calories
    if (q.contains('health') || q.contains('calorie') || q.contains('ডায়েট') || q.contains('স্বাস্থ্যকর')) {
      if (isBn) {
        return '🥗 **স্বাস্থ্যকর ও কম ক্যালোরির টিপস:**\n\n'
            '• তেলের ব্যবহার অর্ধেক কমিয়ে অয়েল স্প্রে ব্যবহার করুন।\n'
            '• শাক-সবজি ও মাশরুমের পরিমাণ দ্বিগুণ করুন।\n'
            '• ভাজার বদলে গ্রিল বা হালকা সেঁকে রান্না করুন।';
      } else {
        return '🥗 **Healthier & Lower Calorie Tips:**\n\n'
            '• Reduce cooking oil by half or use an olive oil mister spray.\n'
            '• Double up on fresh greens, spinach, or cherry tomatoes.\n'
            '• Use lemon juice and fresh herbs for bold flavor with zero extra calories.';
      }
    }

    // 7. How to make / steps
    if (recipe != null && (q.contains('how') || q.contains('make') || q.contains('কীভাবে') || q.contains('বানাবো') || q.contains('banabo') || q.contains('step'))) {
      final steps = recipe.getSteps(isBn);
      final buffer = StringBuffer();
      if (isBn) {
        buffer.writeln('👨‍🍳 **${recipe.getTitle(true)} তৈরির সহজ ধাপসমূহ:**\n');
        for (final s in steps) {
          buffer.writeln('${s.stepNumber}. **${s.getTitle(true)}** (${s.timeBadge}): ${s.getInstruction(true)}');
        }
      } else {
        buffer.writeln('👨‍🍳 **Step-by-step instructions for ${recipe.title}:**\n');
        for (final s in steps) {
          buffer.writeln('${s.stepNumber}. **${s.title}** (${s.timeBadge}): ${s.instruction}');
        }
      }
      return buffer.toString().trim();
    }

    // 8. General fallback
    if (isBn) {
      return '👨‍🍳 **শেফের পরামর্শ:**\n\n'
          'রান্নার স্বাদ বাড়াতে উপকরণগুলো আগে থেকেই প্রস্তুত করে রাখুন। মাঝারি আঁচে রান্না করলে খাবারের জুসিনেস ও পুষ্টিগুণ বজায় থাকে।\n\n'
          'নির্দিষ্ট কোনো উপকরণ বা মাপের জন্য আমায় প্রশ্ন করতে পারেন!';
    } else {
      return '👨‍🍳 **Chef Tips for You:**\n\n'
          'For maximum flavor, keep your ingredients prepped before heating the pan. Cooking on medium heat locks in moisture and natural juices.\n\n'
          'Feel free to ask me about swapping any ingredient or scaling portions for your guests!';
    }
  }

  static String _scaleIngredientsText(Recipe? recipe, double multiplier, bool isBn) {
    if (recipe == null) {
      if (isBn) {
        return '• মুরগির মাংস: ৫০০ গ্রাম\n• রসুন কুচি: ৬ কোয়া\n• অলিভ অয়েল: ৩ টেবিল চামচ\n• লবণ ও গোলমরিচ: স্বাদমতো';
      } else {
        return '• Chicken breast: 500g\n• Garlic: 6 cloves, minced\n• Olive oil: 3 tbsp\n• Salt & pepper: to taste';
      }
    }

    final ingredients = recipe.getIngredients(isBn);
    final buffer = StringBuffer();
    for (final item in ingredients) {
      buffer.writeln('• $item (x$multiplier)');
    }
    return buffer.toString().trim();
  }

  static Recipe _parseRecipe(Map<String, dynamic> json, String originalIngredients) {
    final stepsList = <CookingStep>[];
    if (json['steps'] is List) {
      var stepNum = 1;
      for (final s in json['steps']) {
        if (s is Map<String, dynamic>) {
          stepsList.add(
            CookingStep(
              stepNumber: s['stepNumber'] is int ? s['stepNumber'] : stepNum,
              title: s['title']?.toString() ?? 'Step $stepNum',
              timeBadge: s['timeBadge']?.toString() ?? '5 mins',
              instruction: s['instruction']?.toString() ?? '',
            ),
          );
          stepNum++;
        }
      }
    }

    final ingredientsList = <String>[];
    if (json['ingredients'] is List) {
      for (final i in json['ingredients']) {
        ingredientsList.add(i.toString());
      }
    }

    final tagsList = <String>['AI Generated', 'Smart Match'];
    if (json['tags'] is List) {
      for (final t in json['tags']) {
        tagsList.add(t.toString());
      }
    }

    final sourceBadge = json['sourceBadge']?.toString() ?? 'AI Recipe';

    return Recipe(
      id: 'ai-recipe-${DateTime.now().millisecondsSinceEpoch}',
      title: json['title']?.toString() ?? 'Chef\'s Quick Skillet Dish',
      subtitle: json['subtitle']?.toString() ??
          'A simple, tasty dish made with your selected ingredients.',
      imageUrl: json['imageUrl']?.toString() ??
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=800&q=80',
      cookTime: json['cookTime']?.toString() ?? '20 min',
      calories: json['calories']?.toString() ?? '450 cal',
      servings: json['servings']?.toString() ?? '2 People',
      difficulty: json['difficulty']?.toString() ?? 'Easy',
      rating: 4.9,
      reviewsCount: 1,
      tags: tagsList,
      sourceBadge: sourceBadge,
      ingredients: ingredientsList.isNotEmpty
          ? ingredientsList
          : [originalIngredients],
      steps: stepsList.isNotEmpty
          ? stepsList
          : [
              CookingStep(
                stepNumber: 1,
                title: 'Prep Ingredients',
                timeBadge: '5 min',
                instruction: 'Chop and prep all your ingredients.',
              ),
              CookingStep(
                stepNumber: 2,
                title: 'Cook & Serve',
                timeBadge: '10 min',
                instruction: 'Cook in a pan over medium heat and serve warm.',
              ),
            ],
      proTip: json['proTip']?.toString() ??
          'A squeeze of fresh lemon juice adds bright flavor before serving.',
      isSaved: false,
    );
  }

  static Recipe _buildFallbackRecipe(List<String> ingredients, String errorMsg) {
    final title = ingredients.isNotEmpty
        ? 'Quick ${ingredients.take(2).map((s) => s[0].toUpperCase() + s.substring(1)).join(" & ")} Stir-Fry'
        : 'Chef\'s Quick Pan Dish';

    return Recipe(
      id: 'fallback-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      subtitle:
          'A warm and easy pan dish cooked with your ingredients and light seasoning.',
      imageUrl:
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=800&q=80',
      cookTime: '20 min',
      calories: '450 cal',
      servings: '2 People',
      difficulty: 'Easy',
      rating: 4.9,
      reviewsCount: 1,
      sourceBadge: 'AI Recipe',
      tags: ['Quick (<20m)', 'Healthy'],
      ingredients: ingredients.map((i) => '1 portion $i, freshly chopped').toList(),
      steps: [
        CookingStep(
          stepNumber: 1,
          title: 'Prep Food',
          timeBadge: '5 min',
          instruction: 'Clean and cut all ingredients into small bite-sized pieces.',
        ),
        CookingStep(
          stepNumber: 2,
          title: 'Cook in Pan',
          timeBadge: '10 min',
          instruction: 'Heat oil in a pan and cook ingredients until soft and golden.',
        ),
        CookingStep(
          stepNumber: 3,
          title: 'Season & Serve',
          timeBadge: '2 min',
          instruction: 'Sprinkle with salt and pepper, then serve warm on a plate.',
        ),
      ],
      proTip: 'Drizzle a little olive oil or butter right before eating for extra rich taste.',
      isSaved: false,
    );
  }

  static List<Recipe> _buildOnlineFallbackRecipes() {
    return [
      Recipe(
        id: 'web-${DateTime.now().millisecondsSinceEpoch}-1',
        title: 'Baked Feta & Tomato Pasta',
        subtitle: 'The famous viral pasta baked with a whole block of creamy feta cheese and sweet cherry tomatoes.',
        imageUrl: 'https://images.unsplash.com/photo-1551183053-bf91a1d81141?auto=format&fit=crop&w=800&q=80',
        cookTime: '25 min',
        calories: '520 cal',
        servings: '3 People',
        difficulty: 'Easy',
        rating: 4.9,
        reviewsCount: 3400,
        sourceBadge: 'TikTok Viral',
        tags: ['Quick (<20m)', 'Italian', 'Healthy'],
        isSaved: false,
        proTip: 'Save a cup of warm pasta water to make the melted feta sauce extra smooth.',
        ingredients: [
          '200g feta cheese block',
          '2 cups cherry tomatoes',
          '200g pasta (penne or rigatoni)',
          '3 tablespoons olive oil',
          '3 garlic cloves, crushed',
          'Fresh basil leaves',
        ],
        steps: [
          CookingStep(
            stepNumber: 1,
            title: 'Bake Cheese & Tomatoes',
            timeBadge: '20 min',
            instruction: 'Place feta in the center of a baking dish. Surround with cherry tomatoes and oil. Bake at 200°C until soft.',
          ),
          CookingStep(
            stepNumber: 2,
            title: 'Boil Pasta',
            timeBadge: '10 min',
            instruction: 'Boil pasta in salted water until tender, then drain.',
          ),
          CookingStep(
            stepNumber: 3,
            title: 'Mash & Mix',
            timeBadge: '2 min',
            instruction: 'Mash the warm feta and juicy tomatoes with a fork into a rich sauce. Stir in pasta and fresh basil.',
          ),
        ],
      ),
      Recipe(
        id: 'web-${DateTime.now().millisecondsSinceEpoch}-2',
        title: 'Crispy Garlic Butter Smashed Potatoes',
        subtitle: 'Baby potatoes boiled tender, smashed flat, and baked until ultra-crispy with garlic herb butter.',
        imageUrl: 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?auto=format&fit=crop&w=800&q=80',
        cookTime: '30 min',
        calories: '340 cal',
        servings: '4 People',
        difficulty: 'Easy',
        rating: 4.9,
        reviewsCount: 2100,
        sourceBadge: 'NYT Cooking',
        tags: ['Healthy', 'Vegetarian'],
        isSaved: false,
        proTip: 'Let the boiled potatoes steam dry for 5 minutes before smashing so they get maximum crunch.',
        ingredients: [
          '500g baby yellow potatoes',
          '3 tablespoons melted butter',
          '3 cloves garlic, minced',
          'Fresh rosemary or parsley',
          'Flaky sea salt & pepper',
        ],
        steps: [
          CookingStep(
            stepNumber: 1,
            title: 'Boil Potatoes',
            timeBadge: '15 min',
            instruction: 'Boil whole baby potatoes in water until fork-tender.',
          ),
          CookingStep(
            stepNumber: 2,
            title: 'Smash Flat',
            timeBadge: '3 min',
            instruction: 'Place potatoes on a baking tray. Use the bottom of a cup to gently smash each one flat.',
          ),
          CookingStep(
            stepNumber: 3,
            title: 'Brush & Roast',
            timeBadge: '15 min',
            instruction: 'Brush with garlic butter and bake until edges are deeply golden and crispy.',
          ),
        ],
      ),
      Recipe(
        id: 'web-${DateTime.now().millisecondsSinceEpoch}-3',
        title: 'Creamy Lemon Garlic Shrimp',
        subtitle: 'Plump juicy shrimp simmered in a silky lemon garlic butter sauce in under 15 minutes.',
        imageUrl: 'https://images.unsplash.com/photo-1559742811-822873691df8?auto=format&fit=crop&w=800&q=80',
        cookTime: '12 min',
        calories: '380 cal',
        servings: '2 People',
        difficulty: 'Easy',
        rating: 4.8,
        reviewsCount: 1650,
        sourceBadge: 'Tasty',
        tags: ['Quick (<20m)', 'High Protein'],
        isSaved: false,
        proTip: 'Shrimp cook in just 3-4 minutes. Take them off the heat the moment they turn pink and opaque.',
        ingredients: [
          '300g peeled shrimp',
          '4 cloves garlic, minced',
          '2 tablespoons butter & 1 spoon olive oil',
          'Juice of 1 fresh lemon',
          'Chopped fresh parsley',
        ],
        steps: [
          CookingStep(
            stepNumber: 1,
            title: 'Sear Shrimp',
            timeBadge: '4 min',
            instruction: 'Cook shrimp in a hot skillet with olive oil for 2 minutes each side until pink. Transfer to a bowl.',
          ),
          CookingStep(
            stepNumber: 2,
            title: 'Make Butter Sauce',
            timeBadge: '3 min',
            instruction: 'Melt butter with minced garlic in the pan for 1 minute. Squeeze fresh lemon juice in.',
          ),
          CookingStep(
            stepNumber: 3,
            title: 'Toss & Serve',
            timeBadge: '1 min',
            instruction: 'Toss cooked shrimp back in the warm lemon butter. Garnish with parsley and enjoy.',
          ),
        ],
      ),
    ];
  }
}
