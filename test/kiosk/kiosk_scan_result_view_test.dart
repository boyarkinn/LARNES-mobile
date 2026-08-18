import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_scan_result.dart';
import 'package:larnes_mobile/features/kiosk/widgets/kiosk_child_bound_view.dart';
import 'package:larnes_mobile/features/kiosk/widgets/kiosk_scan_result_view.dart';
import 'package:larnes_mobile/features/parent/theme/child_card_colors.dart';
import 'package:larnes_mobile/features/parent/widgets/child_gender_silhouette.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

void main() {
  Widget wrap(KioskScanResult result) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ru'),
      home: Scaffold(
        body: KioskScanResultView(result: result),
      ),
    );
  }

  group('KioskScanResultView', () {
    testWidgets('shows play outcome with child name', (tester) async {
      await tester.pumpWidget(
        wrap(
          const KioskScanResult(
            outcome: KioskScanOutcome.play,
            childId: '88888888-8888-4888-8888-888888888888',
            childDisplayName: 'Анна Петрова',
            childSessionToken: 'child-jwt',
            programId: '77777777-7777-4777-8777-777777777777',
          ),
        ),
      );

      expect(find.text('Анна Петрова'), findsOneWidget);
      expect(find.text('Программа назначена'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('shows no_program as child bound card', (tester) async {
      await tester.pumpWidget(
        wrap(
          const KioskScanResult(
            outcome: KioskScanOutcome.noProgram,
            childId: '88888888-8888-4888-8888-888888888888',
            childDisplayName: 'Сидоров Иван Петрович',
            childSessionToken: 'child-jwt',
            childCardColor: ChildCardColor.sky,
            childGender: 'male',
            childLastName: 'Сидоров',
            childGivenName: 'Иван Петрович',
          ),
        ),
      );

      expect(find.byType(KioskChildBoundView), findsOneWidget);
      expect(find.text('Сидоров'), findsOneWidget);
      expect(find.text('Иван Петрович'), findsOneWidget);
      expect(find.byType(ChildGenderSilhouette), findsOneWidget);
      expect(find.text('Пока нет программы для этого ребёнка.'), findsNothing);
    });
  });
}
