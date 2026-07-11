import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/flashcard_digit_match/match_hit_test.dart';

void main() {
  group('isPointInsideBoardRect', () {
    testWidgets('accepts points inside the target with padding', (tester) async {
      final boardKey = GlobalKey();
      final targetKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              key: boardKey,
              width: 800,
              height: 600,
              child: Stack(
                children: [
                  Positioned(
                    left: 100,
                    top: 200,
                    child: SizedBox(
                      key: targetKey,
                      width: 80,
                      height: 80,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final board = boardKey.currentContext!.findRenderObject() as RenderBox;
      final target = targetKey.currentContext!.findRenderObject() as RenderBox;

      expect(
        isPointInsideBoardRect(
          const BoardPoint(130, 230),
          target,
          board,
          padding: 12,
        ),
        isTrue,
      );
      expect(
        isPointInsideBoardRect(
          const BoardPoint(50, 230),
          target,
          board,
          padding: 12,
        ),
        isFalse,
      );
    });
  });
}
