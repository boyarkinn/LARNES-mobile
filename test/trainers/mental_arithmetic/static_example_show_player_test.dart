import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/static_example_show/static_example_show_trainer.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_player.dart';

void main() {
  group('TrainerPlayer static-example-show', () {
    testWidgets('loads trainer through player with validated params', (tester) async {
      final l10n = lookupAppLocalizations(const Locale('ru'));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ru'),
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: TrainerPlayer(
                trainerKey: 'static-example-show',
                params: {
                  'operation': 'subtract',
                  'operandA': 10,
                  'operandB': 9,
                  'totalRods': 2,
                },
                l10n: l10n,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(StaticExampleShowTrainer), findsOneWidget);
      expect(find.text('10 − 9'), findsOneWidget);
      expect(find.textContaining('не зарегистрирован'), findsNothing);
    });

    testWidgets('shows validation error for invalid params', (tester) async {
      final l10n = lookupAppLocalizations(const Locale('ru'));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ru'),
          home: Scaffold(
            body: TrainerPlayer(
              trainerKey: 'static-example-show',
              params: {
                'operation': 'subtract',
                'operandA': 3,
                'operandB': 5,
                'totalRods': 1,
              },
              l10n: l10n,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(StaticExampleShowTrainer), findsNothing);
      expect(
        find.text('При вычитании первое число не может быть меньше второго.'),
        findsOneWidget,
      );
    });
  });
}
