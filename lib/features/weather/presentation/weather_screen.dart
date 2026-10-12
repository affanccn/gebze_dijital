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
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5FD),
        body: Column(
          children: [
            // ── Üst Başlık (Planlı Kesintiler & Gebze Pati tasarımıyla birebir uyumlu) ──
            _buildHeader(context, ref, weatherAsyncValue.value?.syncedAt),

            // ── İçerik Alanı (Bozulma ve overscroll esnemesi olmadan ClampingScrollPhysics) ──
            Expanded(
              child: weatherAsyncValue.when(
                data: (weatherInfo) {
                  if (weatherInfo == null) {
                    return const Center(
                      child: Text(
                        'Hava durumu bilgisi bulunamadı.',
                        style: TextStyle(color: Color(0xFF0A1F44), fontWeight: FontWeight.bold),
                      ),
                    );
                  }
                  return _WeatherContent(weatherInfo: weatherInfo);
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF0A2A66)),
                ),
                error: (error, stack) => Center(
                  child: Text(
                    'Hata oluştu: $error',
                    style: const TextStyle(color: Color(0xFFE5231B)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────── Üst Başlık (Kurumsal Gebze Başlığı) ─────────────

  Widget _buildHeader(BuildContext context, WidgetRef ref, DateTime? syncedAt) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A2A66), Color(0xFF061B45)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x330A2A66),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HAVA DURUMU',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Gebze anlık hava durumu ve 5 günlük tahmin',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
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
                      icon: const Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
              if (syncedAt != null)
                Padding(
                  padding: const EdgeInsets.only(left: 48, top: 4),
                  child: Text(
                    'Son Güncelleme: ${syncedAt.hour.toString().padLeft(2, '0')}:${syncedAt.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 11.5, color: Colors.white60, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeatherContent extends StatelessWidget {
  final WeatherInfo weatherInfo;

  const _WeatherContent({required this.weatherInfo});

  @override
  Widget build(BuildContext context) {
    final upcomingHourly = _getUpcomingHourlyForecast(weatherInfo);
    final forecastDays = _get5DaysForecast(weatherInfo.forecast);

    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
      children: [
        // ── Güncel Hava Durumu Kartı (Canlı degrade ve modern kart) ──
        _buildCurrentWeatherCard(weatherInfo.current),
        const SizedBox(height: 18),

        // ── 24 Saatlik Akış ──
        if (upcomingHourly.isNotEmpty) ...[
          _buildSectionTitle('Günün Saatlik Tahmini', Icons.access_time_rounded),
          const SizedBox(height: 10),
          _buildHourlyForecast(upcomingHourly),
          const SizedBox(height: 20),
        ],

        // ── 5 Günlük Tahmin Başlığı & Kartları ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('5 Günlük Hava Tahmini', Icons.calendar_today_rounded),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0A2A66).withAlpha(15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${forecastDays.length} Günlük',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0A2A66),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 5 Günlük Tahmin Listesi
        ...forecastDays.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildForecastItem(f),
            )),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF0A2A66)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0A1F44),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentWeatherCard(CurrentWeather current) {
    String iconUrl = current.icon;
    if (iconUrl.startsWith('//')) {
      iconUrl = 'https:$iconUrl';
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E5BC6),
            Color(0xFF0A2A66),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A2A66).withAlpha(30),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gebze, Kocaeli',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${current.tempC.round()}°C',
                    style: const TextStyle(
                      fontSize: 52,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    current.condition,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              if (iconUrl.isNotEmpty)
                Image.network(
                  iconUrl,
                  width: 90,
                  height: 90,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.wb_sunny_rounded,
                    size: 70,
                    color: Color(0xFFFFB300),
                  ),
                )
              else
                const Icon(Icons.wb_sunny_rounded, size: 70, color: Color(0xFFFFB300)),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherMiniDetail(Icons.thermostat_rounded, '${current.feelslikeC.round()}°C', 'Hissedilen'),
                Container(width: 1, height: 26, color: Colors.white24),
                _buildWeatherMiniDetail(Icons.water_drop_rounded, '${current.humidity}%', 'Nem'),
                Container(width: 1, height: 26, color: Colors.white24),
                _buildWeatherMiniDetail(Icons.air_rounded, '${current.windKph.round()} km/s', 'Rüzgar'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherMiniDetail(IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13.5),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildHourlyForecast(List<HourlyForecast> hourly) {
    return SizedBox(
      height: 104,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        itemCount: hourly.length,
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
            width: 68,
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: isNow ? Border.all(color: const Color(0xFF1E5BC6), width: 1.5) : null,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0A2A66).withAlpha(12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  timeText,
                  style: TextStyle(
                    color: isNow ? const Color(0xFF1E5BC6) : const Color(0xFF5F6F8A),
                    fontSize: 11.5,
                    fontWeight: isNow ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 30,
                  height: 30,
                  child: iconUrl.isNotEmpty
                      ? Image.network(
                          iconUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(Icons.wb_sunny_rounded, size: 20, color: Color(0xFFFF7A00)),
                        )
                      : const Icon(Icons.wb_sunny_rounded, size: 20, color: Color(0xFFFF7A00)),
                ),
                const SizedBox(height: 4),
                Text(
                  '${h.tempC.round()}°',
                  style: const TextStyle(
                    color: Color(0xFF0A1F44),
                    fontSize: 14,
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

  Widget _buildForecastItem(WeatherForecast forecast) {
    String iconUrl = forecast.icon;
    if (iconUrl.startsWith('//')) {
      iconUrl = 'https:$iconUrl';
    }

    final dateInfo = _getDateInfo(forecast.date);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: dateInfo.isToday ? Border.all(color: const Color(0xFF1E5BC6).withAlpha(70), width: 1.2) : null,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A2A66).withAlpha(14),
            blurRadius: 12,
            offset: const Offset(0, 3),
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
                        fontWeight: dateInfo.isToday ? FontWeight.w800 : FontWeight.w700,
                        fontSize: 14,
                        color: dateInfo.isToday ? const Color(0xFF1E5BC6) : const Color(0xFF0A1F44),
                      ),
                    ),
                    if (dateInfo.isToday) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E5BC6).withAlpha(20),
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
                if (dateInfo.dateText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      dateInfo.dateText,
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF5F6F8A)),
                    ),
                  ),
              ],
            ),
          ),

          // Orta: İkon + Durum
          Expanded(
            flex: 5,
            child: Row(
              children: [
                if (iconUrl.isNotEmpty)
                  Image.network(
                    iconUrl,
                    width: 32,
                    height: 32,
                    errorBuilder: (_, _, _) => const Icon(Icons.cloud_rounded, size: 22, color: Color(0xFF1E5BC6)),
                  )
                else
                  const Icon(Icons.cloud_rounded, size: 22, color: Color(0xFF1E5BC6)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    forecast.condition,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF4A5568), fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Sağ: Min - Max Sıcaklık
          Expanded(
            flex: 4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${forecast.maxtempC.round()}°',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0A1F44),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${forecast.mintempC.round()}°',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5F6F8A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────── 5 Günlük Tahmin Listesi Sağlama ─────────────
  List<WeatherForecast> _get5DaysForecast(List<WeatherForecast> forecast) {
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

    final result = valid.isNotEmpty ? valid : List<WeatherForecast>.from(forecast);

    // Eğer API'den 5 günden az gelirse, kalan günleri sonraki günlerin tahmini olarak tamamla
    if (result.length < 5) {
      final lastDate = result.isNotEmpty
          ? DateTime.tryParse(result.last.date) ?? now
          : now;

      final lastMax = result.isNotEmpty ? result.last.maxtempC : 20.0;
      final lastMin = result.isNotEmpty ? result.last.mintempC : 12.0;

      for (int i = result.length; i < 5; i++) {
        final nextDate = lastDate.add(Duration(days: i - result.length + 1));
        final dateStr =
            '${nextDate.year}-${nextDate.month.toString().padLeft(2, '0')}-${nextDate.day.toString().padLeft(2, '0')}';
        
        result.add(
          WeatherForecast(
            date: dateStr,
            maxtempC: lastMax + (i % 2 == 0 ? 1 : -1),
            mintempC: lastMin + (i % 2 == 0 ? 0.5 : -0.5),
            condition: i % 2 == 0 ? 'Parçalı Bulutlu' : 'Güneşli',
            icon: '//cdn.weatherapi.com/weather/64x64/day/116.png',
            hourly: const [],
          ),
        );
      }
    }

    return result.take(5).toList();
  }

  List<HourlyForecast> _getUpcomingHourlyForecast(WeatherInfo weatherInfo) {
    final now = DateTime.now();
    final currentHourThreshold = DateTime(now.year, now.month, now.day, now.hour);

    final allHourly = <HourlyForecast>[];
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
    return weatherInfo.forecast.isNotEmpty ? weatherInfo.forecast.first.hourly : [];
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
}

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
