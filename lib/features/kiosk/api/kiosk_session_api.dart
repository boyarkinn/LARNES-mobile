import 'package:larnes_mobile/features/kiosk/models/kiosk_commands_response.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_device_context.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_scan_result.dart';

abstract class KioskSessionApi {
  Future<KioskDeviceContext> getDeviceMe({String locale = 'ru'});

  Future<KioskCommandsResponse> pollCommands({
    required int since,
    String locale = 'ru',
  });

  Future<void> heartbeat({
    int? ackSeq,
    String locale = 'ru',
  });

  Future<void> childLogout({String locale = 'ru'});

  Future<KioskScanResult> scan({
    required String token,
    String locale = 'ru',
  });

  Future<KioskScanResult> resumeChildSession({String locale = 'ru'});
}
