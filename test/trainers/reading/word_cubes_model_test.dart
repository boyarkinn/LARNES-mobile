import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/word_cubes/model.dart';
import 'package:larnes_mobile/trainers/reading/word_cubes/definition.dart';
import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';

void main() {
  test('seed 42 matches the frozen Web vector', () {
    final rounds = buildCubeRounds('all', TrainerSnapshotRandom(42).nextDouble);
    expect(rounds.map((round) => round.cubes.map((cube) => cube.cube.faces[cube.initialFace]).toList()).toList(), [['РЮ', 'СУ'], ['Э', 'ЛЫ', 'А']]);
  });
  test('the approved examples keep warehouse boundaries and every initial cube is wrong', () {
    for (var seed = 0; seed < 100; seed++) {
      final rounds = buildCubeRounds('all', TrainerSnapshotRandom(seed).nextDouble);
      expect(rounds.map((round) => round.word.word), ['РИС', 'АЛОЭ']);
      for (final round in rounds) {
        expect(round.word.parts.map((part) => part.target).join(), round.word.word);
        expect(round.word.word.length, lessThanOrEqualTo(4));
        final faces = round.cubes.map((cube) => cube.initialFace).toList();
        expect(isCubeRoundComplete(round, faces), isFalse);
        for (var i = 0; i < round.cubes.length; i++) {
          final item = round.cubes[i];
          expect(item.cube.faces[faces[i]], isNot(item.target));
          while (item.cube.faces[faces[i]] != item.target) { faces[i] = nextCubeFace(item.cube, faces[i]); }
          expect(isCubeRoundComplete(round, faces), i == round.cubes.length - 1);
        }
      }
    }
  });
  test('table, cycles and selection validators match the web', () {
    expect(warehouseCubes.length, 38);
    expect(warehouseCubes.firstWhere((cube) => cube.id == 'Р-soft').faces, ['РЬ', 'РЯ', 'РЁ', 'РЮ', 'РИ', 'РЕ']);
    final hard = warehouseCubes.firstWhere((cube) => cube.id == 'С-hard');
    expect(hard.faces[nextCubeFace(hard, hard.faces.indexOf('СЫ'))], 'СЭ');
    expect(hard.faces[nextCubeFace(hard, hard.faces.indexOf('СЭ'))], 'С');
    expect(validateWordCubesParams({}).params, {'wordSlug': 'all'});
    for (final slug in ['all', 'ris', 'aloe']) { expect(validateWordCubesParams({'wordSlug': slug}).ok, isTrue); }
    for (final slug in [null, 'арбуз', '', 1]) { expect(validateWordCubesParams({'wordSlug': slug}).ok, isFalse); }
  });
}
