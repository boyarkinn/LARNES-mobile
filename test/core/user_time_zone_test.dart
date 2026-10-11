import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/time/user_time_zone.dart';
import 'package:larnes_mobile/core/time/time_zone_options.dart';
import 'package:larnes_mobile/core/api/auth_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_timezone');
  var deviceZone = 'Asia/Tbilisi';
  setUp(() async {
    UserTimeZone.manualZone = null;
    UserTimeZone.cityZone = null;
    deviceZone = 'Asia/Tbilisi';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => deviceZone);
    await UserTimeZone.initialize();
  });
  tearDown(() {
    UserTimeZone.manualZone = null;
    UserTimeZone.cityZone = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'keeps city calendar while travelling and manual selection takes priority',
    () async {
      UserTimeZone.cityZone = 'Asia/Tbilisi';
      deviceZone = 'America/New_York';
      await UserTimeZone.refreshDeviceZone();
      expect(UserTimeZone.effectiveZone, 'Asia/Tbilisi');
      expect(
        UserTimeZone.dayKey(DateTime.parse('2026-10-09T20:30:00Z')),
        '2026-10-10',
      );
      UserTimeZone.manualZone = 'Europe/Moscow';
      expect(UserTimeZone.effectiveZone, 'Europe/Moscow');
      UserTimeZone.manualZone = null;
      UserTimeZone.cityZone = null;
      expect(UserTimeZone.effectiveZone, 'America/New_York');
    },
  );
  test('parses manual and city zones as separate account values', () {
    final user = AuthUser.fromJson({
      'id': 'sample',
      'accountType': 'parent',
      'city': 'Тбилиси',
      'timeZone': 'Europe/Moscow',
      'cityTimeZone': 'Asia/Tbilisi',
    });
    expect(user.timeZone, 'Europe/Moscow');
    expect(user.cityTimeZone, 'Asia/Tbilisi');
  });
  test(
    'labels selected zones with localized cities and date-specific offsets',
    () {
      expect(
        timeZoneLabel('Asia/Yekaterinburg', 'ru'),
        contains('Екатеринбург'),
      );
      expect(
        timeZoneLabel('America/New_York', 'en', DateTime.utc(2026, 1, 10)),
        contains('UTC-5'),
      );
      expect(
        timeZoneLabel('America/New_York', 'en', DateTime.utc(2026, 7, 10)),
        contains('UTC-4'),
      );
      expect(availableTimeZones('Asia/Tbilisi'), contains('Asia/Tbilisi'));
    },
  );
  test('detects the device IANA zone and crosses midnight', () {
    expect(UserTimeZone.deviceZone, 'Asia/Tbilisi');
    expect(
      UserTimeZone.dayKey(DateTime.parse('2026-10-09T20:30:00Z')),
      '2026-10-10',
    );
  });
  test(
    'manual account zone overrides presentation, preserving device identity',
    () {
      UserTimeZone.manualZone = 'America/New_York';
      expect(
        UserTimeZone.dayKey(DateTime.parse('2026-10-10T01:00:00Z')),
        '2026-10-09',
      );
      expect(UserTimeZone.deviceZone, 'Asia/Tbilisi');
    },
  );
  test('refresh follows travel without guessing from an offset', () async {
    deviceZone = 'Asia/Kathmandu';
    await UserTimeZone.refreshDeviceZone();
    final local = UserTimeZone.displayTime(
      DateTime.parse('2026-10-10T00:00:00Z'),
    );
    expect(local.hour, 5);
    expect(local.minute, 45);
    expect(UserTimeZone.deviceZone, 'Asia/Kathmandu');
  });
  test('uses DST rules for instants on both sides of a transition', () {
    UserTimeZone.manualZone = 'America/New_York';
    final before = UserTimeZone.displayTime(
      DateTime.parse('2026-03-08T06:30:00Z'),
    );
    final after = UserTimeZone.displayTime(
      DateTime.parse('2026-03-08T07:30:00Z'),
    );
    expect(before.hour, 1);
    expect(after.hour, 3);
  });
  test('plugin failure retains the last detected zone', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (_) async => throw PlatformException(code: 'offline'),
        );
    await UserTimeZone.refreshDeviceZone();
    expect(UserTimeZone.deviceZone, 'Asia/Tbilisi');
  });
}
