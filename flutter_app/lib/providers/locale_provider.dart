import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the app locale and persists it across restarts using SharedPreferences.
class LocaleProvider extends ChangeNotifier {
  static const _key = 'app_locale';

  Locale _locale = const Locale('de');
  Locale get locale => _locale;

  bool get isRtl => _locale.languageCode == 'ar';

  static const List<Locale> supportedLocales = [
    Locale('de'),
    Locale('en'),
    Locale('fr'),
    Locale('ar'),
  ];

  /// Load saved locale from SharedPreferences on startup.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  /// Change locale and persist the choice.
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
  }
}
