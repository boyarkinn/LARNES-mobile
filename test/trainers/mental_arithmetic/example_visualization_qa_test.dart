import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/abacus_movement_plan.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/abacus_playback_plan.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/example_parser.dart';
import 'package:larnes_mobile/trainers/runtime/validate_params.dart';

class _RegressionCase {
  const _RegressionCase({
    required this.example,
    required this.stepPauseSec,
    required this.totalRods,
    required this.values,
  });

  final String example;
  final double stepPauseSec;
  final int totalRods;
  final List<int> values;
}

const _regressionCases = [
  _RegressionCase(
    example: '+2 -1',
    stepPauseSec: 2,
    totalRods: 1,
    values: [0, 2, 1],
  ),
  _RegressionCase(
    example: '+9 -1',
    stepPauseSec: 1.5,
    totalRods: 1,
    values: [0, 9, 8],
  ),
  _RegressionCase(
    example: '+1 +9',
    stepPauseSec: 2,
    totalRods: 2,
    values: [0, 1, 10],
  ),
  _RegressionCase(
    example: '+10 -1',
    stepPauseSec: 2,
    totalRods: 2,
    values: [0, 10, 9],
  ),
];

void main() {
  group('example-visualization QA regression', () {
    for (final params in _regressionCases) {
      test(
        'shared plan values for ${params.example} (${params.totalRods} rods)',
        () {
          final plan = planAbacusMovements(params.example, params.totalRods);
          final events = buildAbacusPlaybackPlan(plan);
          final actions = parseExampleActions(params.example);

          expect([
            0,
            ...events
                .where(
                  (event) =>
                      event.type == AbacusPlaybackEventType.actionComplete,
                )
                .map((event) => event.value),
          ], params.values);
          expect(plan.actions.length, actions.length);
          expect(plan.gestures.last.value, params.values.last);
        },
      );

      test('shared gesture events for ${params.example}', () {
        final events = buildAbacusPlaybackPlan(
          planAbacusMovements(params.example, params.totalRods),
        );
        expect(
          events
              .where(
                (event) => event.type == AbacusPlaybackEventType.actionStart,
              )
              .length,
          2,
        );
        expect(
          events
              .where((event) => event.type == AbacusPlaybackEventType.gesture)
              .length,
          greaterThanOrEqualTo(2),
        );
        expect(events.last.type, AbacusPlaybackEventType.complete);
      });

      test('validates params for ${params.example}', () {
        final result = validateTrainerParams('example-visualization', {
          'example': params.example,
          'stepPauseSec': params.stepPauseSec,
          'totalRods': params.totalRods,
        });

        expect(result.ok, isTrue);
        expect(result.params, {
          'example': params.example,
          'stepPauseSec': params.stepPauseSec,
          'totalRods': params.totalRods,
        });
      });
    }
  });

  group('example-visualization homework smoke', () {
    test('accepts coerced homework params', () {
      final result = validateTrainerParams('example-visualization', {
        'example': '+9 -1',
        'stepPauseSec': '1.5',
        'totalRods': '1',
      });

      expect(result.ok, isTrue);
      expect(result.params, {
        'example': '+9 -1',
        'stepPauseSec': 1.5,
        'totalRods': 1,
      });
    });

    test('rejects overflow homework item', () {
      final result = validateTrainerParams('example-visualization', {
        'example': '+10 -1',
        'stepPauseSec': 2,
        'totalRods': 1,
      });

      expect(result.ok, isFalse);
    });

    test('normalizes spaced example from homework input', () {
      final result = validateTrainerParams('example-visualization', {
        'example': '+2 - 1',
        'stepPauseSec': '2',
        'totalRods': '2',
      });

      expect(result.ok, isTrue);
      expect(result.params?['example'], '+2 -1');
    });
  });
}
