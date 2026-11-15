// a calenda date without time or timezone.

class DateOnly implements Comparable<DateOnly>{
    final int year;
    final int month;
    final int day;

    DateOnly(this.year, this.month, this.day){
        final value = DateTime.utc(year, month, day); // create a UTC date to check whether the given date is valid.
        if(value.year != year || value.month != month || value.day != day ){
            throw ArgumentError('Ivalid calendar date: $day/$month?$year');
        }
    }

    //convert a normal DateTime obj into a DateOnly obj
    DateOnly.fromDateTime(DateTime value) : this(value.year, value.month, value.day,);

    DateOnly addDays(int days){
        //create a date and add the requested number of day
        final value = DateTime.utc(year, month, day).add(Duration(days: days));

        //return a new DateOnly obj with the update date.
        return DateOnly(value.year, value.month, value.day);
    }

    // calculate how many day are between two dates.
    int differenceInDays(DateOnly other) =>
    DateTime.utc(year, month, day).difference(DateTime.utc(other.year, other.month, other.day)).inDays;
    
    bool isBefore(DateOnly other) => compareTo(other) < 0;  //check if the current date come be4 the other date
    bool isAfter(DateOnly other) => compareTo(other) > 0; // check if the cureent date come after the other date.

    //compare 2 date
    @override
    int compareTo(DateOnly other) {
    // TODO: implement compareTo
    if(year != other.year){
        return year.compareTo(other.year);
    }
    if(month != other.month){
        return month.compareTo(other.month);
    }
    return day.compareTo(other.day);
    }

    //check whether two dates are equal
    @override
    bool operator ==(Object other) {
    // TODO: implement ==
    if(other is DateOnly){
        return year == other.year && month == other.month && day == other.day;
    }
    return false;
    }

    //Generate hash code 
    @override
  // TODO: implement hashCode
  int get hashCode{
    return Object.hash(year, month, day);
  }
  //convert date to string(DD, MM, YYYY)
    @override
    String toString() {
    String d = day.toString().padLeft(2, '0');
    String m = month.toString().padLeft(2, '0');
    String y = year.toString().padLeft(4, '0');

    return '$d/$m/$y';
    }
}