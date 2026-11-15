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
}