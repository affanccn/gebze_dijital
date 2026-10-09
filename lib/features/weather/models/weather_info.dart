import 'package:cloud_firestore/cloud_firestore.dart';

class WeatherInfo {
  final CurrentWeather current;
  final List<WeatherForecast> forecast;

  const WeatherInfo({
    required this.current,
    required this.forecast,
  });

  factory WeatherInfo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    
    final currentData = data?['current'] as Map<String, dynamic>?;
    final forecastData = data?['forecast'] as List<dynamic>?;

    return WeatherInfo(
      current: CurrentWeather.fromMap(currentData ?? {}),
      forecast: forecastData?.map((e) => WeatherForecast.fromMap(e)).toList() ?? [],
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

  const WeatherForecast({
    required this.date,
    required this.maxtempC,
    required this.mintempC,
    required this.condition,
    required this.icon,
  });

  factory WeatherForecast.fromMap(Map<String, dynamic> map) {
    return WeatherForecast(
      date: map['date'] ?? '',
      maxtempC: (map['maxtemp_c'] ?? 0).toDouble(),
      mintempC: (map['mintemp_c'] ?? 0).toDouble(),
      condition: map['condition'] ?? '',
      icon: map['icon'] ?? '',
    );
  }
}
