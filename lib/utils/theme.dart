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
  
  // Neutral colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F0F0);
  
  // Text colors
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textLight = Color(0xFFFFFFFF);
  
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
        surface: RivlColors.surface,
        error: RivlColors.error,
      ),
      
      scaffoldBackgroundColor: RivlColors.background,
      
      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: RivlColors.surface,
        foregroundColor: RivlColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: RivlColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      
      // Cards
      cardTheme: CardThemeData(
        color: RivlColors.surface,
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
        fillColor: RivlColors.surfaceVariant,
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
        hintStyle: const TextStyle(color: RivlColors.textSecondary),
      ),
      
      // Bottom navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: RivlColors.surface,
        selectedItemColor: RivlColors.primary,
        unselectedItemColor: RivlColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // Tab bar
      tabBarTheme: const TabBarThemeData(
        labelColor: RivlColors.primary,
        unselectedLabelColor: RivlColors.textSecondary,
        indicatorColor: RivlColors.primary,
      ),
      
      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: RivlColors.surfaceVariant,
        selectedColor: RivlColors.primary.withOpacity(0.2),
        labelStyle: const TextStyle(color: RivlColors.textPrimary),
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
        color: RivlColors.surfaceVariant,
        thickness: 1,
      ),
      
      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: RivlColors.textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      colorScheme: const ColorScheme.dark(
        primary: RivlColors.primary,
        secondary: RivlColors.secondary,
        surface: Color(0xFF1E1E2E),
        error: RivlColors.error,
      ),
      
      scaffoldBackgroundColor: const Color(0xFF121212),
      
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E2E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E2E),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A3E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// Text styles
class RivlTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: RivlColors.textPrimary,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: RivlColors.textPrimary,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: RivlColors.textPrimary,
  );
  
  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: RivlColors.textPrimary,
  );
  
  static const TextStyle bodySecondary = TextStyle(
    fontSize: 16,
    color: RivlColors.textSecondary,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 14,
    color: RivlColors.textSecondary,
  );
  
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  
  static const TextStyle stat = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: RivlColors.primary,
  );
}
