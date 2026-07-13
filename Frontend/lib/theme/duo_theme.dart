import 'package:flutter/material.dart';

class DuoColors {
  const DuoColors._();

  static const primaryYellow = Color(0xFFFACC15); // Tailwind yellow-400
  static const darkYellow = Color(0xFFEAB308); // Tailwind yellow-500
  static const tactileShadow = Color(0xFFC99D00); // Tactile button shadow
  static const background = Color(0xFFFFFDF7);
  static const card = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF0F172A); // Tailwind slate-900
  static const textSecondary = Color(0xFF475569); // Tailwind slate-600
  static const success = Color(0xFF15803D); // Tailwind green-700
  static const lockedGray = Color(0xFFE2E8F0); // Tailwind slate-200
  static const lockedShadow = Color(0xFFCBD5E1); // Shadow for locked button
  static const softYellow = Color(0xFFFEFCE8); // Tailwind yellow-50
  static const border = Color(0xFFFEF08A); // Tailwind yellow-200
}

class DuoTheme {
  const DuoTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      scaffoldBackgroundColor: DuoColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: DuoColors.primaryYellow,
        brightness: Brightness.light,
        primary: DuoColors.primaryYellow,
        secondary: DuoColors.success,
        surface: DuoColors.card,
      ),
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        headlineSmall: const TextStyle(
          color: DuoColors.textPrimary,
          fontSize: 30,
          fontWeight: FontWeight.w900,
          height: 1.05,
        ),
        titleLarge: const TextStyle(
          color: DuoColors.textPrimary,
          fontSize: 25,
          fontWeight: FontWeight.w900,
          height: 1.08,
        ),
        titleMedium: const TextStyle(
          color: DuoColors.textPrimary,
          fontSize: 19,
          fontWeight: FontWeight.w900,
          height: 1.1,
        ),
        bodyMedium: const TextStyle(
          color: DuoColors.textSecondary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          backgroundColor: DuoColors.primaryYellow,
          foregroundColor: Colors.white,
          disabledBackgroundColor: DuoColors.lockedGray,
          disabledForegroundColor: DuoColors.textSecondary,
          elevation: 0,
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}
