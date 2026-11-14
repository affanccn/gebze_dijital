import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../models/municipal_news.dart';

final newsListProvider = StreamProvider<List<MunicipalNews>>((ref) {
  return NewsService().watchNews(limit: 25);
});

class NewsService {
  NewsService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static final Map<String, String> _summaryCache = {};
  static List<MunicipalNews>? _cachedNews;

  static List<MunicipalNews> _dedupeAndSort(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
    int? limit,
  }) {
    final items = docs
        .map((doc) => MunicipalNews.fromMap(doc.id, doc.data()))
        .where((item) => item.title.trim().isNotEmpty)
        .toList();

    items.sort((a, b) => b.sortKey.compareTo(a.sortKey));

    final map = <String, MunicipalNews>{};
    for (final item in items) {
      final key = item.newsId != null
          ? 'id_${item.newsId}'
          : 'title_${item.title.trim().toLowerCase()}';

      if (!map.containsKey(key)) {
        map[key] = item;
      } else {
        final existing = map[key]!;
        if (existing.publishedAtText.isEmpty &&
            item.publishedAtText.isNotEmpty) {
          map[key] = item;
        } else if (existing.summary.isEmpty && item.summary.isNotEmpty) {
          map[key] = item;
        }
      }
    }

    final result = map.values.toList()
      ..sort((a, b) => b.sortKey.compareTo(a.sortKey));
    if (limit != null && result.length > limit) {
      return result.take(limit).toList();
    }
    return result;
  }

  Future<List<MunicipalNews>> fetchNews({
    int limit = 20,
    bool force = false,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('municipal_news')
          .limit(100)
          .get(
            force
                ? const GetOptions(source: Source.server)
                : const GetOptions(source: Source.serverAndCache),
          );

      final sorted = _dedupeAndSort(snapshot.docs, limit: limit);
      _cachedNews = sorted;
      return sorted;
    } catch (e) {
      debugPrint('fetchNews hatası: $e');
      if (_cachedNews != null) return _cachedNews!.take(limit).toList();
      return [];
    }
  }

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
      final res = await http
          .get(uri, headers: {'User-Agent': 'Mozilla/5.0'})
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final dynamic data = jsonDecode(res.body);
        if (data is List && data.isNotEmpty && data[0] is List) {
          final translated = (data[0] as List)
              .map(
                (seg) => (seg != null && seg is List && seg.isNotEmpty)
                    ? seg[0].toString()
                    : '',
              )
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

  Stream<List<MunicipalNews>> watchNews({int limit = 25}) {
    return _firestore.collection('municipal_news').limit(100).snapshots().map((
      snapshot,
    ) {
      final sorted = _dedupeAndSort(snapshot.docs, limit: limit);
      _cachedNews = sorted;
      return sorted;
    });
  }

  Future<String?> fetchNewsSummary(String url, {String? title}) async {
    if (url.isEmpty) return null;
    if (_summaryCache.containsKey(url)) {
      return _summaryCache[url];
    }
    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));
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
