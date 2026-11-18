import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/parent/widgets/lesson_board_live_transport.dart';

class Socket implements LessonLiveSocket {
  final controller = StreamController<dynamic>();
  final sent = <Map<String, dynamic>>[];
  bool closed = false;
  @override
  Stream<dynamic> get messages => controller.stream;
  @override
  Future<void> send(String text) async {
    sent.add(Map<String, dynamic>.from(jsonDecode(text) as Map));
  }

  @override
  Future<void> close() async {
    closed = true;
    unawaited(controller.close());
  }
}

const scope = {
  'lessonSessionId': '31313131-3131-4313-8313-313131313131',
  'roomId': 'main',
  'roomEpoch': 0,
  'sceneIdentity': 'child:one',
  'sceneGeneration': 0,
};
void main() {
  test(
    'actual fallback counter stops at WS activation and resumes after loss',
    () {
      fakeAsync((clock) {
        var active = false, pulls = 0;
        final timer = startLessonBoardFallbackPolling(
          pull: () async {
            pulls++;
          },
          socketActive: () => active,
        );
        clock.elapse(const Duration(seconds: 1));
        expect(pulls, 3);
        active = true;
        clock.elapse(const Duration(seconds: 2));
        expect(pulls, 3);
        active = false;
        clock.elapse(const Duration(milliseconds: 500));
        expect(pulls, 4);
        timer.cancel();
      });
    },
  );
  test(
    'real native socket disconnects and receives a new baseline after return',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0),
          peers = <WebSocket>[],
          hellos = <List<dynamic>>[];
      server.listen((request) async {
        final peer = await WebSocketTransformer.upgrade(request);
        peers.add(peer);
        peer.listen((raw) {
          final frame = jsonDecode(raw as String) as Map;
          if (frame['kind'] == 'hello') {
            hellos.add(frame['features'] as List<dynamic>);
            peer.add(
              jsonEncode({
                'type': 'lesson-board-live',
                'version': 1,
                'kind': 'ready',
                'connectionId': frame['connectionId'],
                'leaseId': 'lease-${peers.length}',
                'scope': scope,
              }),
            );
            peer.add(
              jsonEncode({
                'type': 'lesson-board-live',
                'version': 1,
                'kind': 'state',
              }),
            );
          }
        });
      });
      final states = <bool>[];
      final transport = LessonBoardLiveTransport(
        apiBase: Uri.parse('http://127.0.0.1:${server.port}'),
        isCurrent: () => true,
        ticket: (_) async => {
          'accepted': true,
          'ticket': 'synthetic-ticket',
          'scope': scope,
        },
        receive: (frame) async => frame['kind'] == 'state' ? 'snapshot' : 'ok',
        changed: states.add,
      );
      Future<void> until(bool Function() done) async {
        final deadline = DateTime.now().add(const Duration(seconds: 4));
        while (!done()) {
          expect(DateTime.now().isBefore(deadline), true);
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      }

      try {
        transport.start();
        await until(() => transport.active);
        expect(peers.length, 1);
        expect(
          await transport.sendSamples([
            {'kind': 'cursor', 'pointer': null},
          ]),
          true,
        );
        await peers.first.close();
        await until(() => !transport.active);
        transport.wake();
        await until(() => transport.active && peers.length == 2);
        expect(states, [true, false, true]);
        expect(
          hellos,
          List.filled(2, ['cursor', 'stroke', 'transform', 'state-v2']),
        );
      } finally {
        transport.stop();
        for (final peer in peers) {
          await peer.close();
        }
        await server.close(force: true);
      }
    },
  );
  test(
    'one native socket activates after baseline, pauses polling and fences disposal',
    () async {
      final socket = Socket(), states = <bool>[], frames = <String>[];
      var ticketCalls = 0;
      final transport = LessonBoardLiveTransport(
        apiBase: Uri.parse('http://127.0.0.1'),
        isCurrent: () => true,
        ticket: (id) async {
          ticketCalls++;
          return {
            'accepted': true,
            'ticket': 'synthetic-ticket',
            'scope': scope,
            'features': [
              'cursor',
              'stroke',
              'transform',
              'state-v2',
              'translate',
              'create-shape',
              'group-move',
              'card-move',
              'tools',
              'angle-preview',
            ],
          };
        },
        connect: (uri) async {
          expect(uri.path, '/api/classroom/lesson-live');
          return socket;
        },
        receive: (frame) async {
          frames.add(frame['kind'] as String);
          return frame['kind'] == 'state' ? 'snapshot' : 'ok';
        },
        changed: states.add,
      );
      transport.start();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(ticketCalls, 1);
      expect(socket.sent.single['kind'], 'hello');
      expect(socket.sent.single['features'], [
        'cursor',
        'stroke',
        'transform',
        'state-v2',
        'translate',
        'create-shape',
        'group-move',
        'card-move',
        'tools',
        'angle-preview',
      ]);
      expect(socket.sent.single.containsKey('leaseId'), false);
      expect(transport.active, false);
      socket.controller.add(
        jsonEncode({
          'type': 'lesson-board-live',
          'version': 1,
          'kind': 'ready',
          'connectionId': transport.connectionId,
          'leaseId': 'lease-one',
          'scope': scope,
        }),
      );
      socket.controller.add(
        jsonEncode({
          'type': 'lesson-board-live',
          'version': 1,
          'kind': 'state',
        }),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(transport.active, true);
      expect(states, [true]);
      expect(
        await transport.sendSamples([
          {'kind': 'cursor', 'pointer': null},
        ]),
        true,
      );
      expect(socket.sent.last['leaseId'], 'lease-one');
      transport.sleep();
      expect(transport.active, false);
      expect(socket.closed, true);
      expect(states.last, false);
      transport.stop();
    },
  );
  test('a ticket completing after stop cannot open a socket', () async {
    final grant = Completer<Map<String, dynamic>?>();
    var connections = 0;
    final transport = LessonBoardLiveTransport(
      apiBase: Uri.parse('http://127.0.0.1'),
      isCurrent: () => true,
      ticket: (_) => grant.future,
      connect: (_) async {
        connections++;
        return Socket();
      },
      receive: (_) async => 'ok',
      changed: (_) {},
    );
    transport.start();
    transport.stop();
    grant.complete({
      'accepted': true,
      'ticket': 'synthetic-ticket',
      'scope': scope,
    });
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(connections, 0);
  });
}
