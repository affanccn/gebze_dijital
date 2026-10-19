import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/weather_info.dart';

final weatherProvider = StreamProvider.autoDispose<WeatherInfo?>((ref) {
  return FirebaseFirestore.instance
      .collection('weather_info')
      .doc('gebze')
      .snapshots()
      .map((doc) {
    if (!doc.exists) return null;
    return WeatherInfo.fromFirestore(doc);
  });
});
