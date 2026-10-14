import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/parking_estimator.dart';
import '../domain/parking_lot.dart';

final parkingSnapshotProvider = StreamProvider.autoDispose<ParkingSnapshot>((
  ref,
) async* {
  while (true) {
    final snap = ParkingEstimator.compute(DateTime.now());
    yield snap;
    final wait =
        snap.nextUpdateAt.difference(DateTime.now()) +
        const Duration(seconds: 1);
    await Future<void>.delayed(wait);
  }
});
