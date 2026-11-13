import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/reading_shutter/model.dart';
import 'package:larnes_mobile/trainers/reading/shared/passage.dart';

void main() {
  test('spaces vanish with the previous letter', () {
    final units = buildVanishUnits('А б');
    expect(units.map((unit) => '${unit.grapheme}:${unit.order}').toList(), [
      'А:1',
      ' :1',
      'б:2',
    ]);
  });

  test('bank text and shutter are frozen from params', () {
    final plan = readingShutterPlanFromParams({
      'disappearance': 'on',
      'edge': 'bottom',
      'letterPauseMs': 240,
      'passageId': 'short-ball',
      'source': 'bank',
    });

    expect(plan.text, isEmpty);
    expect(plan.disappearance, isTrue);
    expect(plan.visibleHalf, 'top');
    expect(plan.letterCount, 0);
  });

  test('snapshot text wins over the bank id', () {
    final plan = readingShutterPlanFromSnapshot({
      'cover': 'quarter',
      'edge': 'top',
      'letterPauseMs': 180,
      'text': 'Кот спит.',
    });

    expect(plan?.text, 'Кот спит.');
    expect(plan?.letterPauseMs, 180);
  });

  test('empty frozen text is rejected', () {
    expect(readingShutterPlanFromSnapshot({'text': ''}), isNull);
  });
}
