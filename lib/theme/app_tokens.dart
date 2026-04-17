// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

/// Single source of truth for all adaptive UI tokens used across every screen.
///
/// Resolves automatically from a [BuildContext]:
/// ```dart
/// final t = AppTokens.of(context);
/// ```
/// Or construct directly with a brightness flag:
/// ```dart
/// final t = AppTokens(isDark);
/// ```
class AppTokens {
  final bool isDark;
  const AppTokens(this.isDark);

  /// Reads the current brightness from [ctx] and returns the tokens.
  static AppTokens of(BuildContext ctx) =>
      AppTokens(Theme.of(ctx).brightness == Brightness.dark);

  // ── Backgrounds ────────────────────────────────────────────────────────────
  Color get bg  => isDark ? const Color(0xFF0E0E18) : const Color(0xFFFAFAF8);
  Color get bg2 => isDark ? const Color(0xFF151522) : Colors.white;
  Color get bg3 => isDark ? const Color(0xFF1C1C2E) : const Color(0xFFF0EEF8);
  Color get bg4 => isDark ? const Color(0xFF23233A) : const Color(0xFFF0EEFF);

  // Aliases used by templates_screen (bg2/txt2 under friendlier names).
  Color get card => bg2;
  Color get sub  => txt2;

  // ── Text ───────────────────────────────────────────────────────────────────
  Color get txt  => isDark ? const Color(0xFFF0EFF8) : const Color(0xFF0D0D1A);
  Color get txt2 => isDark ? const Color(0xFF8A88A8) : const Color(0xFF5C5870);
  Color get txt3 => isDark ? const Color(0xFF6A6888) : const Color(0xFF9B97AA);

  // ── Borders ────────────────────────────────────────────────────────────────
  Color get border => isDark ? const Color(0x18FFFFFF) : const Color(0xFFE6E4F0);

  // ── Accent — purple in both modes (lighter in dark) ───────────────────────
  Color get accent => isDark ? const Color(0xFF9D8FFF) : const Color(0xFF7C6FD8);

  // ── Special amber surfaces (daily check-ins) ───────────────────────────────
  Color get amberBg     => isDark ? const Color(0xFF2E1F00) : const Color(0xFFFFF8E8);
  Color get amberBorder => amber.withOpacity(isDark ? 0.30 : 0.40);

  // ── Category bg tints ──────────────────────────────────────────────────────
  Color categoryBg(Color color) {
    if (color == purple) return isDark ? const Color(0x1A8B7FFF) : const Color(0xFFF0EEFF);
    if (color == coral)  return isDark ? const Color(0x1AFF6B47) : const Color(0xFFFFF0EE);
    if (color == teal)   return isDark ? const Color(0x1A00D4A0) : const Color(0xFFE0FAF5);
    if (color == blue)   return isDark ? const Color(0x1A4DA6FF) : const Color(0xFFE8F3FF);
    if (color == amber)  return isDark ? const Color(0x1AFFB830) : const Color(0xFFFFF5E0);
    return color.withOpacity(isDark ? 0.10 : 0.08);
  }

  // ── Category colours (same in both modes) ──────────────────────────────────
  static const Color purple = Color(0xFF8B7FFF);
  static const Color coral  = Color(0xFFFF6B47);
  static const Color teal   = Color(0xFF00D4A0);
  static const Color blue   = Color(0xFF4DA6FF);
  static const Color amber  = Color(0xFFFFB830);

  // ── Spacing ────────────────────────────────────────────────────────────────
  static const double s4  = 4;
  static const double s5  = 5;
  static const double s8  = 8;
  static const double s10 = 10;
  static const double s12 = 12;
  static const double s14 = 14;
  static const double s16 = 16;
  static const double s18 = 18;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s40 = 40;
  static const double s64 = 64;

  // ── Border radii ───────────────────────────────────────────────────────────
  static const double r8   = 8;
  static const double r12  = 12;
  static const double r16  = 16;
  static const double r20  = 20;
  static const double r24  = 24;
  static const double r100 = 100;

  // ── Text styles ────────────────────────────────────────────────────────────
  TextStyle heading({double size = 24, double spacing = -1.0}) => TextStyle(
    fontSize: size, fontWeight: FontWeight.w700, color: txt,
    height: 1.1, letterSpacing: spacing,
  );

  TextStyle body({double size = 14, Color? color}) => TextStyle(
    fontSize: size, color: color ?? txt2, height: 1.6, letterSpacing: -0.1,
  );

  TextStyle label({double size = 11, Color? color}) => TextStyle(
    fontSize: size, fontWeight: FontWeight.w500,
    color: color ?? txt3, letterSpacing: 0.06 * size,
  );
}
