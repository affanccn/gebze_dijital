import 'package:cloud_firestore/cloud_firestore.dart';

class FeedingPoint {
  final String id;
  final String title;
  final String neighborhood;
  final String address;
  final double latitude;
  final double longitude;
  final String
  type; // 'Mama ve Su Odak Noktası', 'Kedi Evi & Besleme Noktası', vb.
  final String
  equipment; // 'Otomatik Su Kabı, Korumalı Kuru Mama Haznesi, Kulübe'
  final String note;
  final DateTime? createdAt;

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
    this.createdAt,
  });

  factory FeedingPoint.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FeedingPoint(
      id: doc.id,
      title: data['title'] as String? ?? '',
      neighborhood: data['neighborhood'] as String? ?? 'Genel',
      address: data['address'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 40.8028,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 29.4307,
      type: data['type'] as String? ?? 'Mama ve Su Odak Noktası',
      equipment: data['equipment'] as String? ?? 'Kuru mama ve taze su haznesi',
      note:
          data['note'] as String? ??
          'Belediyemiz ekiplerince düzenli denetlenmektedir.',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'neighborhood': neighborhood,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'type': type,
      'equipment': equipment,
      'note': note,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
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
  final DateTime? createdAt;

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
    this.createdAt,
  });

  factory DutyVetClinic.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DutyVetClinic(
      id: doc.id,
      name: data['name'] as String? ?? '',
      district: data['district'] as String? ?? 'Gebze',
      address: data['address'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      emergencyHours: data['emergencyHours'] as String? ?? '7/24 Nöbetçi',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 40.8028,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 29.4307,
      is24Hours: data['is24Hours'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'district': district,
      'address': address,
      'phone': phone,
      'emergencyHours': emergencyHours,
      'latitude': latitude,
      'longitude': longitude,
      'is24Hours': is24Hours,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
