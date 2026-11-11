import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/abacus_warmup/abacus_warmup_trainer.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_player.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_widget.dart';

void main() {
  testWidgets(
    'Flutter player completes the warm-up once and starts a new run',
    (tester) async {
      final l10n = lookupAppLocalizations(const Locale('ru'));
      var completions = 0;

      Future<void> open(String key) => tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ru'),
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: TrainerPlayer(
                key: ValueKey(key),
                trainerKey: 'abacus-warmup',
                params: const {'warmupType': 'simple-2digit', 'speed': 'fast'},
                l10n: l10n,
                onComplete: () => completions++,
              ),
            ),
          ),
        ),
      );

      await open('first');
      await tester.pump();
      expect(find.byType(AbacusWarmupTrainer), findsOneWidget);
      expect(find.byType(AbacusWidget), findsOneWidget);

      for (var second = 0; second < 120 && completions == 0; second++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(completions, 1);
      final rods = tester.widget<AbacusWidget>(find.byType(AbacusWidget)).rods;
      expect(rods.map(beadsToDigit).join(), '0000000000000');
      await tester.pump(const Duration(seconds: 10));
      expect(completions, 1);

      await open('second');
      await tester.pump();
      for (var second = 0; second < 120 && completions == 1; second++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(completions, 2);
    },
  );

  testWidgets('closing the Flutter player cancels its future completion', (
    tester,
  ) async {
    final l10n = lookupAppLocalizations(const Locale('ru'));
    var completions = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        home: Scaffold(
          body: TrainerPlayer(
            trainerKey: 'abacus-warmup',
            params: const {'warmupType': 'friends', 'speed': 'fast'},
            l10n: l10n,
            onComplete: () => completions++,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(minutes: 5));
    expect(completions, 0);
  });
}
