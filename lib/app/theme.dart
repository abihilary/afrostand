import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.orange,
        brightness: Brightness.light,
      ),
    );

    return base.copyWith(
      // Dual-font system: Plus Jakarta Sans for titles, Inter for body
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          textStyle: base.textTheme.displayLarge,
          fontWeight: FontWeight.w800,
          color: AppColors.dark,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          textStyle: base.textTheme.displayMedium,
          fontWeight: FontWeight.w800,
          color: AppColors.dark,
        ),
        displaySmall: GoogleFonts.plusJakartaSans(
          textStyle: base.textTheme.displaySmall,
          fontWeight: FontWeight.w800,
          color: AppColors.dark,
        ),
        headlineLarge: GoogleFonts.plusJakartaSans(
          textStyle: base.textTheme.headlineLarge,
          fontWeight: FontWeight.w800,
          color: AppColors.dark,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          textStyle: base.textTheme.headlineMedium,
          fontWeight: FontWeight.w800,
          color: AppColors.dark,
        ),
        headlineSmall: GoogleFonts.plusJakartaSans(
          textStyle: base.textTheme.headlineSmall,
          fontWeight: FontWeight.w800,
          color: AppColors.dark,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          textStyle: base.textTheme.titleLarge,
          fontWeight: FontWeight.w700,
          color: AppColors.dark,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          textStyle: base.textTheme.titleMedium,
          fontWeight: FontWeight.w700,
          color: AppColors.dark,
        ),
        titleSmall: GoogleFonts.plusJakartaSans(
          textStyle: base.textTheme.titleSmall,
          fontWeight: FontWeight.w700,
          color: AppColors.dark,
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.dark,
        elevation: 0,
        centerTitle: false,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.dark,
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          side: const BorderSide(color: Color(0x1A000000)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0x1A000000)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0x1A000000)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.dark,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        hintStyle: const TextStyle(
          color: Color(0x66121212),
          fontSize: 14,
        ),
      ),
    );
  }
}
