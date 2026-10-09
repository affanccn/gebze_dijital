import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/municipal_news.dart';

class NewsService {
  NewsService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<MunicipalNews>> watchNews() {
    return _firestore.collection('municipal_news').snapshots().map((snapshot) {
      final news = snapshot.docs
          .map((doc) => MunicipalNews.fromMap(doc.id, doc.data()))
          .toList();

      news.sort((a, b) {
        final pageCompare = a.pageIndex.compareTo(b.pageIndex);
        if (pageCompare != 0) return pageCompare;

        return a.itemIndex.compareTo(b.itemIndex);
      });

      return news;
    });
  }
}
