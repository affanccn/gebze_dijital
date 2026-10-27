import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gebze_dijital/core/theme/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Theme Mode & Provider Tests', () {
    test('appThemeModeProvider defaults to ThemeMode.light', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(appThemeModeProvider), equals(ThemeMode.light));
    });

    test('setThemeMode updates state to dark and saves to prefs', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(appThemeModeProvider.notifier).setThemeMode('dark');
      expect(container.read(appThemeModeProvider), equals(ThemeMode.dark));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_theme_mode'), equals('dark'));
    });

    test('setThemeMode updates state to system and saves to prefs', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(appThemeModeProvider.notifier).setThemeMode('system');
      expect(container.read(appThemeModeProvider), equals(ThemeMode.system));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_theme_mode'), equals('system'));
    });

    test('setDirectThemeMode updates state properly', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(appThemeModeProvider.notifier)
          .setDirectThemeMode(ThemeMode.dark);
      expect(container.read(appThemeModeProvider), equals(ThemeMode.dark));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_theme_mode'), equals('dark'));
    });

    testWidgets('ThemeContextExtension returns correct dark and light colors', (
      tester,
    ) async {
      late BuildContext lightCtx;
      late BuildContext darkCtx;

      await tester.pumpWidget(
        MaterialApp(
          home: Theme(
            data: ThemeData.light(),
            child: Builder(
              builder: (ctx) {
                lightCtx = ctx;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(lightCtx.isDark, isFalse);
      expect(lightCtx.appBg, equals(const Color(0xFFF1F5FD)));
      expect(lightCtx.appCard, equals(Colors.white));
      expect(lightCtx.appText, equals(const Color(0xFF0A1F44)));

      await tester.pumpWidget(
        MaterialApp(
          home: Theme(
            data: ThemeData(brightness: Brightness.dark),
            child: Builder(
              builder: (ctx) {
                darkCtx = ctx;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(darkCtx.isDark, isTrue);
      expect(darkCtx.appBg, equals(const Color(0xFF0F172A)));
      expect(darkCtx.appCard, equals(const Color(0xFF1E293B)));
      expect(darkCtx.appCardBorder, equals(const Color(0xFF334155)));
      expect(darkCtx.appText, equals(Colors.white));
    });
  });
}
