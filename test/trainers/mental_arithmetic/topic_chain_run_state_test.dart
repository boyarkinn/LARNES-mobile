import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:larnes_mobile/trainers/runtime/topic_chain_run_state.dart';
import 'package:larnes_mobile/features/parent/trainers/parent_trainer_play_session.dart';

Map<String, dynamic> copy(Map<String, dynamic> value) =>
    Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const prefix = topicChainStatePrefix;
  final source = {
    'source': 'homework',
    'childId': 'child-a',
    'assignmentId': 'assignment-a',
    'stepIndex': 0,
  };
  late Map<String, dynamic> server;
  late List<Map<String, dynamic>> calls;
  var offline = false, loseAck = false;
  var saves = 0;
  final seen = <String>{};
  Future<Map<String, dynamic>> request(Map<String, dynamic> command) async {
    calls.add(copy(command));
    if (offline) throw StateError('offline');
    if (command['action'] == 'save') {
      if (!seen.contains(command['requestId'])) {
        if (command['revision'] != server['revision']) {
          return {'status': 'conflict', 'run': copy(server)};
        }
        seen.add(command['requestId'] as String);
        saves++;
        server['revision'] = (server['revision'] as int) + 1;
        server['state'] = command['state'];
        server['completed'] =
            (command['state'] as Map)['${prefix}phase'] == 'complete';
      }
      if (loseAck) {
        loseAck = false;
        throw StateError('lost response');
      }
    }
    return {'status': 'ok', 'run': copy(server)};
  }

  TopicChainRunController controller({
    String owner = 'parent-a',
    Map<String, dynamic>? context,
  }) => TopicChainRunController(
    request: request,
    context: context ?? source,
    ownerId: owner,
    locale: 'ru',
  );
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    server = {
      'id': 'run-a',
      'revision': 0,
      'params': {},
      'runtimeSnapshot': {},
      'state': <String, dynamic>{},
      'completed': false,
    };
    calls = [];
    offline = false;
    loseAck = false;
    saves = 0;
    seen.clear();
  });

  test(
    'a lost acknowledgement replays one request after a cold restart, without duplicating the result',
    () async {
      final first = controller();
      await first.open();
      first.record({
        '${prefix}phase': 'review',
        '${prefix}attempts': {
          '0': {
            'firstAnswer': 99,
            'reviewCompleted': false,
            'retryAnswer': null,
          },
        },
      });
      loseAck = true;
      await expectLater(first.flush(), throwsStateError);
      final prefs = await SharedPreferences.getInstance();
      final cached =
          (jsonDecode(prefs.getString(first.storageKey)!) as Map)['command']
              as Map;
      expect(saves, 1);
      first.dispose();
      final restored = controller();
      await restored.open();
      expect(restored.state['${prefix}phase'], 'review');
      expect(saves, 1);
      expect(
        calls.where((c) => c['action'] == 'save').last['requestId'],
        cached['requestId'],
      );
      expect(prefs.getString(restored.storageKey), isNull);
      restored.dispose();
    },
  );

  test(
    'failed writes keep the accepted retry until reconnect and do not turn it into another first answer',
    () async {
      final active = controller();
      await active.open();
      offline = true;
      final state = {
        '${prefix}phase': 'complete',
        '${prefix}attempts': {
          '0': {'firstAnswer': 99, 'reviewCompleted': true, 'retryAnswer': 2},
        },
      };
      active.record(state);
      await expectLater(active.flush(), throwsStateError);
      expect(active.failed, true);
      expect(server['completed'], false);
      offline = false;
      await active.retry();
      expect(server['completed'], true);
      expect(saves, 1);
      expect(
        (server['state'] as Map)['${prefix}attempts'],
        state['${prefix}attempts'],
      );
      active.dispose();
    },
  );

  test(
    'a conflicting writer adopts the server checkpoint and never overwrites its immutable first answer',
    () async {
      final active = controller();
      await active.open();
      server['revision'] = 2;
      server['state'] = {
        '${prefix}phase': 'complete',
        '${prefix}attempts': {
          '0': {
            'firstAnswer': 2,
            'reviewCompleted': false,
            'retryAnswer': null,
          },
        },
      };
      active.record({
        '${prefix}phase': 'review',
        '${prefix}attempts': {
          '0': {
            'firstAnswer': 99,
            'reviewCompleted': false,
            'retryAnswer': null,
          },
        },
      });
      await active.flush();
      expect(saves, 0);
      expect(active.generation, 1);
      expect(active.state, server['state']);
      active.dispose();
    },
  );

  test('pending data is isolated by adult, child and homework step', () async {
    final a = controller(),
        otherAdult = controller(owner: 'parent-b'),
        otherChild = controller(context: {...source, 'childId': 'child-b'}),
        otherStep = controller(context: {...source, 'stepIndex': 1});
    expect(
      {
        a.storageKey,
        otherAdult.storageKey,
        otherChild.storageKey,
        otherStep.storageKey,
      }.length,
      4,
    );
    for (final c in [a, otherAdult, otherChild, otherStep]) {
      c.dispose();
    }
  });

  test(
    'a new direct launch gets a new ID while a cold read retains the previous launch',
    () async {
      await ParentTrainerPlaySessionStore.write(
        trainerKey: 'topic-chain-flash',
        params: {'topicId': 'simple-1'},
      );
      final first = await ParentTrainerPlaySessionStore.read(
        'topic-chain-flash',
      );
      final restored = await ParentTrainerPlaySessionStore.read(
        'topic-chain-flash',
      );
      expect(first!.launchId, restored!.launchId);
      expect(first.launchId, matches(RegExp(r'^[a-f0-9-]{36}$')));
      await ParentTrainerPlaySessionStore.write(
        trainerKey: 'topic-chain-flash',
        params: {'topicId': 'simple-1'},
      );
      final next = await ParentTrainerPlaySessionStore.read(
        'topic-chain-flash',
      );
      expect(next!.launchId, isNot(first.launchId));
    },
  );

  test(
    'legacy direct sessions gain a stable ID once and malformed pending bytes cannot replace the server state',
    () async {
      SharedPreferences.setMockInitialValues({
        'parent-trainer-play:topic-chain-flash': jsonEncode({
          'topicId': 'simple-1',
        }),
      });
      final old = await ParentTrainerPlaySessionStore.read('topic-chain-flash');
      final twice = await ParentTrainerPlaySessionStore.read(
        'topic-chain-flash',
      );
      expect(old!.launchId, twice!.launchId);
      final active = controller();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(active.storageKey, '[]');
      await active.open();
      expect(active.failed, false);
      expect(active.state, isEmpty);
      active.dispose();
    },
  );
}
