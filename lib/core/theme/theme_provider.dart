import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppThemeModeNotifier extends Notifier<ThemeMode> {
  static const _kPrefKey = 'app_theme_mode';

  @override
  ThemeMode build() {
    _loadFromPrefs();
    return ThemeMode.light;
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kPrefKey);
      if (saved != null) {
        switch (saved.toLowerCase()) {
          case 'dark':
            state = ThemeMode.dark;
            break;
          case 'system':
            state = ThemeMode.system;
            break;
          case 'light':
          default:
            state = ThemeMode.light;
            break;
        }
      }
    } catch (_) {}
  }

  void setThemeMode(String mode) {
    ThemeMode target;
    switch (mode.toLowerCase()) {
      case 'dark':
        target = ThemeMode.dark;
        break;
      case 'system':
        target = ThemeMode.system;
        break;
      case 'light':
      default:
        target = ThemeMode.light;
        break;
    }
    state = target;
    _saveToPrefs(mode.toLowerCase());
  }

  void setDirectThemeMode(ThemeMode mode) {
    state = mode;
    final str = mode == ThemeMode.dark
        ? 'dark'
        : (mode == ThemeMode.system ? 'system' : 'light');
    _saveToPrefs(str);
  }

  Future<void> _saveToPrefs(String mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPrefKey, mode);
    } catch (_) {}
  }
}

final appThemeModeProvider = NotifierProvider<AppThemeModeNotifier, ThemeMode>(
  AppThemeModeNotifier.new,
);

extension ThemeContextExtension on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get appBg => isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5FD);
  Color get appCard => isDark ? const Color(0xFF1E293B) : Colors.white;
  Color get appCardBorder =>
      isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  Color get appText => isDark ? Colors.white : const Color(0xFF0A1F44);
  Color get appTextMuted =>
      isDark ? const Color(0xFF94A3B8) : const Color(0xFF5F6F8A);
  Color get appDivider =>
      isDark ? const Color(0xFF334155) : const Color(0xFFF1F5FD);
}
