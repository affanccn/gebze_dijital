import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/gebze_time.dart';

class WeatherInfo {
  final CurrentWeather current;
  final List<WeatherForecast> forecast;
  final DateTime? syncedAt;

  const WeatherInfo({
    required this.current,
    required this.forecast,
    this.syncedAt,
  });

  DateTime? get syncedAtGebze =>
      syncedAt != null ? GebzeTime.toGebzeTime(syncedAt!) : null;

  factory WeatherInfo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    
    final currentData = data?['current'] as Map<String, dynamic>?;
    final forecastData = data?['forecast'] as List<dynamic>?;
    final syncedAtTimestamp = data?['syncedAt'] as Timestamp?;

    return WeatherInfo(
      current: CurrentWeather.fromMap(currentData ?? {}),
      forecast: forecastData?.map((e) => WeatherForecast.fromMap(e)).toList() ?? [],
      syncedAt: syncedAtTimestamp?.toDate(),
    );
  }
}

class CurrentWeather {
  final double tempC;
  final double feelslikeC;
  final String condition;
  final String icon;
  final int humidity;
  final double windKph;

  const CurrentWeather({
    required this.tempC,
    required this.feelslikeC,
    required this.condition,
    required this.icon,
    required this.humidity,
    required this.windKph,
  });

  factory CurrentWeather.fromMap(Map<String, dynamic> map) {
    return CurrentWeather(
      tempC: (map['temp_c'] ?? 0).toDouble(),
      feelslikeC: (map['feelslike_c'] ?? 0).toDouble(),
      condition: map['condition'] ?? '',
      icon: map['icon'] ?? '',
      humidity: map['humidity'] ?? 0,
      windKph: (map['wind_kph'] ?? 0).toDouble(),
    );
  }
}

class WeatherForecast {
  final String date;
  final double maxtempC;
  final double mintempC;
  final String condition;
  final String icon;
  final List<HourlyForecast> hourly;

  const WeatherForecast({
    required this.date,
    required this.maxtempC,
    required this.mintempC,
    required this.condition,
    required this.icon,
    this.hourly = const [],
  });

  DateTime get dateTime => GebzeTime.parseWeatherDate(date);

  factory WeatherForecast.fromMap(Map<String, dynamic> map) {
    return WeatherForecast(
      date: map['date'] ?? '',
      maxtempC: (map['maxtemp_c'] ?? 0).toDouble(),
      mintempC: (map['mintemp_c'] ?? 0).toDouble(),
      condition: map['condition'] ?? '',
      icon: map['icon'] ?? '',
      hourly: (map['hourly'] as List<dynamic>?)
              ?.map((e) => HourlyForecast.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class HourlyForecast {
  final String time;
  final double tempC;
  final String icon;

  const HourlyForecast({
    required this.time,
    required this.tempC,
    required this.icon,
  });

  DateTime get dateTime => GebzeTime.parseWeatherTime(time);

  factory HourlyForecast.fromMap(Map<String, dynamic> map) {
    return HourlyForecast(
      time: map['time'] ?? '',
      tempC: (map['temp_c'] ?? 0).toDouble(),
      icon: map['icon'] ?? '',
    );
  }
}

