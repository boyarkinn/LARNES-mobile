import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:larnes_mobile/core/api/kiosk_api.dart';
import 'package:larnes_mobile/features/kiosk/api/kiosk_session_api.dart';
import 'package:larnes_mobile/features/kiosk/controllers/kiosk_session_controller.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_commands_response.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_active_child.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_device_command.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_device_context.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_scan_result.dart';
import 'package:larnes_mobile/features/kiosk/utils/kiosk_initial_mode.dart';
import 'package:larnes_mobile/features/network/models/network_device.dart';
import 'package:larnes_mobile/features/parent/theme/child_card_colors.dart';

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
  KioskScanResult? scanResult;
  final KioskApiException? scanError;
  final KioskApiException? pollError;
  KioskDeviceContext? deviceMeResponse;
  Future<KioskDeviceContext> Function()? readDevice;
  Future<KioskScanResult> Function()? resume;
  Future<void> Function()? leave;
  Future<KioskCommandsResponse> Function()? poll;
  Map<String, String?>? leaveScope;

  int pollCalls = 0;
  int getDeviceMeCalls = 0;
  int heartbeatCalls = 0;
  int? lastHeartbeatAck;
  int childLogoutCalls = 0;
  int leaveDeskCalls = 0;
  int scanCalls = 0;
  String? lastScanToken;

  @override
  Future<KioskDeviceContext> getDeviceMe({String locale = 'ru'}) async {
    getDeviceMeCalls += 1;
    if (readDevice != null) return readDevice!();
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
    if (poll != null) return poll!();
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
  Future<void> leaveDesk({
    String locale = 'ru',
    String? childId,
    String? lessonSessionId,
    String? assignment,
  }) async {
    leaveDeskCalls += 1;
    leaveScope = {
      'childId': childId,
      'lessonSessionId': lessonSessionId,
      'assignment': assignment,
    };
    if (leave != null) return leave!();
  }

  @override
  Future<KioskScanResult> scan({
    required String token,
    String locale = 'ru',
  }) async {
    scanCalls += 1;
    lastScanToken = token;
    if (scanError != null) {
      throw scanError!;
    }
    return scanResult!;
  }

  @override
  Future<KioskScanResult> resumeChildSession({String locale = 'ru'}) async {
    if (resume != null) return resume!();
    if (scanResult == null) {
      throw KioskApiException('resume failed');
    }
    return scanResult!;
  }
}

