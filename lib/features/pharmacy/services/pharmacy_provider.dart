import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pharmacy.dart';

final pharmacyProvider = FutureProvider.autoDispose<List<Pharmacy>>((
  ref,
) async {
  final querySnapshot = await FirebaseFirestore.instance
      .collection('pharmacies_on_duty')
      .get();

  return querySnapshot.docs.map((doc) => Pharmacy.fromFirestore(doc)).toList();
});
