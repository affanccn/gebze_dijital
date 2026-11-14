import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLargeFontNotifier extends Notifier<bool> {
  static const _kPrefKey = 'app_large_font';
  bool _userChanged = false;

  @override
  bool build() {
    _loadFromPrefs();
    return false;
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool(_kPrefKey);
      if (!_userChanged && saved != null && saved != state) {
        state = saved;
      }
    } catch (_) {}
  }

  void setLargeFont(bool isLarge) {
    _userChanged = true;
    if (state != isLarge) {
      state = isLarge;
    }
    _saveToPrefs(isLarge);
  }

  void toggle() {
    setLargeFont(!state);
  }

  Future<void> _saveToPrefs(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kPrefKey, value);
    } catch (_) {}
  }
}

final appLargeFontProvider = NotifierProvider<AppLargeFontNotifier, bool>(
  AppLargeFontNotifier.new,
);
