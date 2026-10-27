import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/parent/widgets/homework/native_homework_outbox.dart';
import 'package:larnes_mobile/features/parent/widgets/homework/native_homework_writer.dart';

void main() {
  late Directory directory;
  final scope = List.generate(4, (_) => nativeHomeworkOperationId());
  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'larnes-homework-writer-',
    );
  });
  tearDown(() async {
    await directory.delete(recursive: true);
  });
  NativeHomeworkOutbox store() => NativeHomeworkOutbox(directory, scope);

  test(
    'local disk precedes network, queued changes coalesce and the CAS chain stays ordered',
    () async {
      final disk = store(),
          first = Completer<void>(),
          requests = <Map<String, dynamic>>[];
      final writer = NativeHomeworkWriter(
        outbox: disk,
        generation: 2,
        versionId: 'base',
        cloudVersionId: 'base',
        changed: (_, _) {},
        waitCloud: (_) async {},
        save: (command) async {
          expect(
            (await disk.pending()).any(
              (row) => jsonEncode(row) == jsonEncode(command),
            ),
            isTrue,
          );
          requests.add(command);
          if (requests.length == 1) await first.future;
          return {'level': 'server-durable'};
        },
      );
      try {
        await writer.enqueue([
          {'id': 'first'},
        ]);
        // Let the first operation reach the network before another drawing arrives.
        await Future<void>.delayed(Duration.zero);
        await writer.enqueue([
          {'id': 'second'},
        ]);
        await writer.enqueue([
          {'id': 'latest'},
        ]);
        final pending = await disk.pending();
        expect(pending.length, 2);
        first.complete();
        expect(await writer.flush(), isTrue);
        expect(requests.length, 2);
        expect(requests.last['elements'][0]['id'], 'latest');
        expect(
          requests.last['expectedVersionId'],
          requests.first['operationId'],
        );
        expect(await disk.pending(), isEmpty);
      } finally {
        writer.dispose();
      }
    },
  );
  test(
    'lost ACK survives a new writer and replays the exact same operation',
    () async {
      final disk = store();
      String? accepted;
      final commands = <String>[];
      final first = NativeHomeworkWriter(
        outbox: disk,
        generation: 2,
        versionId: 'backfill-head-with-no-operation',
        cloudVersionId: 'backfill-head-with-no-operation',
        changed: (_, _) {},
        waitCloud: (_) async {},
        save: (command) async {
          accepted = command['operationId'] as String;
          commands.add(jsonEncode(command));
          throw StateError('lost-ACK-after-server-commit');
        },
      );
      await first.enqueue([
        {'id': 'survives'},
      ]);
      expect(await first.flush(), isFalse);
      first.dispose();
      expect((await disk.pending()).single['operationId'], accepted);
      final next = NativeHomeworkWriter(
        outbox: store(),
        generation: 2,
        versionId: accepted,
        cloudVersionId: accepted,
        changed: (_, _) {},
        waitCloud: (id) async {
          expect(id, accepted);
        },
        save: (command) async {
          commands.add(jsonEncode(command));
          return {'level': 'cloud'};
        },
      );
      try {
        await next.restore();
        expect(await next.flush(), isTrue);
        expect(commands[0], commands[1]);
        expect(await disk.pending(), isEmpty);
      } finally {
        next.dispose();
      }
    },
  );
  test(
    'a complete flushed temp file is recovered and account/child scope is isolated',
    () async {
      final disk = store(),
          id = nativeHomeworkOperationId(),
          command = {
            'protocol': 2,
            'operationId': id,
            'generation': 2,
            'expectedVersionId': null,
            'elements': [
              {'id': 'temp-drawing'},
            ],
          };
      await disk.directory.create(recursive: true);
      await File(
        '${disk.directory.path}/$id.tmp',
      ).writeAsString(jsonEncode(command), flush: true);
      expect((await disk.pending()).single, command);
      await disk.put(command);
      await File(
        '${disk.directory.path}/$id.tmp',
      ).writeAsString('{partial', flush: true);
      expect(
        (await disk.pending()).single,
        command,
        reason:
            'an interrupted replacement cannot hide the last durable operation',
      );
      expect(
        await NativeHomeworkOutbox(directory, [
          nativeHomeworkOperationId(),
          ...scope.skip(1),
        ]).pending(),
        isEmpty,
      );
      await disk.acknowledge(id);
      expect(await disk.pending(), isEmpty);
    },
  );
  test(
    'a changed generation retains the old drawing and sends nothing',
    () async {
      final disk = store();
      await disk.put({
        'protocol': 2,
        'operationId': nativeHomeworkOperationId(),
        'generation': 1,
        'expectedVersionId': null,
        'elements': [
          {'id': 'old-branch'},
        ],
      });
      var sent = 0;
      final writer = NativeHomeworkWriter(
        outbox: disk,
        generation: 2,
        versionId: null,
        cloudVersionId: null,
        changed: (_, _) {},
        waitCloud: (_) async {},
        save: (_) async {
          sent++;
          return {};
        },
      );
      try {
        await expectLater(writer.restore(), throwsStateError);
        expect(sent, 0);
        expect(
          (await disk.pending()).single['elements'][0]['id'],
          'old-branch',
        );
      } finally {
        writer.dispose();
      }
    },
  );
  test(
    'local disk failure prevents upload and an unavailable cloud keeps the operation',
    () async {
      final blocker = File('${directory.path}/blocked');
      await blocker.writeAsString('not a directory');
      var sent = 0;
      final writer = NativeHomeworkWriter(
        outbox: NativeHomeworkOutbox(Directory(blocker.path), scope),
        generation: 2,
        versionId: null,
        cloudVersionId: null,
        changed: (_, _) {},
        waitCloud: (_) async {},
        save: (_) async {
          sent++;
          return {};
        },
      );
      try {
        await expectLater(
          writer.enqueue([
            {'id': 'never-uploaded'},
          ]),
          throwsA(isA<FileSystemException>()),
        );
        expect(await writer.flush(), isFalse);
        expect(sent, 0);
      } finally {
        writer.dispose();
      }
      final disk = store(),
          offline = NativeHomeworkWriter(
            outbox: store(),
            generation: 2,
            versionId: null,
            cloudVersionId: null,
            changed: (_, _) {},
            waitCloud: (_) async {
              throw StateError('cloud-unavailable');
            },
            save: (_) async => {'level': 'server-durable'},
          );
      try {
        await offline.enqueue([
          {'id': 'durable-local'},
        ]);
        expect(await offline.flush(), isFalse);
        expect(
          (await disk.pending()).single['elements'][0]['id'],
          'durable-local',
        );
      } finally {
        offline.dispose();
      }
    },
  );
}
