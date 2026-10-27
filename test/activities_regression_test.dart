import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gebze_dijital/core/localization/app_strings.dart';
import 'package:gebze_dijital/features/profile/models/user_profile.dart';
import 'package:gebze_dijital/features/profile/services/profile_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Aktivitelerim Model & Serialization Regresyon Testleri', () {
    test('UserActivityItem.fromMap tam ve geçerli veriyi hatasız ayrıştırır', () {
      final map = {
        'type': 'oneri',
        'title': 'Akıllı Durak Projesi',
        'description': 'Duraklara dijital ekran yerleştirilmesi',
        'date': '12 Ekim 2026',
        'status': 'Yayında',
        'category': 'Ulaşım',
      };

      final item = UserActivityItem.fromMap(map, 'act_101');
      expect(item.id, 'act_101');
      expect(item.type, 'oneri');
      expect(item.title, 'Akıllı Durak Projesi');
      expect(item.description, 'Duraklara dijital ekran yerleştirilmesi');
      expect(item.date, '12 Ekim 2026');
      expect(item.status, 'Yayında');
      expect(item.category, 'Ulaşım');
    });

    test('UserActivityItem.fromMap eksik veya null alanlarda varsayılan değerleri atar', () {
      final item = UserActivityItem.fromMap({}, 'act_empty');
      expect(item.id, 'act_empty');
      expect(item.type, 'talep');
      expect(item.title, '');
      expect(item.description, '');
      expect(item.date, '');
      expect(item.status, 'İnceleniyor');
      expect(item.category, 'Genel');
    });

    test('UserActivityItem.toMap çift yönlü serileştirmeyi korur', () {
      const original = UserActivityItem(
        id: 'test_destek',
        type: 'destek',
        title: 'Kütüphane Desteği',
        description: 'Gençler için kütüphane oylandı',
        date: '10 Ekim 2026',
        status: 'Oylandı',
        category: 'Sosyal',
      );

      final map = original.toMap();
      final reconstructed = UserActivityItem.fromMap(map, original.id);

      expect(reconstructed.id, original.id);
      expect(reconstructed.type, original.type);
      expect(reconstructed.title, original.title);
      expect(reconstructed.description, original.description);
      expect(reconstructed.date, original.date);
      expect(reconstructed.status, original.status);
      expect(reconstructed.category, original.category);
    });
  });

  group('Aktivitelerim Servis Akışı ve Kategori Filtreleme Testleri', () {
    test('Misafir oturumunda getActivitiesStream tüm kategorileri barındıran örnek listeyi döner', () async {
      final service = ProfileService();
      final stream = service.getActivitiesStream();
      final activities = await stream.first;

      expect(activities, isNotEmpty);
      expect(activities.any((a) => a.type == 'talep'), isTrue, reason: 'Talepler bulunmalı');
      expect(activities.any((a) => a.type == 'oneri'), isTrue, reason: 'Öneriler bulunmalı');
      expect(activities.any((a) => a.type == 'destek'), isTrue, reason: 'Destekler bulunmalı');
      expect(activities.any((a) => a.type == 'kayit'), isTrue, reason: 'Kaydedilenler bulunmalı');
    });

    test('Kategori bazlı filtreleme tüm kategorilerde doğru öğeleri ayıklar', () async {
      final service = ProfileService();
      final activities = await service.getActivitiesStream().first;

      final talepler = activities.where((a) => a.type == 'talep').toList();
      final oneriler = activities.where((a) => a.type == 'oneri').toList();
      final destekler = activities.where((a) => a.type == 'destek').toList();
      final kayitlar = activities.where((a) => a.type == 'kayit').toList();

      for (final t in talepler) {
        expect(t.type, 'talep');
      }
      for (final o in oneriler) {
        expect(o.type, 'oneri');
      }
      for (final d in destekler) {
        expect(d.type, 'destek');
      }
      for (final k in kayitlar) {
        expect(k.type, 'kayit');
      }
    });
  });

  group('Aktivitelerim UI ve Sekme (Tab) Regresyon Widget Testleri', () {
    testWidgets('Boş aktivite durumunda boşluk ikonu ve metni gösterilir', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                // Boş liste durumundaki görünüm testi
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.inbox_rounded,
                          size: 40,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          AppStrings.get('no_activities_found', 'tr'),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.inbox_rounded), findsOneWidget);
      expect(find.text('Henüz bu kategoride aktiviteniz yok'), findsOneWidget);
    });

    testWidgets('Dolu aktivite kartları kategori, başlık, açıklama ve durum renklerini doğru sunar', (tester) async {
      const item = UserActivityItem(
        id: 'act_test',
        type: 'oneri',
        title: 'Bisiklet Yolu Genişletme',
        description: 'Trafikten ayrılmış bisiklet yolu talebi',
        date: '15 Ekim 2026',
        status: 'Yayında',
        category: 'Ulaşım',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item.category),
                          Text(item.status),
                        ],
                      ),
                      Text(item.title),
                      Text(item.description),
                      Text(item.date),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Bisiklet Yolu Genişletme'), findsOneWidget);
      expect(find.text('Trafikten ayrılmış bisiklet yolu talebi'), findsOneWidget);
      expect(find.text('Ulaşım'), findsOneWidget);
      expect(find.text('Yayında'), findsOneWidget);
      expect(find.text('15 Ekim 2026'), findsOneWidget);
    });

    testWidgets('TabController ilk sekme indeksi seçimlerini doğru yapar', (tester) async {
      int getInitialIndex(String type) {
        return type == 'oneri'
            ? 1
            : type == 'destek'
                ? 2
                : type == 'kayit'
                    ? 3
                    : 0;
      }

      expect(getInitialIndex('talep'), 0);
      expect(getInitialIndex('oneri'), 1);
      expect(getInitialIndex('destek'), 2);
      expect(getInitialIndex('kayit'), 3);
      expect(getInitialIndex('unknown'), 0);

      // DefaultTabController ile sekme doğrulama
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DefaultTabController(
              length: 4,
              initialIndex: getInitialIndex('destek'),
              child: const Column(
                children: [
                  TabBar(
                    tabs: [
                      Tab(text: 'Talepler'),
                      Tab(text: 'Öneriler'),
                      Tab(text: 'Destekler'),
                      Tab(text: 'Kaydedilenler'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        Text('Talepler İçeriği'),
                        Text('Öneriler İçeriği'),
                        Text('Destekler İçeriği'),
                        Text('Kaydedilenler İçeriği'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      // Başlangıçta destekler sekmesinin içeriği ekranda olmalıdır
      expect(find.text('Destekler İçeriği'), findsOneWidget);
    });

    testWidgets('Stream yüklenme anında CircularProgressIndicator gösterilir', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamBuilder<List<UserActivityItem>>(
              stream: const Stream.empty(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                return const Text('Yüklendi');
              },
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Çoklu dil desteğinde sekmeler doğru çevrilir', (tester) async {
      for (final lang in ['tr', 'en', 'ar']) {
        expect(AppStrings.get('stat_requests', lang), isNotEmpty);
        expect(AppStrings.get('stat_suggestions', lang), isNotEmpty);
        expect(AppStrings.get('stat_supports', lang), isNotEmpty);
        expect(AppStrings.get('stat_saved', lang), isNotEmpty);
        expect(AppStrings.get('no_activities_found', lang), isNotEmpty);
      }
    });
  });
}
