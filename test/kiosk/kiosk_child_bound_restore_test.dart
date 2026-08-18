import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_active_child.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_device_context.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_scan_result.dart';
import 'package:larnes_mobile/features/kiosk/utils/kiosk_child_bound_restore.dart';
import 'package:larnes_mobile/features/kiosk/utils/kiosk_initial_mode.dart';
import 'package:larnes_mobile/features/kiosk/api/kiosk_session_api.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_commands_response.dart';
import 'package:larnes_mobile/features/network/models/network_device.dart';
import 'package:larnes_mobile/features/parent/theme/child_card_colors.dart';

import 'memory_child_session_token_storage.dart';

class _RestoreFakeApi implements KioskSessionApi {
  _RestoreFakeApi({required this.resumeResult});

  final KioskScanResult resumeResult;
  int resumeCalls = 0;

  @override
  Future<KioskDeviceContext> getDeviceMe({String locale = 'ru'}) {
    throw UnimplementedError();
  }

  @override
  Future<KioskCommandsResponse> pollCommands({
    required int since,
    String locale = 'ru',
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> heartbeat({int? ackSeq, String locale = 'ru'}) {
    throw UnimplementedError();
  }

  @override
  Future<void> childLogout({String locale = 'ru'}) async {}

  @override
  Future<KioskScanResult> scan({required String token, String locale = 'ru'}) {
    throw UnimplementedError();
  }

  @override
  Future<KioskScanResult> resumeChildSession({String locale = 'ru'}) async {
    resumeCalls += 1;
    return resumeResult;
  }
}

KioskDeviceContext _deviceWithActiveChild({required bool withLessonStatus}) {
  return KioskDeviceContext(
    deviceId: '55555555-5555-4555-8555-555555555555',
    kind: NetworkDeviceKind.phone,
    activeChild: const KioskActiveChild(
      childId: '88888888-8888-4888-8888-888888888888',
      childDisplayName: 'Петрова Анна',
      childCardColor: ChildCardColor.violet,
      childGender: 'female',
      childGivenName: 'Анна',
      childLastName: 'Петрова',
      lessonSessionId: '66666666-6666-4666-8666-666666666666',
    ),
    lesson: withLessonStatus
        ? const KioskDeviceLessonBinding(
            commandSeq: 2,
            lessonSessionId: '66666666-6666-4666-8666-666666666666',
            status: 'child_active',
          )
        : null,
  );
}

void main() {
  group('restoreKioskChildBoundSnapshot', () {
    test('uses stored child token when present', () async {
      final storage = MemoryChildSessionTokenStorage();
      await storage.writeToken('stored-child-jwt');

      final result = await restoreKioskChildBoundSnapshot(
        device: _deviceWithActiveChild(withLessonStatus: true),
        kioskApi: _RestoreFakeApi(
          resumeResult: const KioskScanResult(
            outcome: KioskScanOutcome.noProgram,
            childId: '88888888-8888-4888-8888-888888888888',
            childDisplayName: 'unused',
            childSessionToken: 'unused',
          ),
        ),
        childSessionTokenStorage: storage,
      );

      expect(result?.childSessionToken, 'stored-child-jwt');
      expect(result?.childLastName, 'Петрова');
    });

    test('resumes child session when token is missing', () async {
      final storage = MemoryChildSessionTokenStorage();
      final api = _RestoreFakeApi(
        resumeResult: const KioskScanResult(
          outcome: KioskScanOutcome.noProgram,
          childId: '88888888-8888-4888-8888-888888888888',
          childDisplayName: 'Петрова Анна',
          childSessionToken: 'fresh-child-jwt',
          childLastName: 'Петрова',
          childGivenName: 'Анна',
        ),
      );

      final result = await restoreKioskChildBoundSnapshot(
        device: _deviceWithActiveChild(withLessonStatus: true),
        kioskApi: api,
        childSessionTokenStorage: storage,
      );

      expect(api.resumeCalls, 1);
      expect(result?.childSessionToken, 'fresh-child-jwt');
      expect(await storage.readToken(), 'fresh-child-jwt');
    });

    test('returns null when lesson expects scan mode', () async {
      final storage = MemoryChildSessionTokenStorage();
      await storage.writeToken('stored-child-jwt');

      final result = await restoreKioskChildBoundSnapshot(
        device: KioskDeviceContext(
          deviceId: '55555555-5555-4555-8555-555555555555',
          kind: NetworkDeviceKind.phone,
          activeChild: _deviceWithActiveChild(withLessonStatus: true).activeChild,
          lesson: const KioskDeviceLessonBinding(
            commandSeq: 2,
            lessonSessionId: '66666666-6666-4666-8666-666666666666',
            status: 'waiting_scan',
          ),
        ),
        kioskApi: _RestoreFakeApi(
          resumeResult: const KioskScanResult(
            outcome: KioskScanOutcome.noProgram,
            childId: '88888888-8888-4888-8888-888888888888',
            childDisplayName: 'unused',
            childSessionToken: 'unused',
          ),
        ),
        childSessionTokenStorage: storage,
      );

      expect(result, isNull);
      expect(
        resolveInitialMode(
          pendingCommand: null,
          status: 'waiting_scan',
        ),
        KioskSessionMode.scan,
      );
    });
  });
}
