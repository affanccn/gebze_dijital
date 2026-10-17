import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gebze_dijital/features/chatbot/chatbot.dart';
import 'package:gebze_dijital/features/chatbot/data/intent_matcher.dart';

void main() {
  group('Chatbot Intent Matcher Comprehensive Tests', () {
    test('Water Outage Intent Tests', () {
      final inputs = [
        'Suyum kesildi',
        'Sular kesildi',
        'Su ne zaman gelecek',
        'Musluktan su gelmiyor',
        'Gebze\'de su yok',
        'Su kesintisi var mı',
      ];

      for (final input in inputs) {
        final intent = IntentMatcher.match(input);
        expect(intent?.id, 'water_outage', reason: 'Failed on input: $input');
      }
    });

    test('Power Outage Intent Tests', () {
      final inputs = [
        'Elektrikler kesildi',
        'Sedaş arıza',
        'Elektrik ne zaman gelecek',
        'Elektrik arızası',
      ];

      for (final input in inputs) {
        final intent = IntentMatcher.match(input);
        expect(intent?.id, 'power_outage', reason: 'Failed on input: $input');
      }
    });

    test('Pharmacy Intent Tests', () {
      final inputs = [
        'Nöbetçi eczaneler',
        'Açık eczane',
        'Eczane nerede',
        'Bugün nöbetçi eczane hangisi',
        'Gece açık eczane',
      ];

      for (final input in inputs) {
        final intent = IntentMatcher.match(input);
        expect(intent?.id, 'pharmacies', reason: 'Failed on input: $input');
      }
    });

    test('Weather Intent Tests', () {
      final inputs = [
        'Hava durumu',
        'Bugün hava nasıl',
        'Yağmur yağacak mı',
        'Hava kaç derece',
      ];

      for (final input in inputs) {
        final intent = IntentMatcher.match(input);
        expect(intent?.id, 'weather', reason: 'Failed on input: $input');
      }
    });

    test('Neighborhood Works Intent Tests', () {
      final inputs = [
        'Mahallemde ne var',
        'Mahalle çalışmaları',
        'Sokağımda kazı var',
        'Yol çalışması nerede',
        'Altyapı çalışmaları',
      ];

      for (final input in inputs) {
        final intent = IntentMatcher.match(input);
        expect(intent?.id, 'neighborhood', reason: 'Failed on input: $input');
      }
    });

    test('Gebze Pati & Animals Intent Tests', () {
      final inputs = [
        'Gebze pati',
        'Kedi sahiplenme',
        'Köpek sahiplenme',
        'Yaralı kedi',
        'Hayvan ambulansı',
        'Mama noktaları',
      ];

      for (final input in inputs) {
        final intent = IntentMatcher.match(input);
        expect(intent?.id, 'animals', reason: 'Failed on input: $input');
      }
    });

    test('Parking Intent Tests', () {
      final inputs = [
        'Otopark nerede',
        'Arabayı nereye park edebilirim',
        'Boş otopark var mı',
        'Otopark doluluk oranları',
        'Kent meydanı otoparkı',
      ];

      for (final input in inputs) {
        final intent = IntentMatcher.match(input);
        expect(intent?.id, 'parking', reason: 'Failed on input: $input');
      }
    });

    test('Söz Sende Intent Tests', () {
      final inputs = [
        'Söz sende nedir',
        'Anketlere katıl',
        'Anket var mı',
        'Belediyeye önerim var',
        'Oy kullanmak istiyorum',
      ];

      for (final input in inputs) {
        final intent = IntentMatcher.match(input);
        expect(intent?.id, 'soz_sende', reason: 'Failed on input: $input');
      }
    });

    test('Report (Çek & Gönder) Intent Tests', () {
      final inputs = [
        'Talep oluştur',
        'Şikayetim var',
        'Sorun bildir',
        'Çek gönder',
        'Çöpler alınmadı',
      ];

      for (final input in inputs) {
        final intent = IntentMatcher.match(input);
        expect(intent?.id, 'report', reason: 'Failed on input: $input');
      }
    });

    test('My Requests Intent Tests', () {
      final inputs = [
        'Taleplerim nerede',
        'Başvurum ne durumda',
        'Şikayetimin sonucu',
        'Yaptığım başvurular',
      ];

      for (final input in inputs) {
        final intent = IntentMatcher.match(input);
        expect(intent?.id, 'my_requests', reason: 'Failed on input: $input');
      }
    });

    test('E-Belediye Intent Tests', () {
      final inputs = [
        'E-belediye',
        'Vergi ödeme',
        'Emlak vergisi nasıl ödenir',
        'Belediye borcu sorgulama',
        'İmar durumu belgesi',
      ];

      for (final input in inputs) {
        final intent = IntentMatcher.match(input);
        expect(intent?.id, 'ebelediye', reason: 'Failed on input: $input');
      }
    });

    test('Kent Lokantaları Intent Tests', () {
      final inputs = [
        'Kent lokantası nerede',
        'Belediye lokantası',
        'Kent lokantası menü',
        'Uygun yemek nerede',
      ];

      for (final input in inputs) {
        final intent = IntentMatcher.match(input);
        expect(intent?.id, 'kent_lokantasi', reason: 'Failed on input: $input');
      }
    });

    test('Semt Pazarları Intent Tests', () {
      final inputs = [
        'Bugün pazar nerede kuruluyor',
        'Gebze semt pazarları',
        'Cuma pazarı nerede',
        'Semt pazarı günleri',
      ];

      for (final input in inputs) {
        final intent = IntentMatcher.match(input);
        expect(intent?.id, 'markets', reason: 'Failed on input: $input');
      }
    });

    test('Accessibility Intent Tests', () {
      final inputs = [
        'Yazıları nasıl büyütebilirim',
        'Büyük yazı modu',
        'Yazılar çok küçük',
        'Erişilebilirlik ayarları',
      ];

      for (final input in inputs) {
        final intent = IntentMatcher.match(input);
        expect(intent?.id, 'accessibility', reason: 'Failed on input: $input');
      }
    });

    test('Emergency Intent Tests', () {
      final inputs = [
        'Acil toplanma alanı nerede',
        'Deprem toplanma alanları',
        'Acil durum numaraları',
      ];

      for (final input in inputs) {
        final intent = IntentMatcher.match(input);
        expect(intent?.id, 'emergency', reason: 'Failed on input: $input');
      }
    });

    test('Contact Intent Tests', () {
      final inputs = [
        'Belediyenin telefonu ne',
        'Belediyeye nasıl ulaşabilirim',
        'İletişim bilgileri',
      ];

      for (final input in inputs) {
        final intent = IntentMatcher.match(input);
        expect(intent?.id, 'contact', reason: 'Failed on input: $input');
      }
    });

    test('Easter Egg 82 Intent Tests', () {
      final inputs = ['Plaka 82', 'Gebze il olsun', '82 numara'];

      for (final input in inputs) {
        final intent = IntentMatcher.match(input);
        expect(intent?.id, 'easter_egg_82', reason: 'Failed on input: $input');
      }
    });

    test('Unknown Intent Tests', () {
      final inputs = ['Bugün ne pişirsem', 'Bitcoin ne kadar', 'Film öner'];

      for (final input in inputs) {
        final intent = IntentMatcher.match(input);
        expect(intent, isNull, reason: 'Expected null for input: $input');
      }
    });

    testWidgets(
      'Bot82Overlay opens ChatbotScreen on fab tap with navigatorKey',
      (tester) async {
        final navKey = GlobalKey<NavigatorState>();
        ChatbotNavigator.navigatorKey = navKey;

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              navigatorKey: navKey,
              builder: (context, child) =>
                  Bot82Overlay(navigatorKey: navKey, child: child!),
              home: const Scaffold(body: Center(child: Text('Home'))),
            ),
          ),
        );

        await tester.pump();
        expect(find.byType(Bot82Fab), findsOneWidget);

        await tester.tap(find.byType(Bot82Fab));
        await tester.pump(const Duration(milliseconds: 600));

        expect(find.byType(ChatbotScreen), findsOneWidget);
      },
    );
  });
}
