import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:larnes_mobile/core/api/api_client.dart';
import 'package:larnes_mobile/core/auth/auth_session.dart';
import 'package:larnes_mobile/core/auth/token_storage.dart';
import 'package:larnes_mobile/core/routing/home_path_mapper.dart';
import 'package:larnes_mobile/features/parent/trainers/parent_trainer_play_session.dart';
import 'package:larnes_mobile/trainers/runtime/topic_chain_resume_store.dart';

const _child = '11111111-1111-4111-8111-111111111111';
const _assignment = '22222222-2222-4222-8222-222222222222';
const _owner = '33333333-3333-4333-8333-333333333333';
const _source = {
  'source': 'homework',
  'childId': _child,
  'assignmentId': _assignment,
  'stepIndex': 2,
};
const _path = '/parent/$_child/homework/$_assignment';

class _Token extends TokenStorage {
  @override
  Future<String?> readToken() async => 'unit';
  @override
  Future<void> clearToken() async {}
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.owner, this.setup);
  final String owner;
  final bool setup;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode(
      options.path.contains('auth/session')
          ? {
              'status': 'success',
              'user': {'id': owner, 'accountType': 'parent'},
            }
          : {
              'status': 'success',
              'familySetup': {
                'isComplete': setup,
                'status': setup ? 'complete' : 'unset',
              },
            },
    ),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
  @override
  void close({bool force = false}) {}
}

AuthSession _auth({String owner = _owner, bool setup = true}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://unit.test'))
    ..httpClientAdapter = _Adapter(owner, setup);
  return AuthSession(
    apiClient: ApiClient(dio: dio, tokenStorage: _Token()),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'authenticated cold bootstrap resumes the same homework, and explicit logout clears the hint',
    () async {
      final cacheRoot = await Directory.systemTemp.createTemp('chain-resume-');
      const cacheChannel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(cacheChannel, (_) async => cacheRoot.path);
      addTearDown(() async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(cacheChannel, null);
        if (await cacheRoot.exists()) await cacheRoot.delete(recursive: true);
      });
      await TopicChainResumeStore.remember(_owner, _source);
      final auth = _auth();
      await auth.bootstrap();
      expect(auth.isLoading, false);
      expect(auth.topicChainResumePath, _path);
      expect(
        resolveAppRedirect(
          isLoading: false,
          isAuthenticated: auth.isAuthenticated,
          path: '/splash',
          accountType: 'parent',
          familySetupComplete: true,
          parentTrainerResumePath: auth.topicChainResumePath,
        ),
        _path,
      );
      await auth.logout();
      expect(await TopicChainResumeStore.read(_owner), isNull);
      auth.dispose();
    },
  );
  test(
    'another account and an incomplete family gate never inherit the saved child route',
    () async {
      await TopicChainResumeStore.remember(_owner, _source);
      final other = _auth(owner: '44444444-4444-4444-8444-444444444444');
      await other.bootstrap();
      expect(other.topicChainResumePath, isNull);
      other.dispose();
      final gated = _auth(setup: false);
      await gated.bootstrap();
      expect(gated.topicChainResumePath, isNull);
      expect(
        resolveSplashDestination(
          hasDeviceToken: false,
          isAuthenticated: true,
          accountType: 'parent',
          familySetupComplete: false,
          parentTrainerResumePath: _path,
        ),
        '/parent/family-setup',
      );
      gated.dispose();
    },
  );
  test(
    'kiosk and an existing lesson route take precedence over parent chain resume',
    () {
      expect(
        resolveSplashDestination(
          hasDeviceToken: true,
          isAuthenticated: true,
          accountType: 'parent',
          familySetupComplete: true,
          parentTrainerResumePath: _path,
        ),
        '/kiosk',
      );
      expect(
        resolveAppRedirect(
          isLoading: false,
          isAuthenticated: true,
          path: '/splash',
          accountType: 'parent',
          hasDeviceToken: true,
          familySetupComplete: true,
          parentTrainerResumePath: _path,
        ),
        '/kiosk',
      );
      expect(
        resolveAppRedirect(
          isLoading: false,
          isAuthenticated: true,
          path: '/parent/$_child/lesson',
          accountType: 'parent',
          familySetupComplete: true,
          parentTrainerResumePath: _path,
        ),
        isNull,
      );
    },
  );
  test(
    'explicit exit clears only the active child/context; background leaves it available',
    () async {
      await TopicChainResumeStore.remember(_owner, _source);
      expect(await TopicChainResumeStore.read(_owner), _path);
      await TopicChainResumeStore.clear(
        _owner,
        context: {'source': 'homework', 'childId': 'other'},
      );
      expect(await TopicChainResumeStore.read(_owner), _path);
      await TopicChainResumeStore.clear(
        _owner,
        context: {
          'source': 'homework',
          'childId': _child,
          'assignmentId': _assignment,
        },
      );
      expect(await TopicChainResumeStore.read(_owner), isNull);
    },
  );
  test('expired and malformed route hints cannot create redirects', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      TopicChainResumeStore.key(_owner),
      jsonEncode({'at': 1, 'context': _source}),
    );
    expect(await TopicChainResumeStore.read(_owner), isNull);
    expect(
      isParentTopicChainResumePath('https://evil.test/parent/$_child'),
      false,
    );
    expect(
      isParentTopicChainResumePath(
        '/parent/$_child/trainers/play/other-trainer',
      ),
      false,
    );
    expect(isParentTopicChainResumePath('$_path?from=evil'), false);
    await prefs.setString(
      TopicChainResumeStore.key(_owner),
      jsonEncode({
        'at': DateTime.now()
            .add(const Duration(days: 1))
            .millisecondsSinceEpoch,
        'context': _source,
      }),
    );
    expect(await TopicChainResumeStore.read(_owner), isNull);
    await TopicChainResumeStore.remember(_owner, {..._source, 'stepIndex': -1});
    expect(await TopicChainResumeStore.read(_owner), isNull);
  });
  test(
    'a cancelled destination cannot recreate a cleared resume hint',
    () async {
      var current = true;
      final remembering = TopicChainResumeStore.remember(
        _owner,
        _source,
        isCurrent: () => current,
      );
      current = false;
      await TopicChainResumeStore.clear(_owner);
      await remembering;
      expect(await TopicChainResumeStore.read(_owner), isNull);
    },
  );
  test(
    'a direct hint resumes its old launch, while creating a fresh launch invalidates it',
    () async {
      await ParentTrainerPlaySessionStore.write(
        trainerKey: 'topic-chain-flash',
        params: {},
      );
      final launch = await ParentTrainerPlaySessionStore.read(
        'topic-chain-flash',
      );
      await TopicChainResumeStore.remember(_owner, {
        'source': 'direct',
        'childId': _child,
        'launchId': launch!.launchId,
      });
      expect(
        await TopicChainResumeStore.read(_owner),
        '/parent/$_child/trainers/play/topic-chain-flash',
      );
      await ParentTrainerPlaySessionStore.write(
        trainerKey: 'topic-chain-flash',
        params: {},
      );
      expect(await TopicChainResumeStore.read(_owner), isNull);
    },
  );
}
