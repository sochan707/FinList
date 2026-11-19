import 'dateOnly.dart';
import 'scheduleItem_model.dart';

class ScheduleException {
  final String scheduleItemId;
  final DateOnly originalDate;
  final bool isCancelled;
  final ScheduleItem? replacement;

  ScheduleException({required this.scheduleItemId, required this.originalDate, this.isCancelled = false, this.replacement}) {
    // ! if cancelled, there shouldn't has any replacement
    if(isCancelled && replacement != null){
      throw ArgumentError('A cancelled date cannot have a replacement');
    }

    // ! Cannot edit without replacement
    if(!isCancelled && replacement == null){
      throw ArgumentError('An edited date needs a replacement');
    }
  }
}