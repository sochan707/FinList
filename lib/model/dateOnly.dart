class DateOnly {
  final int day;
  final int month;
  final int year;

  DateOnly({required this.day, required this.month, required this.year}) {
    final checkedDate = DateTime(year, month, day);

    if (checkedDate.day != day || checkedDate.month != month || checkedDate.year != year) {
      throw ArgumentError('Invalid date');
    }
  }

  bool isSameDay(DateOnly other) {
    return day == other.day &&
        month == other.month &&
        year == other.year;
    }
}