import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/network/models/enroll_device_result.dart';
import 'package:larnes_mobile/features/network/models/network_center.dart';
import 'package:larnes_mobile/features/network/models/network_classroom.dart';
import 'package:larnes_mobile/features/network/models/network_device.dart';

void main() {
  group('NetworkCenter.fromJson', () {
    test('parses center payload', () {
      final center = NetworkCenter.fromJson({
        'id': '11111111-1111-4111-8111-111111111111',
        'name': 'Center A',
        'ownerUserId': '22222222-2222-4222-8222-222222222222',
        'createdAt': '2026-07-06T10:00:00.000Z',
        'city': 'Moscow',
        'directions': ['reading', 'math'],
      });

      expect(center.name, 'Center A');
      expect(center.city, 'Moscow');
      expect(center.directions, ['reading', 'math']);
    });

    test('defaults missing directions to empty list', () {
      final center = NetworkCenter.fromJson({
        'id': '11111111-1111-4111-8111-111111111111',
        'name': 'Center B',
        'ownerUserId': '22222222-2222-4222-8222-222222222222',
        'createdAt': '2026-07-06T10:00:00.000Z',
      });

      expect(center.directions, isEmpty);
      expect(center.city, isNull);
    });
  });

  group('NetworkDevice.fromJson', () {
    test('parses device payload', () {
      final device = NetworkDevice.fromJson({
        'id': '33333333-3333-4333-8333-333333333333',
        'kind': 'phone',
        'isOnline': true,
        'centerId': '11111111-1111-4111-8111-111111111111',
        'centerName': 'Center A',
        'classroomId': '44444444-4444-4444-8444-444444444444',
        'classroomTitle': 'Room 1',
        'slotLabel': 'M1',
        'enrolledAt': '2026-07-06T09:00:00.000Z',
        'lastSeenAt': '2026-07-06T10:00:00.000Z',
      });

      expect(device.kind, NetworkDeviceKind.phone);
      expect(device.isOnline, isTrue);
      expect(device.slotLabel, 'M1');
      expect(device.classroomTitle, 'Room 1');
    });

    test('falls back to tablet for unknown kind', () {
      final device = NetworkDevice.fromJson({
        'id': '33333333-3333-4333-8333-333333333333',
        'kind': 'unknown',
        'isOnline': false,
      });

      expect(device.kind, NetworkDeviceKind.tablet);
      expect(device.isOnline, isFalse);
    });
  });

  group('NetworkClassroom.fromJson', () {
    test('parses classroom payload', () {
      final classroom = NetworkClassroom.fromJson({
        'id': '44444444-4444-4444-8444-444444444444',
        'centerId': '11111111-1111-4111-8111-111111111111',
        'centerName': 'Center A',
        'title': 'Room 1',
      });

      expect(classroom.title, 'Room 1');
      expect(classroom.centerName, 'Center A');
      expect(classroom.centerId, '11111111-1111-4111-8111-111111111111');
    });
  });

  group('EnrollDeviceResult.fromJson', () {
    test('parses enroll success payload', () {
      final result = EnrollDeviceResult.fromJson({
        'deviceId': '55555555-5555-4555-8555-555555555555',
        'deviceToken': 'device-jwt-token',
        'status': 'success',
      });

      expect(result.deviceId, '55555555-5555-4555-8555-555555555555');
      expect(result.deviceToken, 'device-jwt-token');
    });
  });
}
