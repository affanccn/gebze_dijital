import 'dart:convert';
import 'package:flutter/material.dart';

class GebzeAvatarItem {
  final String id;
  final String assetPath;
  final String titleTr;
  final String category;

  const GebzeAvatarItem({
    required this.id,
    required this.assetPath,
    required this.titleTr,
    required this.category,
  });
}

const List<GebzeAvatarItem> kGebzeAvatars = [
  // 1: Erkek Öğrenci
  GebzeAvatarItem(
    id: 'avatar_1',
    assetPath: 'assets/images/avatars/avatar_1.png',
    titleTr: 'Erkek Öğrenci',
    category: 'Öğrenci',
  ),
  // 2: Kız Öğrenci
  GebzeAvatarItem(
    id: 'avatar_2',
    assetPath: 'assets/images/avatars/avatar_2.png',
    titleTr: 'Kız Öğrenci',
    category: 'Öğrenci',
  ),
  // 3: Kız Öğrenci (Türbanlı)
  GebzeAvatarItem(
    id: 'avatar_3',
    assetPath: 'assets/images/avatars/avatar_3.png',
    titleTr: 'Kız Öğrenci (Türbanlı)',
    category: 'Öğrenci',
  ),
  // 4: Erkek Genç
  GebzeAvatarItem(
    id: 'avatar_4',
    assetPath: 'assets/images/avatars/avatar_4.png',
    titleTr: 'Erkek Genç',
    category: 'Genç',
  ),
  // 5: Kız Genç
  GebzeAvatarItem(
    id: 'avatar_5',
    assetPath: 'assets/images/avatars/avatar_5.png',
    titleTr: 'Kız Genç',
    category: 'Genç',
  ),
  // 6: Kız Genç (Türbanlı)
  GebzeAvatarItem(
    id: 'avatar_6',
    assetPath: 'assets/images/avatars/avatar_6.png',
    titleTr: 'Kız Genç (Türbanlı)',
    category: 'Genç',
  ),
  // 7: Erkek Çalışan / Mühendis
  GebzeAvatarItem(
    id: 'avatar_7',
    assetPath: 'assets/images/avatars/avatar_7.png',
    titleTr: 'Erkek Çalışan / Mühendis',
    category: 'Çalışan',
  ),
  // 8: Kadın Çalışan / Yönetici
  GebzeAvatarItem(
    id: 'avatar_8',
    assetPath: 'assets/images/avatars/avatar_8.png',
    titleTr: 'Kadın Çalışan / Yönetici',
    category: 'Çalışan',
  ),
  // 9: Kadın Çalışan (Türbanlı)
  GebzeAvatarItem(
    id: 'avatar_9',
    assetPath: 'assets/images/avatars/avatar_9.png',
    titleTr: 'Kadın Çalışan (Türbanlı)',
    category: 'Çalışan',
  ),
  // 10: Erkek Yaşlı (Gebzeli Dede)
  GebzeAvatarItem(
    id: 'avatar_10',
    assetPath: 'assets/images/avatars/avatar_10.png',
    titleTr: 'Erkek Yaşlı (Gebzeli Dede)',
    category: 'Kıdemli',
  ),
  // 11: Kadın Yaşlı (Gebzeli Teyze)
  GebzeAvatarItem(
    id: 'avatar_11',
    assetPath: 'assets/images/avatars/avatar_11.png',
    titleTr: 'Kadın Yaşlı (Gebzeli Teyze)',
    category: 'Kıdemli',
  ),
  // 12: Kadın Yaşlı (Türbanlı / Eşarplı)
  GebzeAvatarItem(
    id: 'avatar_12',
    assetPath: 'assets/images/avatars/avatar_12.png',
    titleTr: 'Kadın Yaşlı (Eşarplı / Tonton Nine)',
    category: 'Kıdemli',
  ),
  // 13: Gebzespor Taraftarı Genç
  GebzeAvatarItem(
    id: 'avatar_13',
    assetPath: 'assets/images/avatars/avatar_13.png',
    titleTr: 'Gebzespor Taraftarı',
    category: 'Özel',
  ),
  // 14: Doğa & Gebze Pati Gönüllüsü
  GebzeAvatarItem(
    id: 'avatar_14',
    assetPath: 'assets/images/avatars/avatar_14.png',
    titleTr: 'Gebze Pati Gönüllüsü',
    category: 'Özel',
  ),
  // 15: Gebze Dijital Hemşehri
  GebzeAvatarItem(
    id: 'avatar_15',
    assetPath: 'assets/images/avatars/avatar_15.png',
    titleTr: 'Gebze Dijital Hemşehri',
    category: 'Özel',
  ),
];

/// Avatar görsel sağlayıcısını çözer (Asset, Base64 Data URI veya Network URL).
ImageProvider? getAvatarImageProvider(String? avatarUrl) {
  if (avatarUrl == null || avatarUrl.trim().isEmpty) return null;
  final url = avatarUrl.trim();

  if (url.startsWith('assets/')) {
    return AssetImage(url);
  }

  if (url.startsWith('data:image') || url.startsWith('base64,')) {
    try {
      final commaIndex = url.indexOf(',');
      final raw = commaIndex != -1 ? url.substring(commaIndex + 1) : url;
      return MemoryImage(base64Decode(raw));
    } catch (_) {
      return null;
    }
  }

  if (url.startsWith('http://') || url.startsWith('https://')) {
    return NetworkImage(url);
  }

  return null;
}
