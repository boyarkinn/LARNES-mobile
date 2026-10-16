import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/parent/models/lesson_child_board.dart';

void main() {
  test('room conversation is optional, bounded and validates its mode', () {
    final base = <String, dynamic>{'status': 'ok', 'lessonSessionId': 'lesson', 'focusRoomId': 'room'};
    expect(LessonChildBoard.fromJson(base)!.conversation, isNull);
    expect(LessonChildBoard.fromJson({...base, 'conversation': {'mode': 'talking', 'remainingMs': 20000}})!.conversation,
        {'mode': 'talking', 'remainingMs': 10000});
    expect(LessonChildBoard.fromJson({...base, 'conversation': {'mode': 'recording', 'remainingMs': 1000}})!.conversation, isNull);
    expect(LessonChildBoard.fromJson({...base, 'conversation': {'mode': 'listening', 'remainingMs': -1}})!.conversation, isNull);
  });
}
