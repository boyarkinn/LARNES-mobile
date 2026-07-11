import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/letter_color/color_letter_canvas.dart';
import 'package:larnes_mobile/trainers/reading/letter_color/color_palette.dart';
import 'package:larnes_mobile/trainers/reading/letter_color/letter_color_model.dart';

void main() {
  group('ColorPalette', () {
    testWidgets('renders all draw colors', (tester) async {
      var selected = drawColors.first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ColorPalette(
              selectedColor: selected,
              onSelect: (color) => selected = color,
            ),
          ),
        ),
      );

      expect(find.byType(ColorPalette), findsOneWidget);
      expect(find.bySemanticsLabel('Выбрать цвет'), findsNWidgets(drawColors.length));
    });
  });

  group('ColorLetterCanvas', () {
    testWidgets('reports ink after stroke and clears via controller', (tester) async {
      final controller = ColorLetterCanvasController();
      var hasInk = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 280,
                height: 280,
                child: ColorLetterCanvas(
                  controller: controller,
                  displayLetter: 'А',
                  selectedColor: drawColors.first,
                  onInkChange: (value) => hasInk = value,
                  semanticsLabel: 'Разукрась букву А',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(hasInk, isFalse);
      expect(controller.hasInk, isFalse);

      final center = tester.getCenter(find.byType(ColorLetterCanvas));
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(40, 30));
      await gesture.moveBy(const Offset(20, 25));
      await gesture.up();
      await tester.pump();

      expect(hasInk, isTrue);
      expect(controller.hasInk, isTrue);

      controller.clear();
      await tester.pump();

      expect(hasInk, isFalse);
      expect(controller.hasInk, isFalse);
    });

    testWidgets('ignores drawing when disabled', (tester) async {
      var hasInk = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 280,
                height: 280,
                child: ColorLetterCanvas(
                  disabled: true,
                  displayLetter: 'О',
                  selectedColor: drawColors[2],
                  onInkChange: (value) => hasInk = value,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final center = tester.getCenter(find.byType(ColorLetterCanvas));
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(35, 20));
      await gesture.up();
      await tester.pump();

      expect(hasInk, isFalse);
    });

    testWidgets('uses semantics label without visible instruction text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 280,
                height: 280,
                child: ColorLetterCanvas(
                  displayLetter: 'М',
                  selectedColor: drawColors.first,
                  semanticsLabel: 'Разукрась букву М',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.bySemanticsLabel('Разукрась букву М'), findsOneWidget);
      expect(find.textContaining('Разукрась'), findsNothing);
    });
  });
}
