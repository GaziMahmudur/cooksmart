import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Obsidian Hearth Palette
  static const Color background = Color(0xFF121214);
  static const Color surfaceCard = Color(0xFF1E1E22);
  static const Color surfaceElevated = Color(0xFF26262B);
  static const Color surfaceHighlight = Color(0xFF28282E);

  // Accents
  static const Color primaryOrange = Color(0xFFFF7A00);
  static const Color primaryOrangeHover = Color(0xFFFF922B);
  static const Color amberGlow = Color(0xFFFFA843);
  static const Color successGreen = Color(0xFF22C55E);

  // Text & Borders
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFFA1A1AA);
  static const Color textSubtle = Color(0xFF71717A);
  static const Color borderSubtle = Color(0x14FFFFFF); // rgba(255, 255, 255, 0.08)
  static const Color borderMedium = Color(0x26FFFFFF); // rgba(255, 255, 255, 0.15)
}

class AppTheme {
  static ThemeData get darkTheme {
    final baseTextTheme = ThemeData.dark().textTheme;
    final plusJakartaTheme = GoogleFonts.plusJakartaSansTextTheme(baseTextTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryOrange,
        onPrimary: AppColors.textWhite,
        surface: AppColors.surfaceCard,
        onSurface: AppColors.textWhite,
      ),
      textTheme: plusJakartaTheme.apply(
        bodyColor: AppColors.textWhite,
        displayColor: AppColors.textWhite,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.textWhite,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
