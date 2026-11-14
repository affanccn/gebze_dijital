class GebzeTime {
  static const Duration offset = Duration(hours: 3);

  static DateTime now() {
    final utc = DateTime.now().toUtc();
    return utc.add(offset);
  }

  static DateTime toGebzeTime(DateTime dt) {
    return dt.toUtc().add(offset);
  }

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

  static String formatHour(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  static String formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}
