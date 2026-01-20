import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// FairShare - Modern Finance App Theme
/// Sophisticated Dark Slate & Teal Palette
class AppColors {
  // Primary Colors - Deep Teal/Cyan (Professional & Trustworthy)
  static const Color teal50 = Color(0xFFECFDF5);
  static const Color teal100 = Color(0xFFD1FAE5);
  static const Color teal200 = Color(0xFFA7F3D0);
  static const Color teal300 = Color(0xFF6EE7B7);
  static const Color teal400 = Color(0xFF34D399);
  static const Color teal500 = Color(0xFF10B981);
  static const Color teal600 = Color(0xFF0D9488); // Main Brand - Teal
  static const Color teal700 = Color(0xFF0F766E);
  static const Color teal800 = Color(0xFF115E59);
  static const Color teal900 = Color(0xFF134E4A);

  // Secondary Colors - Soft Purple (Premium Touch)
  static const Color purple500 = Color.fromARGB(255, 7, 5, 11);
  static const Color purple600 = Color(0xFF7C3AED); // Main Brand Purple
  static const Color purple700 = Color(0xFF6D28D9);

  // Neutral Colors - Warm Dark Slate (Modern & Readable)
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral200 = Color(0xFFE5E5E5);
  static const Color neutral300 = Color(0xFFD4D4D4);
  static const Color neutral400 = Color(0xFFA3A3A3);
  static const Color neutral500 = Color(0xFF737373);
  static const Color neutral600 = Color(0xFF525252); // Body Text
  static const Color neutral700 = Color(0xFF404040); // Headings
  static const Color neutral800 = Color(0xFF262626); // Cards Dark
  static const Color neutral900 = Color(0xFF171717); // Background Dark

  // Success Colors - Mint Green (You're Owed)
  static const Color success50 = Color(0xFFF0FDF4);
  static const Color success100 = Color(0xFFDCFCE7);
  static const Color success500 = Color(0xFF22C55E); // Softer Green
  static const Color success600 = Color(0xFF16A34A);

  // Danger Colors - Coral Red (You Owe)
  static const Color danger50 = Color(0xFFFEF2F2);
  static const Color danger100 = Color(0xFFFEE2E2);
  static const Color danger500 = Color(0xFFF87171); // Softer Red
  static const Color danger600 = Color(0xFFEF4444);

  // Warning Colors - Warm Amber
  static const Color warning50 = Color(0xFFFFFBEB);
  static const Color warning100 = Color(0xFFFEF3C7);
  static const Color warning500 = Color(0xFFFBBF24); // Softer Orange
  static const Color warning600 = Color(0xFFF59E0B);

  // Info Colors - Blue
  static const Color info50 = Color(0xFFEFF6FF);
  static const Color info500 = Color(0xFF60A5FA);

  // Legacy compatibility - Map old names to new colors
  @Deprecated('Use teal50 instead')
  static const Color primaryBlue50 = teal50;
  @Deprecated('Use teal100 instead')
  static const Color primaryBlue100 = teal100;
  @Deprecated('Use teal200 instead')
  static const Color primaryBlue200 = teal200;
  @Deprecated('Use teal300 instead')
  static const Color primaryBlue300 = teal300;
  @Deprecated('Use teal400 instead')
  static const Color primaryBlue400 = teal400;
  @Deprecated('Use teal500 instead')
  static const Color primaryBlue500 = teal500;
  @Deprecated('Use teal600 instead')
  static const Color primaryBlue600 = teal600; // Main Brand
  @Deprecated('Use teal700 instead')
  static const Color primaryBlue700 = teal700;
  @Deprecated('Use teal800 instead')
  static const Color primaryBlue800 = teal800;
  @Deprecated('Use teal900 instead')
  static const Color primaryBlue900 = teal900;

  @Deprecated('Use purple500 instead')
  static const Color indigo500 = purple500;
  @Deprecated('Use purple600 instead')
  static const Color indigo600 = purple600;
  @Deprecated('Use purple700 instead')
  static const Color indigo700 = purple700;

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [teal600, purple600],
  );

  static const LinearGradient emergencyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [warning500, danger500],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [success500, Color(0xFF10B981)],
  );

  // Shadow Colors
  static Color shadowLight = teal600.withOpacity(0.08);
  static Color shadowMedium = teal600.withOpacity(0.15);
  static Color shadowDark = neutral900.withOpacity(0.1);

  // Background
  static const Color background = neutral50;
  static const Color surface = Colors.white;
  static const Color surfaceVariant = neutral100;

  // Text Colors
  static const Color textPrimary = neutral700;
  static const Color textSecondary = neutral500;
  static const Color textTertiary = neutral400;
  static const Color textDisabled = neutral300;
  static const Color textOnPrimary = Colors.white;
  static const Color textOnDark = neutral100;

  static const Color border = neutral200;
  static const Color primaryLight = teal50;

  // Additional danger colors
  static const Color danger200 = Color(0xFFFECACA);
  static const Color danger700 = Color(0xFFC81E1E);

  // Additional info colors
  static const Color info700 = Color(0xFF1E40AF);

  static Color? get primary50 => null;
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color Scheme
      colorScheme: ColorScheme.light(
        primary: AppColors.teal600,
        onPrimary: AppColors.textOnPrimary,
        secondary: AppColors.purple600,
        onSecondary: AppColors.textOnPrimary,
        error: AppColors.danger500,
        onError: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surfaceVariant,
        outline: AppColors.border,
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColors.background,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: AppColors.shadowLight,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),

      // Text Theme
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
          displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.4,
          ),
          displaySmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
          headlineLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
          headlineSmall: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: -0.1,
          ),
          titleLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          titleMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          titleSmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: AppColors.textPrimary,
            height: 1.5,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          labelMedium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
          labelSmall: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.textTertiary,
          ),
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shadowColor: AppColors.shadowLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.border, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal600,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.teal600,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: BorderSide(
            color: AppColors.teal600.withOpacity(0.3),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.teal600,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.teal600, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger500, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger500, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: const TextStyle(
          color: AppColors.textTertiary,
          fontWeight: FontWeight.normal,
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.teal600,
        unselectedItemColor: AppColors.neutral400,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.teal600,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: CircleBorder(),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.teal50,
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 24),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: const ColorScheme.dark(
        primary: AppColors.teal500,
        onPrimary: Colors.white,
        secondary: AppColors.purple500,
        onSecondary: Colors.white,
        error: AppColors.danger500,
        onError: Colors.white,
        surface: AppColors.neutral800,
        onSurface: AppColors.textOnDark,
        outline: AppColors.neutral700,
      ),

      scaffoldBackgroundColor: AppColors.neutral900,

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.neutral900,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme.apply(
          bodyColor: AppColors.textOnDark,
          displayColor: Colors.white,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.neutral800,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.neutral700, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal600,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.neutral800,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.neutral700, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.neutral700, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.teal500, width: 2),
        ),
        hintStyle: const TextStyle(color: AppColors.neutral500),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.neutral900,
        selectedItemColor: AppColors.teal500,
        unselectedItemColor: AppColors.neutral500,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.neutral700,
        thickness: 1,
      ),
    );
  }
}
