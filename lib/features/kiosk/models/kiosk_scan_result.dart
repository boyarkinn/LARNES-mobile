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
    this.programId,
  });

  factory KioskScanResult.fromJson(Map<String, dynamic> json) {
    return KioskScanResult(
      outcome: kioskScanOutcomeFromString(json['outcome'] as String?),
      childId: json['childId'] as String,
      childDisplayName: json['childDisplayName'] as String,
      childSessionToken: json['childSessionToken'] as String,
      programId: json['programId'] as String?,
    );
  }

  final KioskScanOutcome outcome;
  final String childId;
  final String childDisplayName;
  final String childSessionToken;
  final String? programId;
}
