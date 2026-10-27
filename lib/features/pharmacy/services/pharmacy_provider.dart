import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pharmacy.dart';

/// Nöbetçi eczaneler günde 1 kez (gece yarısı) güncellenir.
/// keepAlive ile 2 saat boyunca bellekte tutulur, her ekran açılışında tekrar Firestore sorgusu yapılmaz.
/// Kullanıcı sayfayı yenilediğinde ref.refresh() ile anında taze veri çekilir.
final pharmacyProvider = FutureProvider<List<Pharmacy>>((ref) async {
  final link = ref.keepAlive();
  final timer = Timer(const Duration(hours: 2), () {
    link.close();
  });
  ref.onDispose(() => timer.cancel());

  try {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('pharmacies_on_duty')
        .get(const GetOptions(source: Source.serverAndCache));

    return querySnapshot.docs.map((doc) => Pharmacy.fromFirestore(doc)).toList();
  } catch (e) {
    return <Pharmacy>[];
  }
});
