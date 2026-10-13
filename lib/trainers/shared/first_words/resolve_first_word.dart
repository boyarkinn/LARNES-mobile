/// Web: `platform/src/trainers/shared/first-words/resolve-first-word.ts`
///
/// Картинки остаются в assets/images. Слово звучит только из каталога.

import 'package:larnes_mobile/trainers/audio/speech_bank.dart';
import 'package:larnes_mobile/trainers/shared/first_words/catalog.dart';

const kFirstWordsImageAssetBase = 'images/ru/first-words';
const kFirstWordAudioPlaybackRate = 1.0;

final _cyrillicLetter = RegExp(r'^[\u0400-\u04FF]$');
final _wordsBySlug = {for (final word in firstWords) word.slug: word};

String? normalizeFirstWordSlug(String value) {
  final slug = value.trim();
  return _wordsBySlug.containsKey(slug) ? slug : null;
}

String? normalizeFirstLetter(String value) {
  final letter = value.trim().toUpperCase();
  return _cyrillicLetter.hasMatch(letter) ? letter : null;
}

FirstWord? getFirstWord(String slug) {
  final normalized = normalizeFirstWordSlug(slug);
  if (normalized == null) {
    return null;
  }
  return _wordsBySlug[normalized];
}

List<FirstWord> listFirstWordsByLetter(String letter) {
  final normalized = normalizeFirstLetter(letter);
  if (normalized == null) {
    return const [];
  }
  return firstWords.where((word) => word.firstLetter == normalized).toList();
}

String? getFirstWordRelativeStem(String slug) {
  final word = getFirstWord(slug);
  if (word == null) {
    return null;
  }
  return '${word.folder}/${word.slug}';
}

String? getFirstWordImageAsset(String slug) {
  final stem = getFirstWordRelativeStem(slug);
  if (stem == null) {
    return null;
  }
  return '$kFirstWordsImageAssetBase/$stem.png';
}

/// Путь для `Image.asset`. Clip-player сам добавляет `assets/`, виджет — нет.
String? getFirstWordImageWidgetAsset(String slug) {
  final path = getFirstWordImageAsset(slug);
  if (path == null) {
    return null;
  }
  return 'assets/$path';
}

String? getFirstWordAudioAsset(String slug) {
  final stem = getFirstWordRelativeStem(slug);
  final semanticKey = wordAudioKey(slug);
  if (stem == null || semanticKey == null) {
    return null;
  }

  return speechPlaybackPath(semanticKey);
}

bool hasFirstWord(String slug) {
  return getFirstWord(slug) != null;
}

double get firstWordAudioPlaybackRate => kFirstWordAudioPlaybackRate;
