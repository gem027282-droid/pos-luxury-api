import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'luxury_colors.dart';

class LuxuryTheme {
  static ThemeData get darkLuxuryTheme {
    final baseTextTheme = ThemeData.dark().textTheme;
    final alexandriaTextTheme = GoogleFonts.alexandriaTextTheme(baseTextTheme).apply(
      bodyColor: LuxuryColors.textPrimary,
      displayColor: LuxuryColors.textPrimary,
    );

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: LuxuryColors.obsidianBackground,
      primaryColor: LuxuryColors.radiantGold,
      canvasColor: LuxuryColors.obsidianSurface,
      cardColor: LuxuryColors.obsidianCard,
      textTheme: alexandriaTextTheme,
      fontFamily: GoogleFonts.alexandria().fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: LuxuryColors.radiantGold,
        secondary: LuxuryColors.champagneGold,
        surface: LuxuryColors.obsidianSurface,
        error: LuxuryColors.imperialCrimson,
        onPrimary: Colors.black,
        onSurface: LuxuryColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.alexandria(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: LuxuryColors.radiantGold,
        ),
        iconTheme: const IconThemeData(color: LuxuryColors.radiantGold),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: LuxuryColors.obsidianCard,
        contentTextStyle: GoogleFonts.alexandria(color: LuxuryColors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: LuxuryColors.radiantGold, width: 0.8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
