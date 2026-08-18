import 'package:larnes_mobile/features/kiosk/models/kiosk_scan_result.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_active_child.dart';
import 'package:larnes_mobile/features/parent/theme/child_card_colors.dart';

enum KioskScanOutcome {
  play,
  noProgram,
}

KioskScanOutcome kioskScanOutcomeFromString(String? value) {
  switch (value) {
    case 'no_program':
      return KioskScanOutcome.noProgram;
    case 'play':
    default:
      return KioskScanOutcome.play;
  }
}

class KioskScanResult {
  const KioskScanResult({
    required this.outcome,
    required this.childId,
    required this.childDisplayName,
    required this.childSessionToken,
    this.childCardColor = defaultChildCardColor,
    this.childGender,
    this.childGivenName,
    this.childLastName,
    this.programId,
  });

  factory KioskScanResult.fromJson(Map<String, dynamic> json) {
    return KioskScanResult(
      outcome: kioskScanOutcomeFromString(json['outcome'] as String?),
      childId: json['childId'] as String,
      childDisplayName: json['childDisplayName'] as String,
      childSessionToken: json['childSessionToken'] as String,
      childCardColor: childCardColorFromString(json['childCardColor'] as String?),
      childGender: json['childGender'] as String?,
      childGivenName: json['childGivenName'] as String?,
      childLastName: json['childLastName'] as String?,
      programId: json['programId'] as String?,
    );
  }

  factory KioskScanResult.fromActiveChild({
    required KioskActiveChild activeChild,
    required String childSessionToken,
    KioskScanOutcome outcome = KioskScanOutcome.noProgram,
    String? programId,
  }) {
    return KioskScanResult(
      outcome: outcome,
      childId: activeChild.childId,
      childDisplayName: activeChild.childDisplayName,
      childSessionToken: childSessionToken,
      childCardColor: activeChild.childCardColor,
      childGender: activeChild.childGender,
      childGivenName: activeChild.childGivenName,
      childLastName: activeChild.childLastName,
      programId: programId,
    );
  }

  final KioskScanOutcome outcome;
  final String childId;
  final String childDisplayName;
  final String childSessionToken;
  final ChildCardColor childCardColor;
  final String? childGender;
  final String? childGivenName;
  final String? childLastName;
  final String? programId;
}
