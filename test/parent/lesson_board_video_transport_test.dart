import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/parent/widgets/lesson_board_video_transport.dart';

const lesson = '01940000-0000-4000-8000-000000000001';
const child = '01940000-0000-4000-8000-000000000002';
const asset = '01940000000040008000000000000003';

void main() {
  test(
    'loopback streams Range and HEAD with fresh native credentials, never a bearer URL',
    () async {
      final requests = <Map<String, dynamic>>[];
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final client = HttpClient();
      var credentials = 0;
      final transport = LessonBoardVideoTransport(
        apiBase: Uri.parse('http://127.0.0.1:${server.port}'),
        lessonSessionId: lesson,
        roomId: 'main',
        childId: child,
        authorization: () async => {
          'Authorization': 'Bearer private-${++credentials}',
        },
        isCurrent: () => true,
      );
      addTearDown(() async {
        await transport.close();
        client.close(force: true);
        await server.close(force: true);
      });
      server.listen((request) async {
        requests.add({
          'method': request.method,
          'uri': request.uri,
          'auth': request.headers.value('authorization'),
          'range': request.headers.value('range'),
        });
        request.response.headers
          ..contentType = ContentType('video', 'mp4')
          ..set('Accept-Ranges', 'bytes')
          ..set('ETag', '"immutable-video"');
        if (request.method == 'HEAD') {
          request.response.contentLength = 4096;
        } else {
          request.response.statusCode = 206;
          request.response.headers.set('Content-Range', 'bytes 5-8/4096');
          request.response.contentLength = 4;
          request.response.add([5, 6, 7, 8]);
        }
        await request.response.close();
      });
      final url = await transport.source(asset);
      expect(
        url,
        matches(
          RegExp(
            r'^http://127\.0\.0\.1:[0-9]+/video/[a-f0-9]{48}/[a-f0-9]{32}$',
          ),
        ),
      );
      expect(url, isNot(contains('private-')));
      expect(url, isNot(contains(lesson)));
      final get = await client.getUrl(Uri.parse(url));
      get.headers.set('Range', 'bytes=5-8');
      final response = await get.close();
      expect(response.statusCode, 206);
      expect(response.headers.value('Content-Range'), 'bytes 5-8/4096');
      expect(
        await response.fold<List<int>>([], (out, part) => out..addAll(part)),
        [5, 6, 7, 8],
      );
      final head = await client.headUrl(Uri.parse(url));
      final metadata = await head.close();
      expect(metadata.statusCode, 200);
      expect(metadata.contentLength, 4096);
      await metadata.drain<void>();
      expect(requests.map((request) => request['auth']), [
        'Bearer private-1',
        'Bearer private-2',
      ]);
      expect(requests.first['range'], 'bytes=5-8');
      final upstream = requests.first['uri'] as Uri;
      expect(upstream.path, '/api/classroom/lesson-room/video');
      expect(upstream.queryParameters, {
        'lessonSessionId': lesson,
        'roomId': 'main',
        'childId': child,
        'assetId': asset,
        'content': '1',
      });
    },
  );

  test(
    'proxy denies unknown capabilities/origins/methods and does not follow upstream redirects',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0),
          client = HttpClient();
      var calls = 0, current = true;
      final transport = LessonBoardVideoTransport(
        apiBase: Uri.parse('http://127.0.0.1:${server.port}'),
        lessonSessionId: lesson,
        roomId: 'main',
        authorization: () async => {
          'X-Larnes-Lesson-Guest-Key': 'private-guest',
        },
        isCurrent: () => current,
      );
      addTearDown(() async {
        await transport.close();
        client.close(force: true);
        await server.close(force: true);
      });
      server.listen((request) async {
        calls++;
        expect(
          request.headers.value('X-Larnes-Lesson-Guest-Key'),
          'private-guest',
        );
        request.response.statusCode = 302;
        request.response.headers.set(
          'Location',
          'http://127.0.0.1:${server.port}/must-not-follow',
        );
        await request.response.close();
      });
      final url = Uri.parse(await transport.source(asset));
      Future<int> local(
        String method,
        Uri uri, {
        Map<String, String> headers = const {},
      }) async {
        final request = await client.openUrl(method, uri);
        request.followRedirects = false;
        headers.forEach(request.headers.set);
        final reply = await request.close();
        await reply.drain<void>();
        return reply.statusCode;
      }

      expect(
        await local('GET', url.replace(path: '/video/${'0' * 48}/$asset')),
        403,
      );
      expect(
        await local(
          'GET',
          url,
          headers: {'Origin': 'https://untrusted.invalid'},
        ),
        403,
      );
      expect(await local('DELETE', url), 405);
      expect(await local('GET', url, headers: {'Range': 'bytes=0-1,4-5'}), 416);
      final duplicateOrigin = await client.getUrl(url);
      duplicateOrigin.headers
        ..add('Origin', 'http://127.0.0.1:${server.port}')
        ..add('Origin', 'https://untrusted.invalid');
      final malformed = await duplicateOrigin.close();
      expect(malformed.statusCode, anyOf(400, 403));
      await malformed.drain<void>();
      expect(calls, 0);
      expect(await local('GET', url), 502);
      expect(calls, 1);
      current = false;
      expect(await local('GET', url), 403);
      expect(calls, 1);
      await expectLater(transport.source(asset), throwsStateError);
      await transport.close();
      await expectLater(transport.source(asset), throwsStateError);
    },
  );

  test(
    'playback requests keep scope in Dart, forward commands and never reveal credentials',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      var current = true, requests = 0;
      Map<String, dynamic>? posted;
      final transport = LessonBoardVideoTransport(
        apiBase: Uri.parse('http://127.0.0.1:${server.port}'),
        lessonSessionId: lesson,
        childId: child,
        roomId: 'main',
        authorization: () async => {'Authorization': 'Bearer private-account'},
        isCurrent: () => current,
      );
      addTearDown(() async {
        await transport.close();
        await server.close(force: true);
      });
      server.listen((request) async {
        requests++;
        expect(request.uri.path, '/api/classroom/lesson-room/video-playback');
        expect(request.uri.queryParameters['lessonSessionId'], lesson);
        expect(
          request.headers.value('Authorization'),
          'Bearer private-account',
        );
        if (request.method == 'POST') {
          posted =
              jsonDecode(await utf8.decoder.bind(request).join())
                  as Map<String, dynamic>;
          expect(
            request.headers.value('Origin'),
            'http://127.0.0.1:${server.port}',
          );
        }
        request.response.headers.contentType = ContentType.json;
        final snapshot = {
          'protocolVersion': 1,
          'lessonSessionId': lesson,
          'roomId': 'main',
          'serverAt': 1,
          'sequence': 0,
          'states': [],
          'internal': 'private-account',
        };
        request.response.write(
          jsonEncode(
            request.method == 'POST'
                ? {
                    'accepted': true,
                    'snapshot': snapshot,
                    'internal': 'private-account',
                  }
                : snapshot,
          ),
        );
        await request.response.close();
      });
      final delivery = await transport.playback('GET', null);
      expect(delivery['states'], isEmpty);
      expect(jsonEncode(delivery), isNot(contains('private-account')));
      final ack = await transport.playback('POST', {
        'protocolVersion': 1,
        'type': 'play',
        'lessonSessionId': 'injected',
        'roomId': 'foreign',
        'childId': 'foreign',
      });
      expect(posted?['lessonSessionId'], lesson);
      expect(posted?['roomId'], 'main');
      expect(posted?['childId'], child);
      expect(ack['accepted'], true);
      expect(jsonEncode(ack), isNot(contains('private-account')));
      current = false;
      await expectLater(
        transport.playback('POST', {'type': 'pause'}),
        throwsStateError,
      );
      expect(requests, 2);
    },
  );

  test(
    'closing a room aborts an active video response instead of retaining its bytes',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0),
          client = HttpClient();
      final entered = Completer<void>(), release = Completer<void>();
      final transport = LessonBoardVideoTransport(
        apiBase: Uri.parse('http://127.0.0.1:${server.port}'),
        lessonSessionId: lesson,
        roomId: 'main',
        authorization: () async => {'Authorization': 'Bearer ephemeral'},
        isCurrent: () => true,
      );
      addTearDown(() async {
        if (!release.isCompleted) release.complete();
        await transport.close();
        client.close(force: true);
        await server.close(force: true);
      });
      server.listen((request) async {
        request.response.headers.contentType = ContentType('video', 'mp4');
        request.response.bufferOutput = false;
        request.response.contentLength = 1024 * 1024;
        request.response.add([1, 2, 3, 4]);
        await request.response.flush();
        entered.complete();
        await release.future;
        try {
          await request.response.close();
        } catch (_) {}
      });
      final request = await client.getUrl(
        Uri.parse(await transport.source(asset)),
      );
      final response = await request.close();
      final completed = response.drain<void>().then<Object?>(
        (_) => null,
        onError: (Object error) => error,
      );
      await entered.future;
      await transport.close();
      expect(
        await completed.timeout(const Duration(seconds: 2)),
        isA<Exception>(),
      );
    },
  );
}
