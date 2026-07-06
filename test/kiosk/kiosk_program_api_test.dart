import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/api/child_session_api_client.dart';
import 'package:larnes_mobile/core/api/kiosk_program_api.dart';

import 'memory_child_session_token_storage.dart';

const _programId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const _childId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';

Map<String, dynamic> _snapshotPayload() {
  return {
    'childId': _childId,
    'programId': _programId,
    'title': 'Program A',
    'status': 'in_progress',
    'topicOrdinal': 1,
    'lessonOrdinal': 1,
    'steps': [
      {
        'id': 'step-1',
        'trainerKey': 'demo',
        'params': {},
        'topicOrdinal': 1,
        'lessonOrdinal': 1,
        'isLastInLesson': true,
        'isLastInProgram': false,
      },
    ],
    'unavailableReason': null,
  };
}

void main() {
  group('ChildSessionApiClient', () {
    test('sends child session bearer on program requests', () async {
      RequestOptions? captured;
      final tokenStorage = MemoryChildSessionTokenStorage();
      await tokenStorage.writeToken('child-jwt-token');

      final dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
      final client = ChildSessionApiClient(
        childSessionTokenStorage: tokenStorage,
        dio: dio,
      );
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            captured = options;
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'status': 'success',
                  'snapshot': _snapshotPayload(),
                },
              ),
            );
          },
        ),
      );

      await client.kioskProgramApi.fetchPlaySnapshot(_programId);

      expect(captured?.headers['Authorization'], 'Bearer child-jwt-token');
    });

    test('omits Authorization when child token is absent', () async {
      RequestOptions? captured;
      final client = ChildSessionApiClient(
        childSessionTokenStorage: MemoryChildSessionTokenStorage(),
        dio: Dio(BaseOptions(baseUrl: 'https://example.com')),
      );
      client.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            captured = options;
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'status': 'success',
                  'snapshot': _snapshotPayload(),
                },
              ),
            );
          },
        ),
      );

      await client.kioskProgramApi.fetchPlaySnapshot(_programId);

      expect(captured?.headers.containsKey('Authorization'), isFalse);
    });
  });

  group('KioskProgramApi.fetchPlaySnapshot', () {
    test('parses success payload and hits classroom play-snapshot route', () async {
      RequestOptions? captured;
      final client = ChildSessionApiClient(
        childSessionTokenStorage: MemoryChildSessionTokenStorage(),
        dio: Dio(BaseOptions(baseUrl: 'https://example.com')),
      );
      client.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            captured = options;
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'status': 'success',
                  'snapshot': _snapshotPayload(),
                },
              ),
            );
          },
        ),
      );

      final snapshot = await client.kioskProgramApi.fetchPlaySnapshot(
        _programId,
        locale: 'ru',
      );

      expect(captured?.path, '/api/classroom/programs/$_programId/play-snapshot');
      expect(captured?.queryParameters['locale'], 'ru');
      expect(snapshot.childId, _childId);
      expect(snapshot.programId, _programId);
      expect(snapshot.steps, hasLength(1));
      expect(snapshot.steps.first.trainerKey, 'demo');
    });

    test('throws on unauthorized response', () async {
      final client = ChildSessionApiClient(
        childSessionTokenStorage: MemoryChildSessionTokenStorage(),
        dio: Dio(BaseOptions(baseUrl: 'https://example.com')),
      );
      client.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response(
                  requestOptions: options,
                  statusCode: 401,
                  data: {'message': 'Unauthorized', 'status': 'error'},
                ),
              ),
            );
          },
        ),
      );

      expect(
        () => client.kioskProgramApi.fetchPlaySnapshot(_programId),
        throwsA(
          isA<KioskProgramApiException>().having(
            (error) => error.statusCode,
            'statusCode',
            401,
          ),
        ),
      );
    });

    test('throws on lesson inactive response', () async {
      final client = ChildSessionApiClient(
        childSessionTokenStorage: MemoryChildSessionTokenStorage(),
        dio: Dio(BaseOptions(baseUrl: 'https://example.com')),
      );
      client.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response(
                  requestOptions: options,
                  statusCode: 409,
                  data: {'message': 'Lesson is not active', 'status': 'error'},
                ),
              ),
            );
          },
        ),
      );

      expect(
        () => client.kioskProgramApi.fetchPlaySnapshot(_programId),
        throwsA(
          isA<KioskProgramApiException>()
              .having((error) => error.statusCode, 'statusCode', 409)
              .having((error) => error.message, 'message', 'Lesson is not active'),
        ),
      );
    });
  });

  group('KioskProgramApi.completeLesson', () {
    test('posts ordinals and parses progressStatus', () async {
      RequestOptions? captured;
      final client = ChildSessionApiClient(
        childSessionTokenStorage: MemoryChildSessionTokenStorage(),
        dio: Dio(BaseOptions(baseUrl: 'https://example.com')),
      );
      client.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            captured = options;
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'status': 'success',
                  'progressStatus': 'in_progress',
                },
              ),
            );
          },
        ),
      );

      final result = await client.kioskProgramApi.completeLesson(
        programId: _programId,
        topicOrdinal: 1,
        lessonOrdinal: 2,
        locale: 'ru',
      );

      expect(captured?.path, '/api/classroom/programs/$_programId/complete-lesson');
      expect(captured?.method, 'POST');
      expect(captured?.data, {
        'topicOrdinal': 1,
        'lessonOrdinal': 2,
        'locale': 'ru',
      });
      expect(result.progressStatus, 'in_progress');
      expect(result.isProgramCompleted, isFalse);
    });
  });
}
