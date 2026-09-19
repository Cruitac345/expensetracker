// SPDX-License-Identifier: BSD-3-Clause
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Настройки приложения: схема оформления и вид диаграмм дашборда.
class SettingsController extends ChangeNotifier {
  SettingsController({ThemeMode themeMode = ThemeMode.system})
    : _themeMode = themeMode;

  static const String _themeKey = 'theme_mode';

  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  /// Читает сохранённые настройки; при ошибке остаются значения по умолчанию.
  Future<void> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? stored = prefs.getString(_themeKey);
      _themeMode = ThemeMode.values.firstWhere(
        (ThemeMode mode) => mode.name == stored,
        orElse: () => ThemeMode.system,
      );
      notifyListeners();
    } on Exception {
      _themeMode = ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) {
      return;
    }
    _themeMode = mode;
    notifyListeners();
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode.name);
    } on Exception {
      // Настройка не сохранилась.
    }
  }

  String get themeModeLabel => switch (_themeMode) {
    ThemeMode.system => 'Как в системе',
    ThemeMode.light => 'Светлая',
    ThemeMode.dark => 'Тёмная',
  };
}
