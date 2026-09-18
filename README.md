# CookSmart 🍳 • AI Kitchen Companion & Recipe Generator

> **Turn everyday pantry ingredients into delicious meals with Google Gemini AI. Now featuring complete 1-tap bilingual support (English & বাংলা)!**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![AI](https://img.shields.io/badge/Google_Gemini-2.5_Flash-FF6B35?logo=google)](https://deepmind.google/technologies/gemini/)
[![Platform](https://img.shields.io/badge/Platform-Android%205.0%2B%20%7C%20Web-green)]()
[![Bilingual](https://img.shields.io/badge/Language-English%20%7C%20বাংলা-orange)]()
[![Status](https://img.shields.io/badge/Release-v1.1.0-success)](https://github.com/GaziMahmudur/cooksmart/releases/latest)

---

## 🌐 Official Showcase & Download Links

CookSmart includes an official landing page and GitHub Release where you can download the latest Android release APK directly:

- **📦 GitHub Release v1.1.0**: **[Download from GitHub Releases](https://github.com/GaziMahmudur/cooksmart/releases/latest)** (Recommended)
- **🚀 Live Showcase Website**: **[https://cook-master-topaz.vercel.app](https://cook-master-topaz.vercel.app)**
- **⚡ Direct APK Mirror**: **[CookSmart-v1.1.0.apk](https://cook-master-topaz.vercel.app/downloads/CookSmart-v1.1.0.apk)** (49.1 MB)

> **⚠️ Important Installation Note**: If you previously had an older version or debug build of CookSmart installed on your phone, **please uninstall it first** before installing `v1.1.0`. Android's package manager requires this when upgrading across different signatures.

---

## ✨ Key Features

### 1. 🌐 1-Tap Bilingual Experience (English & বাংলা)
- Seamless 1-tap language switch pill (`🌐 বাংলা` / `🌐 English`) on the home screen.
- All navigation tabs, ingredients, dietary filters, and UI labels adapt instantly.
- **Gemini AI outputs full recipe names, ingredient amounts, and step-by-step instructions in natural Bengali script (বাংলা ভাষা)** when active.

### 2. 🪄 Smart Pantry Recipe Generator
- Add ingredients by typing or tapping common kitchen essentials (Garlic, Olive oil, Chicken, Rice, Eggs, etc.).
- Tap **"Make Recipe with Gemini AI"** to generate an authentic, personalized meal tailored specifically to your ingredients.
- Dietary preferences and time filters: `⚡ Fast (<20m)`, `🥗 Healthy`, `🥩 High Protein`, `🌱 No Meat`, `🌾 Gluten-Free`.

### 3. 👨‍🍳 Conversational "Ask AI Chef"
- Interactive cooking assistant powered by Gemini.
- Context-aware recipe customization:
  - **"👥 Scale for 5 people"** or **"👥 Scale for 2 people"** — calculates new ingredient proportions automatically.
  - **"🔄 Swap ingredients"** — suggests smart substitutions for missing items.
  - **"🍳 Air fryer instructions"** & **"⏱️ Cook faster"** — temperature and timing conversions.

### 4. 📋 Interactive Recipe Cook Mode
- Structured recipe display with time badges, calorie estimates, and serving counts.
- Step-by-step interactive cooking checklist.
- One-tap share to clipboard for sending formatted recipes to family and friends.

### 5. 🔖 Saved Recipes Vault
- Save your favorite creations for offline access.
- Filter by `⚡ Quick (<30m)`, `🥩 High Protein`, or `🥗 Healthy`.
- Sort by Highest Rating, Shortest Cook Time, or Name (A-Z).

### 6. 🔥 Trending from the Web
- Real-time inspired dishes from popular food creators (TikTok Viral, NYT Cooking, Tasty).
- One-tap "Discover" button queries Gemini to fetch fresh recipe trends.

---

## 📱 Opening & Building in Android Studio

CookSmart is pre-configured and tested for Android Studio with zero Gradle build errors.

### Step-by-Step Instructions:

1. Launch **Android Studio**.
2. Select **File &rarr; Open** (or **Open Project** on the Welcome screen).
3. Navigate to the `flutter_app` folder:
   ```
   c:\Users\mdshu\Desktop\cook-master\flutter_app
   ```
4. Click **OK**. Android Studio will import the project and index Dart/Flutter dependencies.
5. In the top notification banner, click **"Pub get"** (or open the embedded terminal and run `flutter pub get`).
6. Select your target device (e.g. Android Emulator or physical phone connected via USB).
7. Click the green **Run (▶)** button or press `Shift + F10`.

---

## 📦 Ready-to-Install APK Locations

| Build Type | Location | Size | Description |
| :--- | :--- | :--- | :--- |
| **Release APK** | `flutter_app/build/app/outputs/flutter-apk/app-release.apk` | 48.7 MB | Optimized production release (tree-shaken, R8) |
| **Debug APK** | `flutter_app/build/app/outputs/flutter-apk/app-debug.apk` | ~60 MB | Local debugging build with hot reload support |
| **Web Download** | `site/public/downloads/app-release.apk` | 48.7 MB | Public download mirror for showcase site |

---

## ⚡ Command Line Commands

Run inside `flutter_app/`:

```bash
# Run code analysis (0 errors, 0 warnings)
flutter analyze

# Run unit and widget tests
flutter test

# Build production Android release APK
flutter build apk --release

# Run locally in Chrome browser (Web preview)
flutter run -d chrome --web-port=8080
```

---

## 🗂️ Project Directory Structure

```
cook-master/
├── flutter_app/                    # Core Flutter Mobile Application
│   ├── lib/
│   │   ├── l10n/                   # Typed English & Bengali (বাংলা) dictionary
│   │   │   └── app_strings.dart
│   │   ├── models/                 # Recipe, Step & Category data models
│   │   │   └── recipe.dart
│   │   ├── screens/                # Main app screens
│   │   │   ├── home_screen.dart
│   │   │   ├── ingredients_screen.dart
│   │   │   ├── recipe_detail_screen.dart
│   │   │   ├── ask_chef_screen.dart
│   │   │   ├── saved_screen.dart
│   │   │   └── main_scaffold.dart
│   │   ├── services/               # Gemini AI Generative API Service
│   │   │   └── gemini_recipe_service.dart
│   │   ├── state/                  # Centralized reactive app state
│   │   │   └── app_state.dart
│   │   ├── theme/                  # Obsidian Hearth dark design system
│   │   │   └── app_theme.dart
│   │   └── main.dart
│   ├── android/                    # Android Studio native host & Gradle config
│   ├── test/                       # Unit & Widget test suite
│   │   └── widget_test.dart
│   └── pubspec.yaml
├── site/                           # Anti-Gravity Style Showcase Website
│   ├── public/
│   │   ├── downloads/
│   │   │   └── app-release.apk     # Direct Android APK download
│   │   └── index.html              # Full showcase landing page
│   ├── vercel.json                 # Vercel deployment configuration
│   └── index.html
├── .gitignore
└── README.md
```

---

## 🔒 Gemini API Key Configuration

The Gemini API integration is housed in `flutter_app/lib/services/gemini_recipe_service.dart`.
For production deployments, you can supply your own Gemini API key or set it via environment variables:

```dart
static const String _defaultApiKey = 'YOUR_GEMINI_API_KEY';
```

Get your free Gemini API key from [Google AI Studio](https://aistudio.google.com/).

---

## 📄 License
This project is open-source under the MIT License.
