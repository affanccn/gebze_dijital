class FeedingPoint {
  final String id;
  final String title;
  final String neighborhood;
  final String address;
  final double latitude;
  final double longitude;
  final String type; // 'Mama ve Su Odak Noktası', 'Kedi Evi & Besleme Noktası', vb.
  final String equipment; // 'Otomatik Su Kabı, Korumalı Kuru Mama Haznesi, Kulübe'
  final String note;

  const FeedingPoint({
    required this.id,
    required this.title,
    required this.neighborhood,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.equipment,
    this.note = 'Belediyemiz veteriner ekipleri tarafından düzenli olarak takviye edilmektedir.',
  });
}

class DutyVetClinic {
  final String id;
  final String name;
  final String district;
  final String address;
  final String phone;
  final String emergencyHours;
  final double latitude;
  final double longitude;
  final bool is24Hours;

  const DutyVetClinic({
    required this.id,
    required this.name,
    required this.district,
    required this.address,
    required this.phone,
    required this.emergencyHours,
    required this.latitude,
    required this.longitude,
    this.is24Hours = true,
  });
}
