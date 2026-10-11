import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Device IANA zone for requests; an account override only changes presentation.
class UserTimeZone {
  static String? deviceZone;
  static String? manualZone;
  static String? cityZone;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (!_initialized) {
      tzdata.initializeTimeZones();
      _initialized = true;
    }
    await refreshDeviceZone();
  }

  static Future<void> refreshDeviceZone() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.getLocation(info.identifier);
      deviceZone = info.identifier;
    } catch (_) {
      // Do not infer an IANA zone from a city, locale, abbreviation or UTC offset.
    }
  }

  static String? get effectiveZone => manualZone ?? cityZone ?? deviceZone;

  static DateTime displayTime(DateTime instant) {
    final zone = effectiveZone;
    if (zone == null) return instant.toLocal();
    try {
      return tz.TZDateTime.from(instant.toUtc(), tz.getLocation(zone));
    } catch (_) {
      return instant.toLocal();
    }
  }

  static String dayKey([DateTime? instant]) {
    final now = displayTime(instant ?? DateTime.now());
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
