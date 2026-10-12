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
            return _WeatherBody(weatherInfo: weatherInfo);
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
}

class _WeatherBody extends ConsumerWidget {
  final WeatherInfo weatherInfo;
  const _WeatherBody({required this.weatherInfo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingHourly = _getUpcomingHourlyForecast(weatherInfo);
    final forecastDays = _getForecastDays(weatherInfo.forecast);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF061B45),
            Color(0xFF1E5BC6),
          ],
        ),
      ),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ──
          SliverToBoxAdapter(
            child: _buildHeader(context, ref, weatherInfo.syncedAt),
          ),

          // ── Güncel hava durumu ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: _buildCurrentWeather(weatherInfo.current),
            ),
          ),

          // ── Saatlik tahmin ──
          if (upcomingHourly.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: _buildHourlyForecast(upcomingHourly),
              ),
            ),

          // ── Günlük tahmin başlığı ──
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.only(top: 24),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 4),
              decoration: const BoxDecoration(
                color: Color(0xFFF4F6FB),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A1F44).withAlpha(35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Günlük Tahmin',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0A1F44),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A1F44).withAlpha(15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${forecastDays.length} Gün',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0A1F44),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),

          // ── Günlük tahmin kartları ──
          SliverToBoxAdapter(
            child: Container(
              color: const Color(0xFFF4F6FB),
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  for (int i = 0; i < forecastDays.length; i++) ...[
                    _buildForecastItem(forecastDays[i]),
                    if (i < forecastDays.length - 1) const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────── Güncel Hava Durumu ─────────────

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
            width: 80,
            height: 80,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.wb_sunny_rounded,
                size: 70,
                color: Color(0xFFFFB300)),
          ),
        const SizedBox(height: 6),
        Text(
          '${current.tempC.round()}°C',
          style: const TextStyle(
            fontSize: 64,
            height: 1.1,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        Text(
          current.condition,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildWeatherDetail(
                Icons.water_drop_rounded, '${current.humidity}%', 'Nem'),
            const SizedBox(width: 48),
            _buildWeatherDetail(Icons.air_rounded,
                '${current.windKph.round()} km/s', 'Rüzgar'),
          ],
        ),
      ],
    );
  }

  Widget _buildWeatherDetail(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
                fontSize: 12)),
      ],
    );
  }

  // ───────────── Saatlik Tahmin ─────────────

  Widget _buildHourlyForecast(List<HourlyForecast> hourly) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: hourly.length,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemBuilder: (context, index) {
          final h = hourly[index];
          String iconUrl = h.icon;
          if (iconUrl.startsWith('//')) iconUrl = 'https:$iconUrl';

          final isNow = index == 0;
          String timeText = 'Şimdi';
          if (!isNow) {
            try {
              final parsed = DateTime.parse(h.time);
              timeText = '${parsed.hour.toString().padLeft(2, '0')}:00';
            } catch (_) {
              timeText = h.time.split(' ').last;
            }
          }

          return Container(
            width: 64,
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              color: isNow
                  ? Colors.white.withAlpha(45)
                  : Colors.white.withAlpha(18),
              borderRadius: BorderRadius.circular(16),
              border: isNow
                  ? Border.all(
                      color: Colors.white.withAlpha(120), width: 1.2)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeText,
                  style: TextStyle(
                    color: isNow ? Colors.white : Colors.white70,
                    fontSize: 11.5,
                    fontWeight: isNow ? FontWeight.w800 : FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 30,
                  height: 30,
                  child: iconUrl.isNotEmpty
                      ? Image.network(
                          iconUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.cloud_rounded,
                                  color: Colors.white, size: 24),
                        )
                      : const Icon(Icons.cloud_rounded,
                          color: Colors.white, size: 24),
                ),
                const SizedBox(height: 4),
                Text(
                  '${h.tempC.round()}°',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ───────────── Günlük Tahmin Kartı ─────────────

  Widget _buildForecastItem(WeatherForecast forecast) {
    String iconUrl = forecast.icon;
    if (iconUrl.startsWith('//')) {
      iconUrl = 'https:$iconUrl';
    }

    final dateInfo = _getDateInfo(forecast.date);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: dateInfo.isToday
            ? Border.all(
                color: const Color(0xFF1E5BC6).withAlpha(60), width: 1.2)
            : null,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A2A66).withAlpha(10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Sol: Gün adı + tarih
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      dateInfo.dayName,
                      style: TextStyle(
                        fontWeight: dateInfo.isToday
                            ? FontWeight.w800
                            : FontWeight.w700,
                        fontSize: 14.5,
                        color: dateInfo.isToday
                            ? const Color(0xFF1E5BC6)
                            : const Color(0xFF0A1F44),
                      ),
                    ),
                    if (dateInfo.isToday) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E5BC6).withAlpha(25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Bugün',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E5BC6),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  dateInfo.dateText,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF909BB0),
                  ),
                ),
              ],
            ),
          ),
          // Orta: İkon
          if (iconUrl.isNotEmpty)
            Image.network(iconUrl,
                width: 34,
                height: 34,
                errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.wb_sunny_rounded,
                    color: Color(0xFFFFB300),
                    size: 26))
          else
            const Icon(Icons.wb_sunny_rounded,
                color: Color(0xFFFFB300), size: 26),
          const SizedBox(width: 8),
          // Sağ: Sıcaklık
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${forecast.maxtempC.round()}°',
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Color(0xFF0A1F44)),
              ),
              const SizedBox(width: 6),
              Text(
                '${forecast.mintempC.round()}°',
                style: const TextStyle(
                    color: Color(0xFF909BB0),
                    fontWeight: FontWeight.w600,
                    fontSize: 15),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────── Yardımcı Fonksiyonlar ─────────────

  List<HourlyForecast> _getUpcomingHourlyForecast(WeatherInfo weatherInfo) {
    final now = DateTime.now();
    final currentHourThreshold =
        DateTime(now.year, now.month, now.day, now.hour);

    final List<HourlyForecast> allHourly = [];
    for (final day in weatherInfo.forecast) {
      allHourly.addAll(day.hourly);
    }

    final upcoming = allHourly.where((h) {
      try {
        final itemTime = DateTime.parse(h.time);
        return !itemTime.isBefore(currentHourThreshold);
      } catch (_) {
        return true;
      }
    }).toList();

    if (upcoming.isNotEmpty) {
      return upcoming.take(24).toList();
    }
    return weatherInfo.forecast.isNotEmpty
        ? weatherInfo.forecast.first.hourly
        : [];
  }

  List<WeatherForecast> _getForecastDays(List<WeatherForecast> forecast) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final valid = forecast.where((f) {
      try {
        final d = DateTime.parse(f.date);
        final itemDate = DateTime(d.year, d.month, d.day);
        return !itemDate.isBefore(today);
      } catch (_) {
        return true;
      }
    }).toList();

    return valid.isNotEmpty ? valid : forecast;
  }

  _DateInfo _getDateInfo(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final target = DateTime(date.year, date.month, date.day);
      final diff = target.difference(today).inDays;

      const dayNames = [
        'Pazartesi',
        'Salı',
        'Çarşamba',
        'Perşembe',
        'Cuma',
        'Cumartesi',
        'Pazar'
      ];
      final dayName = dayNames[date.weekday - 1];
      final dateText =
          '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

      return _DateInfo(
        dayName: dayName,
        dateText: dateText,
        isToday: diff == 0,
      );
    } catch (e) {
      return _DateInfo(
        dayName: dateStr,
        dateText: '',
        isToday: false,
      );
    }
  }

  // ───────────── Başlık ─────────────

  Widget _buildHeader(
      BuildContext context, WidgetRef ref, DateTime? syncedAt) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 22),
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
                IconButton(
                  tooltip: 'Yenile',
                  onPressed: () {
                    ref.invalidate(weatherProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Hava durumu güncelleniyor...'),
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.refresh_rounded,
                        color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 48, top: 2),
              child: Row(
                children: [
                  const Text(
                    'Gebze hava durumu raporu',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  if (syncedAt != null) ...[
                    const Text(' • ',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(
                      '${syncedAt.hour.toString().padLeft(2, '0')}:${syncedAt.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarih bilgisi yardımcı sınıfı
class _DateInfo {
  final String dayName;
  final String dateText;
  final bool isToday;

  const _DateInfo({
    required this.dayName,
    required this.dateText,
    required this.isToday,
  });
}