KioskDeviceContext _deviceContext({
  KioskActiveChild? activeChild,
  KioskDeviceLessonBinding? lesson,
}) {
  return KioskDeviceContext(
    deviceId: '55555555-5555-4555-8555-555555555555',
    kind: NetworkDeviceKind.phone,
    activeChild: activeChild,
    centerName: 'Center A',
    classroomTitle: 'Room 1',
    slotLabel: 'M1',
    lesson: lesson,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory cacheRoot;
  const cacheChannel = MethodChannel('plugins.flutter.io/path_provider');
  setUp(() async {
    cacheRoot = await Directory.systemTemp.createTemp(
      'larnes-kiosk-lifecycle-',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(cacheChannel, (_) async => cacheRoot.path);
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(cacheChannel, null);
    await cacheRoot.delete(recursive: true);
  });
  group('KioskSessionController', () {
    test(
      'assignment and play command in the same poll restore the shared board from idle',
      () async {
        const child = KioskActiveChild(
          childId: 'child-1',
          childDisplayName: 'Test',
          childCardColor: ChildCardColor.violet,
          lessonSessionId: 'lesson-1',
        );
        final storage = MemoryChildSessionTokenStorage();
        final api = FakeKioskSessionApi(
          pollResponses: [
            const KioskCommandsResponse(
              since: 0,
              commandSeq: 1,
              commands: [
                KioskDeviceCommand(
                  command: KioskDeviceCommandKind.playTrainer,
                  seq: 1,
                ),
              ],
            ),
          ],
          deviceMeResponse: _deviceContext(
            activeChild: child,
            lesson: const KioskDeviceLessonBinding(
              commandSeq: 1,
              lessonSessionId: 'lesson-1',
              status: 'child_active',
              workspaceFormat: 'board',
              pendingCommand: 'play_trainer',
            ),
          ),
          scanResult: KioskScanResult.fromActiveChild(
            activeChild: child,
            childSessionToken: 'fresh-board-token',
          ),
        );
        final controller = KioskSessionController(
          kioskApi: api,
          childSessionTokenStorage: storage,
          deviceContext: _deviceContext(),
          onDeviceUnauthorized: () {},
        );
        await controller.runSyncCycle();
        expect(controller.lessonWorkspaceOn, isTrue);
        expect(controller.mode, KioskSessionMode.result);
        expect(await storage.readToken(), 'fresh-board-token');
        expect(api.lastHeartbeatAck, 1);
        controller.dispose();
      },
    );
    test(
      'a restored board seat opens the shared workspace with class video off',
      () async {
        const child = KioskActiveChild(
          childId: 'child-1',
          childDisplayName: 'Test',
          childCardColor: ChildCardColor.violet,
          lessonSessionId: 'lesson-1',
        );
        const lesson = KioskDeviceLessonBinding(
          commandSeq: 2,
          lessonSessionId: 'lesson-1',
          status: 'child_active',
          workspaceFormat: 'board',
          pendingCommand: 'play_trainer',
        );
        final storage = MemoryChildSessionTokenStorage();
        await storage.writeToken('child-token');
        final api = FakeKioskSessionApi(
          deviceMeResponse: _deviceContext(activeChild: child, lesson: lesson),
          pollResponses: [
            const KioskCommandsResponse(
              since: 1,
              commandSeq: 2,
              commands: [
                KioskDeviceCommand(
                  command: KioskDeviceCommandKind.playTrainer,
                  seq: 2,
                ),
              ],
            ),
          ],
        );
        final controller = KioskSessionController(
          kioskApi: api,
          childSessionTokenStorage: storage,
          deviceContext: _deviceContext(activeChild: child, lesson: lesson),
          initialScanResult: KioskScanResult.fromActiveChild(
            activeChild: child,
            childSessionToken: 'child-token',
          ),
          initialMode: KioskSessionMode.result,
          onDeviceUnauthorized: () {},
        );
        expect(controller.lessonWorkspaceOn, isTrue);
        await controller.runSyncCycle();
        expect(controller.mode, KioskSessionMode.result);
        expect(api.lastHeartbeatAck, 2);
        controller.updateDeviceContext(_deviceContext(lesson: lesson));
        expect(controller.lessonWorkspaceOn, isFalse);
        controller.updateDeviceContext(
          _deviceContext(
            activeChild: child,
            lesson: const KioskDeviceLessonBinding(
              commandSeq: 0,
              lessonSessionId: 'another-lesson',
              status: 'child_active',
              workspaceFormat: 'board',
            ),
          ),
        );
        expect(controller.lessonWorkspaceOn, isFalse);
        controller.dispose();
      },
    );

    test(
      'an assignment without a restored child token keeps the workspace closed',
      () {
        final controller = KioskSessionController(
          kioskApi: FakeKioskSessionApi(pollResponses: []),
          childSessionTokenStorage: MemoryChildSessionTokenStorage(),
          deviceContext: _deviceContext(
            activeChild: const KioskActiveChild(
              childId: 'child-1',
              childDisplayName: 'Test',
              childCardColor: ChildCardColor.violet,
              lessonSessionId: 'lesson-1',
            ),
            lesson: const KioskDeviceLessonBinding(
              commandSeq: 0,
              lessonSessionId: 'lesson-1',
              status: 'no_program',
              workspaceFormat: 'board',
            ),
          ),
          onDeviceUnauthorized: () {},
        );
        expect(controller.lessonWorkspaceOn, isFalse);
        controller.dispose();
      },
    );

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

    test(
      'sync cycle acks leftover open_scan without opening the camera',
      () async {
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

        expect(controller.mode, KioskSessionMode.idle);
        expect(api.childLogoutCalls, 0);
        expect(await childStorage.hasToken(), isFalse);
        expect(api.heartbeatCalls, 1);
        expect(api.lastHeartbeatAck, 2);

        controller.dispose();
      },
    );

    test(
      'sync cycle advances since without command and sends heartbeat',
      () async {
        final api = FakeKioskSessionApi(
          pollResponses: [
            const KioskCommandsResponse(since: 1, commandSeq: 3, commands: []),
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
        expect(api.lastHeartbeatAck, 3);

        controller.dispose();
      },
    );

    test(
      'sync cycle stays idle for leftover waiting_scan when QR is frozen',
      () async {
        final api = FakeKioskSessionApi(
          pollResponses: [
            const KioskCommandsResponse(since: 0, commandSeq: 1, commands: []),
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

        expect(controller.mode, KioskSessionMode.idle);
        expect(api.getDeviceMeCalls, 1);
        expect(api.heartbeatCalls, 1);

        controller.dispose();
      },
    );

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
