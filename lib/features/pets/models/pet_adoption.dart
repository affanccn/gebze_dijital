import 'package:cloud_firestore/cloud_firestore.dart';

class PetAdoption {
  final String id;
  final String name;
  final String species;
  final String breed;
  final String gender;
  final String age;
  final String imageUrl;
  final String description;
  final String healthStatus;
  final String centerPhone;
  final bool isAdopted;
  final DateTime? createdAt;

  const PetAdoption({
    required this.id,
    required this.name,
    required this.species,
    required this.breed,
    required this.gender,
    required this.age,
    required this.imageUrl,
    required this.description,
    required this.healthStatus,
    this.centerPhone = '(0262) 642 04 30',
    this.isAdopted = false,
    this.createdAt,
  });

  factory PetAdoption.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PetAdoption(
      id: doc.id,
      name: data['name'] as String? ?? 'İsimsiz Can Dostumuz',
      species: data['species'] as String? ?? 'Köpek',
      breed: data['breed'] as String? ?? 'Melez',
      gender: data['gender'] as String? ?? 'Belirtilmedi',
      age: data['age'] as String? ?? 'Genç',
      imageUrl: data['imageUrl'] as String? ?? '',
      description: data['description'] as String? ?? '',
      healthStatus:
          data['healthStatus'] as String? ??
          'Sağlık kontrolü ve aşıları yapıldı',
      centerPhone: data['centerPhone'] as String? ?? '(0262) 642 04 30',
      isAdopted: data['isAdopted'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'species': species,
      'breed': breed,
      'gender': gender,
      'age': age,
      'imageUrl': imageUrl,
      'description': description,
      'healthStatus': healthStatus,
      'centerPhone': centerPhone,
      'isAdopted': isAdopted,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
