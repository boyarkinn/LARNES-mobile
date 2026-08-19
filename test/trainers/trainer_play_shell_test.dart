import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_play_shell.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_play_theme.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_step_chrome.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ru'),
      home: child,
    );
  }

  group('TrainerPlayShell', () {
    testWidgets('renders parchment HUD with progress and menu', (tester) async {
      var exitCalled = false;

      await tester.pumpWidget(
        wrap(
          TrainerPlayShell(
            currentStep: 2,
            totalSteps: 5,
            menuContinueLabel: 'Продолжить занятие',
            menuExitLabel: 'Выйти',
            onExit: () => exitCalled = true,
            child: const Center(child: Text('stage')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ParentParchmentBackground), findsOneWidget);
      expect(find.text('stage'), findsOneWidget);
      expect(find.bySemanticsLabel('Шаг 2 из 5'), findsOneWidget);
      expect(find.bySemanticsLabel('Меню'), findsOneWidget);
      expect(find.text('Продолжить занятие'), findsNothing);

      final menuButton = tester.getRect(find.bySemanticsLabel('Меню'));
      expect(menuButton.width, 48);
      expect(menuButton.height, 48);
      expect(menuButton.left, greaterThan(0));
      expect(menuButton.left, lessThan(tester.getSize(find.byType(TrainerPlayShell)).width / 2));

      await tester.tap(find.bySemanticsLabel('Меню'));
      await tester.pumpAndSettle();

      expect(find.text('Продолжить занятие'), findsOneWidget);
      expect(find.text('Выйти'), findsOneWidget);

      await tester.tap(find.text('Продолжить занятие'));
      await tester.pumpAndSettle();
      expect(find.text('Продолжить занятие'), findsNothing);

      await tester.tap(find.bySemanticsLabel('Меню'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Выйти'));
      await tester.pumpAndSettle();
      expect(exitCalled, isTrue);
    });

    testWidgets('progress bar uses parent shell accent', (tester) async {
      await tester.pumpWidget(
        wrap(
          TrainerPlayShell(
            currentStep: 1,
            totalSteps: 3,
            menuContinueLabel: 'Продолжить занятие',
            menuExitLabel: 'Выйти',
            onExit: () {},
            child: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final progressFill = tester.widgetList<ColoredBox>(
        find.descendant(
          of: find.byType(TrainerPlayShell),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is ColoredBox &&
                widget.color == TrainerPlayTheme.parent.accent,
          ),
        ),
      );
      expect(progressFill, isNotEmpty);
    });

    testWidgets('stage extends under menu HUD overlay', (tester) async {
      await tester.pumpWidget(
        wrap(
          TrainerPlayShell(
            currentStep: 1,
            totalSteps: 3,
            menuContinueLabel: 'Продолжить занятие',
            menuExitLabel: 'Выйти',
            onExit: () {},
            child: const ColoredBox(
              key: Key('trainer-stage'),
              color: Color(0xFFE4DDD2),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final stageRect = tester.getRect(find.byKey(const Key('trainer-stage')));
      final menuRect = tester.getRect(find.bySemanticsLabel('Меню'));

      expect(stageRect.top, lessThan(menuRect.bottom));
    });

    testWidgets('edgeToEdge keeps parchment stage background', (tester) async {
      await tester.pumpWidget(
        wrap(
          TrainerPlayShell(
            currentStep: 1,
            totalSteps: 1,
            edgeToEdge: true,
            menuContinueLabel: 'Продолжить',
            menuExitLabel: 'Выйти',
            onExit: () {},
            child: const Center(child: Text('stage')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ParentParchmentBackground), findsOneWidget);
      expect(find.text('stage'), findsOneWidget);
    });
  });

  group('TrainerPlayShell admin theme', () {
    testWidgets('uses admin accent in progress bar', (tester) async {
      await tester.pumpWidget(
        wrap(
          TrainerPlayShell(
            currentStep: 1,
            totalSteps: 1,
            theme: TrainerPlayTheme.admin,
            menuContinueLabel: 'Continue check',
            menuExitLabel: 'Back',
            onExit: () {},
            child: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pump();

      final progressFill = tester.widgetList<ColoredBox>(
        find.descendant(
          of: find.byType(TrainerPlayShell),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is ColoredBox &&
                widget.color == TrainerPlayTheme.admin.accent,
          ),
        ),
      );
      expect(progressFill, isNotEmpty);
    });
  });

  group('TrainerStepChromeBar', () {
    testWidgets('shows advance button for non-interactive step', (tester) async {
      var advanced = false;

      await tester.pumpWidget(
        wrap(
          TrainerStepChromeBar(
            chrome: TrainerStepChrome(
              finishLabel: 'Завершить',
              isInteractive: false,
              isLast: false,
              nextLabel: 'Далее',
              onAdvance: () => advanced = true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Далее'), findsOneWidget);

      await tester.tap(find.text('Далее'));
      await tester.pump();
      expect(advanced, isTrue);
    });

    testWidgets('hides chrome for interactive step without error', (tester) async {
      await tester.pumpWidget(
        wrap(
          TrainerStepChromeBar(
            chrome: TrainerStepChrome(
              finishLabel: 'Завершить',
              isInteractive: true,
              isLast: false,
              nextLabel: 'Далее',
              onAdvance: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Далее'), findsNothing);
    });

    testWidgets('shows error message', (tester) async {
      await tester.pumpWidget(
        wrap(
          TrainerStepChromeBar(
            chrome: TrainerStepChrome(
              errorMessage: 'Не удалось сохранить прогресс.',
              finishLabel: 'Завершить',
              isInteractive: true,
              isLast: true,
              nextLabel: 'Далее',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Не удалось сохранить прогресс.'), findsOneWidget);
    });
  });
}
