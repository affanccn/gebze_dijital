import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/weather_provider.dart';
import '../models/weather_info.dart';

class WeatherScreen extends ConsumerWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsyncValue = ref.watch(weatherProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gebze Hava Durumu'),
        backgroundColor: const Color(0xFF0A2A66),
        foregroundColor: Colors.white,
      ),
      body: weatherAsyncValue.when(
        data: (weatherInfo) {
          if (weatherInfo == null) {
            return const Center(child: Text('Hava durumu bilgisi bulunamadı.'));
          }
          return _buildContent(context, weatherInfo);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Hata oluştu: $error')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WeatherInfo weatherInfo) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A2A66), Color(0xFF1E5BC6)],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),
          _buildCurrentWeather(weatherInfo.current),
          const SizedBox(height: 40),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5FD),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gelecek Günler',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A1F44),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: weatherInfo.forecast.length,
                      itemBuilder: (context, index) {
                        return _buildForecastItem(weatherInfo.forecast[index]);
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
    // Add "https:" if icon url starts with "//"
    String iconUrl = current.icon;
    if (iconUrl.startsWith('//')) {
      iconUrl = 'https:$iconUrl';
    }

    return Column(
      children: [
        if (iconUrl.isNotEmpty)
          Image.network(
            iconUrl,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.cloud, size: 80, color: Colors.white),
          ),
        const SizedBox(height: 8),
        Text(
          '${current.tempC.round()}°C',
          style: const TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        Text(
          current.condition,
          style: const TextStyle(
            fontSize: 24,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildWeatherDetail(Icons.water_drop, '${current.humidity}%', 'Nem'),
            const SizedBox(width: 40),
            _buildWeatherDetail(Icons.air, '${current.windKph.round()} km/s', 'Rüzgar'),
          ],
        )
      ],
    );
  }

  Widget _buildWeatherDetail(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  Widget _buildForecastItem(WeatherForecast forecast) {
    String iconUrl = forecast.icon;
    if (iconUrl.startsWith('//')) {
      iconUrl = 'https:$iconUrl';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A2A66).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              _formatDate(forecast.date),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF0A1F44),
              ),
            ),
          ),
          if (iconUrl.isNotEmpty)
            Image.network(iconUrl, width: 40, height: 40, errorBuilder: (_, __, ___) => const Icon(Icons.cloud, color: Colors.grey))
          else
            const Icon(Icons.cloud, color: Colors.grey, size: 40),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${forecast.maxtempC.round()}°',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  '${forecast.mintempC.round()}°',
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    // Basic date formatter from "YYYY-MM-DD"
    try {
      final date = DateTime.parse(dateStr);
      final days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
      return '${date.day}.${date.month} ${days[date.weekday - 1]}';
    } catch (e) {
      return dateStr;
    }
  }
}
