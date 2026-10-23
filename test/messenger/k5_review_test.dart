// K5: nonvisual controller checks. Expected failures reproduce review findings.
import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:larnes_mobile/features/messenger/messenger_files.dart';
import 'package:larnes_mobile/features/messenger/messenger_api.dart';
import 'package:larnes_mobile/features/messenger/messenger_room.dart';
import 'package:larnes_mobile/features/messenger/messenger_scope.dart';
import 'package:larnes_mobile/features/messenger/messenger_wire.dart';

MessengerScope scope() => MessengerScope.parent(
  accountId: 'synthetic-parent',
  intent: MessengerIntent.child,
  childId: '11111111-1111-4111-8111-111111111111',
  lessonSessionId: '22222222-2222-4222-8222-222222222222',
);

class _Gateway implements MessengerGateway {
  bool networkDown = false;
  int opens = 0;
  int metadata = 0;
  int reads = 0;
  final List<String> sentKeys = [];
  List<MessengerEntry> page = [];
  Completer<MessengerValue<MessengerPage>>? delayedHistory;
  Completer<MessengerValue<Uint8List>>? delayedDownload;

  @override
  Future<MessengerValue<MessengerCapabilities>> open(
    MessengerScope scope,
  ) async {
    opens++;
    return const MessengerOk(MessengerCapabilities(read: true, send: true));
  }

  @override
  Future<MessengerValue<MessengerPage>> history(
    MessengerScope scope, {
    String? after,
    String? before,
  }) async {
    if (delayedHistory != null) return delayedHistory!.future;
    return MessengerOk(MessengerPage(entries: page));
  }

  @override
  Future<MessengerValue<MessengerSent>> send(
    MessengerScope scope, {
    required String body,
    required String clientKey,
    required List<String> fileIds,
    String? replyToMessageId,
  }) async {
    sentKeys.add(clientKey);
    if (networkDown) {
      throw DioException(
        requestOptions: RequestOptions(path: '/synthetic'),
        type: DioExceptionType.connectionError,
      );
    }
    return MessengerOk(
      MessengerSent(
        author: 'Synthetic',
        body: body,
        fileIds: fileIds,
        id: 'message',
        seq: '1',
      ),
    );
  }

  @override
  Future<MessengerValue<void>> markRead(
    MessengerScope scope,
    String cursor,
  ) async {
    reads++;
    return const MessengerOk(null);
  }

  @override
  Future<MessengerValue<Uint8List>> download(MessengerScope scope, String id) =>
      delayedDownload!.future;

