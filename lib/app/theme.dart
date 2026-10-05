import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      cardColor: Colors.white,
      dividerColor: Colors.black.withOpacity(0.05),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.orange,
        brightness: Brightness.light,
        surface: Colors.white,
        onSurface: AppColors.dark,
        primary: AppColors.dark,
        secondary: AppColors.orange,
      ),
    );

    return _buildTheme(base);
  }

  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      cardColor: const Color(0xFF161616),
      dividerColor: Colors.white.withOpacity(0.05),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.orange,
        brightness: Brightness.dark,
        surface: const Color(0xFF121212),
        onSurface: Colors.white,
        primary: AppColors.orange,
        secondary: AppColors.sand,
      ),
    );

    return _buildTheme(base);
  }

  static ThemeData _buildTheme(ThemeData base) {
    final isDark = base.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.dark;
    final secondaryTextColor = isDark ? Colors.white60 : Colors.black45;

    return base.copyWith(
      // Dual-font system
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          textStyle: base.textTheme.displayLarge,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          textStyle: base.textTheme.displayMedium,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
        displaySmall: GoogleFonts.plusJakartaSans(
          textStyle: base.textTheme.displaySmall,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
        headlineLarge: GoogleFonts.plusJakartaSans(
          textStyle: base.textTheme.headlineLarge,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          textStyle: base.textTheme.headlineMedium,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
        headlineSmall: GoogleFonts.plusJakartaSans(
          textStyle: base.textTheme.headlineSmall,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          textStyle: base.textTheme.titleLarge,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          textStyle: base.textTheme.titleMedium,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        titleSmall: GoogleFonts.plusJakartaSans(
          textStyle: base.textTheme.titleSmall,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(color: textColor),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(color: textColor),
        bodySmall: base.textTheme.bodySmall?.copyWith(color: secondaryTextColor),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF0A0A0A) : AppColors.background,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: false,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? AppColors.orange : AppColors.dark,
          foregroundColor: isDark ? AppColors.dark : AppColors.white,
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
          side: BorderSide(color: isDark ? Colors.white24 : const Color(0x1A000000)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1A1A1A) : AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? Colors.white10 : const Color(0x1A000000)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? Colors.white10 : const Color(0x1A000000)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? AppColors.orange : AppColors.dark,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        hintStyle: TextStyle(
          color: isDark ? Colors.white38 : const Color(0x66121212),
          fontSize: 14,
        ),
      ),
    );
  }
}
