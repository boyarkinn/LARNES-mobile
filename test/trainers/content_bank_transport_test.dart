import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:larnes_mobile/core/auth/auth_session.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/features/shared/trainer_content_bank_field.dart';
import 'package:larnes_mobile/core/api/api_client.dart';
import 'package:larnes_mobile/core/auth/token_storage.dart';
import 'package:larnes_mobile/features/admin/models/trainer_play.dart';
import 'package:larnes_mobile/features/parent/models/parent_program.dart';
import 'package:larnes_mobile/trainers/reading/shared/content_bank.dart';
import 'package:larnes_mobile/trainers/runtime/validate_params.dart';

class _Token extends TokenStorage {
  @override
  Future<String?> readToken() async => 'test-token';
}

class _Adapter implements HttpClientAdapter {
  RequestOptions? request;
  Object response = const {};
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      jsonEncode(response),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'offline bank requests provide retry copy without transport internals',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://unit.invalid'));
      final client = ApiClient(dio: dio, tokenStorage: _Token());
      dio.interceptors.clear();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
                error: 'internal transport details',
              ),
            );
          },
        ),
      );
      await expectLater(
        client.trainerContentBankApi.browse(
          trainerKey: 'reading-vanish',
          uiLocale: 'en',
        ),
        throwsA(
          predicate(
            (error) =>
                error.toString() ==
                'Exception: No connection. Check your internet and try again.',
          ),
        ),
      );
      await expectLater(
        client.trainerContentBankApi.prepare(
          trainerKey: 'reading-vanish',
          params: {},
          uiLocale: 'ru',
        ),
        throwsA(
          predicate(
            (error) =>
                error.toString() ==
                'Exception: Нет соединения. Проверьте интернет и повторите.',
          ),
        ),
      );
    },
  );
  testWidgets(
    'chooser follows an external form reset and keeps empty bank state usable',
    (tester) async {
      final adapter = _Adapter()
        ..response = {
          'status': 'success',
          'materials': [],
          'selectedMaterials': [],
          'categories': [],
          'total': 0,
        };
      final dio = Dio(BaseOptions(baseUrl: 'https://unit.invalid'))
        ..httpClientAdapter = adapter;
      final client = ApiClient(dio: dio, tokenStorage: _Token());
      dio.interceptors.clear();
      final session = AuthSession(apiClient: client);
      Widget form(List<String> materialIds) => AuthScope(
        authSession: session,
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TrainerContentBankField(
                trainerKey: 'reading-vanish',
                value: jsonEncode({
                  'libraryId': readingContentBankLibraryId,
                  'materialIds': materialIds,
                }),
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(form(['removed-material']));
      await tester.pumpAndSettle();
      expect(find.text('Unavailable material'), findsOneWidget);
      expect(find.text('No matching published materials.'), findsOneWidget);
      await tester.pumpWidget(form([]));
      await tester.pumpAndSettle();
      expect(find.byType(InputChip), findsNothing);
      expect(find.text('Select at least one material.'), findsOneWidget);
      expect(adapter.request?.queryParameters['selectedMaterialIds'], '');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      session.dispose();
    },
  );
  test(
    'new launches require explicit IDs while bounded custom input is preserved for server preparation',
    () {
      expect(
        validateTrainerParams('reading-vanish', {
          'contentBank': {
            'libraryId': readingContentBankLibraryId,
            'materialIds': [],
          },
        }).ok,
        isFalse,
      );
      expect(
        validateTrainerParams('letter-first-by-sound', {
          'contentBank': {
            'libraryId': readingContentBankLibraryId,
            'materialIds': [],
          },
        }).ok,
        isFalse,
      );
      final custom = validateTrainerParams('reading-vanish', {
        'source': 'custom',
        'customText': '  Авторский текст.  ',
        'letterPauseMs': 240,
      });
      expect(custom.ok, isTrue);
      expect(custom.params?['customText'], 'Авторский текст.');
      expect(custom.params?['source'], 'custom');
      expect(custom.params?.containsKey('contentBank'), isFalse);
    },
  );
  testWidgets(
    'native chooser selects a published material without a code catalogue',
    (tester) async {
      final adapter = _Adapter()
        ..response = {
          'status': 'success',
          'materials': [
            {
              'materialId': 'new-material',
              'versionId': 'new-version',
              'title': 'Новый материал',
              'kind': 'text',
              'locale': 'ru-RU',
              'preview': 'Лист упал.',
              'hasImage': false,
            },
          ],
          'categories': [],
          'total': 1,
          'page': 1,
          'pageSize': 25,
        };
      final dio = Dio(BaseOptions(baseUrl: 'https://unit.invalid'))
        ..httpClientAdapter = adapter;
      final client = ApiClient(dio: dio, tokenStorage: _Token());
      dio.interceptors.clear();
      final session = AuthSession(apiClient: client);
      String? selection;
      await tester.pumpWidget(
        AuthScope(
          authSession: session,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: TrainerContentBankField(
                  trainerKey: 'reading-vanish',
                  value: jsonEncode({
                    'libraryId': readingContentBankLibraryId,
                    'materialIds': [],
                  }),
                  onChanged: (value) => selection = value,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Новый материал'), findsOneWidget);
      await tester.ensureVisible(find.text('Новый материал'));
      await tester.tap(find.text('Новый материал'));
      await tester.pumpAndSettle();
      expect((jsonDecode(selection!) as Map)['materialIds'], ['new-material']);
      expect(adapter.request?.queryParameters['trainerKey'], 'reading-vanish');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      session.dispose();
    },
  );
  test(
    'native selection metadata preserves canonical object and arbitrary IDs',
    () {
      final config = TrainerPlayConfig.fromJson({
        'trainerKey': 'reading-vanish',
        'title': 'Reading',
        'direction': 'reading',
        'defaultParams': {
          'contentBank': {
            'libraryId': readingContentBankLibraryId,
            'materialIds': ['new-id'],
          },
        },
        'fields': [
          {
            'key': 'contentBank',
            'labelKey': 'contentBankLabel',
            'type': 'content-bank',
            'selectionMode': 'single',
          },
        ],
      });
      final payload = buildPlayParamsPayload(config, config.initialValues());
      expect(config.fields.single.type, TrainerPlayFieldType.contentBank);
      expect((payload['contentBank'] as Map)['materialIds'], ['new-id']);
    },
  );
  test(
    'prepare sends canonical params and retains returned frozen payload',
    () async {
      final adapter = _Adapter()
        ..response = {
          'status': 'success',
          'params': {
            'contentBank': {'libraryId': readingContentBankLibraryId},
          },
          'runtimeSnapshot': {
            'version': 1,
            'trainerKey': 'reading-vanish',
            'mode': 'materialized',
            'payload': {'text': 'New material.', 'letterPauseMs': 180},
          },
        };
      final dio = Dio(BaseOptions(baseUrl: 'https://unit.invalid'))
        ..httpClientAdapter = adapter;
      final api = ApiClient(
        dio: dio,
        tokenStorage: _Token(),
      ).trainerContentBankApi;
      final content = await api.prepare(
        trainerKey: 'reading-vanish',
        params: {
          'contentBank': {'libraryId': readingContentBankLibraryId},
        },
        uiLocale: 'en',
      );
      expect(
        adapter.request?.path,
        '/api/mobile/trainers/content-bank/prepare',
      );
      expect((adapter.request?.data as Map)['uiLocale'], 'en');
      expect(adapter.request?.headers['Authorization'], 'Bearer test-token');
      expect(
        (content.runtimeSnapshot['payload'] as Map)['text'],
        'New material.',
      );
      await expectLater(
        api.image({'url': 'https://untrusted.invalid/image.png'}),
        throwsFormatException,
      );
    },
  );
  test('image bytes must match the pinned size and digest', () async {
    final bytes = Uint8List.fromList([1, 2, 3]);
    final dio = Dio(BaseOptions(baseUrl: 'https://unit.invalid'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.resolve(
          Response(requestOptions: options, statusCode: 200, data: bytes),
        ),
      ),
    );
    final api = ApiClient(
      dio: dio,
      tokenStorage: _Token(),
    ).trainerContentBankApi;
    final descriptor = {
      'url':
          '/api/trainers/content-bank/images/11111111-1111-4111-8111-111111111111/22222222-2222-4222-8222-222222222222?grant=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      'byteSize': 3,
      'sha256': sha256.convert(bytes).toString(),
    };
    expect(await api.image(descriptor), bytes);
    await expectLater(
      api.image({...descriptor, 'sha256': 'wrong'}),
      throwsFormatException,
    );
    for (final url in [
      '/api/trainers/content-bank/images/../../../../api/mobile/parent/children',
      '/api/trainers/content-bank/images/version/file?grant=unsigned',
      '${descriptor['url']}\n',
      '${descriptor['url']}&extra=1',
    ]) {
      await expectLater(
        api.image({...descriptor, 'url': url}),
        throwsFormatException,
      );
    }
  });
  test('program steps retain exact frozen snapshots and bank error', () {
    final snapshot = ParentProgramPlaySnapshot.fromJson({
      'childId': 'child',
      'programId': 'program',
      'title': 'Program',
      'status': 'active',
      'contentBankError': 'No eligible materials',
      'steps': [
        {
          'id': 'step',
          'trainerKey': 'reading-vanish',
          'params': {},
          'runtimeSnapshot': {
            'version': 1,
            'payload': {'text': 'Issued text'},
          },
        },
      ],
    });
    expect(snapshot.contentBankError, 'No eligible materials');
    expect(
      (snapshot.steps.single.runtimeSnapshot?['payload'] as Map)['text'],
      'Issued text',
    );
  });
}
