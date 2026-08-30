import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parent trainers play M4 smoke', () {
    late String paramsSource;
    late String playSource;
    late String panelSource;
    late String parentApiSource;
    late String playConfigRouteSource;

    setUp(() {
      paramsSource =
          File('lib/features/parent/screens/trainers/trainer_params_screen.dart').readAsStringSync();
      playSource =
          File('lib/features/parent/screens/trainers/trainer_play_screen.dart').readAsStringSync();
      panelSource = File('lib/features/parent/widgets/trainers/parent_trainer_run_panel.dart')
          .readAsStringSync();
      parentApiSource = File('lib/core/api/parent_api.dart').readAsStringSync();
      playConfigRouteSource = File(
        '../platform/src/app/api/mobile/parent/trainers/[trainerKey]/play-config/route.ts',
      ).readAsStringSync();
    });

    test('params screen uses run panel and direction guard', () {
      expect(paramsSource, contains('ParentTrainerRunPanel'));
      expect(paramsSource, contains('isTrainerDirectionSlug'));
    });

    test('play screen loads session and uses TrainerPlayer without advance API', () {
      expect(playSource, contains('ParentTrainerPlaySessionStore.read'));
      expect(playSource, contains('TrainerPlayShell'));
      expect(playSource, contains('TrainerPlayer'));
      expect(playSource, isNot(contains('advanceHomeworkStep')));
    });

    test('run panel validates, stores session, and opens play route', () {
      expect(panelSource, contains('fetchTrainerPlayConfig'));
      expect(panelSource, contains('validateTrainerParams'));
      expect(panelSource, contains('ParentTrainerPlaySessionStore.write'));
      expect(panelSource, contains('trainers/play/'));
    });

    test('parent API and server route expose play-config with published guard', () {
      expect(parentApiSource, contains('fetchTrainerPlayConfig'));
      expect(playConfigRouteSource, contains('isPublishedTrainerKey'));
      expect(playConfigRouteSource, contains('getAdminMobileTrainerPlayConfig'));
    });
  });
}
