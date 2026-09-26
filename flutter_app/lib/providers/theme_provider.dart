import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages dark mode state and persists it across restarts.
class ThemeProvider extends ChangeNotifier {
  static const _key = 'dark_mode';

  bool _isDark = false;
  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  /// Load saved theme preference on startup.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool(_key) ?? false;
    notifyListeners();
  }

  /// Toggle dark mode and persist the choice.
  Future<void> toggle() async {
    _isDark = !_isDark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, _isDark);
  }

  Future<void> setDark(bool value) async {
    if (_isDark == value) return;
    _isDark = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, _isDark);
  }
}
