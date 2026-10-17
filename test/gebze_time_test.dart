import 'package:flutter_test/flutter_test.dart';
import 'package:gebze_dijital/core/utils/gebze_time.dart';

void main() {
  group('GebzeTime Tests', () {
    test('now() is exactly 3 hours ahead of universal UTC', () {
      final utcNow = DateTime.now().toUtc();
      final gebzeNow = GebzeTime.now();

      final diff = gebzeNow.difference(utcNow);
      expect(diff.inHours, equals(3));
    });

    test('toGebzeTime correctly adds 3 hours to any DateTime', () {
      final utcTimestamp = DateTime.utc(2026, 10, 13, 6, 45); // 06:45 UTC
      final gebzeTime = GebzeTime.toGebzeTime(utcTimestamp);

      expect(gebzeTime.hour, equals(9));
      expect(gebzeTime.minute, equals(45));
      expect(GebzeTime.formatHour(gebzeTime), equals('09:45'));
    });

    test('parseWeatherTime parses "YYYY-MM-DD HH:mm" properly', () {
      final timeStr = '2026-10-13 14:00';
      final parsed = GebzeTime.parseWeatherTime(timeStr);

      expect(parsed.year, equals(2026));
      expect(parsed.month, equals(10));
      expect(parsed.day, equals(13));
      expect(parsed.hour, equals(14));
      expect(parsed.minute, equals(0));
    });

    test('parseWeatherDate parses "YYYY-MM-DD" properly', () {
      final dateStr = '2026-10-13';
      final parsed = GebzeTime.parseWeatherDate(dateStr);

      expect(parsed.year, equals(2026));
      expect(parsed.month, equals(10));
      expect(parsed.day, equals(13));
      expect(GebzeTime.formatDate(parsed), equals('13.10.2026'));
    });

    test(
      'hourly threshold filters out past hours regardless of device timezone',
      () {
        // Mock: current Gebze time is 14:30
        final threshold = DateTime.utc(2026, 10, 13, 14);

        final past11 = GebzeTime.parseWeatherTime('2026-10-13 11:00');
        final past13 = GebzeTime.parseWeatherTime('2026-10-13 13:00');
        final current14 = GebzeTime.parseWeatherTime('2026-10-13 14:00');
        final future15 = GebzeTime.parseWeatherTime('2026-10-13 15:00');

        expect(past11.isBefore(threshold), isTrue);
        expect(past13.isBefore(threshold), isTrue);
        expect(current14.isBefore(threshold), isFalse);
        expect(future15.isBefore(threshold), isFalse);
      },
    );
  });
}
