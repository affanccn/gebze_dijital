enum ParkingProfile { katli, yolUstu, adliye }

enum ParkingStatus { musait, yogun, dolu }

class ParkingLot {
  final String code;
  final String name;
  final int capacity;
  final double lat;
  final double lng;
  final ParkingProfile profile;

  const ParkingLot({
    required this.code,
    required this.name,
    required this.capacity,
    required this.lat,
    required this.lng,
    required this.profile,
  });
}

class ParkingOccupancy {
  final ParkingLot lot;
  final int occupied;

  const ParkingOccupancy(this.lot, this.occupied);

  int get free => lot.capacity - occupied;
  double get ratio => occupied / lot.capacity;
  int get percent => (ratio * 100).round();

  ParkingStatus get status {
    if (ratio >= 0.95) return ParkingStatus.dolu;
    if (ratio >= 0.80) return ParkingStatus.yogun;
    return ParkingStatus.musait;
  }
}

class ParkingSnapshot {
  final List<ParkingOccupancy> items;
  final DateTime updatedAt;
  final DateTime nextUpdateAt;

  const ParkingSnapshot(this.items, this.updatedAt, this.nextUpdateAt);

  int get totalCapacity => items.fold(0, (s, e) => s + e.lot.capacity);
  int get totalOccupied => items.fold(0, (s, e) => s + e.occupied);
  int get totalFree => totalCapacity - totalOccupied;
  int get totalPercent => ((totalOccupied / totalCapacity) * 100).round();
}
