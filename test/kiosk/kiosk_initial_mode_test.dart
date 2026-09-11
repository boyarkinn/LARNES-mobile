import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_device_command.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_device_context.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_scan_result.dart';
import 'package:larnes_mobile/features/kiosk/utils/kiosk_initial_mode.dart';

void main() {
  group('resolveInitialMode', () {
    test('stays idle for leftover QR signals while scan is frozen', () {
      expect(
        resolveInitialMode(pendingCommand: 'open_scan', status: 'idle_child'),
        KioskSessionMode.idle,
      );
      expect(
        resolveInitialMode(pendingCommand: 'reset_child', status: null),
        KioskSessionMode.idle,
      );
      expect(
        resolveInitialMode(pendingCommand: null, status: 'waiting_scan'),
        KioskSessionMode.idle,
      );
      expect(
        resolveInitialMode(pendingCommand: null, status: 'offline'),
        KioskSessionMode.idle,
      );
    });

    test('returns result for child_active and no_program statuses', () {
      expect(
        resolveInitialMode(pendingCommand: null, status: 'child_active'),
        KioskSessionMode.result,
      );
      expect(
        resolveInitialMode(pendingCommand: null, status: 'no_program'),
        KioskSessionMode.result,
      );
    });

    test('resolves standby copy from lesson presence', () {
      expect(
        resolveKioskStandbyKind(hasActiveLesson: false, hasAssignedChild: false),
        KioskStandbyKind.lessonNotStarted,
      );
      expect(
        resolveKioskStandbyKind(hasActiveLesson: true, hasAssignedChild: false),
        KioskStandbyKind.childNotAssigned,
      );
    });

    test('returns idle when no active scan signals', () {
      expect(
        resolveInitialMode(pendingCommand: null, status: 'idle_child'),
        KioskSessionMode.idle,
      );
      expect(resolveInitialMode(), KioskSessionMode.idle);
    });
  });

  group('resolveInitialCommandSeq', () {
    test('returns lesson commandSeq or zero', () {
      expect(
        resolveInitialCommandSeq(null),
        0,
      );
      expect(
        resolveInitialCommandSeq(
          const KioskDeviceLessonBinding(
            commandSeq: 5,
            lessonSessionId: 'lesson-id',
            status: 'waiting_scan',
          ),
        ),
        5,
      );
    });

    test('returns commandSeq minus one when a command is still pending', () {
      expect(
        resolveInitialCommandSeq(
          const KioskDeviceLessonBinding(
            commandSeq: 5,
            lessonSessionId: 'lesson-id',
            pendingCommand: 'play_trainer',
            status: 'no_program',
          ),
        ),
        4,
      );
    });
  });

  group('modeFromScanOutcome', () {
    test('maps scan outcomes to session modes', () {
      expect(
        modeFromScanOutcome(KioskScanOutcome.play),
        KioskSessionMode.play,
      );
      expect(
        modeFromScanOutcome(KioskScanOutcome.noProgram),
        KioskSessionMode.result,
      );
    });
  });

  group('modeFromCommand', () {
    test('maps device commands to session modes', () {
      expect(
        modeFromCommand(KioskDeviceCommandKind.openScan),
        KioskSessionMode.idle,
      );
      expect(
        modeFromCommand(KioskDeviceCommandKind.resetChild),
        KioskSessionMode.idle,
      );
      expect(
        modeFromCommand(KioskDeviceCommandKind.idle),
        KioskSessionMode.idle,
      );
    });
  });
}
