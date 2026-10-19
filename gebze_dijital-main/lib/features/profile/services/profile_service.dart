import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';

const String kCurrentUserId = 'default_citizen';

final profileProvider = StreamProvider.autoDispose<UserProfile>((ref) {
  final docRef = FirebaseFirestore.instance.collection('users').doc(kCurrentUserId);

  return docRef.snapshots().asyncMap((doc) async {
    if (!doc.exists) {
      // Döküman henüz yoksa başlangıç profilini Firestore'a yazıyoruz
      final defaultProfile = UserProfile.defaultProfile();
      await docRef.set(defaultProfile.toFirestore());
      return defaultProfile;
    }
    return UserProfile.fromFirestore(doc);
  });
});

final profileServiceProvider = Provider((ref) => ProfileService());

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _userRef =>
      _firestore.collection('users').doc(kCurrentUserId);

  CollectionReference<Map<String, dynamic>> get _activitiesRef =>
      _userRef.collection('activities');

  /// Profil bilgilerini (ad, eposta, telefon, adres, tc) güncelle
  Future<void> updateProfile({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String address,
    required String neighborhood,
    String? tcNo,
  }) async {
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
    await _userRef.set(updateData, SetOptions(merge: true));
  }

  /// Mahalle seçimini doğrudan güncelle
  Future<void> updateNeighborhood(String neighborhood) async {
    await _userRef.set({
      'neighborhood': neighborhood,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Bildirim tercihlerini güncelle
  Future<void> updateNotificationPreference(String key, bool enabled) async {
    await _userRef.set({
      'notificationPreferences.$key': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Dil tercihini güncelle ('tr', 'en', 'ar')
  Future<void> updateLanguage(String languageCode) async {
    await _userRef.set({
      'language': languageCode,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Büyük yazı tipi tercihini güncelle
  Future<void> updateLargeFont(bool isLarge) async {
    await _userRef.set({
      'isLargeFont': isLarge,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Tema modunu güncelle ('light', 'dark', 'system')
  Future<void> updateThemeMode(String themeMode) async {
    await _userRef.set({
      'themeMode': themeMode,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Profil resmini güncelle
  Future<void> updateAvatarUrl(String avatarUrl) async {
    await _userRef.set({
      'avatarUrl': avatarUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Hesabı sil
  Future<void> deleteAccount() async {
    await _userRef.set({
      'status': 'deleted',
      'fullName': 'Silinmiş Kullanıcı',
      'email': '',
      'phoneNumber': '',
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Kullanıcı aktivitelerini getir
  Stream<List<UserActivityItem>> getActivitiesStream() {
    return _activitiesRef.snapshots().map((snap) {
      if (snap.docs.isEmpty) {
        return _fallbackActivities;
      }
      return snap.docs
          .map((d) => UserActivityItem.fromMap(d.data(), d.id))
          .toList();
    });
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
      description: 'Eskihisar sahil şeridine kiralık bisiklet istasyonu kurulması.',
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
      description: 'Sosyal tesis anketinde Kütüphane & Etüt Merkezini desteklediniz.',
      date: '09 Ekim 2026',
      status: 'Oylandı',
      category: 'Sosyal Hizmet',
    ),
    UserActivityItem(
      id: 'destek_2',
      type: 'destek',
      title: 'Sahil Parkı Yürüyüş ve Bisiklet Yolu',
      description: 'Eskihisar Sahil Parkı anketinde yürüyüş yolunu desteklediniz.',
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
