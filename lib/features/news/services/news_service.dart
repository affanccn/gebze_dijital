import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../models/municipal_news.dart';

/// Haberler günde 1 kez (öğlen 12:00) GitHub Actions ile güncellenir.
/// keepAlive ile 1 saat boyunca bellekte tutulur, her ekran açılışında Firestore okunmaz.
/// Kullanıcı sayfayı aşağı çekerek yenilediğinde ref.refresh() ile anında güncellenir.
final newsListProvider = FutureProvider<List<MunicipalNews>>((ref) async {
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 60), () {
    link.close();
  });
  ref.onDispose(() => timer.cancel());

  return NewsService().fetchNews(limit: 20);
});

class NewsService {
  NewsService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static final Map<String, String> _summaryCache = {};
  static List<MunicipalNews>? _cachedNews;
  static DateTime? _newsLastFetch;
  static const _newsTtl = Duration(minutes: 60);

  /// Önbellekli ve sınırlandırılmış haber çekme fonksiyonu.
  /// 60 dakika geçerli bellek içi önbellek kullanır (0 read maliyeti).
  Future<List<MunicipalNews>> fetchNews({int limit = 10, bool force = false}) async {
    final now = DateTime.now();
    if (!force &&
        _cachedNews != null &&
        _newsLastFetch != null &&
        now.difference(_newsLastFetch!) < _newsTtl) {
      return _cachedNews!.take(limit).toList();
    }

    try {
      final snapshot = await _firestore
          .collection('municipal_news')
          .orderBy('newsId', descending: true)
          .limit(limit)
          .get(force
              ? const GetOptions(source: Source.server)
              : const GetOptions(source: Source.serverAndCache));

      final map = <String, MunicipalNews>{};
      for (final doc in snapshot.docs) {
        final item = MunicipalNews.fromMap(doc.id, doc.data());
        final key = item.newsId != null
            ? 'id_${item.newsId}'
            : 'title_${item.title.trim().toLowerCase()}';

        if (!map.containsKey(key)) {
          map[key] = item;
        } else {
          final existing = map[key]!;
          if (existing.publishedAtText.isEmpty && item.publishedAtText.isNotEmpty) {
            map[key] = item;
          } else if (existing.summary.isEmpty && item.summary.isNotEmpty) {
            map[key] = item;
          }
        }
      }

      _cachedNews = map.values.toList();
      _newsLastFetch = now;
      return _cachedNews!.take(limit).toList();
    } catch (e) {
      debugPrint('fetchNews hatası: $e');
      if (_cachedNews != null) return _cachedNews!.take(limit).toList();
      return [];
    }
  }

  /// Metni hedef dile ('en', 'ar') anlık olarak çevirir (ücretsiz Google Translate servisi).
  Future<String?> translateText(String text, String targetLang) async {
    if (text.trim().isEmpty || targetLang == 'tr') return text;
    final cacheKey = '$targetLang:${text.hashCode}';
    if (_summaryCache.containsKey(cacheKey)) {
      return _summaryCache[cacheKey];
    }
    try {
      final clean = text.trim();
      final uri = Uri.parse(
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=tr&tl=$targetLang&dt=t&q=${Uri.encodeComponent(clean)}',
      );
      final res = await http.get(uri, headers: {
        'User-Agent': 'Mozilla/5.0',
      }).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final dynamic data = jsonDecode(res.body);
        if (data is List && data.isNotEmpty && data[0] is List) {
          final translated = (data[0] as List)
              .map((seg) =>
                  (seg != null && seg is List && seg.isNotEmpty)
                      ? seg[0].toString()
                      : '')
              .join('')
              .trim();
          if (translated.isNotEmpty) {
            _summaryCache[cacheKey] = translated;
            return translated;
          }
        }
      }
    } catch (e) {
      debugPrint('Haber çeviri hatası ($targetLang): $e');
    }
    return null;
  }


  /// En yeni haber en üstte (sitedeki haber numarası büyük = daha yeni).
  /// Mükerrer / çift kayıt oluşmasını engellemek için newsId ve başlığa göre tekilleştirilir.
  /// Varsayılan olarak sadece en güncel 10 haber alınır.
  Stream<List<MunicipalNews>> watchNews({int limit = 10}) {
    return _firestore
        .collection('municipal_news')
        .orderBy('newsId', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final map = <String, MunicipalNews>{};

          for (final doc in snapshot.docs) {
            final item = MunicipalNews.fromMap(doc.id, doc.data());
            // Tekilleştirme anahtarı: Varsa newsId (örn. 7435), yoksa temizlenmiş başlık
            final key = item.newsId != null
                ? 'id_${item.newsId}'
                : 'title_${item.title.trim().toLowerCase()}';

            if (!map.containsKey(key)) {
              map[key] = item;
            } else {
              // Eğer mevcut kopyanın tarihi boş ama bu kopyada doluysa, dolu olanı seç
              final existing = map[key]!;
              if (existing.publishedAtText.isEmpty &&
                  item.publishedAtText.isNotEmpty) {
                map[key] = item;
              } else if (existing.summary.isEmpty && item.summary.isNotEmpty) {
                map[key] = item;
              }
            }
          }

          return map.values.toList();
        });
  }

  /// Haberin web sayfasından 5-6 satırlık kısa ön okuma / özet metnini çeker.
  Future<String?> fetchNewsSummary(String url, {String? title}) async {
    if (url.isEmpty) return null;
    if (_summaryCache.containsKey(url)) {
      return _summaryCache[url];
    }
    try {
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final document = html_parser.parse(res.body);
        final pElements = document.querySelectorAll('p');
        for (final p in pElements) {
          final text = p.text
              .replaceAll('\u00a0', ' ')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
          if (text.length > 50 &&
              !text.contains('Tüm Hakları Saklıdır') &&
              !text.contains('KOCAELİ') &&
              !text.contains('Mahallesi') &&
              (title == null || !text.contains(title))) {
            _summaryCache[url] = text;
            return text;
          }
        }
      }
    } catch (e) {
      debugPrint('Haber özeti alınamadı: $e');
    }
    return null;
  }
}

