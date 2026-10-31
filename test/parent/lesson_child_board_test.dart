import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/parent/models/lesson_child_board.dart';

void main() {
  test('document replacement generation is preserved while old responses default to zero', () {
    final base = <String, dynamic>{'status': 'ok', 'lessonSessionId': 'lesson', 'focusRoomId': 'main'};
    expect(LessonChildBoard.fromJson(base)!.sceneGeneration, 0);
    expect(LessonChildBoard.fromJson({...base, 'sceneGeneration': 7})!.sceneGeneration, 7);
  });
  test('room conversation is optional, bounded and validates its mode', () {
    final base = <String, dynamic>{'status': 'ok', 'lessonSessionId': 'lesson', 'focusRoomId': 'room'};
    expect(LessonChildBoard.fromJson(base)!.conversation, isNull);
    expect(LessonChildBoard.fromJson({...base, 'conversation': {'mode': 'talking', 'remainingMs': 20000}})!.conversation,
        {'mode': 'talking', 'remainingMs': 10000});
    expect(LessonChildBoard.fromJson({...base, 'conversation': {'mode': 'recording', 'remainingMs': 1000}})!.conversation, isNull);
    expect(LessonChildBoard.fromJson({...base, 'conversation': {'mode': 'listening', 'remainingMs': -1}})!.conversation, isNull);
  });

  test('personal runs retain separate children, activation and frozen state', () {
    final board = LessonChildBoard.fromJson({
      'status': 'ok', 'lessonSessionId': 'lesson', 'focusRoomId': 'main',
      'roomEpoch': 3,
      'personalRuns': [
        {'id': 'run-one', 'childId': 'child-one', 'activation': 2, 'state': {'answer': '12'}},
        {'id': 'run-two', 'childId': 'child-two', 'activation': 1, 'state': {'answer': '7'}},
      ],
    });
    expect(board, isNotNull);
    expect(board!.roomEpoch, 3);
    expect(board.personalRuns.length, 2);
    expect(board.personalRuns.first['activation'], 2);
    expect(board.personalRuns.first['state']['answer'], '12');
    expect(board.personalRuns.last['state']['answer'], '7');
  });

  test('a snapshot without personal runs still decodes its legacy exercise', () {
    final board = LessonChildBoard.fromJson({
      'status': 'ok', 'lessonSessionId': 'lesson', 'focusRoomId': 'main',
      'exercises': [{'instanceId': 'legacy-card'}],
    });
    expect(board!.personalRuns, isEmpty);
    expect(board.exercises.single['instanceId'], 'legacy-card');
  });
}
