/// SMARTCARE+ Theme Configuration
///
/// Dark + Light futuristic themes with shared neon branding
library;

import 'package:flutter/material.dart';
import '../constants/colors.dart';

@immutable
class SmartCarePalette extends ThemeExtension<SmartCarePalette> {
  final List<Color> backgroundGradient;
  final Color background;
  final Color surface;
  final Color surfaceLight;
  final Color surfaceLighter;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color glassWhite;
  final Color glassBorder;

  const SmartCarePalette({
    required this.backgroundGradient,
    required this.background,
    required this.surface,
    required this.surfaceLight,
    required this.surfaceLighter,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.glassWhite,
    required this.glassBorder,
  });

  static const SmartCarePalette dark = SmartCarePalette(
    backgroundGradient: [
      Color(0xFF0A0E17),
      Color(0xFF0D1321),
      Color(0xFF111827),
    ],
    background: Color(0xFF0A0E17),
    surface: Color(0xFF111827),
    surfaceLight: Color(0xFF1F2937),
    surfaceLighter: Color(0xFF374151),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF9CA3AF),
    textMuted: Color(0xFF6B7280),
    glassWhite: Color(0x1AFFFFFF),
    glassBorder: Color(0x33FFFFFF),
  );

  static const SmartCarePalette light = SmartCarePalette(
    backgroundGradient: [
      Color(0xFFF5F7FC),
      Color(0xFFF1F4FA),
      Color(0xFFEBF0F9),
    ],
    background: Color(0xFFF4F7FC),
    surface: Color(0xFFFAFBFD),
    surfaceLight: Color(0xFFF0F4FA),
    surfaceLighter: Color(0xFFE3EAF4),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF1E293B),
    textMuted: Color(0xFF334155),
    glassWhite: Color(0xEAF8FAFF),
    glassBorder: Color(0x33334155),
  );

  @override
  SmartCarePalette copyWith({
    List<Color>? backgroundGradient,
    Color? background,
    Color? surface,
    Color? surfaceLight,
    Color? surfaceLighter,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? glassWhite,
    Color? glassBorder,
  }) {
    return SmartCarePalette(
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceLight: surfaceLight ?? this.surfaceLight,
      surfaceLighter: surfaceLighter ?? this.surfaceLighter,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      glassWhite: glassWhite ?? this.glassWhite,
      glassBorder: glassBorder ?? this.glassBorder,
    );
  }

  @override
  SmartCarePalette lerp(ThemeExtension<SmartCarePalette>? other, double t) {
    if (other is! SmartCarePalette) {
      return this;
    }

    return SmartCarePalette(
      backgroundGradient: List<Color>.generate(
        backgroundGradient.length,
        (index) => Color.lerp(
            backgroundGradient[index], other.backgroundGradient[index], t)!,
      ),
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceLight: Color.lerp(surfaceLight, other.surfaceLight, t)!,
      surfaceLighter: Color.lerp(surfaceLighter, other.surfaceLighter, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      glassWhite: Color.lerp(glassWhite, other.glassWhite, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
    );
  }
}

extension SmartCareThemeExt on BuildContext {
  SmartCarePalette get palette {
    return Theme.of(this).extension<SmartCarePalette>() ??
        SmartCarePalette.dark;
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData get darkFuturistic {
    const p = SmartCarePalette.dark;
    return _buildTheme(
      brightness: Brightness.dark,
      palette: p,
      colorScheme: ColorScheme.dark(
        primary: AppColors.neonCyan,
        secondary: AppColors.neonPurple,
        surface: p.surface,
        error: AppColors.neonRed,
        onPrimary: const Color(0xFF0A0E17),
        onSecondary: const Color(0xFFFFFFFF),
        onSurface: const Color(0xFFFFFFFF),
        onError: const Color(0xFFFFFFFF),
      ),
    );
  }

  static ThemeData get lightFuturistic {
    const p = SmartCarePalette.light;
    return _buildTheme(
      brightness: Brightness.light,
      palette: p,
      colorScheme: ColorScheme.light(
        primary: const Color(0xFF0E7490),
        secondary: const Color(0xFF7C3AED),
        surface: p.surface,
        error: AppColors.neonRed,
        onPrimary: const Color(0xFFFFFFFF),
        onSecondary: const Color(0xFFFFFFFF),
        onSurface: const Color(0xFF0F172A),
        onError: const Color(0xFFFFFFFF),
      ),
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required SmartCarePalette palette,
    required ColorScheme colorScheme,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: palette.background,
      colorScheme: colorScheme,
      extensions: [palette],
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: palette.textPrimary,
          letterSpacing: 1.5,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: palette.textPrimary,
          letterSpacing: 1.2,
        ),
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: palette.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: palette.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: palette.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: palette.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: palette.textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: palette.textPrimary,
          letterSpacing: 1.1,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.primary,
          letterSpacing: 1.5,
        ),
        iconTheme: IconThemeData(color: colorScheme.primary),
      ),
      cardTheme: CardThemeData(
        color: palette.glassWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: palette.glassBorder),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surfaceLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.neonRed, width: 2),
        ),
        labelStyle: TextStyle(color: palette.textSecondary),
        hintStyle: TextStyle(color: palette.textMuted),
        prefixIconColor: palette.textSecondary,
        suffixIconColor: palette.textSecondary,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: palette.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: palette.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 8,
        shape: const CircleBorder(),
      ),
      iconTheme: IconThemeData(color: palette.textSecondary, size: 24),
      dividerTheme: DividerThemeData(color: palette.glassBorder, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.surface,
        contentTextStyle: TextStyle(color: palette.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: palette.glassBorder),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: palette.glassBorder),
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: palette.textPrimary,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return palette.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withValues(alpha: 0.3);
          }
          return palette.surfaceLight;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(colorScheme.onPrimary),
        side: BorderSide(color: palette.textMuted, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: palette.surfaceLight,
        circularTrackColor: palette.surfaceLight,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: palette.surfaceLight,
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withValues(alpha: 0.2),
        trackHeight: 4,
      ),
    );
  }
}
