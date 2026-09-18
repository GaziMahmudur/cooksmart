# CookSmart - Android Studio & APK Build Guide

The **CookSmart** Flutter project is configured and ready to be opened in **Android Studio** and built into an Android APK.

---

## 📁 Project Directory for Android Studio

Open either of the following in Android Studio:
1. **Flutter Root (Recommended)**:
   `c:\Users\mdshu\Desktop\cook-master\flutter_app`
2. **Native Android Subfolder** (if opening as a pure Android project):
   `c:\Users\mdshu\Desktop\cook-master\flutter_app\android`

---

## ⚙️ Android Configurations Applied

1. **Native Android Scaffolding**:
   - Generated standard Gradle files, Kotlin activity (`MainActivity.kt`), and Gradle wrapper.
2. **Network & Permissions**:
   - Added `<uses-permission android:name="android.permission.INTERNET"/>` in `android/app/src/main/AndroidManifest.xml` so the Gemini API can be queried on real devices or emulators.
   - Updated the app display label to **`CookSmart`**.
3. **Dependencies & Compatibility**:
   - `http` package installed for calling the Gemini API endpoint.
   - `google_fonts` configured for **Plus Jakarta Sans** typography.
   - Java 17 compatibility target configured in `build.gradle.kts`.
   - `android.useAndroidX=true` and `android.enableJetifier=true` in `gradle.properties`.

---

## 🔨 Building the Android APK

### Option A: Via Command Line (Terminal)

Inside `c:\Users\mdshu\Desktop\cook-master\flutter_app`:

- **Debug APK (Fast testing on phone/emulator)**:
  ```powershell
  flutter build apk --debug
  ```
  *Output location*: `flutter_app/build/app/outputs/flutter-apk/app-debug.apk`

- **Release APK**:
  ```powershell
  flutter build apk --release
  ```
  *Output location*: `flutter_app/build/app/outputs/flutter-apk/app-release.apk`

- **Direct Run on Connected Phone or Emulator**:
  ```powershell
  flutter run
  ```

---

### Option B: Via Android Studio

1. Open **Android Studio**.
2. Click **Open** and select `c:\Users\mdshu\Desktop\cook-master\flutter_app`.
3. Wait for Gradle and Dart sync to complete.
4. Select your connected Android device or emulator from the device dropdown.
5. Click the green **Run (▶)** button, or navigate to **Build > Flutter > Build APK**.
