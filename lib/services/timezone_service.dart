import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/intl.dart';

class TimezoneService {
  static const String bangladeshTimezone = 'Asia/Dhaka';
  static const String bangladeshOffset = '+06:00';
  static const int bangladeshOffsetHours = 6;

  /// Initialize timezone data
  static void initialize() {
    tz.initializeTimeZones();
  }

  /// Get current time in Bangladesh timezone
  static DateTime getCurrentTimeInBangladesh() {
    return tz.TZDateTime.now(tz.getLocation(bangladeshTimezone));
  }

  /// Convert UTC time to Bangladesh timezone
  static DateTime convertToBangladeshTime(DateTime utcTime) {
    return tz.TZDateTime.from(utcTime, tz.getLocation(bangladeshTimezone));
  }

  /// Convert Bangladesh time to UTC
  static DateTime convertToUTC(DateTime bangladeshTime) {
    return tz.TZDateTime.from(bangladeshTime, tz.getLocation(bangladeshTimezone)).toUtc();
  }

  /// Format time for display in Bangladesh timezone
  static String formatBangladeshTime(DateTime time, {String format = 'yyyy-MM-dd HH:mm:ss'}) {
    final bangladeshTime = convertToBangladeshTime(time);
    return DateFormat(format).format(bangladeshTime);
  }

  /// Format time for display with custom format
  static String formatTime(DateTime time, {String format = 'MMM dd, yyyy h:mm a'}) {
    final bangladeshTime = convertToBangladeshTime(time);
    return DateFormat(format).format(bangladeshTime);
  }

  /// Get relative time (e.g., "2 hours ago", "Just now")
  static String getRelativeTime(DateTime time) {
    final now = getCurrentTimeInBangladesh();
    final bangladeshTime = convertToBangladeshTime(time);
    final difference = now.difference(bangladeshTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  /// Get time difference between two times
  static String getTimeDifference(DateTime startTime, DateTime endTime) {
    final start = convertToBangladeshTime(startTime);
    final end = convertToBangladeshTime(endTime);
    final difference = end.difference(start);

    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Check if time is within business hours (6 AM to 10 PM)
  static bool isWithinBusinessHours(DateTime time) {
    final bangladeshTime = convertToBangladeshTime(time);
    final hour = bangladeshTime.hour;
    return hour >= 6 && hour < 22;
  }

  /// Get start of day in Bangladesh timezone
  static DateTime getStartOfDayInBangladesh(DateTime date) {
    final bangladeshTime = convertToBangladeshTime(date);
    return DateTime(bangladeshTime.year, bangladeshTime.month, bangladeshTime.day);
  }

  /// Get end of day in Bangladesh timezone
  static DateTime getEndOfDayInBangladesh(DateTime date) {
    final bangladeshTime = convertToBangladeshTime(date);
    return DateTime(bangladeshTime.year, bangladeshTime.month, bangladeshTime.day, 23, 59, 59);
  }

  /// Create a date in Bangladesh timezone
  static DateTime createBangladeshDate(int year, int month, int day, {int hour = 0, int minute = 0, int second = 0}) {
    return tz.TZDateTime(tz.getLocation(bangladeshTimezone), year, month, day, hour, minute, second);
  }

  /// Get current timezone info
  static Map<String, dynamic> getBangladeshTimezoneInfo() {
    final now = getCurrentTimeInBangladesh();
    return {
      'timezone': bangladeshTimezone,
      'offset': bangladeshOffset,
      'offsetHours': bangladeshOffsetHours,
      'currentTime': formatBangladeshTime(now),
      'currentTimeFormatted': formatTime(now),
      'isDST': false, // Bangladesh doesn't observe DST
    };
  }

  /// Format rental time for display
  static String formatRentalTime(DateTime time) {
    return formatTime(time, format: 'MMM dd, h:mm a');
  }

  /// Format rental duration
  static String formatRentalDuration(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (hours > 0) {
      return '${hours}h ${remainingMinutes}m';
    } else {
      return '${remainingMinutes}m';
    }
  }

  /// Get timezone offset string
  static String getTimezoneOffsetString() {
    return bangladeshOffset;
  }

  /// Get timezone name
  static String getTimezoneName() {
    return 'Bangladesh Standard Time (BST)';
  }
}
