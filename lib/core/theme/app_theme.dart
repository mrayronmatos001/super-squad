import 'package:flutter/material.dart';

/// Paleta "central de comando": fundo grafite profundo, painéis em azul-aço
/// e um âmbar de sinalização como cor de ação.
class AppColors {
  static const ink = Color(0xFF080B12);
  static const panel = Color(0xFF10151F);
  static const panelHigh = Color(0xFF182030);
  static const line = Color(0xFF243044);

  static const signal = Color(0xFFFFB020);
  static const signalDeep = Color(0xFFE07A00);

  static const textPrimary = Color(0xFFEDF1F7);
  static const textMuted = Color(0xFF8A96AB);

  static const success = Color(0xFF3DDC97);
  static const danger = Color(0xFFFF4D5E);
  static const warning = Color(0xFFFFD23F);

  // Moldura vermelha das cartas, inspirada no modelo dos slides.
  static const cardFrameLight = Color(0xFFE63946);
  static const cardFrameDark = Color(0xFF8E0413);
  static const cardInner = Color(0xFF0D1830);
}

class AppTheme {
  static const displayFont = 'ChakraPetch';

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.signal,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.signal,
      onPrimary: Colors.black,
      secondary: AppColors.signal,
      surface: AppColors.panel,
      onSurface: AppColors.textPrimary,
      error: AppColors.danger,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    TextStyle display(double size, FontWeight weight) => TextStyle(
          fontFamily: displayFont,
          fontSize: size,
          fontWeight: weight,
          color: AppColors.textPrimary,
          height: 1.1,
        );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.ink,
      textTheme: base.textTheme.copyWith(
        displaySmall: display(36, FontWeight.w700),
        headlineMedium: display(28, FontWeight.w700),
        headlineSmall: display(24, FontWeight.w700),
        titleLarge: display(21, FontWeight.w700),
        titleMedium: display(17, FontWeight.w600),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
        bodySmall: base.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: display(22, FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        color: AppColors.panel,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.signal,
          foregroundColor: Colors.black,
          disabledBackgroundColor: AppColors.panelHigh,
          disabledForegroundColor: AppColors.textMuted,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: display(17, FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size.fromHeight(56),
          side: const BorderSide(color: AppColors.line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: display(17, FontWeight.w600),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.panelHigh,
        contentTextStyle: TextStyle(color: AppColors.textPrimary),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.signal),
      dividerColor: AppColors.line,
    );
  }
}
