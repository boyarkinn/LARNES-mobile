import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/trainers/audio/trainer_error_reporter.dart';
import 'package:package_info_plus/package_info_plus.dart';

class _Api implements ParentApi {
  final events = <Map<String, Object?>>[];
  int status = 202;
  @override
  Future<int> reportTrainerRuntimeError(Map<String, Object?> event) async {
    events.add(event);
    return status;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  PackageInfo.setMockInitialValues(
    appName: 'LARNES',
    packageName: 'test',
    version: '1.0.12',
    buildNumber: '14',
    buildSignature: 'test',
  );
  testWidgets(
    'native incidents preserve homework scope/version and exclude raw messages and URLs',
    (tester) async {
      final api = _Api();
      reportNativeTrainerAudioIssue(
        api: api,
        trainerKey: 'flashcard-digit-match',
        childId: '11111111-1111-4111-8111-111111111111',
        assignmentId: '22222222-2222-4222-8222-222222222222',
        stepIndex: 2,
        issue: {
          'code': 'AUDIO-PLAYBACK',
          'stage': 'audio-playback',
          'elapsedMs': 42,
          'url': 'https://example.invalid/private',
          'answer': 'private',
          'failedSha256': ['a' * 64, 'bad hash'],
        },
      );
      await tester.pump();
      await tester.pump();
      expect(api.events, hasLength(1));
      final event = api.events.single;
      expect(event['runtime'], 'native');
      expect(event['source'], 'homework');
      expect(event['phase'], 'audio_play');
      expect(event['stepIndex'], 2);
      expect(event['appVersion'], '1.0.12');
      expect(event['buildCode'], 14);
      expect(event['failedSha256'], ['a' * 64]);
      expect(event.containsKey('url'), false);
      expect(event.containsKey('answer'), false);
    },
  );
  testWidgets('a quota response retries the same event without user action', (
    tester,
  ) async {
    final api = _Api()..status = 429;
    reportNativeTrainerAudioIssue(
      api: api,
      trainerKey: 'fruit-count-tap',
      issue: {
        'code': 'AUDIO-TIMEOUT',
        'stage': 'audio-preparation',
        'elapsedMs': 20000,
      },
    );
    await tester.pump();
    await tester.pump();
    expect(api.events, hasLength(1));
    api.status = 202;
    await tester.pump(const Duration(seconds: 15));
    await tester.pump();
    expect(api.events, hasLength(2));
    expect(api.events[0]['eventId'], api.events[1]['eventId']);
    expect(api.events[0]['source'], 'direct');
  });
  testWidgets(
    'queued incidents keep the original homework when the next homework opens',
    (tester) async {
      final api = _Api();
      for (final assignment in [
        '22222222-2222-4222-8222-222222222222',
        '33333333-3333-4333-8333-333333333333',
      ]) {
        reportNativeTrainerAudioIssue(
          api: api,
          trainerKey: 'fruit-count-tap',
          childId: '11111111-1111-4111-8111-111111111111',
          assignmentId: assignment,
          stepIndex: 0,
          issue: {
            'code': 'AUDIO-STORAGE',
            'stage': 'audio-preparation',
            'elapsedMs': 1,
          },
        );
      }
      await tester.pump();
      await tester.pump();
      expect(api.events, hasLength(2));
      expect(
        api.events[0]['assignmentId'],
        '22222222-2222-4222-8222-222222222222',
      );
      expect(
        api.events[1]['assignmentId'],
        '33333333-3333-4333-8333-333333333333',
      );
      expect(api.events[0]['code'], 'AUDIO-STORAGE');
    },
  );
  testWidgets(
    'arbitrary errors cannot send exercise content through the fixed event code',
    (tester) async {
      final api = _Api();
      reportNativeTrainerAudioIssue(
        api: api,
        trainerKey: 'fruit-count-tap',
        issue: {'code': 'raw private sentence', 'stage': 'audio-playback'},
      );
      await tester.pump();
      expect(api.events, isEmpty);
    },
  );
}
