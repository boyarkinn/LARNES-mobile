import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/api/api_client.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/auth/auth_session.dart';
import 'package:larnes_mobile/trainers/reading/shared/content_bank_image.dart';

void main() {
  testWidgets(
    'a new material never shows the prior picture while its own image waits',
    (tester) async {
      const firstVersion = '11111111-1111-4111-8111-111111111111';
      const secondVersion = '22222222-2222-4222-8222-222222222222';
      const file = '33333333-3333-4333-8333-333333333333';
      const grant = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
      final firstBytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4z8DwHwAFAAH/iZk9HQAAAABJRU5ErkJggg==',
      );
      final secondBytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGNgYPj/HwADAgH/5ncLrgAAAABJRU5ErkJggg==',
      );
      Map<String, dynamic> image(String version, List<int> bytes) => {
        'url': '/api/trainers/content-bank/images/$version/$file?grant=$grant',
        'byteSize': bytes.length,
        'sha256': sha256.convert(bytes).toString(),
      };
      final dio = Dio(BaseOptions(baseUrl: 'https://unit.invalid'));
      final client = ApiClient(dio: dio);
      dio.interceptors.clear();
      RequestInterceptorHandler? secondRequest;
      RequestOptions? secondOptions;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.uri.path.contains(secondVersion)) {
              secondRequest = handler;
              secondOptions = options;
            } else {
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: firstBytes,
                ),
              );
            }
          },
        ),
      );
      final session = AuthSession(apiClient: client);
      final payload = {
        'contentBank': {
          'materials': [
            {'materialId': 'first', 'image': image(firstVersion, firstBytes)},
            {
              'materialId': 'second',
              'image': image(secondVersion, secondBytes),
            },
          ],
        },
      };
      Widget render(String slug) => AuthScope(
        authSession: session,
        child: MaterialApp(
          home: Scaffold(
            body: ContentBankImageScope(
              payload: payload,
              child: ContentBankImage(
                slug: slug,
                fallback: Text('Fallback $slug'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(render('first'));
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget);
      await tester.pumpWidget(render('second'));
      for (var frame = 0; frame < 10 && secondRequest == null; frame++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(find.byType(Image), findsNothing);
      expect(find.text('Fallback second'), findsOneWidget);
      expect(secondRequest, isNotNull);
      secondRequest!.resolve(
        Response(
          requestOptions: secondOptions!,
          statusCode: 200,
          data: secondBytes,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      session.dispose();
    },
  );
}
