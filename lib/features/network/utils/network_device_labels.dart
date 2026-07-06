import 'package:larnes_mobile/features/network/models/network_device.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

String networkDeviceKindLabel(NetworkDeviceKind kind, AppLocalizations l10n) {
  switch (kind) {
    case NetworkDeviceKind.laptop:
      return l10n.networkDeviceKindLaptop;
    case NetworkDeviceKind.phone:
      return l10n.networkDeviceKindPhone;
    case NetworkDeviceKind.tablet:
      return l10n.networkDeviceKindTablet;
  }
}

String networkDeviceTitle(NetworkDevice device, AppLocalizations l10n) {
  final slot = device.slotLabel?.trim();
  if (slot != null && slot.isNotEmpty) {
    return l10n.networkDeviceSlotValue(slot);
  }
  return networkDeviceKindLabel(device.kind, l10n);
}

String networkDevicePlacementLine(NetworkDevice device, AppLocalizations l10n) {
  final center = device.centerName?.trim();
  final classroom = device.classroomTitle?.trim();

  if ((center == null || center.isEmpty) && (classroom == null || classroom.isEmpty)) {
    return l10n.networkDeviceUnassigned;
  }

  if (classroom == null || classroom.isEmpty) {
    return center ?? l10n.networkDeviceUnassigned;
  }

  if (center == null || center.isEmpty) {
    return classroom;
  }

  return '$center · $classroom';
}
