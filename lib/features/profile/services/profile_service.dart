import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/push_service.dart';
import '../../../screens/auth_service.dart' show authStateProvider;
import '../../../screens/favorites_service.dart' show favoritesProvider;
import '../models/user_profile.dart';

String get kCurrentUserId {
  try {
    return FirebaseAuth.instance.currentUser?.uid ?? 'default_citizen';
  } catch (_) {
    return 'default_citizen';
  }
}

FutureProvider<int> _subCountProvider(String sub) =>
    FutureProvider<int>((ref) async {
      final user = ref.watch(authStateProvider).value;
      if (user == null) return 0;
      try {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection(sub)
            .count()
            .get(source: AggregateSource.server);
        return snap.count ?? 0;
      } catch (_) {
        return 0;
      }
    });

final _votesCountProvider = _subCountProvider('votes');
final _supportedCountProvider = _subCountProvider('supported');

final _mySuggestionsCountProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return 0;
  try {
    final snap = await FirebaseFirestore.instance
        .collection('suggestions')
        .where('authorUid', isEqualTo: user.uid)
        .count()
        .get(source: AggregateSource.server);
    return snap.count ?? 0;
  } catch (_) {
    return 0;
  }
});

final profileProvider = StreamProvider.autoDispose<UserProfile>((ref) {
  final user = ref.watch(authStateProvider).value;

  final favCount = ref.watch(favoritesProvider.select((v) => v.value?.length));
  final voteCount = ref.watch(_votesCountProvider.select((v) => v.value));
  final supCount = ref.watch(_supportedCountProvider.select((v) => v.value));
  final sugCount = ref.watch(
    _mySuggestionsCountProvider.select((v) => v.value),
  );
  UserProfile withCounts(UserProfile p) => p.copyWith(
    totalSaved: favCount ?? p.totalSaved,
    totalSupported: (voteCount != null && supCount != null)
        ? voteCount + supCount
        : p.totalSupported,
    totalSuggestions: sugCount ?? p.totalSuggestions,
  );

  if (user == null) {
    return Stream.value(UserProfile.defaultProfile());
  }

  final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

  return docRef.snapshots().map((doc) {
    if (!doc.exists) {
      final defaultProfile = UserProfile.defaultProfile();
      try {
        docRef.set(defaultProfile.toFirestore());
      } catch (_) {}
      return withCounts(defaultProfile);
    }
    final profile = UserProfile.fromFirestore(doc);
    return withCounts(profile);
  });
});

final profileServiceProvider = Provider((ref) => ProfileService());

class ProfileService {
  ProfileService({FirebaseFirestore? firestore}) : _customFirestore = firestore;

  final FirebaseFirestore? _customFirestore;

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  DocumentReference<Map<String, dynamic>>? get _userRef {
    final db = _firestore;
    if (db == null) return null;
    return db.collection('users').doc(kCurrentUserId);
  }

