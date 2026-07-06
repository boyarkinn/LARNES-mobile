import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/api/kiosk_api.dart';
import 'package:larnes_mobile/features/kiosk/api/kiosk_session_api.dart';
import 'package:larnes_mobile/features/kiosk/controllers/kiosk_session_controller.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_commands_response.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_device_command.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_device_context.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_scan_result.dart';
import 'package:larnes_mobile/features/kiosk/utils/kiosk_initial_mode.dart';
import 'package:larnes_mobile/features/network/models/network_device.dart';

import 'memory_child_session_token_storage.dart';

class FakeKioskSessionApi implements KioskSessionApi {
  FakeKioskSessionApi({
    required this.pollResponses,
    this.scanResult,
    this.scanError,
    this.pollError,
    this.deviceMeResponse,
  });

  final List<KioskCommandsResponse> pollResponses;
  final KioskScanResult? scanResult;
  final KioskApiException? scanError;
  final KioskApiException? pollError;
  final KioskDeviceContext? deviceMeResponse;

  int pollCalls = 0;
  int getDeviceMeCalls = 0;
  int heartbeatCalls = 0;
  int? lastHeartbeatAck;
  int childLogoutCalls = 0;
  int scanCalls = 0;
  String? lastScanToken;

  @override
  Future<KioskDeviceContext> getDeviceMe({String locale = 'ru'}) async {
    getDeviceMeCalls += 1;
    return deviceMeResponse ??
        KioskDeviceContext(
          deviceId: '55555555-5555-4555-8555-555555555555',
          kind: NetworkDeviceKind.phone,
        );
  }

  @override
  Future<KioskCommandsResponse> pollCommands({
    required int since,
    String locale = 'ru',
  }) async {
    pollCalls += 1;
    if (pollError != null) {
      throw pollError!;
    }
    if (pollResponses.isEmpty) {
      return KioskCommandsResponse(
        since: since,
        commandSeq: since,
        commands: const [],
      );
    }
    return pollResponses.removeAt(0);
  }

  @override
  Future<void> heartbeat({int? ackSeq, String locale = 'ru'}) async {
    heartbeatCalls += 1;
    lastHeartbeatAck = ackSeq;
  }

  @override
  Future<void> childLogout({String locale = 'ru'}) async {
    childLogoutCalls += 1;
  }

  @override
  Future<KioskScanResult> scan({required String token, String locale = 'ru'}) async {
    scanCalls += 1;
    lastScanToken = token;
    if (scanError != null) {
      throw scanError!;
    }
    return scanResult!;
  }
}

KioskDeviceContext _deviceContext({KioskDeviceLessonBinding? lesson}) {
  return KioskDeviceContext(
    deviceId: '55555555-5555-4555-8555-555555555555',
    kind: NetworkDeviceKind.phone,
    centerName: 'Center A',
    classroomTitle: 'Room 1',
    slotLabel: 'M1',
    lesson: lesson,
  );
}

