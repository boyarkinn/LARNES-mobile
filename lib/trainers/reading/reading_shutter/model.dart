import 'package:larnes_mobile/trainers/reading/shared/text_passage_model.dart';
import 'package:larnes_mobile/trainers/reading/shared/passage.dart';

typedef ReadingShutterPlan = TextPassagePlan;
String? validateReadingShutterRaw(Map<String, dynamic> raw) {
  final pause = int.tryParse('${raw['letterPauseMs'] ?? 180}');
  if (pause == null || pause < 80 || pause > 800)
    return 'Укажите паузу исчезновения от 80 до 800 мс.';
  if (raw['edge'] != null && !['top', 'bottom'].contains(raw['edge']))
    return 'Выберите видимую половину строки.';
  if (raw['disappearance'] != null &&
      !['on', 'off'].contains(raw['disappearance']))
    return 'Выберите режим исчезновения.';
  return null;
}

ReadingShutterPlan readingShutterPlanFromParams(Map<String, dynamic> raw) =>
    TextPassagePlan(
      text: resolvePassageText(raw),
      letterPauseMs: int.tryParse('${raw['letterPauseMs'] ?? 180}') ?? 180,
      disappearance: raw['disappearance'] == 'on',
      visibleHalf: raw['edge'] == 'top' ? 'bottom' : 'top',
    );
ReadingShutterPlan? readingShutterPlanFromSnapshot(Map<String, dynamic>? raw) {
  if (raw == null ||
      raw['text'] is! String ||
      (raw['text'] as String).trim().isEmpty)
    return null;
  return TextPassagePlan(
    text: raw['text'] as String,
    letterPauseMs: (int.tryParse('${raw['letterPauseMs'] ?? 180}') ?? 180)
        .clamp(80, 800),
    disappearance:
        raw['disappearance'] == 'on' ||
        (raw['disappearance'] == null && raw['cover'] != null),
    visibleHalf:
        raw['visibleHalf']?.toString() ??
        (raw['edge'] == 'top' ? 'bottom' : 'top'),
  );
}
