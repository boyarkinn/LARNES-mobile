import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/math/digit_find_tap/digit_colors.dart';

void main() {
  group('getDigitDisplayColor', () {
    test('returns a distinct color for each digit 0-9', () {
      final colors = <Color>{
        for (var digit = 0; digit < 10; digit++) getDigitDisplayColor(digit),
      };

      expect(colors.length, 10);
      expect(getDigitDisplayColor(2), digitDisplayColors[2]);
    });

    test('clamps out-of-range values', () {
      expect(getDigitDisplayColor(12), digitDisplayColors[9]);
      expect(getDigitDisplayColor(-1), digitDisplayColors[0]);
    });
  });
}