  bool get _isAuthAvailable {
    try {
      return FirebaseAuth.instance.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> updateProfile({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String address,
    required String neighborhood,
    String? tcNo,
  }) async {
    if (!_isAuthAvailable) return;
    try {
      final updateData = <String, dynamic>{
        'fullName': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
        'address': address,
        'neighborhood': neighborhood,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (tcNo != null && tcNo.isNotEmpty) {
        updateData['tcNo'] = tcNo;
      }
      await _userRef?.set(updateData, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> updateNeighborhood(String neighborhood) async {
    if (!_isAuthAvailable) return;
    try {
      await _userRef?.set({
        'neighborhood': neighborhood,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> updateNotificationPreference(String key, bool enabled) async {
    await PushService.syncPreference(key, enabled);
    if (!_isAuthAvailable) return;
    try {
      await _userRef?.set({
        'notificationPreferences.$key': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> updateLanguage(String languageCode) async {
    if (!_isAuthAvailable) return;
    try {
      await _userRef?.set({
        'language': languageCode,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('updateLanguage hatası: $e');
      rethrow;
    }
  }

  Future<void> updateLargeFont(bool isLarge) async {
    if (!_isAuthAvailable) return;
    try {
      await _userRef?.set({
        'largeFont': isLarge,
        'isLargeFont': isLarge,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('updateLargeFont hatası: $e');
      rethrow;
    }
  }

  Future<void> updateThemeMode(String themeMode) async {
    if (!_isAuthAvailable) return;
    try {
      await _userRef?.set({
        'themeMode': themeMode,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> updateAvatarUrl(String avatarUrl) async {
    if (!_isAuthAvailable) return;
    try {
      await _userRef?.set({
        'avatarUrl': avatarUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> deleteAccount() async {
    if (!_isAuthAvailable) return;
    try {
      await _userRef?.set({
        'status': 'deleted',
        'fullName': 'Silinmiş Kullanıcı',
        'email': '',
        'phoneNumber': '',
        'deletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  static const List<String> _months = [
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

  static String _fmtDate(dynamic v) {
    if (v is! Timestamp) return '';
    final d = v.toDate();
    return '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]} ${d.year}';
  }

  static UserActivityItem _favoriteToActivity(
    QueryDocumentSnapshot<Map<String, dynamic>> d,
  ) {
    final m = d.data();
    return UserActivityItem(
      id: 'fav_${d.id}',
      type: 'kayit',
      title: (m['name'] ?? '').toString(),
      description: (m['summary'] ?? '').toString(),
      date: _fmtDate(m['createdAt']),
      status: 'Kaydedildi',
      category: (m['category'] ?? 'Gebze Rehberi').toString(),
    );
  }

  static List<QueryDocumentSnapshot<Map<String, dynamic>>> _byNewest(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    int ms(dynamic v) => v is Timestamp ? v.millisecondsSinceEpoch : 0;
    final list = [...docs];
    list.sort(
      (a, b) => ms(b.data()['createdAt']).compareTo(ms(a.data()['createdAt'])),
    );
    return list;
  }

  static String _optionText(dynamic options, int index) {
    if (options is List && index >= 0 && index < options.length) {
      final o = options[index];
      if (o is Map) return (o['text'] ?? '').toString();
      return o.toString();
    }
    return '';
  }

  Future<UserActivityItem> _voteToActivity(
    FirebaseFirestore db,
    QueryDocumentSnapshot<Map<String, dynamic>> d,
  ) async {
    final m = d.data();
    var title = 'Anket';
    var category = 'Anket';
    var choice = '';
    try {
      final poll = await db.collection('polls').doc(d.id).get();
      final pm = poll.data();
      if (pm != null) {
        title = (pm['question'] ?? pm['title'] ?? title).toString();
        category = (pm['category'] ?? category).toString();
        final idx = (m['optionIndex'] as num?)?.toInt() ?? -1;
        choice = _optionText(pm['options'], idx);
      }
    } catch (_) {}
    return UserActivityItem(
      id: 'vote_${d.id}',
      type: 'destek',
      title: title,
      description: choice.isEmpty ? 'Ankete oy verdiniz.' : 'Oyunuz: $choice',
      date: _fmtDate(m['createdAt']),
      status: 'Oylandı',
      category: category,
    );
  }

  Future<UserActivityItem> _supportToActivity(
    FirebaseFirestore db,
    QueryDocumentSnapshot<Map<String, dynamic>> d,
  ) async {
    final m = d.data();
    var title = 'Vatandaş Önerisi';
    var category = 'Öneri';
    try {
      final sug = await db.collection('suggestions').doc(d.id).get();
      final sm = sug.data();
      if (sm != null) {
        title = (sm['title'] ?? title).toString();
        category = (sm['category'] ?? category).toString();
      }
    } catch (_) {}
    return UserActivityItem(
      id: 'support_${d.id}',
      type: 'destek',
      title: title,
      description: 'Bu öneriyi desteklediniz.',
      date: _fmtDate(m['createdAt']),
      status: 'Desteklendi',
      category: category,
    );
  }

  static UserActivityItem _suggestionToActivity(
    QueryDocumentSnapshot<Map<String, dynamic>> d,
  ) {
    final m = d.data();
    final isApproved = m['approved'] == true;
    final statusText = isApproved
        ? 'Onaylandı'
        : (m['status'] ?? 'İncelemede').toString();
    return UserActivityItem(
      id: 'sug_${d.id}',
      type: 'oneri',
      title: (m['title'] ?? '').toString(),
      description: (m['description'] ?? '').toString(),
      date: _fmtDate(m['createdAt']),
      status: statusText,
      category: (m['category'] ?? 'Genel').toString(),
    );
  }

  Stream<List<UserActivityItem>> getActivitiesStream() {
    if (!_isAuthAvailable) {
      return Stream.value(_fallbackActivities);
    }
    final userRef = _userRef;
    final db = _firestore;
    String? uid;
    try {
      uid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return Stream.value(_fallbackActivities);
    }
    if (userRef == null || db == null || uid == null) {
      return Stream.value(_fallbackActivities);
    }

    const order = [
      'activities',
      'suggestions',
      'votes',
      'supported',
      'favorites',
    ];
    final parts = <String, List<UserActivityItem>>{};
    final subs = <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];
    late final StreamController<List<UserActivityItem>> controller;

    void emit() {
      if (controller.isClosed) return;
      controller.add([for (final k in order) ...?parts[k]]);
    }

    void listenTo(
      String key,
      Query<Map<String, dynamic>> query,
      Future<List<UserActivityItem>> Function(
        QuerySnapshot<Map<String, dynamic>> snap,
      )
      convert,
    ) {
      subs.add(
        query.snapshots().listen(
          (snap) async {
            try {
              parts[key] = await convert(snap);
            } catch (_) {
              parts[key] = [];
            }
            emit();
          },
          onError: (_) {
            parts[key] = [];
            emit();
          },
        ),
      );
    }

    controller = StreamController<List<UserActivityItem>>(
      onListen: () {
        listenTo(
          'activities',
          userRef.collection('activities'),
          (snap) async => snap.docs
              .map((d) => UserActivityItem.fromMap(d.data(), d.id))
              .toList(),
        );
        listenTo(
          'suggestions',
          db.collection('suggestions').where('authorUid', isEqualTo: uid),
          (snap) async =>
              _byNewest(snap.docs).map(_suggestionToActivity).toList(),
        );
        listenTo(
          'votes',
          userRef.collection('votes'),
          (snap) async => Future.wait(
            _byNewest(snap.docs).map((d) => _voteToActivity(db, d)),
          ),
        );
        listenTo(
          'supported',
          userRef.collection('supported'),
          (snap) async => Future.wait(
            _byNewest(snap.docs).map((d) => _supportToActivity(db, d)),
          ),
        );
        listenTo(
          'favorites',
          userRef.collection('favorites'),
          (snap) async =>
              _byNewest(snap.docs).map(_favoriteToActivity).toList(),
        );
      },
      onCancel: () async {
        for (final sub in subs) {
          await sub.cancel();
        }
      },
    );
    return controller.stream;
  }

  static const List<UserActivityItem> _fallbackActivities = [
    UserActivityItem(
      id: 'talep_1',
      type: 'talep',
      title: 'Mustafapaşa Mah. Sokak Lambası Onarımı',
      description: '712. Sokak üzerindeki sokak lambası yanmıyor.',
      date: '10 Ekim 2026',
      status: 'İşleme Alındı',
      category: 'Altyapı',
    ),
    UserActivityItem(
      id: 'talep_2',
      type: 'talep',
      title: 'Çocuk Parkı Kauçuk Zemin Yenileme',
      description: 'Osman Yılmaz Parkı oyun alanı zemin tamiri talebi.',
      date: '04 Ekim 2026',
      status: 'Çözüldü',
      category: 'Park & Bahçe',
    ),
    UserActivityItem(
      id: 'talep_3',
      type: 'talep',
      title: 'Kaldırım Düzenleme ve Rampa Talebi',
      description: 'Engelli erişimi için rampa düzenlemesi başvurusu.',
      date: '28 Eylül 2026',
      status: 'İnceleniyor',
      category: 'Ulaşım',
    ),
    UserActivityItem(
      id: 'oneri_1',
      type: 'oneri',
      title: 'Sahil Yolu Akıllı Bisiklet İstasyonu',
      description:
          'Eskihisar sahil şeridine kiralık bisiklet istasyonu kurulması.',
      date: '08 Ekim 2026',
      status: 'Yayında',
      category: 'Ulaşım',
    ),
    UserActivityItem(
      id: 'oneri_2',
      type: 'oneri',
      title: 'Geri Dönüşüm Karşılığı Mama Otomatı',
      description: 'Plastik ve metal atık karşılığı sokak hayvanlarına mama veren otomatlar.',
      date: '01 Ekim 2026',
      status: 'Değerlendiriliyor',
      category: 'Çevre',
    ),
    UserActivityItem(
      id: 'destek_1',
      type: 'destek',
      title: 'Mustafapaşa Mahallesi Kütüphane & Etüt Projesi',
      description:
          'Sosyal tesis anketinde Kütüphane & Etüt Merkezini desteklediniz.',
      date: '09 Ekim 2026',
      status: 'Oylandı',
      category: 'Sosyal Hizmet',
    ),
    UserActivityItem(
      id: 'destek_2',
      type: 'destek',
      title: 'Sahil Parkı Yürüyüş ve Bisiklet Yolu',
      description:
          'Eskihisar Sahil Parkı anketinde yürüyüş yolunu desteklediniz.',
      date: '05 Ekim 2026',
      status: 'Oylandı',
      category: 'Çevre',
    ),
    UserActivityItem(
      id: 'kayit_1',
      type: 'kayit',
      title: 'Eskihisar Kalesi ve Tarihi Ziyaret Rehberi',
      description: 'Gebze tarihi mekanlar rehberinden kaydedildi.',
      date: '07 Ekim 2026',
      status: 'Kaydedildi',
      category: 'Kültür & Turizm',
    ),
    UserActivityItem(
      id: 'kayit_2',
      type: 'kayit',
      title: 'Gebze Belediyesi Acil Durum Toplanma Alanları',
      description: 'Acil durum toplanma alanları ve iletişim rehberi.',
      date: '02 Ekim 2026',
      status: 'Kaydedildi',
      category: 'Acil Durum',
    ),
  ];
}
