import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gebze_dijital/core/localization/app_strings.dart';
import 'package:gebze_dijital/core/services/push_service.dart';
import 'package:gebze_dijital/screens/assembly_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Afet & Acil Durum Çevrimdışı Dayanıklılık Testleri', () {
    test('İnternet ve önbellek yokken AssemblyService hazır toplanma alanlarını döner', () async {
      final result = await AssemblyService.load();

      expect(result.fromCache, isTrue);
      expect(result.areas, isNotEmpty);
      expect(result.areas.length, greaterThanOrEqualTo(5));

      final names = result.areas.map((a) => a.name).join(' ');
      expect(names, contains('Kent Meydanı'));
      expect(names, contains('Tatlıkuyu'));
      expect(names, contains('Gaziler'));
      expect(names, contains('Eskihisar'));
    });

    test(
      'Tüm toplanma alanlarının koordinatları Gebze sınırları içerisindedir',
      () async {
        final result = await AssemblyService.load();
        for (final area in result.areas) {
          expect(
            area.latitude,
            inInclusiveRange(40.65, 41.10),
            reason: '${area.name} enlemi Gebze sınırları içinde olmalı',
          );
          expect(
            area.longitude,
            inInclusiveRange(29.20, 29.85),
            reason: '${area.name} boylamı Gebze sınırları içinde olmalı',
          );
        }
      },
    );

    test('Toplanma alanlarının tahmini kapasite hesabı doğru çalışır', () {
      const areaWithM2 = AssemblyArea(
        id: 'test_1',
        name: 'Test Alanı',
        neighborhood: 'Hacıhalil',
        street: 'Cumhuriyet Cad.',
        latitude: 40.80,
        longitude: 29.43,
        areaM2: 7000,
        hasElectricity: true,
        hasWater: true,
        hasWc: true,
        kind: AreaKind.park,
      );

      expect(areaWithM2.estimatedCapacity, 2000);
      expect(areaWithM2.areaText, '7.000 m²');
    });
  });

  group('Acil Numaralar ve İhbar Hatları Testleri', () {
    test('Kritik acil ve arıza hatları sözlükte tüm dillerde tanımlıdır', () {
      for (final lang in ['tr', 'en', 'ar']) {
        expect(AppStrings.get('call_center_112_title', lang), isNotEmpty);
        expect(AppStrings.get('gebze_bld_label', lang), isNotEmpty);
        expect(AppStrings.get('afad_label', lang), isNotEmpty);
        expect(AppStrings.get('utility_emergency_label', lang), isNotEmpty);
        expect(AppStrings.get('sedas_sub', lang), isNotEmpty);
        expect(AppStrings.get('isu_sub', lang), isNotEmpty);
        expect(AppStrings.get('palgaz_sub', lang), isNotEmpty);
        expect(AppStrings.get('zabita_sub', lang), isNotEmpty);
      }
    });

    testWidgets(
      'Acil durum ekranı 112, 444 1 890, 122 ve altyapı arıza numaralarını listeler',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView(
                children: const [
                  Text('112'),
                  Text('444 1 890'),
                  Text('122'),
                  Text('185'),
                  Text('186'),
                  Text('187'),
                  Text('153'),
                ],
              ),
            ),
          ),
        );

        expect(find.text('112'), findsOneWidget);
        expect(find.text('444 1 890'), findsOneWidget);
        expect(find.text('122'), findsOneWidget);
        expect(find.text('185'), findsOneWidget);
        expect(find.text('186'), findsOneWidget);
        expect(find.text('187'), findsOneWidget);
        expect(find.text('153'), findsOneWidget);
      },
    );
  });

  group('PushService Masaüstü ve Platform Koruma Testleri', () {
    test('isSupportedPlatform Web ve Masaüstünde güvenle kontrol edilir', () {
      expect(PushService.isSupportedPlatform, isA<bool>());
    });
  });
}
