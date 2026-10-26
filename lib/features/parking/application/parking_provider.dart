import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/parking_estimator.dart';
import '../domain/parking_lot.dart';

final parkingSnapshotProvider = StreamProvider.autoDispose<ParkingSnapshot>((ref) {
  final controller = StreamController<ParkingSnapshot>();
  StreamSubscription? sub;

  void emitFallback() {
    final now = DateTime.now();
    final snap = ParkingEstimator.compute(now);
    if (!controller.isClosed) {
      controller.add(snap);
    }
  }

  try {
    sub = FirebaseFirestore.instance
        .collection('parking_lots')
        .snapshots()
        .listen(
      (querySnap) {
        if (querySnap.docs.isEmpty) {
          emitFallback();
          return;
        }

        final items = <ParkingOccupancy>[];
        for (final doc in querySnap.docs) {
          final data = doc.data();
          final code = (data['code'] as String?)?.trim() ?? doc.id;
          final name = (data['name'] as String?)?.trim() ?? 'Gebze Otoparkı';
          final capacity = (data['capacity'] as num?)?.toInt() ?? 50;
          final occupied = (data['occupied'] as num?)?.toInt() ?? 0;
          final lat = (data['lat'] as num?)?.toDouble() ?? 40.8000;
          final lng = (data['lng'] as num?)?.toDouble() ?? 29.4300;
          final profStr = (data['profile'] as String?)?.toLowerCase();

          final profile = switch (profStr) {
            'katli' => ParkingProfile.katli,
            'adliye' => ParkingProfile.adliye,
            _ => ParkingProfile.yolUstu,
          };

          final lot = ParkingLot(
            code: code,
            name: name,
            capacity: capacity,
            lat: lat,
            lng: lng,
            profile: profile,
          );
          items.add(ParkingOccupancy(lot, occupied.clamp(0, capacity)));
        }

        // Koda göre sırala (GBZ-001 ... GBZ-009)
        items.sort((a, b) => a.lot.code.compareTo(b.lot.code));

        final now = DateTime.now();
        if (!controller.isClosed) {
          controller.add(
            ParkingSnapshot(
              items,
              now,
              now.add(const Duration(seconds: 30)),
            ),
          );
        }
      },
      onError: (Object err) {
        emitFallback();
      },
    );
  } catch (_) {
    emitFallback();
  }

  ref.onDispose(() {
    sub?.cancel();
    controller.close();
  });

  return controller.stream;
});
