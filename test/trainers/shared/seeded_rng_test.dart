import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';

void main() {
  group('createSeededRng', () {
    test('same seed yields same sequence', () {
      final first = createSeededRng(42);
      final second = createSeededRng(42);

      expect(
        List.generate(8, (_) => first()),
        equals(List.generate(8, (_) => second())),
      );
    });

    test('matches web createSeededRng(42) sequence', () {
      final rng = createSeededRng(42);
      expect(
        List.generate(8, (_) => rng()),
        [
          0.2523451747838408,
          0.08812504541128874,
          0.5772811982315034,
          0.22255426598712802,
          0.37566019711084664,
          0.02566390484571457,
          0.4472812858875841,
          0.1184600037522614,
        ],
      );
    });

    test('different seeds yield different values', () {
      final a = createSeededRng(1);
      final b = createSeededRng(2);

      expect(a(), isNot(equals(b())));
    });
  });

  group('hashParamsSeed', () {
    test('is deterministic for the same parts', () {
      expect(
        hashParamsSeed([2, 3, 8]),
        equals(hashParamsSeed([2, 3, 8])),
      );
    });

    test('differs when parts change', () {
      expect(
        hashParamsSeed(['watermelon', 4, 2]),
        isNot(equals(hashParamsSeed(['apple', 4, 2]))),
      );
    });

    test('matches web letter-find-tap / digit-find-tap vectors', () {
      expect(hashParamsSeed([2, 3, 8]), 837436190);
      expect(hashParamsSeed(['watermelon', 4, 2]), 3644572753);
    });
  });

  group('createLayoutSalt', () {
    test('returns uint32 values', () {
      for (var index = 0; index < 20; index++) {
        final salt = createLayoutSalt();
        expect(salt, greaterThanOrEqualTo(0));
        expect(salt, lessThanOrEqualTo(0xFFFFFFFF));
      }
    });
  });
}
