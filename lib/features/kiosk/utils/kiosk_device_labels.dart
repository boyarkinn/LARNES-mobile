import 'package:larnes_mobile/features/kiosk/models/kiosk_device_context.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

String kioskDevicePlacementLine(KioskDeviceContext device, AppLocalizations l10n) {
  final center = device.centerName?.trim();
  final classroom = device.classroomTitle?.trim();
  final slot = device.slotLabel?.trim();

  final parts = <String>[];
  if (center != null && center.isNotEmpty) {
    parts.add(center);
  }
  if (classroom != null && classroom.isNotEmpty) {
    parts.add(classroom);
  }
  if (slot != null && slot.isNotEmpty) {
    parts.add(l10n.networkDeviceSlotValue(slot));
  }

  if (parts.isEmpty) {
    return l10n.networkDeviceUnassigned;
  }

  return parts.join(' · ');
}
