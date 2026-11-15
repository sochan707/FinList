import 'package:flutter_test/flutter_test.dart';
import '../lib/model/dateOnly.dart';
import '../lib/service/dateOnly_service.dart';

void main() {
  test('rejects an invalid date', () {
    expect(() => DateOnly(day: 31, month: 2, year: 2026), throwsArgumentError);
  });

  test('recognizes the same calendar day', () {
    final first = DateOnly(day: 15, month: 11, year: 2026);
    final second = DateOnly(day: 15, month: 11, year: 2026);

    expect(first.isSameDay(second), true);
  });

  test('shows d/m/y', () {
    final service = DateOnlyService();

    final date = DateOnly(day: 5, month: 11, year: 2026);

    expect(service.showDate(date), '5/11/2026');
  });

  test('adds days across a month boundary', () {
    final service = DateOnlyService();

    final start = DateOnly(day: 28, month: 2, year: 2024);

    final result = service.addDays(start, 2);

    expect(result.isSameDay(DateOnly(day: 1, month: 3, year: 2024)), true);
  });

  test('updateDate changes the day and keeps the month and year', () {
    final service = DateOnlyService();

    final original = DateOnly(day: 5, month: 11, year: 2026);

    final updated = service.updateDate(original, day: 15);

    expect(updated.day, 15);
    expect(updated.month, 11);
    expect(updated.year, 2026);
    expect(original.day, 5); // The original date did not change.
  });
}