  @override
  Future<MessengerValue<MessengerFileCard>> fileMeta(
    MessengerScope scope,
    String id,
  ) async {
    metadata++;
    // Stop before invoking any native filesystem or viewer plugin.
    throw StateError('K5 controlled stop before disk write');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('K5 independent review', () {
    test(
      'K5: the child lesson scope used by LiveLessonRoomScreen must author as the child',
      () {
        expect(
          scope().intent,
          MessengerIntent.child,
          reason:
              'LiveLessonRoomScreen uses this factory while the pupil is in the lesson; the archive needs a separate adult intent',
        );
      },
    );

    test(
      'K5: a real network exception must release sending and permit the same-key retry',
      () async {
        final gateway = _Gateway()..networkDown = true;
        final room = MessengerRoom(scope: scope(), gateway: gateway)
          ..capabilities = const MessengerCapabilities(read: true, send: true)
          ..draft = 'Retry me';
        try {
          try {
            await room.send();
          } catch (_) {
            /* Observe the state after Dio throws. */
          }
          final key = room.pending?.clientKey;
          expect(
            room.sending,
            isFalse,
            reason: 'network errors leave the send button locked indefinitely',
          );
          gateway.networkDown = false;
          await room.send();
          expect(key, isNotNull);
          expect(room.pending, isNull);
          expect(room.entries, hasLength(1));
          expect(gateway.sentKeys, hasLength(2));
          expect(gateway.sentKeys[0], gateway.sentKeys[1]);
        } finally {
          room.dispose();
        }
      },
    );

    test(
      'K5: reattaching a paused lesson room must resume history requests',
      () async {
        final gateway = _Gateway();
        final room = MessengerRoom(scope: scope(), gateway: gateway)..pause();
        try {
          // These are the same calls used by LessonCallStage when reopening a retained room.
          room.setVisible(true);
          await Future<void>.delayed(const Duration(milliseconds: 20));
          expect(
            gateway.opens,
            greaterThan(0),
            reason:
                'setVisible never clears paused; reopening the lesson freezes its chat',
          );
        } finally {
          room.dispose();
        }
      },
    );

    test(
      'K5: moderation wire events must preserve the ID of the message to hide',
      () {
        final event = messengerEntryFromJson({
          'kind': 'access',
          'action': 'redacted',
          'messageId': 'message-to-hide',
          'participantId': 'teacher',
          'seq': '9',
        });
        expect(
          event?.messageId,
          'message-to-hide',
          reason:
              'Flutter discards the target and cannot update already displayed text',
        );
      },
    );

    test(
      'K5: an addressed removal masks old text, files and a late history page',
      () async {
        const original = MessengerEntry(
          seq: '1',
          messageId: 'message',
          author: 'Pupil',
          body: 'PRIVATE',
          fileIds: ['file'],
        );
        final gateway = _Gateway()..page = [original];
        final room = MessengerRoom(scope: scope(), gateway: gateway)
          ..visible = true;
        try {
          await room.pull();
          gateway.page = [
            const MessengerEntry(
              seq: '2',
              access: true,
              action: 'redacted',
              messageId: 'message',
            ),
          ];
          await room.pull();
          expect(room.entries.first.redacted, isTrue);
          expect(room.entries.first.body, isEmpty);
          expect(room.entries.first.fileIds, isEmpty);
          gateway.page = [original];
          room.earlier = '3';
          await room.loadEarlier();
          expect(room.entries.first.redacted, isTrue);
          expect(room.entries.first.body, isEmpty);
        } finally {
          room.dispose();
        }
      },
    );
    test(
      'K5: a history response arriving in background does not advance read state',
      () async {
        final gateway = _Gateway()
          ..delayedHistory = Completer<MessengerValue<MessengerPage>>();
        final room = MessengerRoom(scope: scope(), gateway: gateway)
          ..visible = true;
        try {
          final pull = room.pull();
          for (var n = 0; n < 20; n++) {
            await Future<void>.value();
          }
          room.pause();
          gateway.delayedHistory!.complete(
            const MessengerOk(
              MessengerPage(
                entries: [
                  MessengerEntry(
                    seq: '1',
                    messageId: 'message',
                    body: 'HIDDEN',
                  ),
                ],
              ),
            ),
          );
          await pull;
          expect(room.entries, isEmpty);
          expect(gateway.reads, 0);
        } finally {
          room.dispose();
        }
      },
    );
    test(
      'K5: the real HTTP adapter converts Dio failures into a retryable result',
      () async {
        var requests = 0;
        final dio = Dio()
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                requests++;
                handler.reject(
                  DioException(
                    requestOptions: options,
                    type: DioExceptionType.connectionError,
                  ),
                );
              },
            ),
          );
        final api = MessengerApi(dio: dio);
        final fresh = MessengerScope(
          authorization: () async => <String, String>{},
          credential: MessengerCredential.account,
          intent: MessengerIntent.child,
          lessonSessionId: scope().lessonSessionId,
          ownerKey: 'synthetic',
        );
        final result = await api.open(fresh);
        expect(requests, 1);
        expect(result, isA<MessengerDenied<MessengerCapabilities>>());
        expect(
          (result as MessengerDenied<MessengerCapabilities>).code,
          'unavailable',
        );
      },
    );

