import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/news_item.dart';

abstract class NewsRepository {
  Stream<List<NewsItem>> watchLatest({int limit = 20});
}

class FirestoreNewsRepository implements NewsRepository {
  FirestoreNewsRepository(this._db);
  final FirebaseFirestore _db;

  @override
  Stream<List<NewsItem>> watchLatest({int limit = 20}) {
    return _db
        .collection('news')
        .where('isPublished', isEqualTo: true)
        .orderBy('publishedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(NewsItem.fromDoc).toList());
  }
}
