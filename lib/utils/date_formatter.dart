import 'package:intl/intl.dart';

/// Formats a date string into a human-readable format like '10:30 AM 21st March, 2025'.
/// Returns 'Invalid date' if parsing fails.
String formatDateTime(String dateTimeString) {
  try {
    DateTime dateTime = DateTime.parse(dateTimeString);

    // Get day and suffix
    int day = dateTime.day;
    String suffix;
    if (day >= 11 && day <= 13) {
      suffix = 'th';
    } else {
      switch (day % 10) {
        case 1:
          suffix = 'st';
          break;
        case 2:
          suffix = 'nd';
          break;
        case 3:
          suffix = 'rd';
          break;
        default:
          suffix = 'th';
      }
    }

    // Format without day suffix first
    String formatted =
        DateFormat("hh:mm a ").format(dateTime) +
        "$day$suffix " +
        DateFormat("MMMM, yyyy").format(dateTime);

    return formatted;
  } catch (e) {
    return "Invalid date";
  }
}
