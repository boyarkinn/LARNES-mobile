import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/parent/models/lesson_call_pass.dart';

void main() {
  final main = <String, dynamic>{
    'status': 'success',
    'displayName': 'Pupil',
    'domain': 'meet.example.test',
    'jwt': 'synthetic',
    'room': 'lesson',
    'xmppDomain': 'meet.jitsi',
  };

  test(
    'main pass stays compatible and confirmed breakout survives the stage bridge',
    () {
      final normal = LessonCallPass.fromJson(main)!;
      expect(normal.toStageJson().containsKey('roomJid'), false);
      final room = LessonCallPass.fromJson({
        ...main,
        'room': 'provider',
        'roomJid': 'provider@breakout.meet.jitsi',
        'mainRoom': 'lesson',
      })!;
      expect(room.toStageJson()['roomJid'], 'provider@breakout.meet.jitsi');
      expect(room.toStageJson()['mainRoom'], 'lesson');
      expect(room.addressKey, isNot(normal.addressKey));
    },
  );

  test(
    'foreign, mismatched, wildcard or incomplete breakout addresses are refused',
    () {
      final room = {
        ...main,
        'room': 'provider',
        'roomJid': 'provider@breakout.meet.jitsi',
        'mainRoom': 'lesson',
      };
      for (final invalid in [
        {'roomJid': 'provider@evil.test'},
        {'roomJid': 'other@breakout.meet.jitsi'},
        {'roomJid': null},
        {'mainRoom': null},
        {'mainRoom': 'provider'},
        {'mainRoom': '*'},
      ]) {
        expect(LessonCallPass.fromJson({...room, ...invalid}), null);
      }
    },
  );
}
