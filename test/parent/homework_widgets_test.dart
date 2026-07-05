import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/locale/locale_controller.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/models/parent_homework.dart';
import 'package:larnes_mobile/features/parent/widgets/homework/homework_list_tabs.dart';
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

  group('HomeworkListTabs', () {
    testWidgets('highlights active tab with shell color', (tester) async {
      ParentHomeworkTab? selected;

      await tester.pumpWidget(
        wrap(
          HomeworkListTabs(
            activeTab: ParentHomeworkTab.due,
            counts: const {
              ParentHomeworkTab.due: 2,
              ParentHomeworkTab.completed: 0,
              ParentHomeworkTab.overdue: 1,
              ParentHomeworkTab.upcoming: 0,
            },
            onTabSelected: (tab) => selected = tab,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final activeDecorations = tester.widgetList<Ink>(
        find.byType(Ink),
      ).where((ink) {
        final decoration = ink.decoration;
        return decoration is BoxDecoration && decoration.color == ParentColors.shell;
      });
      expect(activeDecorations.length, 1);

      await tester.tap(find.textContaining('Просрочен'));
      await tester.pumpAndSettle();
      expect(selected, ParentHomeworkTab.overdue);
    });
  });
}
