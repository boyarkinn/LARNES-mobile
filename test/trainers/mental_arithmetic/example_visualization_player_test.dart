import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/example_visualization/example_visualization_trainer.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_player.dart';

void main() {
  group('TrainerPlayer example-visualization', () {
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
                trainerKey: 'example-visualization',
                params: {
                  'example': '+2 -1',
                  'stepPauseSec': 2,
                  'totalRods': 2,
                },
                l10n: l10n,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ExampleVisualizationTrainer), findsOneWidget);
      expect(find.text('+2'), findsOneWidget);
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
              trainerKey: 'example-visualization',
              params: {
                'example': '+10 -1',
                'stepPauseSec': 2,
                'totalRods': 1,
              },
              l10n: l10n,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ExampleVisualizationTrainer), findsNothing);
      expect(find.textContaining('9'), findsOneWidget);
    });
  });
}
