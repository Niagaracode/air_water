import 'package:intl/intl.dart';

class DateFormatter {

  static String formatDateShort(DateTime dateTime) {
    return DateFormat('dd-MM-yyyy').format(dateTime);
  }

  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm:ss').format(dateTime);
  }

  static String formatDateCustom(DateTime dateTime, String pattern) {
    return DateFormat(pattern).format(dateTime);
  }

  static String formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final time = DateFormat('hh:mm a').format(dateTime);

    if (messageDate == today) return 'Today at $time';
    if (messageDate == yesterday) return 'Yesterday at $time';
    return DateFormat('dd MMM yyyy \'at\' hh:mm a').format(dateTime);
  }
}