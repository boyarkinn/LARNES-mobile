import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_device_context.dart';
import 'package:larnes_mobile/features/kiosk/utils/kiosk_device_placement.dart';
import 'package:larnes_mobile/features/network/models/network_device.dart';

KioskDeviceContext _device({
  String? classroomId,
  String? slotLabel,
}) {
  return KioskDeviceContext(
    deviceId: '55555555-5555-4555-8555-555555555555',
    kind: NetworkDeviceKind.phone,
    classroomId: classroomId,
    slotLabel: slotLabel,
  );
}

void main() {
  group('isKioskDevicePlaced', () {
    test('returns false when classroom is missing', () {
      expect(isKioskDevicePlaced(_device(slotLabel: 'M1')), isFalse);
    });

    test('returns false when slot is missing', () {
      expect(
        isKioskDevicePlaced(
          _device(classroomId: '44444444-4444-4444-8444-444444444444'),
        ),
        isFalse,
      );
    });

    test('returns false for freshly enrolled device', () {
      expect(isKioskDevicePlaced(_device()), isFalse);
    });

    test('returns true when classroom and slot are set', () {
      expect(
        isKioskDevicePlaced(
          _device(
            classroomId: '44444444-4444-4444-8444-444444444444',
            slotLabel: 'M1',
          ),
        ),
        isTrue,
      );
    });
  });
}
