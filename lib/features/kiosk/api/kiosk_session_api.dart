import 'package:larnes_mobile/features/kiosk/models/kiosk_commands_response.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_scan_result.dart';

abstract class KioskSessionApi {
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
}
