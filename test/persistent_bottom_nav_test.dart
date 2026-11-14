import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gebze_dijital/screens/app_bottom_nav.dart';
import 'package:gebze_dijital/screens/guest_home_screen.dart';
import 'package:gebze_dijital/core/localization/app_strings.dart';
import 'package:gebze_dijital/screens/auth_service.dart';

void main() {
  group('Persistent Bottom Navigation Bar Tests', () {
    testWidgets('AppBottomNav renders 5 tabs and indicates active tab', (
      tester,
    ) async {
      int selectedTab = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: StatefulBuilder(
              builder: (context, setState) {
                return AppBottomNav(
                  index: selectedTab,
                  lang: 'tr',
                  onTap: (i) {
                    setState(() => selectedTab = i);
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(AppBottomNav), findsOneWidget);
      expect(find.text(AppStrings.get('nav_home', 'tr')), findsOneWidget);
      expect(find.text(AppStrings.get('nav_guide', 'tr')), findsOneWidget);
      expect(find.text(AppStrings.get('nav_report', 'tr')), findsOneWidget);
      expect(find.text(AppStrings.get('nav_services', 'tr')), findsOneWidget);
      expect(find.text(AppStrings.get('nav_profile', 'tr')), findsOneWidget);

      // Tap on Rehber (tab 1)
      await tester.tap(find.text(AppStrings.get('nav_guide', 'tr')));
      await tester.pump();
      expect(selectedTab, 1);

      // Tap on Hizmetler (tab 3)
      await tester.tap(find.text(AppStrings.get('nav_services', 'tr')));
      await tester.pump();
      expect(selectedTab, 3);
    });

    testWidgets(
      'GuestHomeScreen maintains single fixed AppBottomNav across tab switches',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              isLoggedInProvider.overrideWith((ref) => true),
            ],
            child: const MaterialApp(
              home: GuestHomeScreen(),
            ),
          ),
        );

        await tester.pump();

        // Exactly one AppBottomNav must exist in the widget tree
        expect(find.byType(AppBottomNav), findsOneWidget);
        expect(find.byType(IndexedStack), findsOneWidget);

        final indexedStackBefore = tester.widget<IndexedStack>(
          find.byType(IndexedStack),
        );
        expect(indexedStackBefore.index, 0);

        // Tap on Services (Hizmetler) tab
        await tester.tap(find.text(AppStrings.get('nav_services', 'tr')));
        await tester.pump();

        // AppBottomNav is STILL exactly one, unchanged, never disposed
        expect(find.byType(AppBottomNav), findsOneWidget);

        final indexedStackAfter = tester.widget<IndexedStack>(
          find.byType(IndexedStack),
        );
        expect(indexedStackAfter.index, 3);
      },
    );
  });
}
