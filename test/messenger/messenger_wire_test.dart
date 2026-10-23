import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/messenger/messenger_api.dart';
import 'package:larnes_mobile/features/messenger/messenger_room.dart';
import 'package:larnes_mobile/features/messenger/messenger_scope.dart';
import 'package:larnes_mobile/features/messenger/messenger_wire.dart';

void main() {
  const lesson = '8e64fb69-a5d9-44e6-a987-4f2f59e87dae';
  const child = '11111111-1111-4111-8111-111111111111';

  test('the parent writes as the adult and the guest key stays out of the query', () {
    final parent = MessengerScope.parent(accountId: 'adult', childId: child, lessonSessionId: lesson);
    expect(parent.intent, MessengerIntent.self);
    expect(parent.credential, MessengerCredential.account);
    expect(parent.query(view: 'history')['intent'], 'self');

    const secret = 'guest-secret-not-for-the-url';
    final guest = MessengerScope.guest(lessonSessionId: lesson, admissionId: 'seat-1', childId: child);
    expect(guest.query(view: 'open').values.contains(secret), isFalse);
    expect(guest.sessionKey.contains(secret), isFalse);
    expect(guest.query()['credential'], 'guest');

    final kiosk = MessengerScope.kiosk(childId: child, deviceId: 'device-1', lessonSessionId: lesson);
    expect(kiosk.intent, MessengerIntent.child);
    expect(kiosk.credential, MessengerCredential.kiosk);
  });

  test('a history page parses and a row without a lesson is refused', () {
    final page = messengerPageFromJson({
      'entries': [
        {
          'kind': 'message',
          'message': {
            'authorDisplayName': 'Adult',
            'body': 'hello',
            'fileIds': <String>[],
            'id': '22222222-2222-4222-8222-222222222222',
            'seq': '4',
          },
        },
      ],
      'nextCursor': null,
    });
    expect(page?.entries.single.body, 'hello');
    expect(page?.entries.single.seq, '4');

    expect(messengerArchiveRowFromJson({'conversationId': 'c', 'title': 'Lesson'}), isNull);
    expect(messengerErrorCode({'error': 'forbidden'}, 403), 'forbidden');
  });

  test('a denied lesson clears history and reports forbidden', () async {
    final room = MessengerRoom(
      scope: MessengerScope.parent(accountId: 'adult', childId: child, lessonSessionId: lesson),
      gateway: _ClosedGateway(),
    );
    room.entries.add(const MessengerEntry(body: 'PRIVATE OLD HISTORY', seq: '2'));
    room.visible = true;

    final code = await room.pull();

    expect(code, 'forbidden');
    expect(room.entries, isEmpty);
    expect(room.errorCode, 'forbidden');
    expect(room.capabilities?.read, isFalse);
    room.dispose();
  });
}

class _ClosedGateway implements MessengerGateway {
  @override
  Future<MessengerValue<MessengerCapabilities>> open(MessengerScope scope) async {
    return const MessengerDenied('forbidden');
  }

  @override
  Future<MessengerValue<MessengerArchivePage>> archive(MessengerScope scope, {String? before}) async {
    return const MessengerDenied('forbidden');
  }

  @override
  Future<MessengerValue<void>> cancelFile(MessengerScope scope, String id) async {
    return const MessengerDenied('forbidden');
  }

  @override
  Future<MessengerValue<Uint8List>> download(MessengerScope scope, String id) async {
    return const MessengerDenied('forbidden');
  }

  @override
  Future<MessengerValue<MessengerFileCard>> fileMeta(MessengerScope scope, String id) async {
    return const MessengerDenied('forbidden');
  }

  @override
  Future<MessengerValue<MessengerFileCard>> fileStatus(MessengerScope scope, String id) async {
    return const MessengerDenied('forbidden');
  }

  @override
  Future<MessengerValue<MessengerPage>> history(MessengerScope scope, {String? after, String? before}) async {
    return const MessengerDenied('forbidden');
  }

  @override
  Future<MessengerValue<void>> markRead(MessengerScope scope, String cursor) async {
    return const MessengerDenied('forbidden');
  }

  @override
  Future<MessengerValue<MessengerSent>> send(
    MessengerScope scope, {
    required String body,
    required String clientKey,
    required List<String> fileIds,
    String? replyToMessageId,
  }) async {
    return const MessengerDenied('forbidden');
  }

  @override
  Future<MessengerValue<({int unread, int waitMs})>> summary(MessengerScope scope) async {
    return const MessengerDenied('forbidden');
  }

  @override
  Future<MessengerValue<MessengerFileCard>> upload(
    MessengerScope scope, {
    required String id,
    required String name,
    required String mime,
    required Uint8List bytes,
    CancelToken? cancel,
    void Function(int sent, int total)? onProgress,
  }) async {
    return const MessengerDenied('forbidden');
  }
}
