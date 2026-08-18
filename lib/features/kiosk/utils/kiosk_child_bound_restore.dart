import 'package:larnes_mobile/core/auth/child_session_token_storage.dart';
import 'package:larnes_mobile/features/kiosk/api/kiosk_session_api.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_device_context.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_scan_result.dart';
import 'package:larnes_mobile/features/kiosk/utils/kiosk_initial_mode.dart';

Future<KioskScanResult?> restoreKioskChildBoundSnapshot({
  required KioskDeviceContext device,
  required KioskSessionApi kioskApi,
  required ChildSessionTokenStorage childSessionTokenStorage,
}) async {
  final activeChild = device.activeChild;
  final lesson = device.lesson;

  if (activeChild == null || lesson == null) {
    return null;
  }

  if (resolveInitialMode(
        pendingCommand: lesson.pendingCommand,
        status: lesson.status,
      ) !=
      KioskSessionMode.result) {
    return null;
  }

  final storedToken = await childSessionTokenStorage.readToken();
  if (storedToken != null && storedToken.isNotEmpty) {
    return KioskScanResult.fromActiveChild(
      activeChild: activeChild,
      childSessionToken: storedToken,
    );
  }

  final resumed = await kioskApi.resumeChildSession();
  await childSessionTokenStorage.writeToken(resumed.childSessionToken);
  return resumed;
}
