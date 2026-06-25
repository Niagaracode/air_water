import 'package:intl/intl.dart';

class DateFormatter {

  static String formatDateTime(DateTime dateTime) {
    final localDateTime = dateTime.toLocal();
    return DateFormat('dd MMM yyyy hh:mm a').format(localDateTime);
  }

  static String formatDateShort(DateTime dateTime) {
    return DateFormat('dd-MM-yyyy').format(dateTime);
  }

  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm:ss').format(dateTime);
  }

  static String formatDateCustom(DateTime dateTime, String pattern) {
    return DateFormat(pattern).format(dateTime);
  }
}