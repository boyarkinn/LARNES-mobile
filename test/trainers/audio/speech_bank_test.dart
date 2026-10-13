import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/audio/speech_bank.dart';
import 'package:larnes_mobile/trainers/shared/first_words/resolve_first_word.dart';
import 'package:larnes_mobile/trainers/shared/letters_syllables/resolve_letter_syllable_audio.dart';

void main() {
  tearDown(() => setSpeechAudioFiles(const {}));

  test('a letter sound stays a phoneme and замок files stay apart', () {
    expect(letterSyllableAudioKey('м'), 'phoneme:ru:М');
    expect(letterSyllableAudioKey('ё'), 'phoneme:ru:Ё');
    expect(letterSyllableAudioKey('ба'), 'syllable:ru:БА');
    expect(letterSyllableAudioKey('ь'), isNull);
    expect(isSpeechBankAudioKey('letter-name:ru:М'), isFalse);
    expect(wordAudioKey('21_замок1'), 'word:ru:21_замок1');
    expect(wordAudioKey('21_замок2'), isNot(wordAudioKey('21_замок1')));
    expect(getFirstWordImageAsset('21_замок1'), contains('21_замок1.png'));
    expect(getLetterSyllableAudioAsset('м'), contains('24-М/24-М.mp3'));
  });

  test('a published file replaces the old asset and a missing download does not', () {
    setSpeechAudioFiles(
      {'phoneme:ru:М': const SpeechAudioFile(path: r'C:\cache\em.mp3')},
      catalogKeys: {'phoneme:ru:М', 'word:ru:1_арка'},
    );

    expect(getLetterSyllableAudioAsset('м'), r'C:\cache\em.mp3');
    expect(getFirstWordAudioAsset('1_арка'), isNull);
    expect(getLetterSyllableAudioAsset('а'), contains('1-А.mp3'));
  });
}
