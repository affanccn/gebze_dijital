import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/weather_info.dart';

final weatherProvider = FutureProvider.autoDispose<WeatherInfo?>((ref) async {
  final doc = await FirebaseFirestore.instance
      .collection('weather_info')
      .doc('gebze')
      .get();
      
  if (!doc.exists) return null;
  return WeatherInfo.fromFirestore(doc);
});
