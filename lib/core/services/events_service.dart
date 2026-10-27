import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Etkinlikler aylık/günlük periyotlarla güncellenir.
/// keepAlive ile 1 saat boyunca bellekte tutulur, her ekran geçişinde Firestore okunmaz.
final eventsListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final link = ref.keepAlive();
  final timer = Timer(const Duration(hours: 1), () {
    link.close();
  });
  ref.onDispose(() => timer.cancel());

  return EventsService().fetchEvents(limit: 50);
});

class EventsService {
  EventsService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static List<Map<String, dynamic>>? _cachedEvents;
  static DateTime? _eventsLastFetch;
  static const _eventsTtl = Duration(hours: 1);

  static const String _eventsJsonUrl =
      'https://www.gebze.bel.tr/json/etkinlik.json';
  static const String _baseUrl = 'https://www.gebze.bel.tr';

  static const List<String> _trMonths = [
    '',
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  static String formatTrDate(String? dateStr) {
    if (dateStr == null || !dateStr.contains('-')) return dateStr ?? '';
    final parts = dateStr.split('-');
    if (parts.length != 3) return dateStr;
    final day = int.tryParse(parts[2]) ?? 0;
    final month = int.tryParse(parts[1]) ?? 0;
    final year = parts[0];
    final monthName = (month >= 1 && month <= 12) ? _trMonths[month] : '';
    return '$day $monthName $year'.trim();
  }

  /// Önbellekli ve sınırlandırılmış etkinlik çekme fonksiyonu.
  Future<List<Map<String, dynamic>>> fetchEvents({int limit = 50, bool force = false}) async {
    final now = DateTime.now();
    if (!force &&
        _cachedEvents != null &&
        _eventsLastFetch != null &&
        now.difference(_eventsLastFetch!) < _eventsTtl) {
      return _cachedEvents!.take(limit).toList();
    }

    try {
      final snap = await _firestore
          .collection('events')
          .where('date', isGreaterThanOrEqualTo: '2026-10-01')
          .orderBy('date')
          .limit(limit)
          .get(force
              ? const GetOptions(source: Source.server)
              : const GetOptions(source: Source.serverAndCache));

      _cachedEvents = snap.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
      _eventsLastFetch = now;
      return _cachedEvents!.take(limit).toList();
    } catch (e) {
      debugPrint('fetchEvents hatası: $e');
      if (_cachedEvents != null) return _cachedEvents!.take(limit).toList();
      return [];
    }
  }

  /// Firestore `events` koleksiyonunu dinler
  Stream<List<Map<String, dynamic>>> watchEvents({int limit = 50}) {
    return _firestore
        .collection('events')
        .where('date', isGreaterThanOrEqualTo: '2026-10-01')
        .orderBy('date')
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList(),
        );
  }

  /// Resmi Gebze Belediyesi web sitesinden (`etkinlik.json`) etkinlikleri çeker
  /// ve Firestore `events` koleksiyonuna kaydeder/günceller.
  Future<int> syncEventsFromWeb() async {
    try {
      final res = await http.get(
        Uri.parse(_eventsJsonUrl),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'GebzeDijitalMobile/1.0',
        },
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}: $_eventsJsonUrl');
      }

      final dynamic decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is! List) {
        throw Exception('Etkinlik verisi liste formatında değil.');
      }

      final batch = _firestore.batch();
      int count = 0;

      for (final item in decoded) {
        if (item is! Map<String, dynamic>) continue;
        final date = (item['tarih'] ?? '').toString().trim();
        // Sadece Ekim 2026 ve sonrası (Ekim, Kasım, Aralık vb.) etkinlikleri kabul et
        if (date.isNotEmpty && date.compareTo('2026-10-01') < 0) continue;

        final rawId = (item['id'] ?? count + 1).toString();
        final title = (item['baslik'] ?? '').toString().trim();
        final category = (item['kategori'] ?? 'Kültür & Sanat').toString().trim();
        final location = (item['konum'] ?? 'Gebze').toString().trim();
        final time = (item['saat'] ?? '').toString().trim();
        final formattedDate = formatTrDate(date);

        final subtitleParts = <String>[];
        if (location.isNotEmpty) subtitleParts.add(location);
        if (formattedDate.isNotEmpty) subtitleParts.add(formattedDate);
        if (time.isNotEmpty) subtitleParts.add(time);
        final subtitle = subtitleParts.join(' • ');

        final rawImg = (item['resim'] ?? '').toString().trim();
        final image = rawImg.isEmpty
            ? ''
            : (rawImg.startsWith('http') ? rawImg : '$_baseUrl/$rawImg');

        final rawUrl = (item['url'] ?? '').toString().trim();
        final url = rawUrl.isEmpty
            ? '$_baseUrl/etkinlik.html'
            : (rawUrl.startsWith('http') ? rawUrl : '$_baseUrl/$rawUrl');

        final docRef = _firestore.collection('events').doc('etkinlik_$rawId');
        batch.set(docRef, {
          'eventId': rawId,
          'title': title,
          'name': title,
          'category': category,
          'location': location,
          'address': location,
          'date': date,
          'time': time,
          'formattedDate': formattedDate,
          'subtitle': subtitle,
          'description': (item['aciklama'] ?? category).toString().trim(),
          'image': image,
          'imageUrl': image,
          'url': url,
          'source': 'Gebze Belediyesi',
          'syncedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        count++;
      }

      await batch.commit();
      debugPrint('EventsService: $count etkinlik Firestore\'a aktarıldı.');
      return count;
    } catch (e) {
      debugPrint('EventsService sync hatası: $e');
      rethrow;
    }
  }

  /// Eğer veritabanında henüz etkinlik yoksa otomatik olarak arka planda doldurur
  Future<void> ensureEventsSeeded() async {
    try {
      final snap = await _firestore.collection('events').limit(1).get();
      if (snap.docs.isEmpty) {
        debugPrint('EventsService: Etkinlikler boş, belediyeden ilk yükleme yapılıyor...');
        await syncEventsFromWeb();
      }
    } catch (e) {
      debugPrint('EventsService seed uyarısı: $e');
    }
  }
}
