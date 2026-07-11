import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/math/shop_pay/shop_item_icon.dart';
import 'package:larnes_mobile/trainers/math/shop_pay/shop_pay_trainer.dart';
import 'package:larnes_mobile/trainers/math/shop_pay/shop_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_shell.dart';

void main() {
  group('ShopPayTrainer', () {
    testWidgets('uses TrainerScene full-bleed without legacy instruction text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: ShopPayTrainer(
                params: {
                  'item': 'candy',
                  'price': 3,
                  'coinCount': 5,
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TrainerScene), findsOneWidget);
      expect(find.byType(TrainerShell), findsNothing);
      expect(find.byType(ShopScene), findsOneWidget);
      expect(find.textContaining('Положи в кассу'), findsNothing);
      expect(find.textContaining('ВИТРИНА'), findsNothing);
      expect(find.textContaining('КАССА'), findsNothing);
      expect(find.textContaining('МОНЕТКИ'), findsNothing);
      expect(find.textContaining('Молодец'), findsNothing);
      expect(find.textContaining('Перетащи'), findsNothing);

      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('shows pay button after reveal chain', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: ShopPayTrainer(
                params: {
                  'item': 'candy',
                  'price': 2,
                  'coinCount': 3,
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Заплатить'), findsNothing);

      await tester.pump(const Duration(seconds: 4));
      await tester.pump();

      expect(find.text('Заплатить'), findsOneWidget);
    });

    testWidgets('fills bounded stage', (tester) async {
      const stageKey = Key('shop-stage');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              key: stageKey,
              width: 320,
              height: 480,
              child: ShopPayTrainer(
                params: {
                  'item': 'banana',
                  'price': 2,
                  'coinCount': 4,
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.getSize(find.byKey(stageKey)), const Size(320, 480));
      expect(tester.getSize(find.byType(TrainerScene)), const Size(320, 480));

      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('showcase item icon is visible in portrait and landscape', (
      tester,
    ) async {
      Future<void> pumpScene(Size size) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: size.width,
                height: size.height,
                child: ShopPayTrainer(
                  params: const {
                    'item': 'candy',
                    'price': 3,
                    'coinCount': 5,
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
      }

      await pumpScene(const Size(360, 640));
      expect(tester.getSize(find.byType(ShopItemIcon)).width, greaterThanOrEqualTo(60));

      await pumpScene(const Size(640, 360));
      expect(tester.getSize(find.byType(ShopItemIcon)).width, greaterThanOrEqualTo(28));
    });
  });
}
