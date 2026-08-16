import 'package:larnes_mobile/features/kiosk/models/kiosk_device_command.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_device_context.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_scan_result.dart';

enum KioskSessionMode {
  idle,
  scan,
  result,
  play,
  trainer,
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
    case KioskDeviceCommandKind.playTrainer:
      return KioskSessionMode.trainer;
    case KioskDeviceCommandKind.idle:
      return KioskSessionMode.idle;
  }
}

KioskSessionMode resolveInitialMode({
  String? pendingCommand,
  String? status,
}) {
  if (pendingCommand == 'play_trainer') {
    return KioskSessionMode.trainer;
  }

  if (pendingCommand == 'open_scan' || pendingCommand == 'reset_child') {
    return KioskSessionMode.scan;
  }

  if (status == 'waiting_scan' || status == 'offline') {
    return KioskSessionMode.scan;
  }

  if (status == 'child_active' || status == 'no_program') {
    return KioskSessionMode.result;
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
  if (lesson == null) {
    return 0;
  }

  if (lesson.pendingCommand != null && lesson.commandSeq > 0) {
    return lesson.commandSeq - 1;
  }

  return lesson.commandSeq;
}
