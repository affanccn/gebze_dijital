import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gebze_dijital/core/accessibility/font_scale_provider.dart';

void main() {
  group('Accessibility & Large Font Tests', () {
    test('appLargeFontProvider defaults to false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(appLargeFontProvider), isFalse);
    });

    test('setLargeFont updates the large font state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(appLargeFontProvider.notifier).setLargeFont(true);
      expect(container.read(appLargeFontProvider), isTrue);

      container.read(appLargeFontProvider.notifier).setLargeFont(false);
      expect(container.read(appLargeFontProvider), isFalse);
    });

    test('toggle flips the state correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(appLargeFontProvider), isFalse);
      container.read(appLargeFontProvider.notifier).toggle();
      expect(container.read(appLargeFontProvider), isTrue);
      container.read(appLargeFontProvider.notifier).toggle();
      expect(container.read(appLargeFontProvider), isFalse);
    });
  });
}
