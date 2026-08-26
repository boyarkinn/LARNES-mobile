import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/shared/first_words/catalog.dart';
import 'package:larnes_mobile/trainers/shared/first_words/resolve_first_word.dart';

void main() {
  group('first-words resolver', () {
    test('keeps word clips at 1×', () {
      expect(firstWordAudioPlaybackRate, 1);
    });

    test('resolves slug, letter list and unknown values', () {
      expect(normalizeFirstWordSlug(' 1_арка '), '1_арка');
      expect(normalizeFirstWordSlug('арка'), isNull);
      expect(normalizeFirstLetter(' д '), 'Д');
      expect(normalizeFirstLetter('ДН'), isNull);
      expect(hasFirstWord('1_арка'), isTrue);
      expect(hasFirstWord('stork'), isFalse);

      final word = getFirstWord('1_арка');
      expect(word, isNotNull);
      expect(word!.label, 'арка');
      expect(word.firstLetter, 'А');
      expect(word.folder, '1-А');

      final letterD = listFirstWordsByLetter('д');
      expect(letterD, isNotEmpty);
      expect(letterD.every((item) => item.firstLetter == 'Д'), isTrue);
      expect(listFirstWordsByLetter('Ъ'), isEmpty);
    });

    test('maps slug to copied image and audio assets', () {
      expect(getFirstWordRelativeStem('1_арка'), '1-А/1_арка');
      expect(
        getFirstWordImageAsset('1_арка'),
        'images/ru/first-words/1-А/1_арка.png',
      );
      expect(
        getFirstWordImageWidgetAsset('1_арка'),
        'assets/images/ru/first-words/1-А/1_арка.png',
      );
      expect(
        getFirstWordAudioAsset('1_арка'),
        'audio/ru/first-words/1-А/1_арка.mp3',
      );
      expect(getFirstWordImageAsset('missing'), isNull);
      expect(getFirstWordAudioAsset('missing'), isNull);
    });

    test('covers the copied bank: 256 words, paired png+mp3', () {
      expect(firstWords, hasLength(256));

      for (final word in firstWords) {
        final stem = '${word.folder}/${word.slug}';
        expect(
          File('assets/images/ru/first-words/$stem.png').existsSync(),
          isTrue,
          reason: 'missing image $stem.png',
        );
        expect(
          File('assets/audio/ru/first-words/$stem.mp3').existsSync(),
          isTrue,
          reason: 'missing audio $stem.mp3',
        );
      }
    });
  });
}
