import 'package:cloud_firestore/cloud_firestore.dart';

/// Söz Sende için Firestore işlemleri.
///
/// Veri modeli:
///   users/{uid}/votes/{pollId}           -> { optionIndex, createdAt }   (Oylarım)
///   users/{uid}/supported/{suggestionId} -> { createdAt }                (Desteklediklerim)
///   users/{uid}/saved/{itemId}           -> { type, createdAt }          (Kaydettiklerim)
///   suggestions/{id}.authorUid                                           (Önerilerim)
///   polls/{id}.voteCounts.{optionIndex}  -> sayaç (eski `votes` alanına eklenir)
class SozSendeRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Oy kaydı + sayaç AYNI batch'te yazılır. Kurallar, oy kaydı yoksa sayaç
  /// artışına izin vermez; kayıt zaten varsa ikinci oyu reddeder.
  /// İnternet yokken kuyruğa alınır, bağlanınca gönderilir.
  Future<void> vote(String uid, String pollId, int optionIndex) {
    final batch = _db.batch();
    batch.set(_db.doc('users/$uid/votes/$pollId'), {
      'optionIndex': optionIndex,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(_db.doc('polls/$pollId'), {
      'voteCounts.$optionIndex': FieldValue.increment(1),
    });
    return batch.commit();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> myVotesRaw(String uid) => _db
      .collection('users/$uid/votes')
      .snapshots(includeMetadataChanges: true);

  /// Destek ver / geri al. Kayıt + `likes` sayacı aynı batch'te.
  Future<void> setSupport(
    String uid,
    String suggestionId, {
    required bool support,
  }) {
    final batch = _db.batch();
    final ref = _db.doc('users/$uid/supported/$suggestionId');
    if (support) {
      batch.set(ref, {'createdAt': FieldValue.serverTimestamp()});
    } else {
      batch.delete(ref);
    }
    batch.update(_db.doc('suggestions/$suggestionId'), {
      'likes': FieldValue.increment(support ? 1 : -1),
    });
    return batch.commit();
  }

  Stream<Set<String>> mySupportedIds(String uid) => _db
      .collection('users/$uid/supported')
      .snapshots()
      .map((s) => s.docs.map((d) => d.id).toSet());

  // ── Kaydettiklerim ──
  Future<void> setSaved(
    String uid,
    String itemId,
    String type, {
    required bool saved,
  }) {
    final ref = _db.doc('users/$uid/saved/$itemId');
    return saved
        ? ref.set({'type': type, 'createdAt': FieldValue.serverTimestamp()})
        : ref.delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> mySaved(String uid) => _db
      .collection('users/$uid/saved')
      .orderBy('createdAt', descending: true)
      .snapshots();

  // ── Önerilerim ──
  Stream<QuerySnapshot<Map<String, dynamic>>> mySuggestions(String uid) => _db
      .collection('suggestions')
      .where('authorUid', isEqualTo: uid)
      .snapshots();
}
