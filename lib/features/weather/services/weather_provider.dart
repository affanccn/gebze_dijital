import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/weather_info.dart';

final weatherProvider = FutureProvider<WeatherInfo?>((ref) async {
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 30), () {
    link.close();
  });
  ref.onDispose(() => timer.cancel());

  try {
    final doc = await FirebaseFirestore.instance
        .collection('weather_info')
        .doc('gebze')
        .get(const GetOptions(source: Source.serverAndCache));

    if (!doc.exists) return null;
    return WeatherInfo.fromFirestore(doc);
  } catch (e) {
    return null;
  }
});