    test(
      'K5: complaints keep their retry key and deletion immediately masks the local message',
      () async {
        final bodies = <Map<String, dynamic>>[];
        var fail = true;
        final dio = Dio()
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                bodies.add(Map<String, dynamic>.from(options.data as Map));
                if (fail) {
                  handler.reject(
                    DioException(
                      requestOptions: options,
                      type: DioExceptionType.connectionError,
                    ),
                  );
                } else {
                  handler.resolve(
                    Response(
                      requestOptions: options,
                      statusCode: 200,
                      data: <String, dynamic>{'redacted': true},
                    ),
                  );
                }
              },
            ),
          );
        final fresh = MessengerScope(
          authorization: () async => <String, String>{},
          credential: MessengerCredential.account,
          intent: MessengerIntent.child,
          lessonSessionId: scope().lessonSessionId,
          ownerKey: 'synthetic',
        );
        final room = MessengerRoom(
          scope: fresh,
          gateway: MessengerApi(dio: dio),
        );
        const entry = MessengerEntry(
          seq: '1',
          messageId: 'message',
          authorParticipantId: 'pupil',
          body: 'PRIVATE',
          fileIds: ['file'],
        );
        room.entries.add(entry);
        try {
          await room.command('report', entry);
          expect(room.errorCode, 'unavailable');
          fail = false;
          await room.command('report', entry);
          expect(bodies[0]['clientKey'], bodies[1]['clientKey']);
          expect(room.commandNotice, 'reported');
          await room.command('redact', entry);
          expect(room.entries.single.redacted, isTrue);
          expect(room.entries.single.body, isEmpty);
          expect(room.entries.single.fileIds, isEmpty);
        } finally {
          room.dispose();
          dio.close(force: true);
        }
      },
    );
    test(
      'K5: private file copies expire and a queued write cannot outlive logout clearing',
      () async {
        final root = await Directory.systemTemp.createTemp('larnes-k5-cache-');
        const channel = MethodChannel('plugins.flutter.io/path_provider');
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async => root.path);
        try {
          expect((await getTemporaryDirectory()).path, root.path);
          final a = await MessengerFileCache.write(
            'same.txt',
            Uint8List.fromList([1]),
            ownerKey: 'owner-a',
            valid: () => true,
          );
          final b = await MessengerFileCache.write(
            'same.txt',
            Uint8List.fromList([2]),
            ownerKey: 'owner-b',
            valid: () => true,
          );
          expect(File(a).parent.path, isNot(File(b).parent.path));
          await File(
            a,
          ).setLastModified(DateTime.now().subtract(const Duration(hours: 25)));
          await MessengerFileCache.prune();
          expect(File(a).existsSync(), isFalse);
          expect(File(b).existsSync(), isTrue);
          final late = MessengerFileCache.write(
            'late.txt',
            Uint8List.fromList([3]),
            ownerKey: 'owner-b',
            valid: () => true,
          );
          final observed = expectLater(late, throwsStateError);
          await MessengerFileCache.clear();
          await observed;
          expect(File(b).existsSync(), isFalse);
        } finally {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(channel, null);
          expect(root.path.startsWith(Directory.systemTemp.path), isTrue);
          await root.delete(recursive: true);
        }
      },
    );

    test(
      'K5: a late download must not continue after logout disposes its room',
      () async {
        final gateway = _Gateway()
          ..delayedDownload = Completer<MessengerValue<Uint8List>>();
        final room = MessengerRoom(scope: scope(), gateway: gateway);
        final download = room.openFile('file');
        room.dispose(); // MessengerRooms.clear performs this before clearing the file cache.
        gateway.delayedDownload!.complete(
          MessengerOk(Uint8List.fromList([1, 2, 3])),
        );
        try {
          await download;
        } catch (_) {
          /* A controlled stop prevents native I/O. */
        }
        expect(
          gateway.metadata,
          0,
          reason:
              'the old download continues into metadata/cache/open after disposal',
        );
      },
    );
  }, skip: Platform.environment['K5_REVIEW'] != '1');
}
