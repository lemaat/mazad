import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';
import 'typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryBlue,
      secondary: AppColors.accentYellow,
      error: AppColors.error,
      surface: AppColors.surfaceWhite,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surfaceWhite,
      foregroundColor: AppColors.neutralDark,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: AppTypography.title.copyWith(color: AppColors.neutralDark),
    ),
    textTheme: TextTheme(
      titleMedium: AppTypography.title.copyWith(color: AppColors.neutralDark),
      bodyMedium: AppTypography.body.copyWith(color: AppColors.neutralDark),
      bodySmall: AppTypography.caption.copyWith(color: AppColors.neutralGray),
      labelSmall: AppTypography.label.copyWith(color: AppColors.neutralGray),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.surfaceWhite,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AppTypography.title,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      labelTextStyle: WidgetStateProperty.all(
        AppTypography.label.copyWith(overflow: TextOverflow.ellipsis),
      ),
    ),
    dividerColor: AppColors.borderLight,
  );

  static ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accentYellow,
      secondary: AppColors.primaryBlue,
      error: AppColors.error,
      surface: AppColors.surfaceDark,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surfaceDark,
      foregroundColor: AppColors.textLight,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: AppTypography.title.copyWith(color: AppColors.textLight),
    ),
    textTheme: TextTheme(
      titleMedium: AppTypography.title.copyWith(color: AppColors.textLight),
      bodyMedium: AppTypography.body.copyWith(color: AppColors.textLight),
      bodySmall: AppTypography.caption.copyWith(color: AppColors.secondaryText),
      labelSmall: AppTypography.label.copyWith(color: AppColors.secondaryText),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentYellow,
        foregroundColor: AppColors.neutralDark,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AppTypography.title,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      labelTextStyle: WidgetStateProperty.all(
        AppTypography.label.copyWith(overflow: TextOverflow.ellipsis),
      ),
    ),
    dividerColor: AppColors.borderDark,
  );
}
