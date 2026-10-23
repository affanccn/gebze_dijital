import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../models/municipal_news.dart';

class NewsService {
  NewsService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static final Map<String, String> _summaryCache = {};

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
  /// `newsId` alanı olmayan eski dokümanlar listeye girmez.
  /// Tek alanlı sıralama olduğu için birleşik index gerekmez.
  Stream<List<MunicipalNews>> watchNews({int limit = 100}) {
    return _firestore
        .collection('municipal_news')
        .orderBy('newsId', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MunicipalNews.fromMap(doc.id, doc.data()))
              .toList(),
        );
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

