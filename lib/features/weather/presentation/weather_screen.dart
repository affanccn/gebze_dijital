import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/weather_provider.dart';
import '../models/weather_info.dart';

class WeatherScreen extends ConsumerWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsyncValue = ref.watch(weatherProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF061B45),
        body: weatherAsyncValue.when(
          data: (weatherInfo) {
            if (weatherInfo == null) {
              return const Center(
                  child: Text('Hava durumu bilgisi bulunamadı.',
                      style: TextStyle(color: Colors.white)));
            }
            return _buildContent(context, weatherInfo);
          },
          loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white)),
          error: (error, stack) => Center(
              child: Text('Hata oluştu: $error',
                  style: const TextStyle(color: Colors.white))),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WeatherInfo weatherInfo) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF061B45), // Deep navy
            Color(0xFF1E5BC6), // Lighter blue
          ],
        ),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          const SizedBox(height: 10),
          _buildCurrentWeather(weatherInfo.current),
          if (weatherInfo.forecast.isNotEmpty && weatherInfo.forecast.first.hourly.isNotEmpty) ...[
            const SizedBox(height: 32),
            _buildHourlyForecast(weatherInfo.forecast.first.hourly),
          ],
          const SizedBox(height: 32),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: const BoxDecoration(
                color: Color(0xFFF4F6FB), // Light soft background
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gelecek Günler',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0A1F44), // Deep navy text
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      physics: const ClampingScrollPhysics(),
                      itemCount: weatherInfo.forecast.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildForecastItem(
                            weatherInfo.forecast[index]);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentWeather(CurrentWeather current) {
    String iconUrl = current.icon;
    if (iconUrl.startsWith('//')) {
      iconUrl = 'https:$iconUrl';
    }

    return Column(
      children: [
        if (iconUrl.isNotEmpty)
          Image.network(
            iconUrl,
            width: 90,
            height: 90,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
                Icons.wb_sunny_rounded,
                size: 80,
                color: Color(0xFFFFB300)),
          ),
        const SizedBox(height: 12),
        Text(
          '${current.tempC.round()}°C',
          style: const TextStyle(
            fontSize: 72,
            height: 1.1,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        Text(
          current.condition,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildWeatherDetail(
                Icons.water_drop_rounded, '${current.humidity}%', 'Nem'),
            const SizedBox(width: 48),
            _buildWeatherDetail(
                Icons.air_rounded, '${current.windKph.round()} km/s', 'Rüzgar'),
          ],
        )
      ],
    );
  }

  Widget _buildWeatherDetail(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
                fontSize: 13)),
      ],
    );
  }

  Widget _buildForecastItem(WeatherForecast forecast) {
    String iconUrl = forecast.icon;
    if (iconUrl.startsWith('//')) {
      iconUrl = 'https:$iconUrl';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A2A66).withAlpha(12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              _formatDate(forecast.date),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Color(0xFF0A1F44),
              ),
            ),
          ),
          if (iconUrl.isNotEmpty)
            Image.network(iconUrl,
                width: 36,
                height: 36,
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.wb_sunny_rounded,
                    color: Color(0xFFFFB300),
                    size: 28))
          else
            const Icon(Icons.wb_sunny_rounded,
                color: Color(0xFFFFB300), size: 28),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${forecast.maxtempC.round()}°',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Color(0xFF0A1F44)),
                ),
                const SizedBox(width: 8),
                Text(
                  '${forecast.mintempC.round()}°',
                  style: const TextStyle(
                      color: Color(0xFF909BB0),
                      fontWeight: FontWeight.w600,
                      fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyForecast(List<HourlyForecast> hourly) {
    // Filter to show from current hour onwards if we want, or just show all.
    // We'll show all but start scroll position? Just showing all is fine.
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: hourly.length,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemBuilder: (context, index) {
          final h = hourly[index];
          String iconUrl = h.icon;
          if (iconUrl.startsWith('//')) iconUrl = 'https:$iconUrl';
          final time = h.time.split(' ').last; // e.g. "2023-10-09 15:00" -> "15:00"

          return Padding(
            padding: const EdgeInsets.only(right: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(time, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                if (iconUrl.isNotEmpty)
                  Image.network(iconUrl, width: 36, height: 36, errorBuilder: (_,__,___)=> const Icon(Icons.cloud_rounded, color: Colors.white, size: 28))
                else
                  const Icon(Icons.cloud_rounded, color: Colors.white, size: 28),
                const SizedBox(height: 10),
                Text('${h.tempC.round()}°', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
      return days[date.weekday - 1];
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.transparent, // Background will seamlessly blend
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'HAVA DURUMU',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.cloud_rounded, color: Colors.white, size: 22),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(left: 48, top: 2),
                child: Text(
                  'Gebze için güncel ve saatlik hava durumu raporu.',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


