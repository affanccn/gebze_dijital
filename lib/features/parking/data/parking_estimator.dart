import 'dart:math';

import '../domain/parking_lot.dart';
import 'parking_data.dart';

typedef Curve = List<(double, double)>;

const _weekday = <ParkingProfile, Curve>{
  ParkingProfile.katli: [
    (0, .15),
    (7, .25),
    (10, .50),
    (13, .65),
    (17, .75),
    (19, .80),
    (22, .45),
    (24, .15),
  ],
  ParkingProfile.yolUstu: [
    (0, .10),
    (7, .20),
    (9, .55),
    (12, .70),
    (15, .65),
    (18, .80),
    (21, .40),
    (24, .10),
  ],
  ParkingProfile.adliye: [
    (0, .05),
    (8, .30),
    (10, .80),
    (12, .85),
    (16, .70),
    (17, .30),
    (24, .05),
  ],
};

const _weekend = <ParkingProfile, Curve>{
  ParkingProfile.katli: [
    (0, .15),
    (9, .30),
    (12, .65),
    (16, .80),
    (20, .85),
    (23, .40),
    (24, .15),
  ],
  ParkingProfile.yolUstu: [
    (0, .10),
    (9, .25),
    (12, .55),
    (17, .70),
    (21, .50),
    (24, .10),
  ],
  ParkingProfile.adliye: [(0, .05), (10, .12), (14, .20), (24, .05)],
};

class ParkingEstimator {
  static const slotHours = 3;

  static double _interpolate(Curve c, double h) {
    for (var i = 0; i < c.length - 1; i++) {
      final (h0, v0) = c[i];
      final (h1, v1) = c[i + 1];
      if (h >= h0 && h <= h1) {
        return v0 + (v1 - v0) * ((h - h0) / (h1 - h0));
      }
    }
    return c.last.$2;
  }

  static int _seed(String code, DateTime slotStart) {
    var h = 17;
    for (final u in code.codeUnits) {
      h = (h * 31 + u) & 0x7fffffff;
    }
    return (h * 31 + slotStart.millisecondsSinceEpoch ~/ 3600000) & 0x7fffffff;
  }

  static DateTime slotStartOf(DateTime now) => DateTime(
    now.year,
    now.month,
    now.day,
    (now.hour ~/ slotHours) * slotHours,
  );

  static ParkingSnapshot compute(DateTime now) {
    final start = slotStartOf(now);
    final next = start.add(const Duration(hours: slotHours));
    final isWeekend = now.weekday >= DateTime.saturday;
    final midHour = start.hour + slotHours / 2;

    final items = parkingLots.map((lot) {
      final curve = (isWeekend ? _weekend : _weekday)[lot.profile]!;
      final base = _interpolate(curve, midHour);
      final jitter = (Random(_seed(lot.code, start)).nextDouble() - 0.5) * 0.12;
      final ratio = (base + jitter).clamp(0.05, 0.98);
      return ParkingOccupancy(lot, (lot.capacity * ratio).round());
    }).toList();

    return ParkingSnapshot(items, start, next);
  }
}
