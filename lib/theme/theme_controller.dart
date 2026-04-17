import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages and persists the user's theme preference.
///
/// Usage — read current mode anywhere:
/// ```dart
/// ThemeController.instance.value  // ThemeMode
/// ```
///
/// Usage — change theme from a settings screen:
/// ```dart
/// await ThemeController.instance.setMode(ThemeMode.light);
/// ```
///
/// Initialise once before [runApp]:
/// ```dart
/// await ThemeController.instance.init();
/// runApp(const MyApp());
/// ```
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController._() : super(ThemeMode.system);

  static final ThemeController instance = ThemeController._();

  static const _prefKey = 'app_theme_mode';

  /// Loads the persisted preference (defaults to [ThemeMode.system]).
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    value = _fromString(saved);
  }

  /// Persists and applies [mode].
  Future<void> setMode(ThemeMode mode) async {
    value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, _toString(mode));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static ThemeMode _fromString(String? s) => switch (s) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  static String _toString(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
}
