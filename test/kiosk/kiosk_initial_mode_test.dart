import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_device_command.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_device_context.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_scan_result.dart';
import 'package:larnes_mobile/features/kiosk/utils/kiosk_initial_mode.dart';

void main() {
  group('resolveInitialMode', () {
    test('returns scan for open_scan pending command', () {
      expect(
        resolveInitialMode(pendingCommand: 'open_scan', status: 'idle_child'),
        KioskSessionMode.scan,
      );
    });

    test('returns scan for reset_child pending command', () {
      expect(
        resolveInitialMode(pendingCommand: 'reset_child', status: null),
        KioskSessionMode.scan,
      );
    });

    test('returns scan for waiting_scan status', () {
      expect(
        resolveInitialMode(pendingCommand: null, status: 'waiting_scan'),
        KioskSessionMode.scan,
      );
    });

    test('returns scan for child_active and no_program statuses', () {
      expect(
        resolveInitialMode(pendingCommand: null, status: 'child_active'),
        KioskSessionMode.scan,
      );
      expect(
        resolveInitialMode(pendingCommand: null, status: 'no_program'),
        KioskSessionMode.scan,
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
        KioskSessionMode.scan,
      );
      expect(
        modeFromCommand(KioskDeviceCommandKind.resetChild),
        KioskSessionMode.scan,
      );
      expect(
        modeFromCommand(KioskDeviceCommandKind.idle),
        KioskSessionMode.idle,
      );
    });
  });
}
