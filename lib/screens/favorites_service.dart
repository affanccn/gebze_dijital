import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_service.dart';
import 'guide_screen.dart' show HistoricPlace;

class FavoritePlace {
  final String id;
  final String name;
  final String summary;
  final String category;
  final String image;
  final String detailUrl;

  const FavoritePlace({
    required this.id,
    required this.name,
    required this.summary,
    required this.category,
    required this.image,
    required this.detailUrl,
  });

  factory FavoritePlace.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return FavoritePlace(
      id: d.id,
      name: (m['name'] ?? '').toString(),
      summary: (m['summary'] ?? '').toString(),
      category: (m['category'] ?? '').toString(),
      image: (m['image'] ?? '').toString(),
      detailUrl: (m['detailUrl'] ?? '').toString(),
    );
  }
}

final favoritesProvider = StreamProvider<List<FavoritePlace>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(const <FavoritePlace>[]);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('favorites')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) {
        final seen = <String>{};
        final out = <FavoritePlace>[];
        for (final d in s.docs) {
          final f = FavoritePlace.fromDoc(d);
          final key = f.name.trim().toLowerCase();
          if (key.isEmpty || seen.add(key)) out.add(f);
        }
        return out;
      });
});

final favoriteIdsProvider = Provider<Set<String>>(
  (ref) =>
      ref.watch(favoritesProvider).value?.map((f) => f.id).toSet() ??
      <String>{},
);

final favoritesServiceProvider = Provider<FavoritesService>(
  (ref) => FavoritesService(),
);

class FavoritesService {
  DocumentReference<Map<String, dynamic>>? _doc(String placeId) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(placeId);
  }

  Future<List<DocumentReference<Map<String, dynamic>>>> _sameName(
    String name,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || name.trim().isEmpty) return const [];
    final q = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .where('name', isEqualTo: name)
        .get();
    return q.docs.map((d) => d.reference).toList();
  }

  Future<void> _deleteAll(
    Iterable<DocumentReference<Map<String, dynamic>>> refs,
  ) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final r in refs) {
      batch.delete(r);
    }
    await batch.commit();
  }

  Future<void> toggle(HistoricPlace p) async {
    final doc = _doc(p.id);
    if (doc == null) return;
    final snap = await doc.get();
    final copies = await _sameName(p.name);
    if (snap.exists || copies.isNotEmpty) {
      await _deleteAll({doc, ...copies});
    } else {
      await doc.set({
        'name': p.name,
        'summary': p.summary,
        'category': p.category,
        'image': p.image ?? '',
        'detailUrl': p.detailUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> remove(String placeId) async {
    final doc = _doc(placeId);
    if (doc == null) return;
    final snap = await doc.get();
    final name = (snap.data()?['name'] ?? '').toString();
    final copies = await _sameName(name);
    await _deleteAll({doc, ...copies});
  }
}
