import 'package:flutter/material.dart';
import 'dateOnly.dart';

enum ScheduleType {classSession, workShift, event}

class ScheduleItem {
  final String id;
  final String title;
  final ScheduleType scheduleType;

  final DateOnly startDate;
  final DateOnly endDate;

  final TimeOfDay startTime;
  final bool repeatsWeekly;
  
  final TimeOfDay endTime;
  final DateOnly? repeatEndDate;
  
  final String? place;
  final String? notes;

  ScheduleItem({required this.id, required this.title, required this.scheduleType, required this.startDate, required this.endDate, required this.startTime, required this.endTime, this.repeatsWeekly = false, this.repeatEndDate, this.place, this.notes});
}