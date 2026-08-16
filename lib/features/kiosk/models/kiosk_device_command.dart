enum KioskDeviceCommandKind {
  idle,
  openScan,
  resetChild,
  playTrainer,
}

KioskDeviceCommandKind kioskDeviceCommandKindFromString(String? value) {
  switch (value) {
    case 'open_scan':
      return KioskDeviceCommandKind.openScan;
    case 'reset_child':
      return KioskDeviceCommandKind.resetChild;
    case 'play_trainer':
      return KioskDeviceCommandKind.playTrainer;
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
    case KioskDeviceCommandKind.playTrainer:
      return 'play_trainer';
    case KioskDeviceCommandKind.idle:
      return 'idle';
  }
}

bool kioskDeviceCommandClearsChildSession(KioskDeviceCommandKind kind) {
  switch (kind) {
    case KioskDeviceCommandKind.openScan:
    case KioskDeviceCommandKind.resetChild:
    case KioskDeviceCommandKind.idle:
      return true;
    case KioskDeviceCommandKind.playTrainer:
      return false;
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
