import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/parent/models/lesson_call_pass.dart';

void main() {
  test('all entry paths preserve endpoint-only v2 roster and omit child identities', () {
    final roster = LessonCallTeachers.fromJson({
      'scopeId': 'lesson-id',
      'teacherEndpointId': 'teacher',
      'teacherEndpointIds': ['teacher'],
      'participantEndpointIds': ['teacher', 'child'],
      'seats': [{'childId': 'private-child-id', 'endpointId': 'child'}],
    });
    expect(roster.toBoardJson(), {
      'scopeId': 'lesson-id',
      'teacherEndpointId': 'teacher',
      'teacherEndpointIds': ['teacher'],
      'participantEndpointIds': ['teacher', 'child'],
    });
  });
  test('legacy response keeps media teachers but cannot authorize new shared board', () {
    final roster = LessonCallTeachers.fromJson({
      'teacherEndpointId': 'teacher',
      'teacherEndpointIds': ['teacher'],
    });
    expect(roster.ids, ['teacher']);
    expect(roster.scopeId, '');
    expect(roster.participants, isEmpty);
  });
  test('unknown name/role and malformed IDs do not supply board membership', () {
    final roster = LessonCallTeachers.fromJson({
      'role': 'teacher',
      'teacherName': 'teacher',
      'teacherEndpointIds': [null, 123, ''],
      'participantEndpointIds': 'child',
    });
    expect(roster.ids, isEmpty);
    expect(roster.participants, isEmpty);
    expect(roster.toBoardJson()['teacherEndpointId'], isNull);
  });
}
