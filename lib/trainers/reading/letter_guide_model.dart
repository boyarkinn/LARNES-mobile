import 'package:larnes_mobile/trainers/reading/letter_model.dart';

const minCompletableSegments = 2;

const _letterGuideSegmentCounts = <String, int>{
  'А': 3,
  'Б': 3,
  'В': 3,
  'Г': 2,
  'Д': 2,
  'Е': 4,
  'Ж': 3,
  'З': 2,
  'И': 3,
  'Й': 1,
  'К': 3,
  'Л': 2,
  'М': 4,
  'Н': 3,
  'О': 1,
  'П': 3,
  'Р': 3,
  'С': 1,
  'Т': 2,
  'У': 2,
  'Ф': 2,
  'Х': 2,
  'Ц': 3,
  'Ч': 2,
  'Ш': 4,
  'Щ': 1,
  'Ъ': 3,
  'Ы': 3,
  'Ь': 2,
  'Э': 2,
  'Ю': 3,
  'Я': 3,
};

int getLetterGuideSegmentCount(String letter) {
  return _letterGuideSegmentCounts[normalizeTargetLetter(letter)] ?? 1;
}

bool isCompletableLetter(String letter) {
  return getLetterGuideSegmentCount(letter) >= minCompletableSegments;
}

bool isValidMissingSegment(String letter, Object missingSegment) {
  final count = getLetterGuideSegmentCount(letter);
  if (count < minCompletableSegments) {
    return false;
  }
  if (missingSegment == 'random') {
    return true;
  }
  final index = missingSegment is int ? missingSegment : int.tryParse('$missingSegment');
  return index != null && index >= 0 && index < count;
}

Object normalizeMissingSegmentParam(dynamic raw) {
  if (raw == 'random') {
    return 'random';
  }
  return int.tryParse('$raw') ?? 'random';
}
