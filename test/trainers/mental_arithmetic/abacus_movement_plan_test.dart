import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/abacus_gesture_view.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/abacus_movement_plan.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/abacus_playback_plan.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';

void main() {
  group('shared abacus movement plan: web parity', () {
    final cases = <(String, int, List<List<Object>>)>[
      (
        '+49 +22',
        2,
        [
          [
            0,
            49,
            [0, 1],
          ],
          [
            1,
            69,
            [0],
          ],
          [
            1,
            71,
            [0, 1],
          ],
        ],
      ),
      (
        '+10 -9',
        2,
        [
          [
            0,
            10,
            [0],
          ],
          [
            1,
            1,
            [0, 1],
          ],
        ],
      ),
      (
        '+4 +2',
        1,
        [
          [
            0,
            4,
            [0],
          ],
          [
            1,
            6,
            [0],
          ],
        ],
      ),
      (
        '+5 -2',
        1,
        [
          [
            0,
            5,
            [0],
          ],
          [
            1,
            3,
            [0],
          ],
        ],
      ),
      (
        '+9 +9',
        2,
        [
          [
            0,
            9,
            [1],
          ],
          [
            1,
            18,
            [0, 1],
          ],
        ],
      ),
      (
        '+20 +13 -7',
        2,
        [
          [
            0,
            20,
            [0],
          ],
          [
            1,
            33,
            [0, 1],
          ],
          [
            2,
            26,
            [0, 1],
          ],
        ],
      ),
      (
        '+34 -19',
        2,
        [
          [
            0,
            34,
            [0, 1],
          ],
          [
            1,
            24,
            [0],
          ],
          [
            1,
            15,
            [0, 1],
          ],
        ],
      ),
      (
        '+99 +1',
        3,
        [
          [
            0,
            99,
            [1, 2],
          ],
          [
            1,
            199,
            [0],
          ],
          [
            1,
            100,
            [1, 2],
          ],
        ],
      ),
      (
        '+109 +50',
        3,
        [
          [
            0,
            100,
            [0],
          ],
          [
            0,
            109,
            [2],
          ],
          [
            1,
            159,
            [1],
          ],
        ],
      ),
    ];

    for (final (example, rods, expected) in cases) {
      test('$example on $rods rods', () {
        final plan = planAbacusMovements(example, rods);
        final actual = [
          for (final gesture in plan.gestures)
            [gesture.actionIndex, gesture.value, gesture.rodIndices],
        ];
        expect(actual, expected);
        for (final gesture in plan.gestures) {
          expect(gesture.rods.length, rods);
          expect(abacusToNumber(gesture.rods), gesture.value);
        }
        final events = buildAbacusPlaybackPlan(plan);
        expect(
          events
              .where(
                (event) => event.type == AbacusPlaybackEventType.actionStart,
              )
              .length,
          plan.actions.length,
        );
        expect(events.last.value, plan.gestures.last.value);
      });
    }

    test('preserves bead states and movement colors for +49 +22', () {
      final plan = planAbacusMovements('+49 +22', 2);
      final first = abacusGestureView(plan, 2, 1);
      final middle = abacusGestureView(plan, 2, 2);
      final last = abacusGestureView(plan, 2, 3);
      expect(first.rods, [digitToBeads(4), digitToBeads(9)]);
      expect(middle.rods, [digitToBeads(6), digitToBeads(9)]);
      expect(last.rods, [digitToBeads(7), digitToBeads(1)]);
      expect(middle.highlights![0].isEmpty, isFalse);
      expect(middle.highlights![1].isEmpty, isTrue);
      expect(last.highlights!.every((rod) => !rod.isEmpty), isTrue);
      expect(last.isDone, isTrue);
    });

    test('rejects an invalid width, overflow and underflow', () {
      expect(() => planAbacusMovements('+1', 0), throwsArgumentError);
      expect(() => planAbacusMovements('+10', 1), throwsFormatException);
      expect(() => planAbacusMovements('+1 -2', 2), throwsFormatException);
    });
  });
}
