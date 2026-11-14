import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/api/api_client.dart';
import 'package:larnes_mobile/core/api/lesson_invite_guest_api.dart';
import 'package:larnes_mobile/core/auth/lesson_guest_key_storage.dart';
import 'package:larnes_mobile/core/auth/token_storage.dart';
import 'package:larnes_mobile/core/time/user_time_zone.dart';
import 'package:larnes_mobile/features/parent/models/lesson_child_board.dart';

class _Token extends TokenStorage {
  @override
  Future<String?> readToken() async => 'synthetic-parent';
}

class _Guest extends LessonGuestKeyStorage {
  @override
  Future<String?> readKey() async => 'synthetic-guest';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_timezone');
  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => 'Asia/Tbilisi');
    await UserTimeZone.initialize();
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  for (final guest in [false, true]) {
    test('${guest ? "guest" : "parent"} polling handles ETag, empty 304 and invalidation on failure', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      final client = ApiClient(dio: dio, tokenStorage: _Token());
      final guestApi = LessonInviteGuestApi(client, storage: _Guest());
      var call = 0;
      String? validator;
      dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        expect(options.method, 'GET');
        expect(options.queryParameters['link'], 'writer');
        expect(options.validateStatus(304), isTrue);
        if (guest) expect(options.headers[lessonGuestKeyHeader], 'synthetic-guest');
        if (call == 0) {
          expect(options.headers['If-None-Match'], isNull);
          handler.resolve(Response(requestOptions: options, statusCode: 200,
            headers: Headers.fromMap({'etag': ['W/"one"']}),
            data: {'status': 'ok', 'lessonSessionId': 'lesson', 'focusRoomId': 'main',
              'scene': [], 'sceneRevision': 1, 'personalRuns': [{'id': 'active'}]},
          ));
        } else if (call == 1) {
          expect(options.headers['If-None-Match'], 'W/"one"');
          handler.resolve(Response(requestOptions: options, statusCode: 304,
            headers: Headers.fromMap({'etag': ['W/"one"']}), data: null));
        } else {
          handler.reject(DioException(requestOptions: options, type: DioExceptionType.connectionError));
        }
        call++;
      }));
      Future<LessonChildBoard?> fetch() => guest
          ? guestApi.fetchBoard(token: 'invite', link: 'writer', ifNoneMatch: validator,
              onETag: (value) => validator = value)
          : client.parentApi.fetchChildBoard(childId: 'child', link: 'writer', ifNoneMatch: validator,
              onETag: (value) => validator = value);
      final first = await fetch();
      expect(first?.personalRuns.length, 1);
      expect(validator, 'W/"one"');
      expect(await fetch(), isNull); // No replacement body: retain the applied board.
      expect(validator, 'W/"one"');
      expect(first?.personalRuns.length, 1);
      expect(await fetch(), isNull);
      expect(validator, isNull); // Next request must obtain a fresh snapshot.
      dio.close(force: true);
    });
  }
}
