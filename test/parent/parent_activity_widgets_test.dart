import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/locale/locale_controller.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/models/parent_activity.dart';
import 'package:larnes_mobile/features/parent/widgets/activity/parent_activity_class_row.dart';
import 'package:larnes_mobile/features/parent/widgets/activity/parent_activity_payments_tabs.dart';
import 'package:larnes_mobile/features/parent/widgets/activity/parent_activity_place_dock.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

void main() {
  Widget wrap(Widget child) {
    final localeController = LocaleController();
    return LocaleScope(
      localeController: localeController,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        home: Scaffold(body: child),
      ),
    );
  }

  const sampleClass = ParentActivityClass(
    groupId: 'group-1',
    groupName: 'Солнышко',
    placeId: 'network:owner-a',
    placeLabel: 'LARNES',
    lineLabel: 'LARNES — «Солнышко»',
    kind: ParentActivityClassKind.center,
    isActive: true,
  );

  const archivedClass = ParentActivityClass(
    groupId: 'group-2',
    groupName: 'Архив',
    placeId: 'network:owner-a',
    placeLabel: 'LARNES',
    lineLabel: 'LARNES — «Архив»',
    kind: ParentActivityClassKind.center,
    isActive: false,
  );

  group('ParentActivityPlaceDock', () {
    testWidgets('shows summary label and switches place', (tester) async {
      String? selectedPlace;

      await tester.pumpWidget(
        wrap(
          ParentActivityPlaceDock(
            places: const [
              ParentActivityPlace(
                placeId: parentActivitySummaryPlaceId,
                kind: ParentActivityPlaceKind.summary,
                label: '',
                archived: false,
                sortOrder: 0,
              ),
              ParentActivityPlace(
                placeId: 'network:owner-a',
                kind: ParentActivityPlaceKind.network,
                label: 'LARNES',
                archived: true,
                sortOrder: 10,
              ),
            ],
            activePlaceId: parentActivitySummaryPlaceId,
            onPlaceSelected: (placeId) => selectedPlace = placeId,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Сводная'), findsOneWidget);
      expect(find.text('LARNES'), findsOneWidget);

      final archivedChip = tester.widget<Opacity>(
        find.ancestor(
          of: find.text('LARNES'),
          matching: find.byType(Opacity),
        ),
      );
      expect(archivedChip.opacity, 0.65);

      await tester.tap(find.text('LARNES'));
      await tester.pumpAndSettle();
      expect(selectedPlace, 'network:owner-a');
    });
  });

  group('ParentActivityPaymentsTabs', () {
    testWidgets('highlights active tab and switches mode', (tester) async {
      ParentActivityPaymentsTab? selected;

      await tester.pumpWidget(
        wrap(
          ParentActivityPaymentsTabs(
            l10n: lookupAppLocalizations(const Locale('ru')),
            activeTab: ParentActivityPaymentsTab.accruals,
            onTabSelected: (tab) => selected = tab,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('НАЧИСЛ'), findsOneWidget);
      expect(find.textContaining('ЧЕКИ'), findsOneWidget);

      await tester.tap(find.textContaining('ЧЕКИ'));
      await tester.pumpAndSettle();
      expect(selected, ParentActivityPaymentsTab.receipts);
    });
  });

  group('ParentActivityClassRow', () {
    testWidgets('invokes tap and dims archived class', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        wrap(
          Column(
            children: [
              ParentActivityClassRow(
                item: sampleClass,
                onTap: () => tapped = true,
              ),
              ParentActivityClassRow(
                item: archivedClass,
                onTap: () {},
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rows = tester.widgetList<Opacity>(find.byType(Opacity)).toList();
      expect(rows.any((row) => row.opacity == 0.78), isTrue);

      await tester.tap(find.text('«Солнышко»'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });
  });
}
