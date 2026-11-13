import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/audio/speech_alignment.dart';
import 'package:larnes_mobile/trainers/reading/reading_tug/reading_tug_trainer.dart';
import 'package:larnes_mobile/trainers/reading/shared/content_bank.dart';

void main() {
  test(
    'media timestamps control the source cursor and survive a pause unchanged',
    () {
      final alignment = SpeechAlignment.fromJson(
        {
          'version': 1,
          'words': [
            {'startOffset': 0, 'endOffset': 4, 'startMs': 0, 'endMs': 500},
            {'startOffset': 5, 'endOffset': 9, 'startMs': 600, 'endMs': 1000},
          ],
        },
        'Мама мыла.',
        1100,
      )!;
      expect(alignment.endOffsetAt(499), 0);
      expect(alignment.endOffsetAt(500), 4);
      expect(alignment.endOffsetAt(500), 4);
      expect(alignment.endOffsetAt(1000), 9);
      expect(
        SpeechAlignment.fromJson(
          {
            'version': 1,
            'words': [
              {'startOffset': 0, 'endOffset': 40, 'startMs': 0, 'endMs': 500},
            ],
          },
          'Мама мыла.',
          1100,
        ),
        isNull,
      );
    },
  );
  test('tug requires a specific text and preserves narrator settings', () {
    final result = validateReadingTugParams({
      'narratorRate': '1.5',
      'disappearance': 'on',
      'contentBank': {
        'libraryId': readingContentBankLibraryId,
        'categoryId': '11111111-1111-4111-8111-111111111111',
        'materialIds': ['22222222-2222-4222-8222-222222222222'],
      },
    });
    expect(result.ok, isTrue);
    expect(result.params?['narratorRate'], 1.5);
    expect(result.params?['disappearance'], 'on');
    expect(
      validateReadingTugParams({
        'contentBank': {
          'libraryId': readingContentBankLibraryId,
          'categoryId': '11111111-1111-4111-8111-111111111111',
          'materialIds': <String>[],
        },
      }).ok,
      isFalse,
    );
    expect(validateReadingTugParams({'narratorRate': '4'}).ok, isFalse);
  });
}
