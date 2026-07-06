import 'package:larnes_mobile/features/kiosk/models/kiosk_device_command.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_device_context.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_scan_result.dart';

enum KioskSessionMode {
  idle,
  scan,
  result,
  play,
}

KioskSessionMode modeFromScanOutcome(KioskScanOutcome outcome) {
  switch (outcome) {
    case KioskScanOutcome.play:
      return KioskSessionMode.play;
    case KioskScanOutcome.noProgram:
      return KioskSessionMode.result;
  }
}

KioskSessionMode modeFromCommand(KioskDeviceCommandKind command) {
  switch (command) {
    case KioskDeviceCommandKind.openScan:
    case KioskDeviceCommandKind.resetChild:
      return KioskSessionMode.scan;
    case KioskDeviceCommandKind.idle:
      return KioskSessionMode.idle;
  }
}

KioskSessionMode resolveInitialMode({
  String? pendingCommand,
  String? status,
}) {
  if (pendingCommand == 'open_scan' || pendingCommand == 'reset_child') {
    return KioskSessionMode.scan;
  }

  if (status == 'waiting_scan' ||
      status == 'child_active' ||
      status == 'no_program') {
    return KioskSessionMode.scan;
  }

  return KioskSessionMode.idle;
}

KioskSessionMode resolveInitialModeFromLesson(KioskDeviceLessonBinding? lesson) {
  if (lesson == null) {
    return KioskSessionMode.idle;
  }

  return resolveInitialMode(
    pendingCommand: lesson.pendingCommand,
    status: lesson.status,
  );
}

int resolveInitialCommandSeq(KioskDeviceLessonBinding? lesson) {
  return lesson?.commandSeq ?? 0;
}
