import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/news_repository.dart';
import '../../domain/news_item.dart';

final newsRepositoryProvider = Provider<NewsRepository>(
  (ref) => FirestoreNewsRepository(FirebaseFirestore.instance),
);

final newsListProvider = StreamProvider<List<NewsItem>>(
  (ref) => ref.watch(newsRepositoryProvider).watchLatest(),
);