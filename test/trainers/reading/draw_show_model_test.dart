import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/letter_draw_show/draw_show_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_draw_show/draw_show_sizes.dart';

void main() {
  group('isSupportedDrawShowLetter', () {
    test('supports full alphabet including Ё, Ъ, Ь', () {
      expect(isSupportedDrawShowLetter('И'), isTrue);
      expect(isSupportedDrawShowLetter('Ё'), isTrue);
      expect(isSupportedDrawShowLetter('Ъ'), isTrue);
      expect(isSupportedDrawShowLetter('Ь'), isTrue);
      expect(isSupportedDrawShowLetter('Q'), isFalse);
    });
  });

  group('getStrokeColor', () {
    test('cycles zaitsev stroke colors', () {
      expect(getStrokeColor(0), '#e11d48');
      expect(getStrokeColor(1), '#2563eb');
      expect(getStrokeColor(2), '#059669');
      expect(getStrokeColor(3), '#e11d48');
    });
  });

  group('normalizeDrawShowRounds', () {
    test('clamps rounds', () {
      expect(normalizeDrawShowRounds(0), 1);
      expect(normalizeDrawShowRounds(3), 3);
      expect(normalizeDrawShowRounds(9), 5);
    });
  });

  group('estimateDrawingDurationMs', () {
    test('estimates duration for И with multiple rounds', () {
      final oneRound = estimateDrawingDurationMs('И', 1);
      final threeRounds = estimateDrawingDurationMs('И', 3);

      expect(oneRound, greaterThan(0));
      expect(threeRounds, greaterThan(oneRound));
    });

    test('returns zero for unsupported letter', () {
      expect(estimateDrawingDurationMs('Q', 1), 0);
    });
  });

  group('draw show sizing', () {
    test('caps letter box with 96vw width', () {
      expect(drawShowBoxSize(800, 400), 384);
    });

    test('caps letter box with 72svh height', () {
      expect(drawShowBoxSize(400, 800), 288);
    });

    test('uses finish delay from settle pulse and complete parts', () {
      expect(drawFinishDelayMs, drawSettlePulseMs + drawShowCompleteDelayMs);
    });
  });
}
