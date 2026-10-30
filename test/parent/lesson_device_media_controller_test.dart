import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/parent/models/lesson_device_media.dart';
import 'package:larnes_mobile/features/parent/widgets/lesson_device_media_controller.dart';

Map<String, dynamic> initial() => {
  'assignment': 'assignment-1',
  'childId': 'child-1',
  'deviceId': 'desk-1',
  'lessonSessionId': 'lesson-1',
  'revision': 0,
  'audio': false,
  'video': false,
  'receive': false,
  'phase': 'idle',
};
void main() {
  test(
    'requests, permission denial, retry and final mute are separate from the board',
    () async {
      var wire = initial();
      final controller = LessonDeviceMediaController(
        childId: 'child-1',
        lessonSessionId: 'lesson-1',
        fetch: () async => LessonDeviceMedia.fromJson(wire),
        send: (body) async {
          final device = body['device'] as String?;
          if (device != null) wire[device] = body['enabled'];
          if (body['failedDevice'] == 'video') {
            wire['video'] = false;
            wire['error'] = 'denied';
          }
          wire['receive'] = wire['audio'] == true || wire['video'] == true;
          wire['revision'] = (wire['revision'] as int) + 1;
          return LessonDeviceMedia.fromJson(wire);
        },
      );
      await controller.refresh();
      expect(controller.needed, isFalse);
      await controller.change('video', true);
      expect(controller.needed, isTrue);
      await controller.report(failedDevice: 'video', error: 'denied');
      expect(controller.needed, isFalse);
      expect(controller.media?.error, 'denied');
      await controller.change('video', true);
      expect(controller.needed, isTrue);
      await controller.change('video', false);
      expect(controller.needed, isFalse);
      controller.dispose();
    },
  );

  test(
    'cancelling while the first request is pending never starts capture from its late reply',
    () async {
      var wire = initial();
      final first = Completer<void>();
      var calls = 0;
      final controller = LessonDeviceMediaController(
        childId: 'child-1',
        lessonSessionId: 'lesson-1',
        fetch: () async => LessonDeviceMedia.fromJson(wire),
        send: (body) async {
          calls++;
          if (calls == 1) await first.future;
          wire['video'] = body['enabled'];
          wire['receive'] = body['enabled'];
          wire['revision'] = (wire['revision'] as int) + 1;
          return LessonDeviceMedia.fromJson(wire);
        },
      );
      await controller.refresh();
      final on = controller.change('video', true);
      await Future<void>.delayed(Duration.zero);
      final off = controller.change('video', false);
      final seen = <bool>[];
      controller.addListener(() => seen.add(controller.needed));
      first.complete();
      await on;
      await off;
      expect(seen, everyElement(isFalse));
      expect(controller.media?.video, isFalse);
      controller.dispose();
    },
  );

  test(
    'a new assignment rejects a late reply and a stale permission failure',
    () async {
      var wire = initial();
      final pending = Completer<LessonDeviceMedia?>();
      var writes = 0;
      final controller = LessonDeviceMediaController(
        childId: 'child-1',
        lessonSessionId: 'lesson-1',
        fetch: () async => LessonDeviceMedia.fromJson(wire),
        send: (_) {
          writes++;
          return pending.future;
        },
      );
      await controller.refresh();
      final old = controller.media!;
      final on = controller.change('video', true);
      await Future<void>.delayed(Duration.zero);
      wire = {...initial(), 'assignment': 'assignment-2'};
      await controller.refresh();
      pending.complete(
        LessonDeviceMedia.fromJson({
          ...initial(),
          'video': true,
          'receive': true,
          'revision': 1,
        }),
      );
      await on;
      await controller.report(
        failedDevice: 'video',
        error: 'denied',
        expected: old,
      );
      expect(writes, 1);
      expect(controller.media?.assignment, 'assignment-2');
      expect(controller.needed, isFalse);
      controller.dispose();
    },
  );

  test(
    'a failed cancel stays locally muted when the old server intent is read again',
    () async {
      final wire = {
        ...initial(),
        'video': true,
        'receive': true,
        'revision': 1,
      };
      final controller = LessonDeviceMediaController(
        childId: 'child-1',
        lessonSessionId: 'lesson-1',
        fetch: () async => LessonDeviceMedia.fromJson(wire),
        send: (_) async => null,
      );
      await controller.refresh();
      expect(controller.needed, isTrue);
      await controller.change('video', false);
      expect(controller.needed, isFalse);
      await controller.refresh();
      expect(controller.needed, isFalse);
      controller.dispose();
    },
  );
}