void main() {
  group('KioskSessionController', () {
    test('starts in idle without lesson binding', () {
      final controller = KioskSessionController(
        kioskApi: FakeKioskSessionApi(pollResponses: []),
        childSessionTokenStorage: MemoryChildSessionTokenStorage(),
        deviceContext: _deviceContext(),
        onDeviceUnauthorized: () {},
      );

      expect(controller.mode, KioskSessionMode.idle);
      controller.dispose();
    });

    test('sync cycle handles open_scan command and ack heartbeat', () async {
      final api = FakeKioskSessionApi(
        pollResponses: [
          KioskCommandsResponse(
            since: 0,
            commandSeq: 2,
            commands: const [
              KioskDeviceCommand(
                command: KioskDeviceCommandKind.openScan,
                seq: 2,
              ),
            ],
          ),
        ],
      );
      final childStorage = MemoryChildSessionTokenStorage();
      await childStorage.writeToken('existing-child-token');

      final controller = KioskSessionController(
        kioskApi: api,
        childSessionTokenStorage: childStorage,
        deviceContext: _deviceContext(),
        onDeviceUnauthorized: () {},
      );

      await controller.runSyncCycle();

      expect(controller.mode, KioskSessionMode.scan);
      expect(api.childLogoutCalls, 1);
      expect(await childStorage.hasToken(), isFalse);
      expect(api.heartbeatCalls, 1);
      expect(api.lastHeartbeatAck, 2);

      controller.dispose();
    });

    test('sync cycle advances since without command and sends heartbeat', () async {
      final api = FakeKioskSessionApi(
        pollResponses: [
          const KioskCommandsResponse(
            since: 1,
            commandSeq: 3,
            commands: [],
          ),
        ],
        deviceMeResponse: _deviceContext(
          lesson: const KioskDeviceLessonBinding(
            commandSeq: 3,
            lessonSessionId: 'lesson-id',
            status: 'idle_child',
          ),
        ),
      );

      final controller = KioskSessionController(
        kioskApi: api,
        childSessionTokenStorage: MemoryChildSessionTokenStorage(),
        deviceContext: _deviceContext(
          lesson: const KioskDeviceLessonBinding(
            commandSeq: 1,
            lessonSessionId: 'lesson-id',
            status: 'idle_child',
          ),
        ),
        onDeviceUnauthorized: () {},
      );

      await controller.runSyncCycle();

      expect(controller.mode, KioskSessionMode.idle);
      expect(api.childLogoutCalls, 0);
      expect(api.heartbeatCalls, 1);
      expect(api.lastHeartbeatAck, isNull);

      controller.dispose();
    });

    test('sync cycle reconciles scan from devices/me when poll skips command', () async {
      final api = FakeKioskSessionApi(
        pollResponses: [
          const KioskCommandsResponse(
            since: 0,
            commandSeq: 1,
            commands: [],
          ),
        ],
        deviceMeResponse: _deviceContext(
          lesson: const KioskDeviceLessonBinding(
            commandSeq: 1,
            lessonSessionId: 'lesson-id',
            status: 'waiting_scan',
          ),
        ),
      );

      final controller = KioskSessionController(
        kioskApi: api,
        childSessionTokenStorage: MemoryChildSessionTokenStorage(),
        deviceContext: _deviceContext(),
        onDeviceUnauthorized: () {},
      );

      await controller.runSyncCycle();

      expect(controller.mode, KioskSessionMode.scan);
      expect(api.getDeviceMeCalls, 1);
      expect(api.heartbeatCalls, 1);

      controller.dispose();
    });

    test('submitScan stores child token and switches to result', () async {
      final api = FakeKioskSessionApi(
        pollResponses: [],
        scanResult: const KioskScanResult(
          outcome: KioskScanOutcome.play,
          childId: '88888888-8888-4888-8888-888888888888',
          childDisplayName: 'Anna',
          childSessionToken: 'child-jwt-token',
          programId: '77777777-7777-4777-8777-777777777777',
        ),
      );
      final childStorage = MemoryChildSessionTokenStorage();

      final controller = KioskSessionController(
        kioskApi: api,
        childSessionTokenStorage: childStorage,
        deviceContext: _deviceContext(),
        initialMode: KioskSessionMode.scan,
        onDeviceUnauthorized: () {},
      );

      await controller.submitScan('qr-token');

      expect(api.scanCalls, 1);
      expect(api.lastScanToken, 'qr-token');
      expect(await childStorage.readToken(), 'child-jwt-token');
      expect(controller.mode, KioskSessionMode.play);
      expect(controller.activeProgramId, '77777777-7777-4777-8777-777777777777');
      expect(controller.scanResult?.childDisplayName, 'Anna');

      controller.dispose();
    });

    test('submitScan with no_program switches to result', () async {
      final api = FakeKioskSessionApi(
        pollResponses: [],
        scanResult: const KioskScanResult(
          outcome: KioskScanOutcome.noProgram,
          childId: '88888888-8888-4888-8888-888888888888',
          childDisplayName: 'Anna',
          childSessionToken: 'child-jwt-token',
        ),
      );

      final controller = KioskSessionController(
        kioskApi: api,
        childSessionTokenStorage: MemoryChildSessionTokenStorage(),
        deviceContext: _deviceContext(),
        initialMode: KioskSessionMode.scan,
        onDeviceUnauthorized: () {},
      );

      await controller.submitScan('qr-token');

      expect(controller.mode, KioskSessionMode.result);
      controller.dispose();
    });

    test('idle command clears play mode', () async {
      final api = FakeKioskSessionApi(
        pollResponses: [
          KioskCommandsResponse(
            since: 2,
            commandSeq: 3,
            commands: const [
              KioskDeviceCommand(
                command: KioskDeviceCommandKind.idle,
                seq: 3,
              ),
            ],
          ),
        ],
        scanResult: const KioskScanResult(
          outcome: KioskScanOutcome.play,
          childId: '88888888-8888-4888-8888-888888888888',
          childDisplayName: 'Anna',
          childSessionToken: 'child-jwt-token',
          programId: '77777777-7777-4777-8777-777777777777',
        ),
      );
      final childStorage = MemoryChildSessionTokenStorage();

      final controller = KioskSessionController(
        kioskApi: api,
        childSessionTokenStorage: childStorage,
        deviceContext: _deviceContext(),
        initialMode: KioskSessionMode.scan,
        onDeviceUnauthorized: () {},
      );

      await controller.submitScan('qr-token');
      expect(controller.mode, KioskSessionMode.play);

      await controller.runSyncCycle();

      expect(controller.mode, KioskSessionMode.idle);
      expect(controller.scanResult, isNull);
      expect(api.childLogoutCalls, 1);

      controller.dispose();
    });

    test('reset_child command during play switches to scan and clears child',
        () async {
      final api = FakeKioskSessionApi(
        pollResponses: [
          KioskCommandsResponse(
            since: 2,
            commandSeq: 4,
            commands: const [
              KioskDeviceCommand(
                command: KioskDeviceCommandKind.resetChild,
                seq: 4,
              ),
            ],
          ),
        ],
        scanResult: const KioskScanResult(
          outcome: KioskScanOutcome.play,
          childId: '88888888-8888-4888-8888-888888888888',
          childDisplayName: 'Anna',
          childSessionToken: 'child-jwt-token',
          programId: '77777777-7777-4777-8777-777777777777',
        ),
      );
      final childStorage = MemoryChildSessionTokenStorage();

      final controller = KioskSessionController(
        kioskApi: api,
        childSessionTokenStorage: childStorage,
        deviceContext: _deviceContext(),
        initialMode: KioskSessionMode.scan,
        initialCommandSeq: 2,
        onDeviceUnauthorized: () {},
      );

      await controller.submitScan('qr-token');
      expect(controller.mode, KioskSessionMode.play);
      expect(await childStorage.hasToken(), isTrue);

      await controller.runSyncCycle();

      expect(controller.mode, KioskSessionMode.scan);
      expect(controller.scanResult, isNull);
      expect(controller.activeProgramId, isNull);
      expect(await childStorage.hasToken(), isFalse);
      expect(api.childLogoutCalls, 1);
      expect(api.getDeviceMeCalls, 0);

      controller.dispose();
    });

    test('401 on poll triggers unauthorized callback', () async {
      var unauthorized = false;
      final api = FakeKioskSessionApi(
        pollResponses: [],
        pollError: const KioskApiException('Unauthorized', statusCode: 401),
      );

      final controller = KioskSessionController(
        kioskApi: api,
        childSessionTokenStorage: MemoryChildSessionTokenStorage(),
        deviceContext: _deviceContext(),
        onDeviceUnauthorized: () => unauthorized = true,
      );

      await controller.runSyncCycle();

      expect(unauthorized, isTrue);
      controller.dispose();
    });

    test('setPaused skips sync cycle', () async {
      final api = FakeKioskSessionApi(pollResponses: []);

      final controller = KioskSessionController(
        kioskApi: api,
        childSessionTokenStorage: MemoryChildSessionTokenStorage(),
        deviceContext: _deviceContext(),
        onDeviceUnauthorized: () {},
      )..setPaused(true);

      await controller.runSyncCycle();

      expect(api.pollCalls, 0);
      controller.dispose();
    });

    test('dispose cancels timer without throwing', () async {
      final api = FakeKioskSessionApi(pollResponses: []);

      final controller = KioskSessionController(
        kioskApi: api,
        childSessionTokenStorage: MemoryChildSessionTokenStorage(),
        deviceContext: _deviceContext(),
        onDeviceUnauthorized: () {},
        syncInterval: const Duration(milliseconds: 20),
      )..start();

      await Future<void>.delayed(const Duration(milliseconds: 50));
      controller.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(api.pollCalls, greaterThan(0));
    });
  });
}
