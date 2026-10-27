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
  // 1
  GebzeAvatarItem(
    id: 'avatar_1',
    assetPath: 'assets/images/avatars/avatar_1.png',
    titleTr: '',
    category: 'Genel',
  ),
  // 2
  GebzeAvatarItem(
    id: 'avatar_2',
    assetPath: 'assets/images/avatars/avatar_2.png',
    titleTr: '',
    category: 'Genel',
  ),
  // 3
  GebzeAvatarItem(
    id: 'avatar_3',
    assetPath: 'assets/images/avatars/avatar_3.png',
    titleTr: '',
    category: 'Genel',
  ),
  // 4
  GebzeAvatarItem(
    id: 'avatar_4',
    assetPath: 'assets/images/avatars/avatar_4.png',
    titleTr: '',
    category: 'Genel',
  ),
  // 5
  GebzeAvatarItem(
    id: 'avatar_5',
    assetPath: 'assets/images/avatars/avatar_5.png',
    titleTr: '',
    category: 'Genel',
  ),
  // 6
  GebzeAvatarItem(
    id: 'avatar_6',
    assetPath: 'assets/images/avatars/avatar_6.png',
    titleTr: '',
    category: 'Genel',
  ),
  // 7
  GebzeAvatarItem(
    id: 'avatar_7',
    assetPath: 'assets/images/avatars/avatar_7.png',
    titleTr: '',
    category: 'Genel',
  ),
  // 8
  GebzeAvatarItem(
    id: 'avatar_8',
    assetPath: 'assets/images/avatars/avatar_8.png',
    titleTr: '',
    category: 'Genel',
  ),
  // 9
  GebzeAvatarItem(
    id: 'avatar_9',
    assetPath: 'assets/images/avatars/avatar_9.png',
    titleTr: '',
    category: 'Genel',
  ),
  // 10
  GebzeAvatarItem(
    id: 'avatar_10',
    assetPath: 'assets/images/avatars/avatar_10.png',
    titleTr: '',
    category: 'Genel',
  ),
  // 11
  GebzeAvatarItem(
    id: 'avatar_11',
    assetPath: 'assets/images/avatars/avatar_11.png',
    titleTr: '',
    category: 'Genel',
  ),
  // 12
  GebzeAvatarItem(
    id: 'avatar_12',
    assetPath: 'assets/images/avatars/avatar_12.png',
    titleTr: '',
    category: 'Genel',
  ),
  // 13: Darwin (Zehra Şef)
  GebzeAvatarItem(
    id: 'avatar_13',
    assetPath: 'assets/images/avatars/avatar_13.png',
    titleTr: 'Darwin (Zehra Şef)',
    category: 'Özel',
  ),
  // 14: Burun Bantlı Genç (Affan)
  GebzeAvatarItem(
    id: 'avatar_14',
    assetPath: 'assets/images/avatars/avatar_14.png',
    titleTr: 'Burun Bantlı Genç (Affan)',
    category: 'Özel',
  ),
  // 15: Çiçek Perisi Flora (Havva)
  GebzeAvatarItem(
    id: 'avatar_15',
    assetPath: 'assets/images/avatars/avatar_15.png',
    titleTr: 'Çiçek Perisi Flora (Havva)',
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
