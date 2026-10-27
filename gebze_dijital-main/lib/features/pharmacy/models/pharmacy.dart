import 'package:cloud_firestore/cloud_firestore.dart';

class Pharmacy {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String district;
  final String loc;

  const Pharmacy({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.district,
    required this.loc,
  });

  factory Pharmacy.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return Pharmacy(
      id: doc.id,
      name: data?['name'] ?? '',
      address: data?['address'] ?? '',
      phone: data?['phone'] ?? '',
      district: data?['district'] ?? 'Gebze',
      loc: data?['loc'] ?? '',
    );
  }
}
