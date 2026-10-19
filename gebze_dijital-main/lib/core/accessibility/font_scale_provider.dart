import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global accessibility state for large font / high readability mode.
/// When enabled, all texts, buttons, and content scale up across the entire application
/// for senior citizens and users with visual impairments.
class AppLargeFontNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setLargeFont(bool isLarge) {
    if (state != isLarge) {
      state = isLarge;
    }
  }

  void toggle() {
    state = !state;
  }
}

final appLargeFontProvider = NotifierProvider<AppLargeFontNotifier, bool>(
  AppLargeFontNotifier.new,
);
