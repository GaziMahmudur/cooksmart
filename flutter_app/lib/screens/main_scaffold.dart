import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav_bar.dart';
import 'home_screen.dart';
import 'ingredients_screen.dart';
import 'ask_chef_screen.dart';
import 'saved_screen.dart';

class MainScaffold extends StatelessWidget {
  final AppState appState;

  const MainScaffold({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final screens = [
          HomeScreen(appState: appState),
          IngredientsScreen(appState: appState),
          AskChefScreen(appState: appState),
          SavedScreen(appState: appState),
        ];

        final isLargeScreen = MediaQuery.of(context).size.width > 600;
        final content = Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: appState.currentTabIndex,
                children: screens,
              ),
            ),
            BottomNavBar(
              currentIndex: appState.currentTabIndex,
              onTabSelected: (index) => appState.setTab(index),
              language: appState.language,
            ),
          ],
        );

        return Scaffold(
          backgroundColor: AppColors.background,
          body: isLargeScreen
              ? Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        border: Border.symmetric(
                          vertical: BorderSide(color: AppColors.borderSubtle),
                        ),
                      ),
                      child: content,
                    ),
                  ),
                )
              : content,
        );
      },
    );
  }
}
