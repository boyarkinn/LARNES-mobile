import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/api/kiosk_program_api.dart';
import 'package:larnes_mobile/features/kiosk/widgets/kiosk_program_player_view.dart';
import 'package:larnes_mobile/features/parent/models/parent_program.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

const _programId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const _childId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';

class FakeKioskProgramGateway implements KioskProgramGateway {
  FakeKioskProgramGateway({
    required this.snapshot,
    this.loadError,
    this.completeResult = const ParentProgramCompleteLessonResult(
      progressStatus: 'in_progress',
    ),
  });

  ParentProgramPlaySnapshot snapshot;
  KioskProgramApiException? loadError;
  ParentProgramCompleteLessonResult completeResult;
  int completeCallCount = 0;
  int? lastTopicOrdinal;
  int? lastLessonOrdinal;

  @override
  Future<ParentProgramPlaySnapshot> fetchPlaySnapshot(
    String programId, {
    String locale = 'ru',
  }) async {
    if (loadError != null) {
      throw loadError!;
    }
    return snapshot;
  }

  @override
  Future<ParentProgramCompleteLessonResult> completeLesson({
    required String programId,
    required int topicOrdinal,
    required int lessonOrdinal,
    String locale = 'ru',
  }) async {
    completeCallCount += 1;
    lastTopicOrdinal = topicOrdinal;
    lastLessonOrdinal = lessonOrdinal;
    return completeResult;
  }
}

ParentProgramPlaySnapshot _snapshotWithSteps(List<ParentProgramPlayStep> steps) {
  return ParentProgramPlaySnapshot(
    childId: _childId,
    programId: _programId,
    title: 'Program A',
    status: 'in_progress',
    topicOrdinal: 1,
    lessonOrdinal: 1,
    steps: steps,
  );
}

void main() {
  Widget wrap({
    required FakeKioskProgramGateway gateway,
    String? childDisplayName,
    VoidCallback? onExit,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ru'),
      home: KioskProgramPlayerView(
        programId: _programId,
        programApi: gateway,
        childDisplayName: childDisplayName,
        onExit: onExit,
      ),
    );
  }

  group('KioskProgramPlayerView', () {
    testWidgets('loads snapshot and shows child name in eyebrow', (tester) async {
      final gateway = FakeKioskProgramGateway(
        snapshot: _snapshotWithSteps(const [
          ParentProgramPlayStep(
            id: 'step-1',
            trainerKey: 'unknown-trainer',
            params: {},
            topicOrdinal: 1,
            lessonOrdinal: 1,
            isLastInLesson: true,
            isLastInProgram: false,
          ),
        ]),
      );

      await tester.pumpWidget(
        wrap(
          gateway: gateway,
          childDisplayName: 'Анна Петрова',
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('АННА ПЕТРОВА'), findsOneWidget);
      expect(find.text('Program A'), findsOneWidget);
      expect(find.text('Выйти'), findsNothing);
    });

    testWidgets('advances non-interactive steps and completes lesson', (tester) async {
      final gateway = FakeKioskProgramGateway(
        snapshot: _snapshotWithSteps(const [
          ParentProgramPlayStep(
            id: 'step-1',
            trainerKey: 'unknown-trainer',
            params: {},
            topicOrdinal: 1,
            lessonOrdinal: 1,
            isLastInLesson: false,
            isLastInProgram: false,
          ),
          ParentProgramPlayStep(
            id: 'step-2',
            trainerKey: 'unknown-trainer',
            params: {},
            topicOrdinal: 1,
            lessonOrdinal: 1,
            isLastInLesson: true,
            isLastInProgram: false,
          ),
        ]),
      );

      await tester.pumpWidget(wrap(gateway: gateway));
      await tester.pump();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Далее'));
      await tester.pumpAndSettle();

      expect(gateway.completeCallCount, 0);
      expect(find.text('Далее'), findsOneWidget);

      await tester.tap(find.text('Далее'));
      await tester.pumpAndSettle();

      expect(gateway.completeCallCount, 1);
      expect(gateway.lastTopicOrdinal, 1);
      expect(gateway.lastLessonOrdinal, 1);
    });

    testWidgets('shows load error and retries', (tester) async {
      final gateway = FakeKioskProgramGateway(
        snapshot: _snapshotWithSteps(const []),
        loadError: const KioskProgramApiException('Lesson is not active', statusCode: 409),
      );

      await tester.pumpWidget(wrap(gateway: gateway));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Lesson is not active'), findsOneWidget);

      gateway.loadError = null;
      gateway.snapshot = _snapshotWithSteps(const [
        ParentProgramPlayStep(
          id: 'step-1',
          trainerKey: 'unknown-trainer',
          params: {},
          topicOrdinal: 1,
          lessonOrdinal: 1,
          isLastInLesson: true,
          isLastInProgram: false,
        ),
      ]);

      await tester.tap(find.text('Продолжить'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Program A'), findsOneWidget);
    });

    testWidgets('shows completed state and calls onExit', (tester) async {
      var exitCalled = false;
      final gateway = FakeKioskProgramGateway(
        snapshot: _snapshotWithSteps(const [
          ParentProgramPlayStep(
            id: 'step-1',
            trainerKey: 'unknown-trainer',
            params: {},
            topicOrdinal: 1,
            lessonOrdinal: 1,
            isLastInLesson: true,
            isLastInProgram: true,
          ),
        ]),
        completeResult: const ParentProgramCompleteLessonResult(
          progressStatus: 'completed',
        ),
      );

      await tester.pumpWidget(
        wrap(
          gateway: gateway,
          onExit: () => exitCalled = true,
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Завершить'));
      await tester.pumpAndSettle();

      expect(find.text('Программа завершена'), findsOneWidget);

      await tester.tap(find.text('К занятиям'));
      await tester.pumpAndSettle();

      expect(exitCalled, isTrue);
    });
  });
}
