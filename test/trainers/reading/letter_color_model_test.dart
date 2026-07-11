import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/letter_color/color_pad_size.dart';
import 'package:larnes_mobile/trainers/reading/letter_color/letter_color_model.dart';

void main() {
  group('letter_color_model', () {
    test('drawColors matches web palette', () {
      expect(drawColors, [
        '#7c3aed',
        '#e11d48',
        '#2563eb',
        '#16a34a',
        '#ea580c',
        '#db2777',
      ]);
    });

    test('uses letter-color viewbox and typography constants', () {
      expect(colorViewboxSize, 100);
      expect(colorLetterFontSize, 72);
      expect(colorLetterCenterX, 50);
      expect(colorLetterCenterY, 56);
      expect(colorOutlineStrokeHex, '#94a3b8');
      expect(colorOutlineStrokeWidth, 1.4);
      expect(colorStrokeWidth, 8);
    });
  });

  group('colorPadSize', () {
    test('caps square pad by height and width fractions', () {
      expect(colorPadSize(800, 400), 340);
      expect(colorPadSize(400, 800), 288);
      expect(colorPadSizeFromSide(500), 360);
    });
  });
}
