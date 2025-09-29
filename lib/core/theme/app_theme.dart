import 'package:flutter/material.dart';
import 'app_theme_constants.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppThemeConstants.primaryColor,
      primary: AppThemeConstants.primaryColor,
      secondary: AppThemeConstants.secondaryColor,
      error: AppThemeConstants.errorColor,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: AppThemeConstants.backgroundColor,

    // Card styling
    cardColor: AppThemeConstants.cardColor,
    cardTheme: CardThemeData(
      color: AppThemeConstants.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppThemeConstants.cardRadius),
      ),
      margin: EdgeInsets.all(AppThemeConstants.pagePadding),
    ),

    // AppBar
    appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),

    // Text themes
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontSize: AppThemeConstants.titleFontSize,
        fontWeight: FontWeight.w600,
        color: AppThemeConstants.secondaryColor,
      ),
      titleMedium: TextStyle(
        fontSize: AppThemeConstants.subtitleFontSize,
        fontWeight: FontWeight.w500,
        color: AppThemeConstants.secondaryColor,
      ),
      bodyMedium: TextStyle(
        fontSize: AppThemeConstants.bodyFontSize,
        color: AppThemeConstants.secondaryColor,
      ),
    ),

    // Elevated button theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppThemeConstants.primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppThemeConstants.buttonRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),

    // Icon theme
    iconTheme: const IconThemeData(
      color: AppThemeConstants.secondaryColor,
      size: 24,
    ),
  );
}
