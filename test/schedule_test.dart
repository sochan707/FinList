import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finlist/model/dateOnly.dart';
import 'package:finlist/model/scheduleItem_model.dart';
import 'package:finlist/service/Schedule_service.dart';

void main() {
  test('last weekly repeat date is included', () {
    final service = ScheduleService();

    final math = ScheduleItem(
      id: 'C1',
      title: 'Math',
      scheduleType: ScheduleType.classSession,
      startDate: DateOnly(day: 16, month: 11, year: 2026),
      endDate: DateOnly(day: 16, month: 11, year: 2026),
      startTime: const TimeOfDay(hour: 9, minute: 0),
      endTime: const TimeOfDay(hour: 10, minute: 0),
      repeatsWeekly: true,
      repeatEndDate: DateOnly(day: 23, month: 11, year: 2026),
    );

    service.addSchedule(math);

    expect(service.getWeeklySchedulesOnDate(DateOnly(day: 23, month: 11, year: 2026)), contains(math));

    expect(service.getWeeklySchedulesOnDate(DateOnly(day: 30, month: 11, year: 2026)),isEmpty);
  });

  test('one-time overnight shift appears on both days', () {
    final service = ScheduleService();

    final shift = ScheduleItem(
      id: 'W1',
      title: 'Night shift',
      scheduleType: ScheduleType.workShift,
      startDate: DateOnly(day: 20, month: 11, year: 2026),
      endDate: DateOnly(day: 21, month: 11, year: 2026),
      startTime: const TimeOfDay(hour: 22, minute: 0),
      endTime: const TimeOfDay(hour: 2, minute: 0),
    );

    service.addSchedule(shift);

    expect(service.getNonRepeatingSchedulesForDate(DateOnly(day: 20, month: 11, year: 2026)), contains(shift));

    expect(service.getNonRepeatingSchedulesForDate(DateOnly(day: 21, month: 11, year: 2026)), contains(shift));
  });

  test('weekly overnight shift appears on Saturday too', () {
    final service = ScheduleService();

    final shift = ScheduleItem(
      id: 'W2',
      title: 'Weekly night shift',
      scheduleType: ScheduleType.workShift,
      startDate: DateOnly(day: 20, month: 11, year: 2026),
      endDate: DateOnly(day: 21, month: 11, year: 2026),
      startTime: const TimeOfDay(hour: 22, minute: 0),
      endTime: const TimeOfDay(hour: 2, minute: 0),
      repeatsWeekly: true,
    );

    service.addSchedule(shift);

    expect(service.getSchedulesForDate(DateOnly(day: 27, month: 11, year: 2026)), contains(shift));
    expect(service.getSchedulesForDate(DateOnly(day: 28, month: 11, year: 2026)), contains(shift));
  });

  test('deleting a one-time overnight shift removes it from both days', () {
    final service = ScheduleService();
    final friday = DateOnly(day: 20, month: 11, year: 2026);
    final saturday = DateOnly(day: 21, month: 11, year: 2026);

    final shift = ScheduleItem(
      id: 'W3',
      title: 'Night shift',
      scheduleType: ScheduleType.workShift,
      startDate: friday,
      endDate: saturday,
      startTime: const TimeOfDay(hour: 22, minute: 0),
      endTime: const TimeOfDay(hour: 2, minute: 0),
    );

    service.addSchedule(shift);
    expect(service.getSchedulesForDate(friday), contains(shift));
    expect(service.getSchedulesForDate(saturday), contains(shift));

    service.deleteNonRepeatingSchedule('W3');

    expect(service.getSchedulesForDate(friday), isEmpty);
    expect(service.getSchedulesForDate(saturday), isEmpty);
  });

  test('one-time delete does not remove a weekly schedule', () {
    final service = ScheduleService();
    final friday = DateOnly(day: 20, month: 11, year: 2026);

    final shift = ScheduleItem(
      id: 'W4',
      title: 'Weekly shift',
      scheduleType: ScheduleType.workShift,
      startDate: friday,
      endDate: friday,
      startTime: const TimeOfDay(hour: 9, minute: 0),
      endTime: const TimeOfDay(hour: 17, minute: 0),
      repeatsWeekly: true,
    );

    service.addSchedule(shift);

    expect(() => service.deleteNonRepeatingSchedule('W4'), throwsException);
    expect(service.getSchedulesForDate(friday), contains(shift));
  });


}