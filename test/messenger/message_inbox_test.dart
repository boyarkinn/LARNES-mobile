import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/messenger/message_inbox.dart';

void main() {
  const now = 1000000;
  Map<String, Object> notice(String id, {int at = now}) => {
    'provider': 'larnes',
    'id': id,
    'lessonSessionId': 'lesson-0001',
    'childId': 'child-00001',
    'author': 'Аня',
    'text': 'Привет',
    'at': at,
  };
  Map<String, Object> inbox(List<Object> items, int count) => {
    'unread': count,
    'items': items,
    'children': {'child-00001': count},
  };
  test('baseline, replay and read suppression use the confirmed inbox', () {
    final tracker = MessageInboxTracker();
    expect(tracker.update(inbox([notice('message-01')], 1), now), isEmpty);
    expect(
      tracker.update(inbox([notice('message-02')], 2), now).single.author,
      'Аня',
    );
    expect(tracker.unread, 2);
    expect(tracker.children['child-00001'], 2);
    expect(tracker.update(inbox([notice('message-02')], 2), now), isEmpty);
    expect(
      tracker.update(
        inbox([notice('message-03')], 3),
        now,
        reading: (_) => true,
      ),
      isEmpty,
    );
    tracker.clear();
    expect(tracker.unread, 0);
    expect(tracker.children, isEmpty);
    expect(tracker.update(inbox([notice('message-04')], 1), now), isEmpty);
  });
  test('old, malformed and future previews never create a notification', () {
    final tracker = MessageInboxTracker();
    tracker.update(inbox([], 0), now);
    expect(
      tracker.update(
        inbox([
          notice('message-01', at: now - 31000),
          notice('message-02', at: now + 6000),
          {'provider': 'larnes', 'text': 'bad'},
        ], 3),
        now,
      ),
      isEmpty,
    );
    expect(
      MessagePreview.parse({...notice('message-03'), 'childId': '../secret'}),
      isNull,
    );
    expect(tracker.update('bad response', now), isEmpty);
    expect(tracker.unread, 3);
  });
}
