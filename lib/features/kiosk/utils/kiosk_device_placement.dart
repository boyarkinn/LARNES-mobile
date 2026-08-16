import 'package:larnes_mobile/features/kiosk/models/kiosk_device_context.dart';

/// Poll interval while waiting for admin seat assignment (web has no auto-refresh).
const kioskPlacementPollInterval = Duration(seconds: 8);

/// Parity with web `/kiosk`: device needs classroom + seat (slotLabel proxy).
bool isKioskDevicePlaced(KioskDeviceContext device) {
  final classroomId = device.classroomId?.trim();
  final slot = device.slotLabel?.trim();
  return classroomId != null &&
      classroomId.isNotEmpty &&
      slot != null &&
      slot.isNotEmpty;
}
