import 'package:flutter/material.dart';

class AppColors {
  static const red = Color(0xFFE10600);
  static const redDark = Color(0xFFA30500);
  static const ink = Color(0xFF15151E);
  static const carbon = Color(0xFF1F1F2B);
  static const carbonLight = Color(0xFF2B2B38);
  static const outline = Color(0xFF3A3A48);
  static const muted = Color(0xFF9A9AA5);
  static const adminBackground = Color(0xFFF1F2F4);
  static const success = Color(0xFF1E8E3E);
  static const warning = Color(0xFFE8A200);
  static const gold = Color(0xFFD4AF37);
  static const silver = Color(0xFFB8BCC2);
  static const bronze = Color(0xFFB0703C);
}

/// Desktop (admin) uses a light theme for long data-entry sessions; mobile uses the dark F1 look from the mockups.
class AppTheme {
  static ThemeData admin() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.red,
      brightness: Brightness.light,
      primary: AppColors.red,
      onPrimary: Colors.white,
      surface: Colors.white,
    );
    return _base(scheme).copyWith(
      scaffoldBackgroundColor: AppColors.adminBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(AppColors.carbonLight),
        headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        dataRowMinHeight: 48,
        dataRowMaxHeight: 64,
        dividerThickness: 0.6,
      ),
      inputDecorationTheme: _inputTheme(fill: Colors.white, border: Colors.grey.shade400),
    );
  }

  static ThemeData mobile() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.red,
      brightness: Brightness.dark,
      primary: AppColors.red,
      onPrimary: Colors.white,
      surface: AppColors.carbon,
      onSurface: Colors.white,
    );
    return _base(scheme).copyWith(
      scaffoldBackgroundColor: AppColors.ink,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.carbon,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.outline),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.carbon,
        indicatorColor: AppColors.red.withValues(alpha: 0.18),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(color: states.contains(WidgetState.selected) ? AppColors.red : AppColors.muted),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            color: states.contains(WidgetState.selected) ? Colors.white : AppColors.muted,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
      inputDecorationTheme: _inputTheme(fill: AppColors.carbon, border: AppColors.outline),
    );
  }

  static ThemeData _base(ColorScheme scheme) => ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    visualDensity: VisualDensity.standard,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.red,
        foregroundColor: Colors.white,
        minimumSize: const Size(64, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );

  static InputDecorationTheme _inputTheme({required Color fill, required Color border}) => InputDecorationTheme(
    filled: true,
    fillColor: fill,
    errorMaxLines: 3,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.red, width: 1.6),
    ),
  );
}
