import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// Entry point for the app-wide Material theme.
///
/// Usage in [MaterialApp]:
/// ```dart
/// MaterialApp(
///   theme: AppTheme.light,
///   darkTheme: AppTheme.dark,
///   themeMode: ThemeMode.dark, // landing hub is always dark
/// )
/// ```
///
/// Both themes share the same accent colour (lime) and shape language; they
/// differ only in surface/text colours so screens can opt into either mode.
abstract final class AppTheme {
  // ── Dark theme ────────────────────────────────────────────────────────────

  static ThemeData get dark {
    const cs = _darkColorScheme;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: cs,
      scaffoldBackgroundColor: AppColors.bg,

      // ── App bar ──────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: AppTextStyles.title(color: AppColors.textPrimary),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),

      // ── Card ─────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.bg2,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.br16,
          side: const BorderSide(color: AppColors.borderDark),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Bottom sheet ─────────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.bg3,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
        modalElevation: 0,
      ),

      // ── Dialog ───────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.bg3,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.br24),
        titleTextStyle: AppTextStyles.title(color: AppColors.textPrimary),
        contentTextStyle: AppTextStyles.body(color: AppColors.textSecondary),
      ),

      // ── Text button / Elevated button / Outlined button ───────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lime,
          foregroundColor: AppColors.bg,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s24,
            vertical: AppSpacing.s14,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brFull),
          textStyle: AppTextStyles.label(size: 15),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.borderDark),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s20,
            vertical: AppSpacing.s12,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brFull),
          textStyle: AppTextStyles.label(),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.lime,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s12,
            vertical: AppSpacing.s8,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.br8),
          textStyle: AppTextStyles.label(),
        ),
      ),

      // ── Icon ─────────────────────────────────────────────────────────────
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: 22,
      ),

      // ── Input / TextField ────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bg3,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s14,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.br12,
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.br12,
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.br12,
          borderSide: const BorderSide(color: AppColors.lime, width: 1.5),
        ),
        hintStyle: AppTextStyles.body(color: AppColors.textMuted),
        labelStyle: AppTextStyles.label(color: AppColors.textSecondary),
      ),

      // ── Divider ──────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDark,
        thickness: 1,
        space: 1,
      ),

      // ── Chip ─────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.bg3,
        selectedColor: AppColors.limeBg,
        labelStyle: AppTextStyles.label(color: AppColors.textSecondary),
        side: const BorderSide(color: AppColors.borderDark),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brFull),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s10,
          vertical: AppSpacing.s4,
        ),
      ),

      // ── SnackBar ─────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.bg4,
        contentTextStyle: AppTextStyles.body(color: AppColors.textPrimary),
        actionTextColor: AppColors.lime,
        elevation: 4,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.br12),
      ),

      // ── Progress indicator ────────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.lime,
        linearTrackColor: AppColors.bg3,
      ),

      // ── Text theme ───────────────────────────────────────────────────────
      textTheme: _buildTextTheme(
        primary: AppColors.textPrimary,
        secondary: AppColors.textSecondary,
      ),
    );
  }

  // ── Light theme ───────────────────────────────────────────────────────────

  static ThemeData get light {
    const cs = _lightColorScheme;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: cs,
      scaffoldBackgroundColor: AppColors.canvas,

      // ── App bar ──────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: AppTextStyles.title(color: AppColors.ink),
        iconTheme: const IconThemeData(color: AppColors.ink),
      ),

      // ── Card ─────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.br16,
          side: const BorderSide(color: AppColors.borderLight),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Bottom sheet ─────────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
        modalElevation: 0,
      ),

      // ── Dialog ───────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.br24),
        titleTextStyle: AppTextStyles.title(color: AppColors.ink),
        contentTextStyle: AppTextStyles.body(color: AppColors.ink2),
      ),

      // ── Buttons ──────────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.purpleLight,
          foregroundColor: AppColors.surface,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s24,
            vertical: AppSpacing.s14,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brFull),
          textStyle: AppTextStyles.label(size: 15),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.borderLight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s20,
            vertical: AppSpacing.s12,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brFull),
          textStyle: AppTextStyles.label(),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.purpleLight,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s12,
            vertical: AppSpacing.s8,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.br8),
          textStyle: AppTextStyles.label(),
        ),
      ),

      // ── Icon ─────────────────────────────────────────────────────────────
      iconTheme: const IconThemeData(
        color: AppColors.ink2,
        size: 22,
      ),

      // ── Input / TextField ────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.canvas,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s14,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.br12,
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.br12,
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.br12,
          borderSide: const BorderSide(color: AppColors.purpleLight, width: 1.5),
        ),
        hintStyle: AppTextStyles.body(color: AppColors.ink3),
        labelStyle: AppTextStyles.label(color: AppColors.ink2),
      ),

      // ── Divider ──────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
        space: 1,
      ),

      // ── Chip ─────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.canvas,
        selectedColor: AppColors.purpleBgLight,
        labelStyle: AppTextStyles.label(color: AppColors.ink2),
        side: const BorderSide(color: AppColors.borderLight),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brFull),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s10,
          vertical: AppSpacing.s4,
        ),
      ),

      // ── SnackBar ─────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: AppTextStyles.body(color: AppColors.surface),
        actionTextColor: AppColors.lime,
        elevation: 4,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.br12),
      ),

      // ── Progress indicator ────────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.purpleLight,
        linearTrackColor: AppColors.borderLight,
      ),

      // ── Text theme ───────────────────────────────────────────────────────
      textTheme: _buildTextTheme(
        primary: AppColors.ink,
        secondary: AppColors.ink2,
      ),
    );
  }

  // ── Color schemes ─────────────────────────────────────────────────────────

  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    // Primary: lime accent used for CTAs and highlights.
    primary: AppColors.lime,
    onPrimary: AppColors.bg,
    primaryContainer: AppColors.limeBg,
    onPrimaryContainer: AppColors.lime,
    // Secondary: purple for category and sub-actions.
    secondary: AppColors.purple,
    onSecondary: AppColors.bg,
    secondaryContainer: AppColors.purpleBgDark,
    onSecondaryContainer: AppColors.purple,
    // Tertiary: teal for success / completion states.
    tertiary: AppColors.teal,
    onTertiary: AppColors.bg,
    tertiaryContainer: AppColors.tealBgDark,
    onTertiaryContainer: AppColors.teal,
    // Surface
    surface: AppColors.bg2,
    onSurface: AppColors.textPrimary,
    surfaceContainerHighest: AppColors.bg3,
    // Background
    error: AppColors.coral,
    onError: AppColors.bg,
    errorContainer: AppColors.coralBgDark,
    onErrorContainer: AppColors.coral,
    outline: AppColors.borderDark,
    outlineVariant: AppColors.textMuted,
  );

  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.purpleLight,
    onPrimary: AppColors.surface,
    primaryContainer: AppColors.purpleBgLight,
    onPrimaryContainer: AppColors.purpleLight,
    secondary: AppColors.teal,
    onSecondary: AppColors.surface,
    secondaryContainer: AppColors.tealBgLight,
    onSecondaryContainer: AppColors.tealDark,
    tertiary: AppColors.amber,
    onTertiary: AppColors.surface,
    tertiaryContainer: AppColors.amberBgLight,
    onTertiaryContainer: AppColors.amberDark,
    surface: AppColors.surface,
    onSurface: AppColors.ink,
    surfaceContainerHighest: AppColors.canvas,
    error: AppColors.coral,
    onError: AppColors.surface,
    errorContainer: AppColors.coralBgLight,
    onErrorContainer: AppColors.coralDark,
    outline: AppColors.borderLight,
    outlineVariant: AppColors.ink3,
  );

  // ── Text theme builder ────────────────────────────────────────────────────

  static TextTheme _buildTextTheme({
    required Color primary,
    required Color secondary,
  }) =>
      TextTheme(
        displayLarge: AppTextStyles.display(color: primary, size: 32),
        displayMedium: AppTextStyles.display(color: primary, size: 28),
        displaySmall: AppTextStyles.display(color: primary, size: 24),
        headlineLarge: AppTextStyles.heading(color: primary, size: 22),
        headlineMedium: AppTextStyles.heading(color: primary, size: 20),
        headlineSmall: AppTextStyles.title(color: primary, size: 18),
        titleLarge: AppTextStyles.title(color: primary, size: 18),
        titleMedium: AppTextStyles.subheading(color: primary, size: 16),
        titleSmall: AppTextStyles.subheading(color: secondary, size: 14),
        bodyLarge: AppTextStyles.body(color: primary, size: 16),
        bodyMedium: AppTextStyles.body(color: primary, size: 15),
        bodySmall: AppTextStyles.bodySmall(color: secondary, size: 13),
        labelLarge: AppTextStyles.label(color: primary, size: 14),
        labelMedium: AppTextStyles.label(color: secondary, size: 13),
        labelSmall: AppTextStyles.caption(color: secondary, size: 11),
      );
}
