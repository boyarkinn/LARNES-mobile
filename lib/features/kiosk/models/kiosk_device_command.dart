enum KioskDeviceCommandKind {
  idle,
  openScan,
  resetChild,
}

KioskDeviceCommandKind kioskDeviceCommandKindFromString(String? value) {
  switch (value) {
    case 'open_scan':
      return KioskDeviceCommandKind.openScan;
    case 'reset_child':
      return KioskDeviceCommandKind.resetChild;
    case 'idle':
    default:
      return KioskDeviceCommandKind.idle;
  }
}

String kioskDeviceCommandKindToApiValue(KioskDeviceCommandKind kind) {
  switch (kind) {
    case KioskDeviceCommandKind.openScan:
      return 'open_scan';
    case KioskDeviceCommandKind.resetChild:
      return 'reset_child';
    case KioskDeviceCommandKind.idle:
      return 'idle';
  }
}

class KioskDeviceCommand {
  const KioskDeviceCommand({
    required this.command,
    required this.seq,
  });

  factory KioskDeviceCommand.fromJson(Map<String, dynamic> json) {
    return KioskDeviceCommand(
      command: kioskDeviceCommandKindFromString(json['command'] as String?),
      seq: json['seq'] as int,
    );
  }

  final KioskDeviceCommandKind command;
  final int seq;
}
