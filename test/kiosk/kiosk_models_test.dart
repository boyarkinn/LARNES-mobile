import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/auth/child_session_token_storage.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_commands_response.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_device_command.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_scan_result.dart';

import 'memory_child_session_token_storage.dart';

void main() {
  group('KioskDeviceCommand', () {
    test('parses command kinds from api strings', () {
      expect(
        KioskDeviceCommand.fromJson({'command': 'open_scan', 'seq': 2}).command,
        KioskDeviceCommandKind.openScan,
      );
      expect(
        KioskDeviceCommand.fromJson({'command': 'reset_child', 'seq': 3}).command,
        KioskDeviceCommandKind.resetChild,
      );
      expect(
        KioskDeviceCommand.fromJson({'command': 'idle', 'seq': 4}).command,
        KioskDeviceCommandKind.idle,
      );
    });
  });

  group('KioskCommandsResponse.fromJson', () {
    test('parses command list payload', () {
      final response = KioskCommandsResponse.fromJson({
        'since': 2,
        'commandSeq': 3,
        'commands': [
          {'command': 'open_scan', 'seq': 3},
        ],
      });

      expect(response.since, 2);
      expect(response.commandSeq, 3);
      expect(response.commands, hasLength(1));
      expect(response.commands.first.command, KioskDeviceCommandKind.openScan);
    });
  });

  group('KioskScanResult.fromJson', () {
    test('parses play outcome', () {
      final result = KioskScanResult.fromJson({
        'ok': true,
        'outcome': 'play',
        'programId': '77777777-7777-4777-8777-777777777777',
        'childId': '88888888-8888-4888-8888-888888888888',
        'childDisplayName': 'Anna',
        'childSessionToken': 'child-jwt-token',
      });

      expect(result.outcome, KioskScanOutcome.play);
      expect(result.programId, '77777777-7777-4777-8777-777777777777');
      expect(result.childDisplayName, 'Anna');
      expect(result.childSessionToken, 'child-jwt-token');
    });

    test('parses no_program outcome', () {
      final result = KioskScanResult.fromJson({
        'ok': true,
        'outcome': 'no_program',
        'childId': '88888888-8888-4888-8888-888888888888',
        'childDisplayName': 'Anna',
        'childSessionToken': 'child-jwt-token',
      });

      expect(result.outcome, KioskScanOutcome.noProgram);
      expect(result.programId, isNull);
    });
  });

  group('ChildSessionTokenStorage (memory)', () {
    test('persists token round-trip', () async {
      final storage = MemoryChildSessionTokenStorage();

      expect(await storage.hasToken(), isFalse);

      await storage.writeToken('child-jwt-token');
      expect(await storage.readToken(), 'child-jwt-token');
      expect(await storage.hasToken(), isTrue);

      await storage.clearToken();
      expect(await storage.hasToken(), isFalse);
    });
  });
}
