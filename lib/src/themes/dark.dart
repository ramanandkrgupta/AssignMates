import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color voidBlack = Color(0xFF000000);
  static const Color eerieBlack = Color(0xFF121212);
  static const Color cardSurface = Color(0xFF1E1E1E);
  
  // Premium Accents
  static const Color electricViolet = Color(0xFFBB86FC);
  static const Color cyberBlue = Color(0xFF03DAC6); // Secondary
  static const Color errorRed = Color(0xFFCF6679);
}

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.eerieBlack,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.electricViolet,
    secondary: AppColors.cyberBlue,
    surface: AppColors.cardSurface,
    error: AppColors.errorRed,
    onPrimary: Colors.black,
    onSecondary: Colors.black,
    onSurface: Colors.white,
  ),
  textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent, // For glass effect or blend 
    elevation: 0,
    centerTitle: true,
    titleTextStyle: GoogleFonts.outfit(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
  ),
  cardTheme: CardThemeData(
    color: AppColors.cardSurface,
    elevation: 4,
    shadowColor: Colors.black26,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white.withOpacity(0.05),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.electricViolet),
    ),
    labelStyle: const TextStyle(color: Colors.white70),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.electricViolet,
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
);
