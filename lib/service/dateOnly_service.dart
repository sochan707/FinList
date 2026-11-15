import '../model/dateOnly.dart';

class DateOnlyService {
  String showDate(DateOnly date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  DateOnly addDays(DateOnly date, int days) {
    final newDate = DateTime(date.year, date.month, date.day + days);

    return DateOnly(day: newDate.day, month: newDate.month, year: newDate.year);
  }

  DateOnly updateDate(DateOnly date, {int? day, int? month, int? year}) {
  return DateOnly(
    day: day ?? date.day,
    month: month ?? date.month,
    year: year ?? date.year,
  );
}

}