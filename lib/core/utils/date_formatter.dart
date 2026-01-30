import 'package:intl/intl.dart';

class DateFormatter {
  // output: "22 jan, 12:00"
  static String toReadable(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd MMM, HH:mm', 'ru').format(date);
  }

  // output: "12:00"
  static String toTime(DateTime? date) {
    if (date == null) return '';
    return DateFormat('HH:mm').format(date);
  }

  // output: "Monday" or "22.01.2026"
  static String toFullDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd.MM.yyyy').format(date);
  }

  // for backend respond (FastAPI loves ISO formate)
  static String toIso(DateTime date) {
    return date.toIso8601String();
  }

  // Check: its today? (for filtration in UI)
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
