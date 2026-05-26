import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary:          AppColors.coffeeBrown,
      onPrimary:        Colors.white,
      primaryContainer: AppColors.creamDark,
      onPrimaryContainer: AppColors.coffeeDark,
      secondary:        AppColors.caramel,
      onSecondary:      Colors.white,
      secondaryContainer: Color(0xFFFFF3E0),
      onSecondaryContainer: AppColors.coffeeDark,
      surface:          AppColors.surface,
      onSurface:        AppColors.textPrimary,
      error:            AppColors.error,
      onError:          Colors.white,
    );

    final textTheme = GoogleFonts.poppinsTextTheme().copyWith(
      displayLarge:  GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      displayMedium: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      headlineLarge: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      headlineMedium:GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      headlineSmall: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      titleLarge:    GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      titleMedium:   GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
      bodyLarge:     GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
      bodyMedium:    GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
      bodySmall:     GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textHint),
      labelLarge:    GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.cream,

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.coffeeBrown,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 2,
        shadowColor: AppColors.coffeeBrown.withOpacity(0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(0),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.coffeeBrown,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.coffeeBrown,
          side: const BorderSide(color: AppColors.coffeeBrown, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.creamDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0D0C0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.caramel, width: 2),
        ),
        labelStyle: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 14),
        hintStyle: GoogleFonts.poppins(color: AppColors.textHint, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.creamDark,
        selectedColor: AppColors.coffeeBrown,
        labelStyle: GoogleFonts.poppins(fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.coffeeBrown,
        unselectedItemColor: AppColors.textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0xFFEEE0D0),
        thickness: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.coffeeDark,
        contentTextStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
