import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _key = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  bool _disposed = false;

  ThemeProvider() {
    _load();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_key);
      if (stored != null) {
        _themeMode = ThemeMode.values.firstWhere(
          (m) => m.name == stored,
          orElse: () => ThemeMode.dark,
        );
        _safeNotify();
      }
    } catch (_) {
      // SharedPreferences unavailable — keep default dark theme
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    _safeNotify();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.name);
    } catch (_) {
      // Persistence failed — in-memory theme is still updated
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
