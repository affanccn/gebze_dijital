/// Utility class to ensure all date and time operations for Gebze services
/// (such as weather forecasts, municipal updates, etc.) are strictly anchored
/// to Gebze Time (Turkey Time, TRT: UTC+3).
///
/// This eliminates any discrepancy caused by devices running in UTC or different timezones
/// (e.g. Android emulators defaulting to UTC+0 or users traveling abroad).
class GebzeTime {
  /// Gebze (Turkey) operates permanently on UTC+3 (TRT - no daylight saving time).
  static const Duration offset = Duration(hours: 3);

  /// Returns the current DateTime anchored to Gebze time (UTC+3).
  ///
  /// Mathematical guarantee: Regardless of the device's local timezone setting,
  /// `DateTime.now().toUtc()` yields universal UTC time, and adding 3 hours
  /// yields the exact wall-clock time in Gebze.
  static DateTime now() {
    final utc = DateTime.now().toUtc();
    return utc.add(offset);
  }

  /// Converts any given [DateTime] (such as Firestore timestamps or local DateTimes)
  /// to Gebze time (UTC+3).
  static DateTime toGebzeTime(DateTime dt) {
    return dt.toUtc().add(offset);
  }

  /// Parses date string in "YYYY-MM-DD" or ISO format as a Gebze calendar date.
  /// Returns a [DateTime] in UTC representing year, month, day.
  static DateTime parseWeatherDate(String dateStr) {
    final clean = dateStr.trim();
    if (clean.length == 10 && !clean.contains('T')) {
      final parts = clean.split('-');
      if (parts.length == 3) {
        final y = int.tryParse(parts[0]) ?? 2026;
        final m = int.tryParse(parts[1]) ?? 1;
        final d = int.tryParse(parts[2]) ?? 1;
        return DateTime.utc(y, m, d);
      }
    }
    try {
      final parsed = DateTime.parse(clean);
      return DateTime.utc(parsed.year, parsed.month, parsed.day);
    } catch (_) {
      final nowGebze = now();
      return DateTime.utc(nowGebze.year, nowGebze.month, nowGebze.day);
    }
  }

  /// Parses weather hour strings from WeatherAPI (e.g. "2026-10-13 14:00" or "2026-10-13T14:00")
  /// as a Gebze hour DateTime.
  ///
  /// Since WeatherAPI returns the local time of Gebze directly in `h.time`,
  /// this method creates a comparable UTC [DateTime] with identical year, month, day, hour, minute.
  static DateTime parseWeatherTime(String timeStr) {
    final clean = timeStr.trim();
    try {
      if (clean.contains(' ')) {
        final parts = clean.split(' ');
        final dateParts = parts[0].split('-');
        final timeParts = parts[1].split(':');
        final y = int.parse(dateParts[0]);
        final m = int.parse(dateParts[1]);
        final d = int.parse(dateParts[2]);
        final h = int.parse(timeParts[0]);
        final min = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
        return DateTime.utc(y, m, d, h, min);
      }
      final parsed = DateTime.parse(clean);
      return DateTime.utc(
        parsed.year,
        parsed.month,
        parsed.day,
        parsed.hour,
        parsed.minute,
      );
    } catch (_) {
      return DateTime.utc(2026, 1, 1);
    }
  }

  /// Formats a DateTime as HH:mm (e.g., "14:05").
  static String formatHour(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  /// Formats a DateTime as DD.MM.YYYY (e.g., "13.10.2026").
  static String formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}
