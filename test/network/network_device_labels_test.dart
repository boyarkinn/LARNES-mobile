import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/network/models/network_device.dart';
import 'package:larnes_mobile/features/network/utils/network_device_labels.dart';
import 'package:larnes_mobile/l10n/app_localizations_ru.dart';

void main() {
  group('network device labels', () {
    test('uses slot label as title when present', () {
      final l10n = AppLocalizationsRu();
      const device = NetworkDevice(
        id: 'd1',
        kind: NetworkDeviceKind.tablet,
        isOnline: true,
        slotLabel: 'M1',
      );

      expect(networkDeviceTitle(device, l10n), 'Слот M1');
    });

    test('builds placement line with center and classroom', () {
      final l10n = AppLocalizationsRu();
      const device = NetworkDevice(
        id: 'd1',
        kind: NetworkDeviceKind.phone,
        isOnline: false,
        centerName: 'Center A',
        classroomTitle: 'Room 1',
      );

      expect(networkDevicePlacementLine(device, l10n), 'Center A · Room 1');
    });
  });
}
