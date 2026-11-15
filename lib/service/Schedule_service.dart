import '../model/scheduleItem_model.dart';
import '../model/dateOnly.dart';
import 'dateOnly_service.dart';

class ScheduleService {
  final List<ScheduleItem> _schedules = [];

  void validateSchedule(ScheduleItem schedule){
    final repeatEndDate = schedule.repeatEndDate;

    final start = DateTime(
      schedule.startDate.year,
      schedule.startDate.month,
      schedule.startDate.day,

      schedule.startTime.hour,
      schedule.startTime.minute,
    );

    final end = DateTime(
      schedule.endDate.year,
      schedule.endDate.month,
      schedule.endDate.day,

      schedule.endTime.hour,
      schedule.endTime.minute,
    );

    // ! Title cannot be empty
    if(schedule.title.trim().isEmpty){
      throw ArgumentError('Title is required');
    }

    // ! End date or time CANNOT BE BEFORE Start date nor time
    if(!(end.isAfter(start))){
      throw ArgumentError('End must be after start');
    }

    // ! Check repeatEndDate
    if(repeatEndDate != null){
      final firstRepeatDate = DateTime(
        schedule.startDate.year,
        schedule.startDate.month,
        schedule.startDate.day,
      );
      
      final lastRepeatDate = DateTime(
        repeatEndDate.year,
        repeatEndDate.month,
        repeatEndDate.day
      );

      // ! Cannot have repeatEndDate without repeatWeekly
      if(schedule.repeatsWeekly == false){
        throw ArgumentError('Only weekly items can have a repeat end date');
      }

      // ! Repeat end date CANNOT be before start date
      if (lastRepeatDate.isBefore(firstRepeatDate)) {
        throw ArgumentError('Repeat end date cannot be before start date');
      }
    }
  }

  void addSchedule(ScheduleItem schedule){
    validateSchedule(schedule);
    _schedules.add(schedule);
  }

  List<ScheduleItem> getNonRepeatingSchedulesForDate(DateOnly date){
    final List<ScheduleItem> results = [];
    final requestedDay = DateTime(date.year, date.month, date.day);

    // ! Find the non-repeated schedule of the requested day
    for(var s in _schedules){
      if (s.repeatsWeekly) {
        continue;
      }

      final startDay = DateTime(
        s.startDate.year,
        s.startDate.month,
        s.startDate.day
      );

      final endDay = DateTime(
        s.endDate.year,
        s.endDate.month,
        s.endDate.day
      );

      if(!(requestedDay.isBefore(startDay)) && !(requestedDay.isAfter(endDay))){
        results.add(s);
      }
    }
    return results;
  }
  
  bool _weeklyRepeatOnDate(ScheduleItem schedule, DateOnly date) {
    final requestedDay = DateTime(date.year, date.month, date.day);
    final repeatEndDate = schedule.repeatEndDate;

    if (!(schedule.repeatsWeekly)) {
      return false;
    }

    final firstDay = DateTime(
      schedule.startDate.year,
      schedule.startDate.month,
      schedule.startDate.day,
    );

    if (requestedDay.isBefore(firstDay)) {
      return false;
    }
    
    if (repeatEndDate != null) {
      final lastDay = DateTime(
        repeatEndDate.year,
        repeatEndDate.month,
        repeatEndDate.day,
      );

      if (requestedDay.isAfter(lastDay)) {
        return false;
      }
    }

    return requestedDay.weekday == firstDay.weekday;
  }

  // List<ScheduleItem> getWeeklySchedulesOnDate(DateOnly date) {
  //   final List<ScheduleItem> results = [];

  //   for (var s in _schedules) {
  //     if (_weeklyRepeatOnDate(s, date)) {
  //       results.add(s);
  //     }
  //   }

  //   return results;
  // }

  List<ScheduleItem> getWeeklySchedulesOnDate(DateOnly date) {
    final List<ScheduleItem> results = [];
    final dateService = DateOnlyService();

    for (var s in _schedules) {
      if (!(s.repeatsWeekly)) continue;

      DateOnly dayToCheck = date;

      final firstStart = DateTime(
        s.startDate.year,
        s.startDate.month,
        s.startDate.day,
      );

      final firstEnd = DateTime(
        s.endDate.year,
        s.endDate.month,
        s.endDate.day,
      );
      
      final daysCovered = firstEnd.difference(firstStart).inDays;

      for (var i = 0; i <= daysCovered; i++) {
        if (_weeklyRepeatOnDate(s, dayToCheck)) {
          results.add(s);
          break;
        }

        dayToCheck = dateService.addDays(dayToCheck, -1);
      }
    }

    return results;
  }

  List<ScheduleItem> getSchedulesForDate(DateOnly date) {
    final results = getNonRepeatingSchedulesForDate(date);

    results.addAll(getWeeklySchedulesOnDate(date));

    return results;
  }
  

}