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
        {
          'id': 'run-one', 'childId': 'child-one', 'activation': 2,
          'stepIndex': 1,
          'steps': [
            {'id': 'first', 'trainerKey': 'digit-find-tap', 'params': {'values': '7'}},
            {'id': 'second', 'trainerKey': 'digit-find-tap', 'params': {'values': '8'}, 'snapshot': {'version': 1, 'payload': {'seed': 42}}},
          ],
          'state': {'answer': '12'},
        },
        {'id': 'run-two', 'childId': 'child-two', 'activation': 1, 'state': {'answer': '7'}},
      ],
    });
    expect(board, isNotNull);
    expect(board!.roomEpoch, 3);
    expect(board.personalRuns.length, 2);
    expect(board.personalRuns.first['activation'], 2);
    expect(board.personalRuns.first['state']['answer'], '12');
    expect(board.personalRuns.first['stepIndex'], 1);
    expect(board.personalRuns.first['steps'][1]['id'], 'second');
    expect(board.personalRuns.first['steps'][1]['params']['values'], '8');
    expect(board.personalRuns.first['steps'][1]['snapshot']['payload']['seed'], 42);
    expect(board.personalRuns.last['state']['answer'], '7');
  });

  test('keeps viewport resize dimensions and corner for the shared SDK', () {
    final resized = LessonChildBoard.fromJson({
      'status': 'ok', 'lessonSessionId': 'lesson', 'focusRoomId': 'main',
      'navigation': [
        {'connectionId': 'tablet', 'x': -100, 'y': 20,
         'resize': {'corner': 'sw', 'width': 400, 'height': 800}},
      ],
    });
    expect(resized!.navigation.single['resize'], {
      'corner': 'sw', 'width': 400, 'height': 800,
    });
  });

  test(
    'preserves a pupil location for one frame in the active trainer card',
    () {
      final board = LessonChildBoard.fromJson({
        'status': 'ok',
        'lessonSessionId': 'lesson',
        'focusRoomId': 'main',
        'presence': [
          {
            'id': 'child:pupil:tablet',
            'childId': 'pupil',
            'viewport': null,
            'location': {'kind': 'trainer', 'runId': 'run', 'cardId': 'card'},
          },
        ],
      });
      expect(board!.presence.single['location'], {
        'kind': 'trainer',
        'runId': 'run',
        'cardId': 'card',
      });
      expect(board.presence.single['viewport'], isNull);
    },
  );

  test('a snapshot without personal runs still decodes its legacy exercise', () {
    final board = LessonChildBoard.fromJson({
      'status': 'ok', 'lessonSessionId': 'lesson', 'focusRoomId': 'main',
      'exercises': [{'instanceId': 'legacy-card'}],
    });
    expect(board!.personalRuns, isEmpty);
    expect(board.exercises.single['instanceId'], 'legacy-card');
  });

  test('participants keep human-readable places beside their educational ID', () {
    final board = LessonChildBoard.fromJson({
      'status': 'ok', 'lessonSessionId': 'lesson', 'focusRoomId': 'main',
      'participants': [
        {'id': 'pupil', 'name': 'Безымянный', 'seatLabels': ['1', 'ПК 2']},
      ],
    });
    expect(board!.participants.single['id'], 'pupil');
    expect(board.participants.single['seatLabels'], ['1', 'ПК 2']);
  });

  test('scoped participant IDs distinguish missing membership from an empty room', () {
    final snapshot = {
      'status': 'ok',
      'lessonSessionId': 'lesson',
      'focusRoomId': 'room',
    };
    expect(LessonChildBoard.fromJson(snapshot)!.participantIds, isNull);
    expect(
      LessonChildBoard.fromJson({...snapshot, 'participantIds': []})!.participantIds,
      isEmpty,
    );
    expect(
      LessonChildBoard.fromJson({
        ...snapshot,
        'participantIds': ['teacher', 'child', false],
      })!.participantIds,
      ['teacher', 'child'],
    );
  });
}
