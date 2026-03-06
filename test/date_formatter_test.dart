import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_calendar/core/utils/date_formatter.dart';

void main() {
  test('toIso returns ISO-8601 string', () {
    final date = DateTime.utc(2026, 1, 1, 12, 30, 15);
    final iso = DateFormatter.toIso(date);

    expect(iso, contains('2026-01-01T12:30:15'));
  });

  test('isToday returns true for current date', () {
    final now = DateTime.now();
    expect(DateFormatter.isToday(now), isTrue);
  });

  test('isToday returns false for non-current date', () {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    expect(DateFormatter.isToday(yesterday), isFalse);
  });
}
