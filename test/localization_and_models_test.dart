import 'package:flutter_test/flutter_test.dart';
import 'package:gebze_dijital/core/localization/app_strings.dart';
import 'package:gebze_dijital/features/weather/models/weather_info.dart';

void main() {
  group('AppStrings Localization & Retry Tests', () {
    test('btn_retry returns correct translations for tr, en, ar', () {
      expect(AppStrings.get('btn_retry', 'tr'), 'Tekrar Dene');
      expect(AppStrings.get('btn_retry', 'en'), 'Try Again');
      expect(AppStrings.get('btn_retry', 'ar'), 'إعادة المحاولة');
    });

    test('AppStrings falls back to Turkish when key or lang is missing', () {
      expect(AppStrings.get('btn_retry', 'de'), 'Tekrar Dene');
      expect(
        AppStrings.get('non_existent_key_xyz', 'tr'),
        'non_existent_key_xyz',
      );
    });

    test('AppStrings day name helper handles all days and languages', () {
      expect(AppStrings.getDayName(1, 'tr'), 'Pazartesi');
      expect(AppStrings.getDayName(1, 'en'), 'Monday');
      expect(AppStrings.getDayName(1, 'ar'), 'الاثنين');
      expect(AppStrings.getDayName(7, 'tr'), 'Pazar');
    });
  });

  group('Weather Models Data Parsing & Robustness', () {
    test('CurrentWeather parses valid map with type conversions', () {
      final map = {
        'temp_c': 22,
        'feelslike_c': 21.5,
        'condition': 'Güneşli',
        'icon': '//cdn.weatherapi.com/64.png',
        'humidity': 55,
        'wind_kph': 14,
      };

      final current = CurrentWeather.fromMap(map);
      expect(current.tempC, 22.0);
      expect(current.feelslikeC, 21.5);
      expect(current.condition, 'Güneşli');
      expect(current.humidity, 55);
      expect(current.windKph, 14.0);
    });

    test('CurrentWeather gracefully handles empty or null map', () {
      final current = CurrentWeather.fromMap({});
      expect(current.tempC, 0.0);
      expect(current.feelslikeC, 0.0);
      expect(current.condition, '');
      expect(current.humidity, 0);
      expect(current.windKph, 0.0);
    });

    test('WeatherForecast parses hourly forecast list properly', () {
      final map = {
        'date': '2026-10-18',
        'maxtemp_c': 24,
        'mintemp_c': 15,
        'condition': 'Açık',
        'icon': '//cdn.weatherapi.com/icon.png',
        'hourly': [
          {'time': '2026-10-18 12:00', 'temp_c': 22.4, 'icon': '//icon.png'},
          {'time': '2026-10-18 13:00', 'temp_c': 23.1, 'icon': '//icon.png'},
        ],
      };

      final forecast = WeatherForecast.fromMap(map);
      expect(forecast.date, '2026-10-18');
      expect(forecast.maxtempC, 24.0);
      expect(forecast.mintempC, 15.0);
      expect(forecast.hourly.length, 2);
      expect(forecast.hourly[0].tempC, 22.4);
      expect(forecast.hourly[1].time, '2026-10-18 13:00');
    });
  });
}
