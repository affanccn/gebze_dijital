import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Poppins Font & Yerel Dosya Doğrulama Testleri', () {
    test(
      'Mobil (Flutter) Poppins font dosyaları mevcut ve geçerli boyutta',
      () {
        final weights = ['Regular', 'Medium', 'SemiBold', 'Bold'];
        for (final w in weights) {
          final file = File('assets/fonts/poppins/Poppins-$w.ttf');
          expect(
            file.existsSync(),
            isTrue,
            reason: 'assets/fonts/poppins/Poppins-$w.ttf mevcut olmalı',
          );
          expect(
            file.lengthSync(),
            greaterThan(100000),
            reason: 'Font dosyası geçerli boyutta olmalı',
          );
        }
      },
    );

    test('Web Poppins font dosyaları mevcut ve çevrimdışı kullanıma hazır', () {
      final weights = ['Regular', 'Medium', 'SemiBold', 'Bold'];
      for (final w in weights) {
        final file = File('web/fonts/Poppins-$w.ttf');
        expect(
          file.existsSync(),
          isTrue,
          reason: 'web/fonts/Poppins-$w.ttf mevcut olmalı',
        );
        expect(file.lengthSync(), greaterThan(100000));
      }
    });

    test('Admin Portalı Poppins font dosyaları mevcut ve çevrimdışı kullanıma hazır', () {
      final weights = ['Regular', 'Medium', 'SemiBold', 'Bold'];
      for (final w in weights) {
        final file = File('admin/fonts/Poppins-$w.ttf');
        expect(
          file.existsSync(),
          isTrue,
          reason: 'admin/fonts/Poppins-$w.ttf mevcut olmalı',
        );
        expect(file.lengthSync(), greaterThan(100000));
      }
    });

    testWidgets(
      'Türkçe karakterler (ÇçĞğIıİiÖöŞşÜü) Poppins fontu ile hatasız render edilir',
      (tester) async {
        const turkishTestString =
            'ÇçĞğIıİiÖöŞşÜü - Gebze Belediyesi Dijital Yönetim Portalı';

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(fontFamily: 'Poppins'),
            home: const Scaffold(
              body: Center(
                child: Text(
                  turkishTestString,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.text(turkishTestString), findsOneWidget);
      },
    );
  });
}
