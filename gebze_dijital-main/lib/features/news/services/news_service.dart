import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/municipal_news.dart';

class NewsService {
  NewsService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

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
}
