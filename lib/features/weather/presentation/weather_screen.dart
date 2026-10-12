import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/weather_provider.dart';
import '../models/weather_info.dart';
import '../../../core/localization/app_strings.dart';

class _C {
  static const navy = Color(0xFF0A2A66);
  static const bg = Color(0xFFF1F5FD);
  static const textDark = Color(0xFF0A1F44);
  static const textMuted = Color(0xFF5F6F8A);
  static const navyGradient = [Color(0xFF1E5BC6), Color(0xFF0A2A66)];
}

const String _kBodyFont = 'system-ui';
const List<String> _kBodyFontFallback = [
  '-apple-system',
  'Segoe UI',
  'Roboto',
  'Helvetica Neue',
  'Noto Sans',
  'Liberation Sans',
  'Arial',
  'sans-serif',
];

List<BoxShadow> _softShadow() => [
      BoxShadow(
        color: const Color(0xFF0A2A66).withAlpha(18),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ];

class _ForecastDateInfo {
  final String dayTitle;
  final String dateSubtitle;
  final bool isToday;
  final bool isTomorrow;

  const _ForecastDateInfo({
    required this.dayTitle,
    required this.dateSubtitle,
    required this.isToday,
    required this.isTomorrow,
  });
}

class WeatherScreen extends ConsumerWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsyncValue = ref.watch(weatherProvider);
    final lang = ref.watch(appLanguageProvider);
    final base = Theme.of(context);

    return Theme(
      data: base.copyWith(
        textTheme: base.textTheme.apply(
          fontFamily: _kBodyFont,
          fontFamilyFallback: _kBodyFontFallback,
        ),
      ),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
        child: Scaffold(
          backgroundColor: _C.bg,
          body: Column(
            children: [
              _buildHeader(context, lang),
              Expanded(
                child: weatherAsyncValue.when(
                  data: (weatherInfo) {
                    if (weatherInfo == null) {
                      return _buildEmptyState(context, lang);
                    }
                    return _buildContent(context, weatherInfo, lang);
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: _C.navy),
                  ),
                  error: (error, stack) => _buildErrorState(context, error.toString(), lang),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String lang) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _C.navyGradient,
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
                  Expanded(
                    child: Text(
                      AppStrings.get('weather_screen_title', lang),
                      style: const TextStyle(
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
                    child: const Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 22),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 48, top: 2),
                child: Text(
                  AppStrings.get('weather_screen_sub', lang),
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WeatherInfo weatherInfo, String lang) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurrentWeatherCard(weatherInfo.current, weatherInfo.syncedAt, lang),
          if (weatherInfo.forecast.isNotEmpty && weatherInfo.forecast.any((f) => f.hourly.isNotEmpty)) ...[
            const SizedBox(height: 20),
            _buildHourlyForecastSection(weatherInfo.forecast, lang),
          ],
          const SizedBox(height: 20),
          _buildMultiDayForecastSection(weatherInfo.forecast, lang),
        ],
      ),
    );
  }

  Widget _buildCurrentWeatherCard(CurrentWeather current, DateTime? syncedAt, String lang) {
    String iconUrl = current.icon;
    if (iconUrl.startsWith('//')) {
      iconUrl = 'https:$iconUrl';
    }

    String syncTimeStr = '';
    if (syncedAt != null) {
      final hour = syncedAt.hour.toString().padLeft(2, '0');
      final minute = syncedAt.minute.toString().padLeft(2, '0');
      syncTimeStr = '$hour:$minute';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
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
            color: const Color(0xFF0A2A66).withAlpha(40),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: Colors.white70, size: 18),
                  const SizedBox(width: 5),
                  Text(
                    AppStrings.get('gebze_location', lang),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(35),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  current.condition.isNotEmpty
                      ? current.condition
                      : AppStrings.get('current_condition', lang),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (iconUrl.isNotEmpty)
                Image.network(
                  iconUrl,
                  width: 82,
                  height: 82,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.wb_sunny_rounded,
                    size: 72,
                    color: Color(0xFFFFB300),
                  ),
                )
              else
                const Icon(
                  Icons.wb_sunny_rounded,
                  size: 72,
                  color: Color(0xFFFFB300),
                ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${current.tempC.round()}°',
                    style: const TextStyle(
                      fontSize: 64,
                      height: 1.0,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${AppStrings.get('feels_like', lang)} ${current.feelslikeC.round()}°C',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withAlpha(210),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherStat(
                  Icons.water_drop_rounded,
                  '${current.humidity}%',
                  AppStrings.get('humidity', lang),
                ),
                Container(width: 1, height: 26, color: Colors.white24),
                _buildWeatherStat(
                  Icons.air_rounded,
                  '${current.windKph.round()} km/s',
                  AppStrings.get('wind', lang),
                ),
                Container(width: 1, height: 26, color: Colors.white24),
                _buildWeatherStat(
                  Icons.thermostat_rounded,
                  '${current.feelslikeC.round()}°',
                  AppStrings.get('feels_like', lang),
                ),
              ],
            ),
          ),
          if (syncTimeStr.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.sync_rounded, size: 12, color: Colors.white.withAlpha(150)),
                const SizedBox(width: 4),
                Text(
                  '${AppStrings.get('last_updated', lang)} $syncTimeStr',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withAlpha(160),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeatherStat(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w500,
            fontSize: 11.5,
          ),
        ),
      ],
    );
  }

  DateTime _getGebzeTime() {
    // Gebze / Türkiye sabit UTC+3 saatindedir
    return DateTime.now().toUtc().add(const Duration(hours: 3));
  }

  DateTime? _parseHourTime(String timeStr, DateTime gebzeNow) {
    final parsed = DateTime.tryParse(timeStr);
    if (parsed != null) return parsed;

    if (timeStr.contains(':')) {
      final parts = timeStr.split(':');
      final hr = int.tryParse(parts[0]) ?? 0;
      return DateTime(gebzeNow.year, gebzeNow.month, gebzeNow.day, hr);
    }
    return null;
  }

  Widget _buildHourlyForecastSection(List<WeatherForecast> forecastList, String lang) {
    final gebzeNow = _getGebzeTime();

    // Tüm tahmin günlerinden saatlik verileri sırayla topla
    final allHours = <HourlyForecast>[];
    for (final day in forecastList) {
      allHours.addAll(day.hourly);
    }

    // Telefon ve Gebze saatine göre mevcut saatten (ve sonrasından) başlat
    final currentHourThreshold =
        DateTime(gebzeNow.year, gebzeNow.month, gebzeNow.day, gebzeNow.hour);

    List<HourlyForecast> upcoming = allHours.where((h) {
      final dt = _parseHourTime(h.time, gebzeNow);
      if (dt == null) return false;
      return !dt.isBefore(currentHourThreshold);
    }).toList();

    // Eğer eski veriler nedeniyle liste boş kalırsa mevcut saate en yakın olandan başlat
    if (upcoming.isEmpty && allHours.isNotEmpty) {
      final matchIndex = allHours.indexWhere((h) {
        final dt = _parseHourTime(h.time, gebzeNow);
        return dt != null && dt.hour == gebzeNow.hour;
      });
      if (matchIndex != -1) {
        upcoming = allHours.sublist(matchIndex);
      } else {
        upcoming = allHours;
      }
    }

    final displayHourly = upcoming.take(24).toList();
    if (displayHourly.isEmpty) return const SizedBox.shrink();

    final gebzeTimeStr =
        '${gebzeNow.hour.toString().padLeft(2, '0')}:${gebzeNow.minute.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.access_time_rounded, size: 18, color: _C.navy),
            const SizedBox(width: 6),
            Text(
              AppStrings.get('hourly_forecast', lang),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _C.textDark,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F1FE),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1E5BC6).withAlpha(40)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E5BC6),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${lang == 'ar' ? 'جبزة' : 'Gebze'} $gebzeTimeStr',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E5BC6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: displayHourly.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final h = displayHourly[index];
              String iconUrl = h.icon;
              if (iconUrl.startsWith('//')) iconUrl = 'https:$iconUrl';

              final isNow = index == 0;
              final timeStr = isNow
                  ? AppStrings.get('now', lang)
                  : (h.time.contains(' ') ? h.time.split(' ').last : h.time);

              return Container(
                width: isNow ? 76 : 72,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                decoration: BoxDecoration(
                  gradient: isNow
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1E5BC6), Color(0xFF0A2A66)],
                        )
                      : null,
                  color: isNow ? null : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: isNow
                      ? Border.all(color: Colors.white.withAlpha(50), width: 1)
                      : null,
                  boxShadow: isNow
                      ? [
                          BoxShadow(
                            color: const Color(0xFF1E5BC6).withAlpha(60),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : _softShadow(),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isNow) ...[
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Color(0xFF64B5F6),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          timeStr,
                          style: TextStyle(
                            color: isNow ? Colors.white : _C.textMuted,
                            fontSize: 12,
                            fontWeight:
                                isNow ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (iconUrl.isNotEmpty)
                      Image.network(
                        iconUrl,
                        width: 32,
                        height: 32,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.cloud_rounded,
                          color: isNow ? Colors.white : const Color(0xFF1E5BC6),
                          size: 26,
                        ),
                      )
                    else
                      Icon(
                        Icons.cloud_rounded,
                        color: isNow ? Colors.white : const Color(0xFF1E5BC6),
                        size: 26,
                      ),
                    Text(
                      '${h.tempC.round()}°',
                      style: TextStyle(
                        color: isNow ? Colors.white : _C.textDark,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMultiDayForecastSection(List<WeatherForecast> forecast, String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_month_rounded, size: 18, color: _C.navy),
            const SizedBox(width: 6),
            Text(
              AppStrings.get('five_day_forecast', lang),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _C.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: forecast.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            return _buildForecastCard(forecast[index], index, lang);
          },
        ),
      ],
    );
  }

  Widget _buildForecastCard(WeatherForecast forecast, int index, String lang) {
    String iconUrl = forecast.icon;
    if (iconUrl.startsWith('//')) {
      iconUrl = 'https:$iconUrl';
    }

    final dateInfo = _getDateInfo(forecast.date, index, lang);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: _softShadow(),
      ),
      child: Row(
        children: [
          // Sol Kısım: Gün Başlığı + Küçük Tarih
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dateInfo.dayTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                        color: dateInfo.isToday ? const Color(0xFF1E5BC6) : _C.textDark,
                      ),
                    ),
                    if (dateInfo.isToday) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F1FE),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF1E5BC6).withAlpha(60)),
                        ),
                        child: Text(
                          AppStrings.get('today', lang).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E5BC6),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (dateInfo.dateSubtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    dateInfo.dateSubtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _C.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Orta Kısım: Hava Durumu İkonu ve Kısa Durum Yazısı
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (iconUrl.isNotEmpty)
                  Image.network(
                    iconUrl,
                    width: 34,
                    height: 34,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.wb_sunny_rounded,
                      color: Color(0xFFFFB300),
                      size: 28,
                    ),
                  )
                else
                  const Icon(
                    Icons.wb_sunny_rounded,
                    color: Color(0xFFFFB300),
                    size: 28,
                  ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    forecast.condition,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: _C.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Sağ Kısım: Sıcaklık Aralığı (En Yüksek / En Düşük)
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${forecast.maxtempC.round()}°',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: _C.textDark,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${forecast.mintempC.round()}°',
                  style: const TextStyle(
                    color: Color(0xFF909BB0),
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _ForecastDateInfo _getDateInfo(String dateStr, int index, String lang) {
    final days = lang == 'en'
        ? const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
        : lang == 'ar'
            ? const ['الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد']
            : const ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];

    final months = lang == 'en'
        ? const ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']
        : lang == 'ar'
            ? const ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر']
            : const ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final parsed = DateTime.tryParse(dateStr);
    if (parsed == null) {
      return _ForecastDateInfo(
        dayTitle: index == 0 ? AppStrings.get('today', lang) : dateStr,
        dateSubtitle: '',
        isToday: index == 0,
        isTomorrow: index == 1,
      );
    }

    final targetDate = DateTime(parsed.year, parsed.month, parsed.day);
    final diffDays = targetDate.difference(today).inDays;
    final dayName = days[parsed.weekday - 1];
    final monthName = months[parsed.month - 1];
    final formattedDate = '${parsed.day} $monthName';

    final isToday = diffDays == 0 || (index == 0 && diffDays <= 0);
    final isTomorrow = diffDays == 1 || (index == 1 && isToday);

    String title;
    if (isToday) {
      title = AppStrings.get('today', lang);
    } else if (isTomorrow) {
      title = AppStrings.get('tomorrow', lang);
    } else {
      title = dayName;
    }

    String subtitle;
    if (isToday || isTomorrow) {
      subtitle = '$formattedDate, $dayName';
    } else {
      subtitle = formattedDate;
    }

    return _ForecastDateInfo(
      dayTitle: title,
      dateSubtitle: subtitle,
      isToday: isToday,
      isTomorrow: isTomorrow,
    );
  }

  Widget _buildEmptyState(BuildContext context, [String lang = 'tr']) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _C.navy.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded, color: _C.navy, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              lang == 'en'
                  ? 'Weather information not found'
                  : lang == 'ar'
                      ? 'لم يتم العثور على معلومات الطقس'
                      : 'Hava durumu bilgisi bulunamadı',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _C.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              lang == 'en'
                  ? 'There may be a problem fetching latest data from the server.'
                  : lang == 'ar'
                      ? 'قد تكون هناك مشكلة في جلب أحدث البيانات من الخادم.'
                      : 'Sunucudan güncel veriler alınırken bir sorun oluşmuş olabilir.',
              style: const TextStyle(
                fontSize: 13,
                color: _C.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message, [String lang = 'tr']) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Text(
              AppStrings.get('error_occurred', lang),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _C.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: const TextStyle(fontSize: 12, color: _C.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
