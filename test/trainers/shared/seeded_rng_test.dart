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
  });
}
