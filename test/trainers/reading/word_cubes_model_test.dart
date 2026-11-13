import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/word_cubes/model.dart';
import 'package:larnes_mobile/trainers/reading/word_cubes/definition.dart';
import 'package:larnes_mobile/trainers/reading/shared/content_bank.dart';

const frozenCubePayload = {
  'rounds': [
    {
      'word': {
        'slug': 'new-word',
        'word': 'ЛУК',
        'parts': [
          {'cubeId': 'left', 'target': 'ЛУ'},
          {'cubeId': 'right', 'target': 'К'},
        ],
      },
      'cubes': [
        {
          'cube': {
            'id': 'left',
            'kind': 'voiced',
            'small': false,
            'faces': ['Л', 'ЛУ'],
          },
          'target': 'ЛУ',
          'initialFace': 0,
        },
        {
          'cube': {
            'id': 'right',
            'kind': 'unvoiced',
            'small': false,
            'faces': ['КА', 'К'],
          },
          'target': 'К',
          'initialFace': 0,
        },
      ],
    },
  ],
};
void main() {
  test(
    'frozen cubes contain every face and solve independently of current inventory',
    () {
      final round = cubeRoundsFromPayload(frozenCubePayload).single;
      expect(round.word.word, 'ЛУК');
      expect(isCubeRoundComplete(round, [0, 0]), isFalse);
      expect(isCubeRoundComplete(round, [1, 1]), isTrue);
      expect(nextCubeFace(round.cubes.first.cube, 1), 0);
      expect(cubeRoundsFromPayload({'seed': 42}), isEmpty);
    },
  );
  test('phonetic inventory remains, legacy word selection is rejected', () {
    expect(warehouseCubes, hasLength(38));
    expect(validateWordCubesParams({'wordSlug': 'ris'}).ok, isFalse);
    expect(
      validateWordCubesParams({
        'contentBank': {
          'libraryId': readingContentBankLibraryId,
          'materialIds': ['11111111-1111-4111-8111-111111111111'],
        },
      }).ok,
      isTrue,
    );
  });
}
