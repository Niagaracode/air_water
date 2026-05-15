
import 'package:intl/intl.dart';

int durationToMinutes(String duration) {
  final parts = duration.split(':');
  if (parts.length != 2) return 10;

  final hours = int.tryParse(parts[0]) ?? 0;
  final minutes = int.tryParse(parts[1]) ?? 0;

  return (hours * 60) + minutes;
}

DateTime parseDateTime(dynamic value) {
  if (value == null) {
    return DateTime.now();
  }
  final str = value.toString().trim();
  if (str == '0.0 0.0' || str.isEmpty) {
    return DateTime.now().subtract(
      const Duration(days: 365),
    );
  }
  try {
    return DateFormat('dd/MM/yyyy HH:mm:ss').parse(str);
  } catch (e) {
    return DateTime.now().subtract(
      const Duration(days: 365),
    );
  }
}
