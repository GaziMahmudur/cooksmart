import 'package:flutter/material.dart';
import 'screens/main_scaffold.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CookSmartApp());
}

class CookSmartApp extends StatefulWidget {
  const CookSmartApp({super.key});

  @override
  State<CookSmartApp> createState() => _CookSmartAppState();
}

class _CookSmartAppState extends State<CookSmartApp> {
  final AppState _appState = AppState();

  @override
  void initState() {
    super.initState();
    try {
      final tabParam = Uri.base.queryParameters['tab'];
      if (tabParam != null) {
        final tabIndex = int.tryParse(tabParam);
        if (tabIndex != null && tabIndex >= 0 && tabIndex <= 3) {
          _appState.setTab(tabIndex);
          if (tabIndex == 1) {
            _appState.addIngredient('Chicken');
            _appState.addIngredient('Garlic');
            _appState.addIngredient('Butter');
          }
        }
      }
      final langParam = Uri.base.queryParameters['lang'];
      if (langParam != null && (langParam == 'bn' || langParam == 'en')) {
        _appState.setLanguage(langParam);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CookSmart',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: MainScaffold(appState: _appState),
    );
  }
}
