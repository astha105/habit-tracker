import 'package:flutter/material.dart';

/// Spacing scale and border-radius tokens for Habit Tracker.
///
/// Use [AppSpacing] for raw numeric values (margins, gaps, padding amounts)
/// and [AppRadius] for [BorderRadius] / [Radius] constants.
///
/// Spacing scale (multiples of 4):
/// ```
/// s2   2 px
/// s4   4 px
/// s6   6 px
/// s8   8 px
/// s10  10 px
/// s12  12 px
/// s14  14 px
/// s16  16 px
/// s20  20 px
/// s24  24 px
/// s28  28 px
/// s32  32 px
/// s40  40 px
/// s48  48 px
/// s64  64 px
/// ```
abstract final class AppSpacing {
  static const double s2 = 2;
  static const double s4 = 4;
  static const double s6 = 6;
  static const double s8 = 8;
  static const double s10 = 10;
  static const double s12 = 12;
  static const double s14 = 14;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s28 = 28;
  static const double s32 = 32;
  static const double s40 = 40;
  static const double s48 = 48;
  static const double s64 = 64;

  // ── Semantic aliases ──────────────────────────────────────────────────────

  /// Horizontal edge padding for full-width screens.
  static const double screenH = s20;

  /// Vertical edge padding for full-width screens.
  static const double screenV = s24;

  /// Internal padding for cards and list tiles.
  static const double cardPad = s16;

  /// Vertical gap between sections on a page.
  static const double sectionGap = s32;

  /// Vertical gap between list items.
  static const double itemGap = s12;

  /// Inline gap between an icon and its label.
  static const double iconGap = s8;

  // ── EdgeInsets presets ────────────────────────────────────────────────────

  /// Standard horizontal screen margin.
  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(horizontal: screenH);

  /// Full screen padding (horizontal + vertical).
  static const EdgeInsets pagePadding =
      EdgeInsets.symmetric(horizontal: screenH, vertical: screenV);

  /// Standard card / tile internal padding.
  static const EdgeInsets cardPadding = EdgeInsets.all(cardPad);

  /// Comfortable symmetric padding for bottom sheets and modals.
  static const EdgeInsets sheetPadding =
      EdgeInsets.symmetric(horizontal: s24, vertical: s20);
}

/// Border-radius tokens.
///
/// ```
/// r4    4 px – subtle rounding (dividers, small chips)
/// r8    8 px – small chips, tags
/// r12  12 px – compact cards
/// r16  16 px – standard cards
/// r20  20 px – large cards, bottom sheet corners
/// r24  24 px – modals, prominent surfaces
/// r32  32 px – pill buttons with large text
/// r100 full pill / circle
/// ```
abstract final class AppRadius {
  static const double r4 = 4;
  static const double r8 = 8;
  static const double r12 = 10;
  static const double r16 = 10;
  static const double r20 = 10;
  static const double r24 = 10;
  static const double r32 = 10;
  static const double r100 = 100;

  // ── BorderRadius shortcuts ────────────────────────────────────────────────
  static final BorderRadius br4 = BorderRadius.circular(r4);
  static final BorderRadius br8 = BorderRadius.circular(r8);
  static final BorderRadius br12 = BorderRadius.circular(r12);
  static final BorderRadius br16 = BorderRadius.circular(r16);
  static final BorderRadius br20 = BorderRadius.circular(r20);
  static final BorderRadius br24 = BorderRadius.circular(r24);
  static final BorderRadius br32 = BorderRadius.circular(r32);
  static final BorderRadius brFull = BorderRadius.circular(r100);

  // ── Bottom-sheet top-rounded shortcut ─────────────────────────────────────
  static final BorderRadius sheetTop = const BorderRadius.vertical(
    top: Radius.circular(16),
  );
}
