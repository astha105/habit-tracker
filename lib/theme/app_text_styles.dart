import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTextStyles {
  static TextStyle display({Color? color, double size = 28}) =>
      GoogleFonts.dmSans(
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.20,
        color: color,
      );

  static TextStyle heading({Color? color, double size = 22}) =>
      GoogleFonts.dmSans(
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
        height: 1.25,
        color: color,
      );

  static TextStyle title({Color? color, double size = 18}) =>
      GoogleFonts.dmSans(
        fontSize: size,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.30,
        color: color,
      );

  static TextStyle subheading({Color? color, double size = 16}) =>
      GoogleFonts.dmSans(
        fontSize: size,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1.35,
        color: color,
      );

  static TextStyle body({Color? color, double size = 15}) =>
      GoogleFonts.dmSans(
        fontSize: size,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.60,
        color: color,
      );

  static TextStyle bodySmall({Color? color, double size = 13}) =>
      GoogleFonts.dmSans(
        fontSize: size,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.55,
        color: color,
      );

  static TextStyle label({Color? color, double size = 13}) =>
      GoogleFonts.dmSans(
        fontSize: size,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.30,
        color: color,
      );

  static TextStyle labelCaps({Color? color, double size = 11}) =>
      GoogleFonts.dmSans(
        fontSize: size,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
        height: 1.30,
        color: color,
      );

  static TextStyle caption({Color? color, double size = 11}) =>
      GoogleFonts.dmSans(
        fontSize: size,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.3,
        height: 1.45,
        color: color,
      );

  static TextStyle stat({Color? color, double size = 36}) =>
      GoogleFonts.dmSans(
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.0,
        color: color,
      );
}
