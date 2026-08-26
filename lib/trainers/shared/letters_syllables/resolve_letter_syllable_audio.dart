/// Web: `platform/src/trainers/shared/letters-syllables/resolve-letter-syllable-audio.ts`

const kLettersSyllablesAudioAssetBase = 'audio/ru/letters-syllables';
const kLettersSyllablesPlaybackRate = 1.0;
final _cyrillicToken = RegExp(r'^[\u0400-\u04FF]{1,2}$');

const _vowelRelativePaths = <String, String>{
  'А': '1-10-А-Е/1-А.mp3',
  'О': '1-10-А-Е/2-О.mp3',
  'У': '1-10-А-Е/3-У.mp3',
  'Ы': '1-10-А-Е/4-Ы.mp3',
  'Э': '1-10-А-Е/5-Э.mp3',
  'Я': '1-10-А-Е/6-Я.mp3',
  'Ё': '1-10-А-Е/7-Ё.mp3',
  'Ю': '1-10-А-Е/8-Ю.mp3',
  'И': '1-10-А-Е/9-И.mp3',
  'Е': '1-10-А-Е/10-Е.mp3',
};

const _consonantLessons = <String, int>{
  'Б': 11,
  'П': 12,
  'В': 13,
  'Ф': 14,
  'Г': 15,
  'К': 16,
  'Д': 17,
  'Т': 18,
  'Ж': 19,
  'Ш': 20,
  'З': 21,
  'С': 22,
  'Л': 23,
  'М': 24,
  'Н': 25,
  'Р': 26,
  'Й': 27,
  'Х': 28,
  'Ц': 29,
  'Ч': 30,
  'Щ': 31,
};

String? normalizeLetterSyllableToken(String value) {
  final normalized = value.trim().toUpperCase();
  if (!_cyrillicToken.hasMatch(normalized)) {
    return null;
  }
  return normalized;
}

String? getLetterSyllableRelativePath(String token) {
  final normalized = normalizeLetterSyllableToken(token);
  if (normalized == null) {
    return null;
  }

  if (normalized.length == 1) {
    final vowelPath = _vowelRelativePaths[normalized];
    if (vowelPath != null) {
      return vowelPath;
    }

    final lesson = _consonantLessons[normalized];
    if (lesson == null) {
      return null;
    }

    return '$lesson-$normalized/$lesson-$normalized.mp3';
  }

  String? consonant;
  for (final rune in normalized.runes) {
    final letter = String.fromCharCode(rune);
    if (_consonantLessons.containsKey(letter)) {
      consonant = letter;
      break;
    }
  }
  if (consonant == null) {
    return null;
  }

  final lesson = _consonantLessons[consonant]!;
  return '$lesson-$consonant/$lesson-$normalized.mp3';
}

String? getLetterSyllableAudioAsset(String token) {
  final relativePath = getLetterSyllableRelativePath(token);
  if (relativePath == null) {
    return null;
  }
  return '$kLettersSyllablesAudioAssetBase/$relativePath';
}

bool hasLetterSyllableAudio(String token) {
  return getLetterSyllableRelativePath(token) != null;
}

double get lettersSyllablesPlaybackRate => kLettersSyllablesPlaybackRate;
