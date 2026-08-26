import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/shared/letters_syllables/resolve_letter_syllable_audio.dart';

void main() {
  group('letter-syllable resolver', () {
    test('maps vowels, consonants and syllables', () {
      expect(lettersSyllablesPlaybackRate, 1);
      expect(normalizeLetterSyllableToken(' а '), 'А');
      expect(normalizeLetterSyllableToken('ба'), 'БА');
      expect(getLetterSyllableRelativePath('а'), '1-10-А-Е/1-А.mp3');
      expect(getLetterSyllableRelativePath('б'), '11-Б/11-Б.mp3');
      expect(getLetterSyllableRelativePath('ба'), '11-Б/11-БА.mp3');
      expect(getLetterSyllableRelativePath('ма'), '24-М/24-МА.mp3');
      expect(getLetterSyllableRelativePath('ъ'), isNull);
      expect(hasLetterSyllableAudio('М'), isTrue);
      expect(hasLetterSyllableAudio('Ъ'), isFalse);
      expect(
        getLetterSyllableAudioAsset('ба'),
        'audio/ru/letters-syllables/11-Б/11-БА.mp3',
      );
    });

    test('points at copied bank files', () {
      expect(File('assets/audio/ru/letters-syllables/1-10-А-Е/1-А.mp3').existsSync(), isTrue);
      expect(File('assets/audio/ru/letters-syllables/11-Б/11-БА.mp3').existsSync(), isTrue);
      expect(
        File('assets/audio/ru/reading/letter-find-by-sound/instruction.mp3').existsSync(),
        isTrue,
      );
    });
  });
}
