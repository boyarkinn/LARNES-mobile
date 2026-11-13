import 'passage.dart';
import 'content_bank.dart';
import 'package:larnes_mobile/trainers/audio/speech_alignment.dart';

bool isTextPassageTrainerKey(String key) =>
    key == 'reading-shutter' ||
    key == 'reading-upside-down' ||
    key == 'reading-tug';

class NarratedPassage {
  const NarratedPassage({
    required this.semanticKey,
    required this.audioVersionId,
    required this.durationMs,
    required this.rate,
    this.alignment,
  });
  final String semanticKey, audioVersionId;
  final int durationMs;
  final double rate;
  final SpeechAlignment? alignment;
}

String? validateTextPassageParams(Map<String, dynamic> raw) {
  final pause = int.tryParse('${raw['letterPauseMs'] ?? 180}');
  if (pause == null || pause < 80 || pause > 800)
    return 'Укажите паузу исчезновения от 80 до 800 мс.';
  if (raw['disappearance'] != null &&
      !['on', 'off'].contains(raw['disappearance']))
    return 'Выберите режим исчезновения.';
  return validateReadingContentSelection(raw, singleText: true);
}

Map<String, dynamic> textPassageParams(Map<String, dynamic> raw) => {
  'source': 'bank',
  'contentBank': raw['contentBank'],
  'disappearance': raw['disappearance'] == 'on' ? 'on' : 'off',
  'letterPauseMs': int.tryParse('${raw['letterPauseMs'] ?? 180}') ?? 180,
};

class TextPassagePlan {
  const TextPassagePlan({
    required this.text,
    required this.letterPauseMs,
    required this.disappearance,
    this.visibleHalf,
  });
  final String text;
  final int letterPauseMs;
  final bool disappearance;
  final String? visibleHalf;
  List<VanishUnit> get units => buildVanishUnits(text.replaceAll('\r\n', '\n'));
  int get letterCount => vanishLetterCount(units);
}
