import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:larnes_mobile/trainers/intel/fly_track/fly_track_trainer.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_player.dart';
import 'package:larnes_mobile/trainers/runtime/unimplemented_trainer.dart';

void main() {
  group('TrainerPlayer fly-track', () {
    testWidgets('loads native trainer with validated params', (tester) async {
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
                trainerKey: 'fly-track',
                params: {
                  'gridSize': 4,
                  'rounds': 1,
                  'stepCount': 3,
                  'stepPauseSec': 0.5,
                },
                l10n: l10n,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(FlyTrackTrainer), findsOneWidget);
      expect(find.byType(UnimplementedTrainer), findsNothing);
      expect(find.textContaining('не зарегистрирован'), findsNothing);
    });

    testWidgets('shows validation error for out-of-range grid', (tester) async {
      final l10n = lookupAppLocalizations(const Locale('ru'));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ru'),
          home: Scaffold(
            body: TrainerPlayer(
              trainerKey: 'fly-track',
              params: {
                'gridSize': 9,
                'rounds': 1,
                'stepCount': 5,
                'stepPauseSec': 1.5,
              },
              l10n: l10n,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(FlyTrackTrainer), findsNothing);
      expect(find.textContaining('Некорректные параметры'), findsOneWidget);
    });
  });
}
