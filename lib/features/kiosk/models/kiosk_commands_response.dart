import 'package:larnes_mobile/features/kiosk/models/kiosk_device_command.dart';

class KioskCommandsResponse {
  const KioskCommandsResponse({
    required this.since,
    required this.commandSeq,
    required this.commands,
  });

  factory KioskCommandsResponse.fromJson(Map<String, dynamic> json) {
    final rawCommands = json['commands'] as List<dynamic>? ?? const [];
    return KioskCommandsResponse(
      since: json['since'] as int? ?? 0,
      commandSeq: json['commandSeq'] as int? ?? 0,
      commands: rawCommands
          .map(
            (item) => KioskDeviceCommand.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
    );
  }

  final int since;
  final int commandSeq;
  final List<KioskDeviceCommand> commands;
}
