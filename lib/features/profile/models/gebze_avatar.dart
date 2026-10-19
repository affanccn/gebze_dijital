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
  // 1: Kıdemli Beyefendi / Gebzeli Dede (Gözlüklü)
  GebzeAvatarItem(
    id: 'avatar_1',
    assetPath: 'assets/images/avatars/avatar_1.png',
    titleTr: 'Gebzeli Dede (Gözlüklü)',
    category: 'Kıdemli',
  ),
  // 2: Kız Öğrenci (Türbanlı / Sırt Çantalı)
  GebzeAvatarItem(
    id: 'avatar_2',
    assetPath: 'assets/images/avatars/avatar_2.png',
    titleTr: 'Kız Öğrenci (Türbanlı)',
    category: 'Öğrenci',
  ),
  // 3: Erkek Öğrenci (Kapüşonlu / Sırt Çantalı)
  GebzeAvatarItem(
    id: 'avatar_3',
    assetPath: 'assets/images/avatars/avatar_3.png',
    titleTr: 'Erkek Öğrenci (Kapüşonlu)',
    category: 'Öğrenci',
  ),
  // 4: Kız Genç (At Kuyruklu)
  GebzeAvatarItem(
    id: 'avatar_4',
    assetPath: 'assets/images/avatars/avatar_4.png',
    titleTr: 'Kız Genç (At Kuyruklu)',
    category: 'Genç',
  ),
  // 5: Kıdemli Beyefendi (Kır Sakallı)
  GebzeAvatarItem(
    id: 'avatar_5',
    assetPath: 'assets/images/avatars/avatar_5.png',
    titleTr: 'Kıdemli Beyefendi',
    category: 'Kıdemli',
  ),
  // 6: Kadın Çalışan (Gözlüklü / Kıvırcık Saçlı)
  GebzeAvatarItem(
    id: 'avatar_6',
    assetPath: 'assets/images/avatars/avatar_6.png',
    titleTr: 'Kadın Çalışan (Kıvırcık Saç)',
    category: 'Çalışan',
  ),
  // 7: Erkek Genç (Kareli Gömlek)
  GebzeAvatarItem(
    id: 'avatar_7',
    assetPath: 'assets/images/avatars/avatar_7.png',
    titleTr: 'Erkek Genç (Kareli Gömlek)',
    category: 'Genç',
  ),
  // 8: Tonton Nine (Desenli Eşarplı)
  GebzeAvatarItem(
    id: 'avatar_8',
    assetPath: 'assets/images/avatars/avatar_8.png',
    titleTr: 'Tonton Nine (Eşarplı)',
    category: 'Kıdemli',
  ),
  // 9: Erkek Genç (Montlu / Sakallı)
  GebzeAvatarItem(
    id: 'avatar_9',
    assetPath: 'assets/images/avatars/avatar_9.png',
    titleTr: 'Erkek Genç (Montlu)',
    category: 'Genç',
  ),
  // 10: Kadın Çalışan (Türbanlı / Ceketli)
  GebzeAvatarItem(
    id: 'avatar_10',
    assetPath: 'assets/images/avatars/avatar_10.png',
    titleTr: 'Kadın Çalışan (Türbanlı)',
    category: 'Çalışan',
  ),
  // 11: Erkek Genç (Kolej Montlu / Ters Şapka)
  GebzeAvatarItem(
    id: 'avatar_11',
    assetPath: 'assets/images/avatars/avatar_11.png',
    titleTr: 'Erkek Genç (Ters Şapkalı)',
    category: 'Genç',
  ),
  // 12: Yetişkin Kadın (Yeşil Fularlı)
  GebzeAvatarItem(
    id: 'avatar_12',
    assetPath: 'assets/images/avatars/avatar_12.png',
    titleTr: 'Yetişkin Kadın (Fularlı)',
    category: 'Çalışan',
  ),
  // 13: Darwin Watterson (Neşeli Karakter)
  GebzeAvatarItem(
    id: 'avatar_13',
    assetPath: 'assets/images/avatars/avatar_13.png',
    titleTr: 'Darwin (Zehra Şef)',
    category: 'Özel',
  ),
  // 14: Tarz Genç Erkek (Piercingli)
  GebzeAvatarItem(
    id: 'avatar_14',
    assetPath: 'assets/images/avatars/avatar_14.png',
    titleTr: 'Burun Bantlı Genç (Affan)',
    category: 'Özel',
  ),
  // 15: Çiçek Perisi (Flora)
  GebzeAvatarItem(
    id: 'avatar_15',
    assetPath: 'assets/images/avatars/avatar_15.png',
    titleTr: 'Çiçek Perisi (Flora)',
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
