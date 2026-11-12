import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:larnes_mobile/core/api/api_client.dart';
import 'package:larnes_mobile/core/api/auth_api.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/api/topic_chain_runs_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/auth/auth_session.dart';
import 'package:larnes_mobile/core/locale/locale_controller.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:larnes_mobile/trainers/runtime/topic_chain_resume_store.dart';
import 'package:larnes_mobile/trainers/runtime/topic_chain_run_scope.dart';
import 'package:larnes_mobile/trainers/runtime/topic_chain_run_state.dart';

const _owner = '33333333-3333-4333-8333-333333333333';
const _source = {
  'source': 'homework',
  'childId': '11111111-1111-4111-8111-111111111111',
  'assignmentId': '22222222-2222-4222-8222-222222222222',
  'stepIndex': 0,
};

Map<String, dynamic> _reply({bool completed = false}) => {
  'status': 'ok',
  'run': {
    'id': 'run-a',
    'revision': 0,
    'params': <String, dynamic>{},
    'runtimeSnapshot': <String, dynamic>{},
    'state': <String, dynamic>{
      if (completed) '${topicChainStatePrefix}phase': 'complete',
    },
    'completed': completed,
  },
};

class _RunsApi extends TopicChainRunsApi {
  _RunsApi(this.reply, this.requested) : super(Dio());
  final Completer<Map<String, dynamic>> reply;
  final Completer<void> requested;

  @override
  Future<Map<String, dynamic>> request(Map<String, dynamic> command) {
    expect(command['action'], 'open');
    requested.complete();
    return reply.future;
  }
}

class _ParentApi extends ParentApi {
  _ParentApi(super.client, this.runs);
  final TopicChainRunsApi runs;
  @override
  TopicChainRunsApi get topicChainRuns => runs;
}

class _Client extends ApiClient {
  _Client(this.runs);
  final TopicChainRunsApi runs;
  @override
  ParentApi get parentApi => _ParentApi(this, runs);
}

AuthSession _auth(
  Completer<Map<String, dynamic>> reply,
  Completer<void> requested,
) =>
    AuthSession(apiClient: _Client(_RunsApi(reply, requested)))
      ..applyUser(const AuthUser(id: _owner, accountType: 'parent'));

Widget _app(
  AuthSession auth,
  LocaleController locale, {
  required void Function(VoidCallback) onReady,
  VoidCallback? onComplete,
}) => LocaleScope(
  localeController: locale,
  child: AuthScope(
    authSession: auth,
    child: MaterialApp(
      locale: const Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: TopicChainRunGate(
          runContext: _source,
          params: const {},
          onComplete: onComplete,
          builder: (params, snapshot, audio, complete) {
            onReady(complete);
            return const Text('ready');
          },
        ),
      ),
    ),
  ),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('late open after exit cannot recreate a cleared resume hint', (
    tester,
  ) async {
    final reply = Completer<Map<String, dynamic>>();
    final requested = Completer<void>();
    final auth = _auth(reply, requested);
    final locale = LocaleController();
    await tester.runAsync(
      () => TopicChainResumeStore.remember(_owner, _source),
    );
    await tester.pumpWidget(_app(auth, locale, onReady: (_) {}));
    for (var i = 0; i < 10 && !requested.isCompleted; i++) {
      await tester.pump();
    }
    expect(requested.isCompleted, true);

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async {
      await TopicChainResumeStore.clear(_owner, context: _source);
      reply.complete(_reply());
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();

    expect(await TopicChainResumeStore.read(_owner), isNull);
    expect(tester.takeException(), isNull);
    auth.dispose();
    locale.dispose();
  });

  testWidgets('a completed run clears its hint and delivers completion once', (
    tester,
  ) async {
    final reply = Completer<Map<String, dynamic>>();
    final requested = Completer<void>();
    final auth = _auth(reply, requested);
    final locale = LocaleController();
    VoidCallback? complete;
    var completed = 0;
    await tester.runAsync(
      () => TopicChainResumeStore.remember(_owner, _source),
    );
    await tester.pumpWidget(
      _app(
        auth,
        locale,
        onReady: (value) => complete = value,
        onComplete: () => completed++,
      ),
    );
    for (var i = 0; i < 10 && !requested.isCompleted; i++) {
      await tester.pump();
    }
    expect(requested.isCompleted, true);
    await tester.runAsync(() async {
      reply.complete(_reply(completed: true));
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();

    expect(find.text('ready'), findsOneWidget);
    expect(await TopicChainResumeStore.read(_owner), isNull);
    complete!();
    complete!();
    await tester.pumpAndSettle();
    complete!();
    await tester.pumpAndSettle();
    expect(completed, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
    locale.dispose();
  });
}
