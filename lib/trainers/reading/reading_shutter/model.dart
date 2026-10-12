import 'package:larnes_mobile/trainers/reading/shared/passage.dart';

export 'package:larnes_mobile/trainers/reading/shared/passage.dart';

class ReadingShutterPlan {
  const ReadingShutterPlan({
    required this.cover,
    required this.edge,
    required this.letterPauseMs,
    required this.text,
    required this.units,
  });

  final String cover;
  final String edge;
  final int letterPauseMs;
  final String text;
  final List<VanishUnit> units;

  int get letterCount => vanishLetterCount(units);
}

/// Returns an error message, or null when [raw] is a valid shutter assignment.
String? validateReadingShutterRaw(Map<String, dynamic> raw) {
  final passageError = validatePassageAssignment(raw);
  if (passageError != null) return passageError;

  final edge = raw['edge']?.toString() ?? 'top';
  if (edge != 'top' && edge != 'bottom') return 'Выберите край шторки.';

  final cover = raw['cover']?.toString() ?? 'quarter';
  if (cover != 'quarter' && cover != 'half') return 'Выберите, сколько текста закрыто.';

  return null;
}

ReadingShutterPlan readingShutterPlanFromParams(Map<String, dynamic> raw) {
  final play = passagePlayFromParams(raw);
  final edge = raw['edge'] == 'bottom' ? 'bottom' : 'top';
  final cover = raw['cover'] == 'half' ? 'half' : 'quarter';

  return ReadingShutterPlan(
    cover: cover,
    edge: edge,
    letterPauseMs: play.letterPauseMs,
    text: play.text,
    units: play.units,
  );
}

ReadingShutterPlan? readingShutterPlanFromSnapshot(Map<String, dynamic>? payload) {
  final play = passagePlayFromSnapshot(payload);
  if (play == null || payload == null) return null;
  final edge = payload['edge']?.toString();
  final cover = payload['cover']?.toString();
  if (edge != 'top' && edge != 'bottom') return null;
  if (cover != 'quarter' && cover != 'half') return null;

  return ReadingShutterPlan(
    cover: cover!,
    edge: edge!,
    letterPauseMs: play.letterPauseMs,
    text: play.text,
    units: play.units,
  );
}
