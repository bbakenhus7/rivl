// utils/theme.dart

import 'package:flutter/material.dart';

class RivlColors {
  // Primary colors
  static const Color primary = Color(0xFF3399FF);
  static const Color primaryDark = Color(0xFF2277DD);
  static const Color primaryLight = Color(0xFF66B2FF);

  // Secondary colors
  static const Color secondary = Color(0xFFFF6B5B);
  static const Color secondaryDark = Color(0xFFE55A4A);

  // Light theme colors
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF0F0F0);
  static const Color lightTextPrimary = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF6C757D);

  // Dark theme colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E2E);
  static const Color darkSurfaceVariant = Color(0xFF2A2A3E);
  static const Color darkTextPrimary = Color(0xFFE8E8E8);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class RivlTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Colors
      colorScheme: const ColorScheme.light(
        primary: RivlColors.primary,
        secondary: RivlColors.secondary,
        surface: RivlColors.lightSurface,
        error: RivlColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: RivlColors.lightTextPrimary,
        onError: Colors.white,
      ),

      scaffoldBackgroundColor: RivlColors.lightBackground,

      // Text theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: RivlColors.lightTextPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: RivlColors.lightTextPrimary,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: RivlColors.lightTextPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: RivlColors.lightTextPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: RivlColors.lightTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: RivlColors.lightTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: RivlColors.lightTextPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: RivlColors.lightTextSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: RivlColors.lightTextPrimary,
        ),
      ),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: RivlColors.lightSurface,
        foregroundColor: RivlColors.lightTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: RivlColors.lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: RivlColors.lightTextPrimary),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: RivlColors.lightSurface,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: RivlColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: RivlColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: RivlColors.primary, width: 2),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: RivlColors.primary,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: RivlColors.lightSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: RivlColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: RivlColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: const TextStyle(color: RivlColors.lightTextSecondary),
        labelStyle: const TextStyle(color: RivlColors.lightTextSecondary),
      ),

      // Bottom navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: RivlColors.lightSurface,
        selectedItemColor: RivlColors.primary,
        unselectedItemColor: RivlColors.lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Tab bar
      tabBarTheme: const TabBarThemeData(
        labelColor: RivlColors.primary,
        unselectedLabelColor: RivlColors.lightTextSecondary,
        indicatorColor: RivlColors.primary,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: RivlColors.lightSurfaceVariant,
        selectedColor: RivlColors.primary.withOpacity(0.2),
        labelStyle: const TextStyle(color: RivlColors.lightTextPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Progress indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: RivlColors.primary,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: RivlColors.lightSurfaceVariant,
        thickness: 1,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: RivlColors.lightTextPrimary,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: RivlColors.lightTextPrimary,
      ),

      // List tile theme
      listTileTheme: const ListTileThemeData(
        textColor: RivlColors.lightTextPrimary,
        iconColor: RivlColors.lightTextSecondary,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Colors
      colorScheme: const ColorScheme.dark(
        primary: RivlColors.primaryLight,
        secondary: RivlColors.secondary,
        surface: RivlColors.darkSurface,
        error: RivlColors.error,
        onPrimary: RivlColors.darkBackground,
        onSecondary: Colors.white,
        onSurface: RivlColors.darkTextPrimary,
        onError: Colors.white,
        background: RivlColors.darkBackground,
      ),

      scaffoldBackgroundColor: RivlColors.darkBackground,

      // Text theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: RivlColors.darkTextPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: RivlColors.darkTextPrimary,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: RivlColors.darkTextPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: RivlColors.darkTextPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: RivlColors.darkTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: RivlColors.darkTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: RivlColors.darkTextPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: RivlColors.darkTextSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: RivlColors.darkTextPrimary,
        ),
      ),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: RivlColors.darkSurface,
        foregroundColor: RivlColors.darkTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: RivlColors.darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: RivlColors.darkTextPrimary),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: RivlColors.darkSurface,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: RivlColors.primaryLight,
          foregroundColor: RivlColors.darkBackground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: RivlColors.primaryLight,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: RivlColors.primaryLight, width: 2),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: RivlColors.primaryLight,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: RivlColors.darkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: RivlColors.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: RivlColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: const TextStyle(color: RivlColors.darkTextSecondary),
        labelStyle: const TextStyle(color: RivlColors.darkTextSecondary),
      ),

      // Bottom navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: RivlColors.darkSurface,
        selectedItemColor: RivlColors.primaryLight,
        unselectedItemColor: RivlColors.darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Tab bar
      tabBarTheme: const TabBarThemeData(
        labelColor: RivlColors.primaryLight,
        unselectedLabelColor: RivlColors.darkTextSecondary,
        indicatorColor: RivlColors.primaryLight,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: RivlColors.darkSurfaceVariant,
        selectedColor: RivlColors.primaryLight.withOpacity(0.2),
        labelStyle: const TextStyle(color: RivlColors.darkTextPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Progress indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: RivlColors.primaryLight,
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: RivlColors.darkSurfaceVariant.withOpacity(0.5),
        thickness: 1,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: RivlColors.darkSurfaceVariant,
        contentTextStyle: const TextStyle(color: RivlColors.darkTextPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: RivlColors.darkTextPrimary,
      ),

      // List tile theme
      listTileTheme: const ListTileThemeData(
        textColor: RivlColors.darkTextPrimary,
        iconColor: RivlColors.darkTextSecondary,
      ),
    );
  }
}

// Helper extensions for accessing theme-aware colors
extension ThemeContext on BuildContext {
  // Text colors that adapt to theme
  Color get textPrimary => Theme.of(this).brightness == Brightness.light
      ? RivlColors.lightTextPrimary
      : RivlColors.darkTextPrimary;

  Color get textSecondary => Theme.of(this).brightness == Brightness.light
      ? RivlColors.lightTextSecondary
      : RivlColors.darkTextSecondary;

  Color get surface => Theme.of(this).brightness == Brightness.light
      ? RivlColors.lightSurface
      : RivlColors.darkSurface;

  Color get surfaceVariant => Theme.of(this).brightness == Brightness.light
      ? RivlColors.lightSurfaceVariant
      : RivlColors.darkSurfaceVariant;
}

// Text styles - Now theme-aware!
// Use Theme.of(context).textTheme instead of these static styles
@Deprecated('Use Theme.of(context).textTheme.displayLarge instead')
class RivlTextStyles {
  // These are deprecated - use Theme.of(context).textTheme instead
  // Keeping for backward compatibility but they won't adapt to dark mode
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontSize: 16,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 14,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle stat = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
  );
}
