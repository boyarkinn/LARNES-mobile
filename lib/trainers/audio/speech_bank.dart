// Смысловые ключи букв, слогов, слов и фруктов. Совпадают с web `speech-bank.ts`.

import 'package:larnes_mobile/trainers/shared/first_words/catalog.dart';

const speechFruitSlugs = [
  'apple',
  'banana',
  'cherry',
  'grape',
  'orange',
  'peach',
  'pear',
  'plum',
  'strawberry',
  'watermelon',
];

final _wordSlugs = {for (final word in firstWords) word.slug};
final _fruitSlugs = speechFruitSlugs.toSet();
final _cyrillicLetter = RegExp(r'^[\u0400-\u04FF]$');
final _cyrillicSyllable = RegExp(r'^[\u0400-\u04FF]{2}$');

String? wordAudioKey(String slug) => _wordSlugs.contains(slug) ? 'word:ru:$slug' : null;

String? fruitAudioKey(String slug) => _fruitSlugs.contains(slug) ? 'stimulus:fruit:$slug' : null;

bool isSpeechBankAudioKey(String semanticKey) {
  if (semanticKey.startsWith('phoneme:ru:')) {
    final letter = semanticKey.substring('phoneme:ru:'.length);
    return letter != 'Ь' && letter != 'Ъ' && _cyrillicLetter.hasMatch(letter);
  }

  if (semanticKey.startsWith('syllable:ru:')) {
    return _cyrillicSyllable.hasMatch(semanticKey.substring('syllable:ru:'.length));
  }

  if (semanticKey.startsWith('word:ru:')) {
    return wordAudioKey(semanticKey.substring('word:ru:'.length)) == semanticKey;
  }

  if (semanticKey.startsWith('stimulus:fruit:')) {
    return fruitAudioKey(semanticKey.substring('stimulus:fruit:'.length)) == semanticKey;
  }

  return false;
}

class SpeechAudioFile {
  const SpeechAudioFile({required this.path, this.durationMs = 0, this.locale = '', this.text = ''});

  final int durationMs;
  final String locale;
  final String path;
  final String text;
}

/// Текст опубликованной версии. Пустая запись оставляет фразу экрана.
String publishedSpeechText(String? semanticKey, String fallback) {
  if (semanticKey == null) {
    return fallback;
  }

  final text = speechAudioFile(semanticKey)?.text.trim() ?? '';
  return text.isEmpty ? fallback : text;
}

final Map<String, SpeechAudioFile> _speechAudioFiles = {};
final Set<String> _speechCatalogKeys = {};

void setSpeechAudioFiles(Map<String, SpeechAudioFile> files, {Set<String> catalogKeys = const {}}) {
  _speechAudioFiles
    ..clear()
    ..addAll(files);
  _speechCatalogKeys
    ..clear()
    ..addAll(catalogKeys);
}

/// Готовый файл каталога заменяет старый. Опубликованный, но ещё не скачанный — null.
SpeechAudioFile? speechAudioFile(String semanticKey) => _speechAudioFiles[semanticKey];

bool speechCatalogHas(String semanticKey) => _speechCatalogKeys.contains(semanticKey);

String? speechPlaybackPath(String? semanticKey, String legacyPath) {
  if (semanticKey == null) {
    return legacyPath;
  }

  final file = _speechAudioFiles[semanticKey];

  if (file != null) {
    return file.path;
  }

  if (_speechCatalogKeys.contains(semanticKey)) {
    return null;
  }

  return legacyPath;
}
