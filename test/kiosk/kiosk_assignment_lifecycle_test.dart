import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/api/kiosk_api.dart';
import 'package:larnes_mobile/features/kiosk/controllers/kiosk_session_controller.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_active_child.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_device_context.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_commands_response.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_scan_result.dart';
import 'package:larnes_mobile/features/kiosk/utils/kiosk_initial_mode.dart';
import 'package:larnes_mobile/features/network/models/network_device.dart';
import 'package:larnes_mobile/features/parent/theme/child_card_colors.dart';
import 'kiosk_session_controller_test.dart' show FakeKioskSessionApi;
import 'memory_child_session_token_storage.dart';

KioskDeviceContext device({
  String? child = 'child-A',
  String assignment = 'assignment-A',
  bool active = true,
}) => KioskDeviceContext(
  deviceId: 'desk-1',
  kind: NetworkDeviceKind.phone,
  classroomId: 'classroom-1',
  slotLabel: 'M1',
  activeChild: child == null || !active
      ? null
      : KioskActiveChild(
          childId: child,
          childDisplayName: child,
          childCardColor: ChildCardColor.violet,
          lessonSessionId: 'lesson-1',
          assignment: assignment,
        ),
  lesson: !active
      ? null
      : const KioskDeviceLessonBinding(
          commandSeq: 5,
          lessonSessionId: 'lesson-1',
          workspaceFormat: 'board',
          status: 'child_active',
        ),
);

KioskScanResult restored(KioskDeviceContext context) =>
    KioskScanResult.fromActiveChild(
      activeChild: context.activeChild!,
      childSessionToken: 'token-${context.activeChild!.assignment}',
    );

Future<
  ({
    KioskSessionController controller,
    FakeKioskSessionApi api,
    MemoryChildSessionTokenStorage storage,
  })
>
fixture() async {
  final context = device();
  final scan = restored(context);
  final storage = MemoryChildSessionTokenStorage();
  await storage.writeToken(scan.childSessionToken);
  final api = FakeKioskSessionApi(
    pollResponses: [],
    deviceMeResponse: context,
    scanResult: scan,
  );
  final controller = KioskSessionController(
    kioskApi: api,
    childSessionTokenStorage: storage,
    deviceContext: context,
    initialScanResult: scan,
    initialMode: KioskSessionMode.result,
    onDeviceUnauthorized: () {},
  );
  addTearDown(controller.dispose);
  return (controller: controller, api: api, storage: storage);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  setUp(() async {
    root = await Directory.systemTemp.createTemp('larnes-run3-lifecycle-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => root.path);
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await root.delete(recursive: true);
  });

  test(
    'confirmed lesson end clears the child bearer and returns standby, retaining device and seat',
    () async {
      final f = await fixture();
      f.api.deviceMeResponse = device(active: false);
      await f.controller.runSyncCycle();
      expect(f.controller.mode, KioskSessionMode.idle);
      expect(f.controller.lessonWorkspaceOn, isFalse);
      expect(f.controller.scanResult, isNull);
      expect(await f.storage.hasToken(), isFalse);
      expect(f.controller.deviceContext.deviceId, 'desk-1');
      expect(f.controller.deviceContext.classroomId, 'classroom-1');
      expect(f.controller.deviceContext.slotLabel, 'M1');
      expect(f.controller.standbyKind, KioskStandbyKind.lessonNotStarted);
    },
  );

  test(
    'a transient device read failure does not pretend the lesson ended',
    () async {
      final f = await fixture();
      f.api.readDevice = () async => throw const KioskApiException('offline');
      await f.controller.runSyncCycle();
      expect(f.controller.lessonWorkspaceOn, isTrue);
      expect(await f.storage.hasToken(), isTrue);
    },
  );

  test(
    'reassignment and reseating the same child replace the old bearer before reopening',
    () async {
      for (final next in [
        device(child: 'child-B', assignment: 'assignment-B'),
        device(assignment: 'assignment-C'),
      ]) {
        final f = await fixture();
        var retired = false;
        f.controller.addListener(() {
          if (!f.controller.lessonWorkspaceOn) retired = true;
        });
        f.api.deviceMeResponse = next;
        f.api.scanResult = restored(next);
        await f.controller.runSyncCycle();
        expect(retired, isTrue);
        expect(
          f.controller.scanResult?.assignment,
          next.activeChild!.assignment,
        );
        expect(await f.storage.readToken(), restored(next).childSessionToken);
        expect(f.controller.lessonWorkspaceOn, isTrue);
        f.controller.dispose();
      }
    },
  );

  test(
    'a delayed resume cannot install child A after the server assigned child B',
    () async {
      final f = await fixture();
      await f.storage.clearToken();
      final pending = Completer<KioskScanResult>();
      f.api.resume = () => pending.future;
      final sync = f.controller.runSyncCycle();
      await Future<void>.delayed(Duration.zero);
      final next = device(child: 'child-B', assignment: 'assignment-B');
      f.api.deviceMeResponse = next;
      pending.complete(restored(device()));
      await sync;
      expect(f.controller.lessonWorkspaceOn, isFalse);
      expect(await f.storage.hasToken(), isFalse);
      f.api.resume = null;
      f.api.scanResult = restored(next);
      await f.controller.runSyncCycle();
      expect(f.controller.lessonWorkspaceOn, isTrue);
      expect(f.controller.scanResult?.childId, 'child-B');
    },
  );

  test(
    'failed desk exit keeps its pupil; confirmed retry clears only child data and sends the assignment scope',
    () async {
      final f = await fixture();
      f.api.leave = () async => throw const KioskApiException('offline');
      expect(await f.controller.leaveDesk(), isFalse);
      expect(f.controller.lessonWorkspaceOn, isTrue);
      expect(await f.storage.hasToken(), isTrue);
      f.api.leave = null;
      expect(await f.controller.leaveDesk(), isTrue);
      expect(f.controller.lessonWorkspaceOn, isFalse);
      expect(await f.storage.hasToken(), isFalse);
      expect(f.controller.deviceContext.deviceId, 'desk-1');
      expect(f.controller.standbyKind, KioskStandbyKind.childNotAssigned);
      expect(f.api.leaveScope, {
        'childId': 'child-A',
        'lessonSessionId': 'lesson-1',
        'assignment': 'assignment-A',
      });
    },
  );

  test(
    'a pending poll from before confirmed exit cannot restore the old pupil',
    () async {
      final f = await fixture();
      final pending = Completer<KioskCommandsResponse>();
      f.api.poll = () => pending.future;
      final sync = f.controller.runSyncCycle();
      expect(await f.controller.leaveDesk(), isTrue);
      pending.complete(
        const KioskCommandsResponse(since: 5, commandSeq: 5, commands: []),
      );
      await sync;
      expect(f.controller.scanResult, isNull);
      expect(await f.storage.hasToken(), isFalse);
    },
  );

  test(
    'a resume that finishes after disposal never writes its child token',
    () async {
      final f = await fixture();
      await f.storage.clearToken();
      final pending = Completer<KioskScanResult>();
      f.api.resume = () => pending.future;
      final sync = f.controller.runSyncCycle();
      await Future<void>.delayed(Duration.zero);
      f.controller.dispose();
      pending.complete(restored(device()));
      await sync;
      expect(await f.storage.hasToken(), isFalse);
    },
  );
}
