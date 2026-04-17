import 'package:flutter/material.dart';

/// Typography scale for Habit Tracker.
///
/// All methods are factory-style: pass an optional [color] and/or [size]
/// override; everything else (weight, height, letter-spacing) is opinionated
/// so screens stay visually consistent without extra boilerplate.
///
/// Scale (default sizes):
/// ```
/// display    28 px  w700  –0.5 ls  1.15 h   – hero numbers, splash titles
/// heading    22 px  w700  –0.4 ls  1.20 h   – section headers
/// title      18 px  w600  –0.3 ls  1.25 h   – card titles, modal headers
/// subheading 16 px  w500  –0.2 ls  1.30 h   – list item labels
/// body       15 px  w400   0.0 ls  1.55 h   – body copy
/// bodySmall  13 px  w400   0.0 ls  1.50 h   – secondary descriptions
/// label      13 px  w500   0.0 ls  1.30 h   – chips, tags, status badges
/// caption    11 px  w400  +0.2 ls  1.40 h   – timestamps, footnotes
/// ```
abstract final class AppTextStyles {
  // ── Display ───────────────────────────────────────────────────────────────
  /// Hero numbers and full-screen titles.
  static TextStyle display({Color? color, double size = 28}) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.15,
        color: color,
      );

  // ── Heading ───────────────────────────────────────────────────────────────
  /// Screen / section heading.
  static TextStyle heading({Color? color, double size = 22}) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.20,
        color: color,
      );

  // ── Title ─────────────────────────────────────────────────────────────────
  /// Card, tile, or modal title.
  static TextStyle title({Color? color, double size = 18}) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.25,
        color: color,
      );

  // ── Subheading ────────────────────────────────────────────────────────────
  /// List-item label or secondary header.
  static TextStyle subheading({Color? color, double size = 16}) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.2,
        height: 1.30,
        color: color,
      );

  // ── Body ──────────────────────────────────────────────────────────────────
  /// Primary body copy.
  static TextStyle body({Color? color, double size = 15}) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.55,
        color: color,
      );

  /// Smaller body copy — descriptions, hints.
  static TextStyle bodySmall({Color? color, double size = 13}) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.50,
        color: color,
      );

  // ── Label ─────────────────────────────────────────────────────────────────
  /// Chips, tags, status badges, button text.
  static TextStyle label({Color? color, double size = 13}) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1.30,
        color: color,
      );

  /// All-caps micro label — e.g. "STREAK", "DAYS LEFT".
  static TextStyle labelCaps({Color? color, double size = 11}) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        height: 1.30,
        color: color,
      );

  // ── Caption ───────────────────────────────────────────────────────────────
  /// Timestamps, footnotes, metadata.
  static TextStyle caption({Color? color, double size = 11}) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        height: 1.40,
        color: color,
      );

  // ── Numeric / Stat display ─────────────────────────────────────────────────
  /// Large stat number (e.g. streak count, completion %).
  static TextStyle stat({Color? color, double size = 36}) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        height: 1.0,
        color: color,
      );
}
