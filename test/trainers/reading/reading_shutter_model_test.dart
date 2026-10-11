import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/reading_shutter/model.dart';

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
      'cover': 'half',
      'edge': 'bottom',
      'letterPauseMs': 240,
      'passageId': 'short-ball',
      'source': 'bank',
    });

    expect(plan.text, contains('Маша'));
    expect(plan.cover, 'half');
    expect(plan.edge, 'bottom');
    expect(plan.letterCount, greaterThan(0));
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

  test('empty custom text is rejected', () {
    expect(
      validateReadingShutterRaw({'customText': '   ', 'source': 'custom'}),
      'Впишите текст.',
    );
  });
}
