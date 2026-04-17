import 'package:flutter/material.dart';

/// Centralised colour palette for Habit Tracker.
///
/// Colours are split into three layers:
///   1. **Semantic aliases** – what colours _mean_ (bg, text, border, accent).
///   2. **Category colours** – the five habit-category tints (purple, coral,
///      teal, blue, amber), each with a main, dark, and two bg variants.
///   3. **Raw primitives** – the hex values that the semantic aliases point to.
///
/// Dark-mode tokens are the default because the landing/hub screen is dark.
/// Light-mode tokens are prefixed with "light" or live in [AppColorsLight].
abstract final class AppColors {
  // ── Dark backgrounds ──────────────────────────────────────────────────────
  static const Color bg = Color(0xFF171410);
  static const Color bg2 = Color(0xFF1E1B17);
  static const Color bg3 = Color(0xFF252118);
  static const Color bg4 = Color(0xFF2C2820);

  // ── Dark text ─────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF0EDE6);
  static const Color textSecondary = Color(0xFF9B9589);
  static const Color textMuted = Color(0xFF6E6860);

  // ── Light backgrounds ─────────────────────────────────────────────────────
  static const Color surface = Color(0xFFFFFFFF);
  static const Color canvas = Color(0xFFF6F3EC);

  // ── Light text ────────────────────────────────────────────────────────────
  static const Color ink = Color(0xFF1A1714);
  static const Color ink2 = Color(0xFF5C5650);
  static const Color ink3 = Color(0xFFA09890);

  // ── Borders ───────────────────────────────────────────────────────────────
  static const Color borderDark = Color(0x14FFFFFF);
  static const Color borderLight = Color(0xFFE2DDD4);

  // ── Brand accent ──────────────────────────────────────────────────────────
  static const Color lime = Color(0xFFE07B45);
  static const Color limeDark = Color(0xFFC45F28);
  static const Color limeBg = Color(0x1AE07B45);

  // ── Category: Purple ──────────────────────────────────────────────────────
  static const Color purple = Color(0xFF8B7FFF);
  static const Color purpleLight = Color(0xFF7C6FD8);
  static const Color purpleBgDark = Color(0xFF1E1A3C);
  static const Color purpleBgLight = Color(0xFFF0EEFF);

  // ── Category: Coral ───────────────────────────────────────────────────────
  static const Color coral = Color(0xFFFF6B47);
  static const Color coralDark = Color(0xFFD94E2E);
  static const Color coralBgDark = Color(0xFF3C1812);
  static const Color coralBgLight = Color(0xFFFFF0EE);

  // ── Category: Teal ───────────────────────────────────────────────────────
  static const Color teal = Color(0xFF00D4A0);
  static const Color tealDark = Color(0xFF00A880);
  static const Color tealBgDark = Color(0xFF082E26);
  static const Color tealBgLight = Color(0xFFE0FAF5);

  // ── Category: Blue ────────────────────────────────────────────────────────
  static const Color blue = Color(0xFF4DA6FF);
  static const Color blueDark = Color(0xFF2986E0);
  static const Color blueBgDark = Color(0xFF0D2040);
  static const Color blueBgLight = Color(0xFFE8F3FF);

  // ── Category: Amber ───────────────────────────────────────────────────────
  static const Color amber = Color(0xFFFFB830);
  static const Color amberDark = Color(0xFFD49010);
  static const Color amberBgDark = Color(0xFF2E2008);
  static const Color amberBgLight = Color(0xFFFFF5E0);

  // ── Status ────────────────────────────────────────────────────────────────
  static const Color success = teal;
  static const Color warning = amber;
  static const Color error = coral;

  // ── Convenience: category palette lookup ─────────────────────────────────
  /// Returns the five category colours in order: purple, coral, teal, blue, amber.
  static const List<Color> categoryColors = [
    purple,
    coral,
    teal,
    blue,
    amber,
  ];

  /// Returns the matching dark-mode background tint for a category colour.
  static Color categoryBgDark(Color c) {
    if (c == purple || c == purpleLight) return purpleBgDark;
    if (c == coral || c == coralDark) return coralBgDark;
    if (c == teal || c == tealDark) return tealBgDark;
    if (c == blue || c == blueDark) return blueBgDark;
    if (c == amber || c == amberDark) return amberBgDark;
    return c.withValues(alpha: 0.12);
  }

  /// Returns the matching light-mode background tint for a category colour.
  static Color categoryBgLight(Color c) {
    if (c == purple || c == purpleLight) return purpleBgLight;
    if (c == coral || c == coralDark) return coralBgLight;
    if (c == teal || c == tealDark) return tealBgLight;
    if (c == blue || c == blueDark) return blueBgLight;
    if (c == amber || c == amberDark) return amberBgLight;
    return c.withValues(alpha: 0.08);
  }
}
