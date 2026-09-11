import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/parent/models/parent_live_lesson_room.dart';
import 'package:larnes_mobile/features/parent/widgets/live_lesson_waiting_view.dart';

void main() {
  testWidgets('shows child name and lesson meta', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LiveLessonWaitingView(
          waiting: ParentLiveLessonWaiting(
            childName: 'Иванова Анна',
            lessonTitle: 'Чтение',
            timeLabel: '16:00–16:45',
          ),
          untitledLabel: 'Урок',
          continueLabel: 'Продолжить занятие',
          exitLabel: 'Выйти',
          waitingLabel: 'Ждём задание',
          onLeave: _noop,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Иванова Анна'), findsOneWidget);
    expect(find.text('Чтение · 16:00–16:45'), findsOneWidget);
  });
}

void _noop() {}
